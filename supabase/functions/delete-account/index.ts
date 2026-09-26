import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const serviceRoleKey =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const admin = createClient(
  supabaseUrl,
  serviceRoleKey,
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  },
);

async function removeStorageFolder(
  bucket: string,
  path: string,
): Promise<void> {
  const filePaths: string[] = [];
  let offset = 0;

  while (true) {
    const { data, error } = await admin.storage
      .from(bucket)
      .list(path, {
        limit: 1000,
        offset,
      });

    if (error) {
      throw new Error(
        `Failed to list ${bucket}/${path}: ${error.message}`,
      );
    }

    const items = data ?? [];

    if (items.length === 0) {
      break;
    }

    for (const item of items) {
      if (!item.name) {
        continue;
      }

      const itemPath = path
        ? `${path}/${item.name}`
        : item.name;

      // Supabase Storage list() returns folders with id = null.
      if (item.id === null) {
        await removeStorageFolder(bucket, itemPath);
      } else {
        filePaths.push(itemPath);
      }
    }

    if (items.length < 1000) {
      break;
    }

    offset += items.length;
  }

  // Supabase Storage remove() supports batches up to 1000.
  for (let i = 0; i < filePaths.length; i += 1000) {
    const batch = filePaths.slice(i, i + 1000);

    const { error: removeError } =
      await admin.storage
        .from(bucket)
        .remove(batch);

    if (removeError) {
      throw new Error(
        `Failed to remove ${bucket} files: ${removeError.message}`,
      );
    }
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders,
    });
  }

  if (request.method !== 'POST') {
    return new Response(
      JSON.stringify({
        error: 'Method not allowed',
      }),
      {
        status: 405,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }

  try {
    const authorization =
      request.headers.get('Authorization');

    if (!authorization?.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({
          error: 'Unauthorized',
        }),
        {
          status: 401,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      );
    }

    const token =
      authorization.substring('Bearer '.length).trim();

    if (!token) {
      return new Response(
        JSON.stringify({
          error: 'Unauthorized',
        }),
        {
          status: 401,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      );
    }

    const {
      data: { user },
      error: userError,
    } = await admin.auth.getUser(token);

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          error: 'Unauthorized',
        }),
        {
          status: 401,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      );
    }

    const userId = user.id;

    // --------------------------------------------------
    // 1. Community post image cleanup
    // --------------------------------------------------

    const { data: posts, error: postsError } =
      await admin
        .from('community_posts')
        .select('id')
        .eq('user_id', userId);

    if (postsError) {
      throw postsError;
    }

    const postIds = (posts ?? [])
      .map((row: { id?: unknown }) => row.id)
      .filter(
        (id): id is string =>
          typeof id === 'string' &&
          id.length > 0,
      );

    if (postIds.length > 0) {
      const { data: images, error: imagesError } =
        await admin
          .from('community_post_images')
          .select('storage_path')
          .in('post_id', postIds);

      if (imagesError) {
        throw imagesError;
      }

      const paths = (images ?? [])
        .map(
          (row: { storage_path?: unknown }) =>
            row.storage_path,
        )
        .filter(
          (path): path is string =>
            typeof path === 'string' &&
            path.length > 0,
        );

      for (let i = 0; i < paths.length; i += 1000) {
        const batch = paths.slice(i, i + 1000);

        const { error: removeError } =
          await admin.storage
            .from('edible-community')
            .remove(batch);

        if (removeError) {
          throw removeError;
        }
      }
    }

    // --------------------------------------------------
    // 2. Recursive user-owned storage cleanup
    // --------------------------------------------------

    await removeStorageFolder(
      'edible-community',
      userId,
    );

    await removeStorageFolder(
      'travel-memory-photos',
      userId,
    );

    // --------------------------------------------------
    // 3. Explicit user-owned data cleanup
    // --------------------------------------------------

    const { error: tokenError } =
      await admin
        .from('device_push_tokens')
        .delete()
        .eq('user_id', userId);

    if (tokenError) {
      throw tokenError;
    }

    const { error: notificationError } =
      await admin
        .from('app_notifications')
        .delete()
        .eq('user_id', userId);

    if (notificationError) {
      throw notificationError;
    }

    // --------------------------------------------------
    // 4. Auth user deletion
    // --------------------------------------------------

    const { error: deleteError } =
      await admin.auth.admin.deleteUser(userId);

    if (deleteError) {
      throw deleteError;
    }

    return new Response(
      JSON.stringify({
        success: true,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  } catch (error) {
    console.error(
      '[DELETE_ACCOUNT]',
      error,
    );

    // Never expose internal storage/database/auth errors
    // to the client.
    return new Response(
      JSON.stringify({
        error: 'Account deletion failed',
      }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }
});