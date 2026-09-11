import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const languageFallbacks: Record<string, string[]> = {
  tr: ['tr', 'en'], en: ['en'], de: ['de', 'en'], fr: ['fr', 'en'],
  es: ['es', 'en'], it: ['it', 'en'], ar: ['ar', 'en'], pt: ['pt', 'en'],
  ja: ['ja', 'en'], ko: ['ko', 'en'], zh: ['zh', 'en'], ru: ['ru', 'en'], nl: ['nl', 'en'],
};

const clean = (v: unknown) => (v ?? '').toString().trim();
const normalize = (v: string) => clean(v).toLowerCase().replace(/\s+/g, ' ');

function key(body: any) {
  return [body.title, body.city, body.country, body.category, body.locale]
    .map(normalize).join('|');
}

function words(value: string) {
  return new Set(normalize(value).replace(/[^\p{L}\p{N} ]/gu, ' ').split(' ').filter(Boolean));
}

function score(requested: string, candidate: string) {
  const a = normalize(requested);
  const b = normalize(candidate);
  if (!a || !b) return 0;
  if (a === b) return 1;
  if (b.startsWith(`${a} `)) return 0.95;
  if (b.includes(a)) return 0.88;
  const aw = words(a); const bw = words(b);
  if (!aw.size || !bw.size) return 0;
  return (2 * [...aw].filter(x => bw.has(x)).length) / (aw.size + bw.size);
}

async function wiki(language: string, title: string, city: string, country: string) {
  const query = [`"${title}"`, city, country].filter(Boolean).join(' ');
  const searchUrl = new URL(`https://${language}.wikipedia.org/w/rest.php/v1/search/page`);
  searchUrl.searchParams.set('q', query);
  searchUrl.searchParams.set('limit', '8');

  const search = await fetch(searchUrl, { headers: { 'User-Agent': 'Edible/1.0 content-description-resolver' } });
  if (!search.ok) return null;
  const data = await search.json();
  const pages = Array.isArray(data?.pages) ? data.pages : [];
  if (!pages.length) return null;

  let chosen: any = null; let best = 0;
  for (const page of pages) {
    const value = score(title, clean(page?.title));
    if (value > best) { best = value; chosen = page; }
  }
  if (!chosen || best < 0.68) return null;

  const titlePath = encodeURIComponent(clean(chosen.title).replace(/ /g, '_'));
  const summaryUrl = `https://${language}.wikipedia.org/api/rest_v1/page/summary/${titlePath}`;
  const summary = await fetch(summaryUrl, { headers: { 'User-Agent': 'Edible/1.0 content-description-resolver' } });
  if (!summary.ok) return null;
  const item = await summary.json();
  const extract = clean(item?.extract);
  const pageUrl = clean(item?.content_urls?.desktop?.page);
  if (extract.length < 100 || !pageUrl) return null;

  return { extract, pageUrl, language };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return new Response('Method not allowed', { status: 405, headers: cors });

  try {
    const body = await req.json();
    const title = clean(body.title);
    const locale = normalize(body.locale).split('-')[0] || 'en';
    const city = clean(body.city);
    const country = clean(body.country);
    const category = clean(body.category);
    const cacheKey = clean(body.cache_key) || key(body);
    if (!title) return new Response(JSON.stringify({ error: 'title_required' }), { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } });

    const { data: cached } = await supabase
      .from('content_description_resolutions')
      .select('short_description,description,source,source_url')
      .eq('cache_key', cacheKey)
      .maybeSingle();
    if (cached?.description) {
      return new Response(JSON.stringify(cached), { headers: { ...cors, 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=86400' } });
    }

    let result: any = null;
    for (const language of (languageFallbacks[locale] ?? ['en'])) {
      result = await wiki(language, title, city, country);
      if (result) break;
    }

    if (!result) {
      return new Response(JSON.stringify({ error: 'description_not_found' }), { status: 404, headers: { ...cors, 'Content-Type': 'application/json' } });
    }

    const shortDescription = result.extract.length > 220
      ? `${result.extract.slice(0, 217).trimEnd()}...`
      : result.extract;

    const payload = {
      cache_key: cacheKey,
      title,
      locale,
      city,
      country,
      category,
      short_description: shortDescription,
      description: result.extract,
      source: `Wikipedia (${result.language})`,
      source_url: result.pageUrl,
    };

    await supabase.from('content_description_resolutions').upsert(payload, { onConflict: 'cache_key' });

    return new Response(JSON.stringify(payload), { headers: { ...cors, 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=86400' } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : 'unknown_error' }), { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } });
  }
});
