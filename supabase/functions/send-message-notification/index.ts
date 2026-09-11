import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { SignJWT, importPKCS8 } from 'npm:jose@6.1.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const serviceAccountRaw = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON') ?? '';

const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function getAccessToken() {
  if (!serviceAccountRaw) return null;
  const account = JSON.parse(serviceAccountRaw);
  const key = await importPKCS8(account.private_key.replace(/\\n/g, '\n'), 'RS256');
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
  })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(account.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) throw new Error(`FCM OAuth failed: ${await response.text()}`);
  const json = await response.json();
  return json.access_token as string;
}

async function sendToToken(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          android: { priority: 'high' },
          apns: {
            payload: {
              aps: { sound: 'default', badge: 1 },
            },
          },
        },
      }),
    },
  );

  return response.ok;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      });
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: authData, error: authError } = await admin.auth.getUser(token);
    if (authError || !authData.user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      });
    }

    const { conversation_id: conversationId } = await request.json();
    if (!conversationId) throw new Error('conversation_id is required');

    const { data: participants, error: participantsError } = await admin
      .from('direct_conversation_participants')
      .select('user_id')
      .eq('conversation_id', conversationId);
    if (participantsError) throw participantsError;

    const recipient = (participants ?? []).find(
      (item) => item.user_id !== authData.user.id,
    );
    if (!recipient) {
      return new Response(JSON.stringify({ sent: 0, reason: 'no_recipient' }), {
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      });
    }

    const { data: latestMessage, error: messageError } = await admin
      .from('direct_messages')
      .select('id,body,sender_id')
      .eq('conversation_id', conversationId)
      .eq('sender_id', authData.user.id)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (messageError) throw messageError;
    if (!latestMessage) {
      return new Response(JSON.stringify({ sent: 0, reason: 'no_message' }), {
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      });
    }

    const { data: profile } = await admin
      .from('profiles')
      .select('display_name')
      .eq('id', authData.user.id)
      .maybeSingle();

    const title = profile?.display_name?.trim() || 'Edible kullanıcısı';
    const body = String(latestMessage.body).slice(0, 240);

    const { data: tokens, error: tokenError } = await admin
      .from('device_push_tokens')
      .select('id,token')
      .eq('user_id', recipient.user_id)
      .eq('enabled', true);
    if (tokenError) throw tokenError;

    if (!serviceAccountRaw || !tokens?.length) {
      return new Response(JSON.stringify({ sent: 0, reason: !serviceAccountRaw ? 'fcm_not_configured' : 'no_tokens' }), {
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      });
    }

    const account = JSON.parse(serviceAccountRaw);
    const accessToken = await getAccessToken();
    if (!accessToken) throw new Error('FCM service account is not configured');

    let sent = 0;
    for (const device of tokens) {
      const ok = await sendToToken(
        accessToken,
        account.project_id,
        device.token,
        title,
        body,
        {
          route: `/messages/chat/${authData.user.id}`,
          conversation_id: String(conversationId),
          message_id: String(latestMessage.id),
          type: 'message',
        },
      );

      if (ok) {
        sent += 1;
      } else {
        await admin
          .from('device_push_tokens')
          .update({ enabled: false })
          .eq('id', device.id);
      }
    }

    return new Response(JSON.stringify({ sent }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    });
  } catch (error) {
    console.error('[send-message-notification]', error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    });
  }
});
