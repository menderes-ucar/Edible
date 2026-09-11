import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization?.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const token = authorization.substring('Bearer '.length).trim();
    const { data: { user }, error: userError } = await admin.auth.getUser(token);
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const userId = user.id;

    // Preserve user content cleanup for the community bucket before the auth
    // user is removed. DB foreign keys then clean up the related rows.
    const { data: posts } = await admin
      .from('community_posts')
      .select('id')
      .eq('user_id', userId);
    const postIds = (posts ?? [])
      .map((row: { id?: unknown }) => row.id)
      .filter((id): id is string => typeof id === 'string' && id.length > 0);

    let paths: string[] = [];
    if (postIds.length > 0) {
      const { data: images } = await admin
        .from('community_post_images')
        .select('storage_path')
        .in('post_id', postIds);
      paths = (images ?? [])
        .map((row: { storage_path?: unknown }) => row.storage_path)
        .filter((path): path is string => typeof path === 'string' && path.length > 0);
    }

    if (paths.length > 0) {
      for (let i = 0; i < paths.length; i += 100) {
        await admin.storage.from('edible-community').remove(paths.slice(i, i + 100));
      }
    }

    // These are safe to remove explicitly and avoid orphaned notification data
    // even if a project schema was created without ON DELETE CASCADE.
    await admin.from('device_push_tokens').delete().eq('user_id', userId);
    await admin.from('app_notifications').delete().eq('user_id', userId);

    const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
    if (deleteError) throw deleteError;

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('[DELETE_ACCOUNT]', error);
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : 'Account deletion failed' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
