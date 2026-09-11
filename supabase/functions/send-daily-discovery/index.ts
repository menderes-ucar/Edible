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

const copy: Record<string, [string, string]> = {
  tr: ['Bugün Edible’da ✨', 'Bugün yeni bir yer keşfet, kültürünü öğren ve bir sonraki yolculuğuna ilham kat.'],
  en: ['Today on Edible ✨', 'Discover a new place, learn its culture and find inspiration for your next journey.'],
  de: ['Heute auf Edible ✨', 'Entdecke einen neuen Ort, lerne seine Kultur kennen und plane deine nächste Reise.'],
  fr: ['Aujourd’hui sur Edible ✨', 'Découvre un nouvel endroit, sa culture et prépare ta prochaine escapade.'],
  es: ['Hoy en Edible ✨', 'Descubre un lugar nuevo, conoce su cultura y prepara tu próximo viaje.'],
  it: ['Oggi su Edible ✨', 'Scopri un nuovo luogo, conosci la sua cultura e prepara il tuo prossimo viaggio.'],
};

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
  return (await response.json()).access_token as string;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const secret = Deno.env.get('DAILY_NOTIFICATION_CRON_SECRET');
    const supplied = request.headers.get('x-edible-cron-secret');
    if (secret && supplied !== secret) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      });
    }

    const today = new Date().toISOString().slice(0, 10);
    const { data: devices, error } = await admin
      .from('device_push_tokens')
      .select('id,user_id,token,language_code')
      .eq('enabled', true);
    if (error) throw error;

    if (!serviceAccountRaw || !devices?.length) {
      return new Response(JSON.stringify({ sent: 0, reason: !serviceAccountRaw ? 'fcm_not_configured' : 'no_devices' }), {
        headers: { ...corsHeaders, 'content-type': 'application/json' },
      });
    }

    const account = JSON.parse(serviceAccountRaw);
    const accessToken = await getAccessToken();
    if (!accessToken) throw new Error('FCM service account is not configured');

    const byUser = new Map<string, typeof devices>();
    for (const device of devices) {
      const list = byUser.get(device.user_id) ?? [];
      list.push(device);
      byUser.set(device.user_id, list);
    }

    let sent = 0;
    for (const [userId, userDevices] of byUser) {
      const language = String(userDevices[0].language_code ?? 'en').toLowerCase();
      const [title, body] = copy[language] ?? copy.en;

      await admin.from('app_notifications').upsert({
        user_id: userId,
        type: 'daily_discovery',
        title,
        body,
        data: { route: '/', type: 'daily_discovery' },
        dedupe_key: `daily:${today}:${userId}`,
      }, { onConflict: 'dedupe_key' });

      for (const device of userDevices) {
        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              authorization: `Bearer ${accessToken}`,
              'content-type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token: device.token,
                notification: { title, body },
                data: { route: '/', type: 'daily_discovery' },
                android: { priority: 'normal' },
                apns: { payload: { aps: { sound: 'default', badge: 1 } } },
              },
            }),
          },
        );

        if (response.ok) {
          sent += 1;
        } else {
          await admin.from('device_push_tokens').update({ enabled: false }).eq('id', device.id);
        }
      }
    }

    return new Response(JSON.stringify({ sent, users: byUser.size }), {
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    });
  } catch (error) {
    console.error('[send-daily-discovery]', error);
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'content-type': 'application/json' },
    });
  }
});
