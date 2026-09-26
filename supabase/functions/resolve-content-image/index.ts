import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type Body = {
  title?: string;
  city?: string;
  country?: string;
  locale?: string;
  excludeProviders?: string[];
};

type Candidate = {
  imageUrl: string;
  provider: string;
  sourceUrl?: string;
  attribution?: string;
  score: number;
};

const clean = (v: unknown) => typeof v === 'string' ? v.trim() : '';

function normalize(v: string): string {
  return v.toLocaleLowerCase('en')
    .replace(/[^\p{L}\p{N} ]/gu, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function similarity(a: string, b: string): number {
  const x = normalize(a), y = normalize(b);
  if (!x || !y) return 0;
  if (x === y) return 1;
  if (y.includes(x)) return 0.95;
  const xt = new Set(x.split(' ').filter(w => w.length > 2));
  const yt = new Set(y.split(' ').filter(w => w.length > 2));
  if (!xt.size || !yt.size) return 0;
  let common = 0;
  for (const word of xt) if (yt.has(word)) common++;
  return common / xt.size;
}

function queries(body: Body): string[] {
  const title = clean(body.title);
  const city = clean(body.city);
  const country = clean(body.country);
  const values = [
    [title, city, country].filter(Boolean).join(' '),
    [title, city].filter(Boolean).join(' '),
    [title, country].filter(Boolean).join(' '),
    title,
  ];
  return [...new Set(values.filter(Boolean))];
}

function excluded(body: Body, provider: string): boolean {
  return (body.excludeProviders ?? []).some(p => p.trim().toLowerCase() === provider);
}

function scoreCandidate(body: Body, text: string, bonus = 0): number {
  const title = clean(body.title);
  const city = clean(body.city);
  const country = clean(body.country);
  const titleScore = similarity(title, text);
  const cityScore = city ? similarity(city, text) : 0;
  const countryScore = country ? similarity(country, text) : 0;
  return Math.min(1.8, titleScore * 0.68 + cityScore * 0.22 + countryScore * 0.10 + bonus);
}

async function openverse(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'openverse')) return null;
  let best: Candidate | null = null;

  await Promise.all(queries(body).slice(0, 3).map(async query => {
    try {
      const url = new URL('https://api.openverse.org/v1/images/');
      url.searchParams.set('q', query);
      url.searchParams.set('page_size', '30');
      url.searchParams.set('license', 'by,by-sa,cc0,pdm');
      const res = await fetch(url, { headers: { 'User-Agent': 'Edible/1.0' } });
      if (!res.ok) return;
      const data = await res.json();
      const rows = Array.isArray(data?.results) ? data.results : [];

      for (const row of rows) {
        const imageUrl = clean(row?.url) || clean(row?.thumbnail);
        if (!imageUrl || row?.watermarked === true) continue;
        const width = Number(row?.width ?? 0), height = Number(row?.height ?? 0);
        if (width && height && (width < 500 || height < 300)) continue;
        const license = clean(row?.license).toLowerCase();
        if (!(license === 'cc0' || license === 'pdm' || license.startsWith('by') || license.startsWith('cc-by'))) continue;
        const text = [row?.title, row?.alt, row?.description, Array.isArray(row?.tags) ? row.tags.join(' ') : row?.tags].map(v => clean(v)).join(' ');
        const score = scoreCandidate(body, text, 0.08);
        if (score < 0.22) continue;
        const candidate: Candidate = {
          imageUrl,
          provider: 'openverse',
          sourceUrl: clean(row?.foreign_landing_url) || imageUrl,
          attribution: [clean(row?.creator), license, 'Openverse'].filter(Boolean).join(' · '),
          score,
        };
        if (!best || candidate.score > best.score) best = candidate;
      }
    } catch (_) {}
  }));
  return best;
}

async function wikimedia(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'wikimedia')) return null;
  let best: Candidate | null = null;

  await Promise.all(queries(body).slice(0, 4).map(async query => {
    try {
      const url = new URL('https://commons.wikimedia.org/w/api.php');
      url.searchParams.set('action', 'query');
      url.searchParams.set('generator', 'search');
      url.searchParams.set('gsrsearch', query);
      url.searchParams.set('gsrnamespace', '6');
      url.searchParams.set('gsrlimit', '20');
      url.searchParams.set('prop', 'imageinfo');
      url.searchParams.set('iiprop', 'url|extmetadata|mime|size');
      url.searchParams.set('iiurlwidth', '1200');
      url.searchParams.set('format', 'json');
      url.searchParams.set('origin', '*');
      const res = await fetch(url, { headers: { 'User-Agent': 'Edible/1.0' } });
      if (!res.ok) return;
      const data = await res.json();
      const pages = Object.values(data?.query?.pages ?? {}) as any[];

      for (const page of pages) {
        const info = Array.isArray(page?.imageinfo) ? page.imageinfo[0] : null;
        if (!info) continue;
        const mime = clean(info.mime).toLowerCase();
        if (!mime.startsWith('image/') || mime === 'image/svg+xml') continue;
        if (Number(info.width ?? 0) < 500 || Number(info.height ?? 0) < 300) continue;

        const meta = info.extmetadata ?? {};
        const value = (key: string) => clean(meta?.[key]?.value).replace(/<[^>]*>/g, ' ');
        const license = value('LicenseShortName').toLowerCase();
        if (!(license.includes('cc by') || license.includes('cc0') || license.includes('public domain'))) continue;

        const pageTitle = clean(page?.title).replace(/^File:\s*/i, '');
        const text = [pageTitle, value('ImageDescription'), value('ObjectName'), value('Categories'), value('Credit')].join(' ');
        const bad = /logo|icon|map|flag|diagram|chart|screenshot|poster|coat of arms|symbol/i.test(text);
        if (bad) continue;

        const score = scoreCandidate(body, text, /view|panorama|exterior|street|landscape|building|museum|castle|mosque|food|dish|mountain|beach/i.test(text) ? 0.08 : 0);
        if (score < 0.25) continue;

        const candidate: Candidate = {
          imageUrl: clean(info.thumburl) || clean(info.url),
          provider: 'wikimedia',
          sourceUrl: clean(info.descriptionurl),
          attribution: [value('Artist'), value('LicenseShortName'), 'Wikimedia Commons'].filter(Boolean).join(' · '),
          score,
        };
        if (!candidate.imageUrl || !candidate.sourceUrl) continue;
        if (!best || candidate.score > best.score) best = candidate;
      }
    } catch (_) {}
  }));
  return best;
}

async function wikipedia(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'wikipedia')) return null;
  const language = clean(body.locale).split('-')[0] || 'en';
  const languages = [...new Set([language, 'en'])];
  let best: Candidate | null = null;

  await Promise.all(languages.map(async lang => {
    try {
      const query = [clean(body.title), clean(body.city)].filter(Boolean).join(' ');
      const searchUrl = new URL(`https://${lang}.wikipedia.org/w/api.php`);
      for (const [k,v] of Object.entries({
        action:'query', list:'search', srsearch:query, srnamespace:'0', srlimit:'5', format:'json', origin:'*'
      })) searchUrl.searchParams.set(k,v);
      const res = await fetch(searchUrl);
      if (!res.ok) return;
      const data = await res.json();
      const rows = Array.isArray(data?.query?.search) ? data.query.search : [];
      let chosen: any = null, chosenScore = 0;
      for (const row of rows) {
        const score = scoreCandidate(body, clean(row?.title));
        if (score > chosenScore) { chosenScore = score; chosen = row; }
      }
      if (!chosen || chosenScore < 0.48) return;

      const pageUrl = new URL(`https://${lang}.wikipedia.org/w/api.php`);
      for (const [k,v] of Object.entries({
        action:'query', titles:clean(chosen.title), prop:'pageimages', piprop:'name|thumbnail', pithumbsize:'1200', format:'json', origin:'*'
      })) pageUrl.searchParams.set(k,v);
      const pageRes = await fetch(pageUrl);
      if (!pageRes.ok) return;
      const pageData = await pageRes.json();
      const page = Object.values(pageData?.query?.pages ?? {})[0] as any;
      const imageUrl = clean(page?.thumbnail?.source);
      if (!imageUrl) return;

      const candidate: Candidate = {
        imageUrl,
        provider: 'wikipedia',
        sourceUrl: `https://${lang}.wikipedia.org/wiki/${encodeURIComponent(clean(chosen.title).replaceAll(' ', '_'))}`,
        attribution: `Wikipedia (${lang}) · CC BY-SA`,
        score: Math.min(1.15, chosenScore + 0.10),
      };
      if (!best || candidate.score > best.score) best = candidate;
    } catch (_) {}
  }));
  return best;
}

async function wikipediaDirect(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'wikipedia')) return null;
  const title = clean(body.title);
  if (!title) return null;
  const language = clean(body.locale).split('-')[0] || 'en';
  const languages = [...new Set([language, 'en', 'tr'])];
  let best: Candidate | null = null;

  await Promise.all(languages.map(async lang => {
    try {
      const url = new URL(`https://${lang}.wikipedia.org/w/api.php`);
      url.searchParams.set('action', 'query');
      url.searchParams.set('titles', title);
      url.searchParams.set('redirects', '1');
      url.searchParams.set('prop', 'pageimages|info');
      url.searchParams.set('inprop', 'url');
      url.searchParams.set('piprop', 'name|thumbnail');
      url.searchParams.set('pithumbsize', '1400');
      url.searchParams.set('format', 'json');
      url.searchParams.set('origin', '*');
      const res = await fetch(url, { headers: { 'User-Agent': 'Edible/1.0' } });
      if (!res.ok) return;
      const data = await res.json();
      const page = Object.values(data?.query?.pages ?? {})[0] as any;
      const imageUrl = clean(page?.thumbnail?.source);
      const pageTitle = clean(page?.title);
      if (!imageUrl || !pageTitle) return;
      const titleScore = similarity(title, pageTitle);
      if (titleScore < 0.55) return;
      const cityBonus = clean(body.city) && normalize(pageTitle).includes(normalize(clean(body.city))) ? 0.04 : 0;
      const candidate: Candidate = {
        imageUrl,
        provider: 'wikipedia',
        sourceUrl: clean(page?.fullurl) || `https://${lang}.wikipedia.org/wiki/${encodeURIComponent(pageTitle.replaceAll(' ', '_'))}`,
        attribution: `Wikipedia (${lang}) · CC BY-SA`,
        score: Math.min(1.25, 0.90 + titleScore * 0.25 + cityBonus),
      };
      if (!best || candidate.score > best.score) best = candidate;
    } catch (_) {}
  }));
  return best;
}

async function libraryOfCongress(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'loc')) return null;
  try {
    const url = new URL('https://www.loc.gov/photos/');
    url.searchParams.set('q', [clean(body.title), clean(body.city), clean(body.country)].filter(Boolean).join(' '));
    url.searchParams.set('fo', 'json');
    url.searchParams.set('c', '30');
    const res = await fetch(url);
    if (!res.ok) return null;
    const data = await res.json();
    let best: Candidate | null = null;
    for (const row of (Array.isArray(data?.results) ? data.results : [])) {
      const rights = clean(row?.rights).toLowerCase();
      if (!(rights.includes('public domain') || rights.includes('no known copyright') || rights.includes('creative commons'))) continue;
      const imageUrl = Array.isArray(row?.image_url) ? row.image_url.find((v: unknown) => clean(v).startsWith('http')) : '';
      if (!imageUrl) continue;
      const text = [row?.title,row?.description,row?.subject].map(v => clean(v)).join(' ');
      const score = scoreCandidate(body, text);
      if (score < 0.20) continue;
      const c: Candidate = { imageUrl: clean(imageUrl), provider:'loc', sourceUrl:clean(row?.url), attribution:'Library of Congress · reusable record', score: score * 0.92 };
      if (!best || c.score > best.score) best = c;
    }
    return best;
  } catch (_) { return null; }
}

async function internetArchive(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'internet_archive')) return null;
  try {
    const query = [clean(body.title), clean(body.city)].filter(Boolean).join(' ');
    const url = new URL('https://archive.org/advancedsearch.php');
    url.searchParams.set('q', `mediatype:image AND title:(${query})`);
    url.searchParams.set('fl[]', 'identifier,title,description');
    url.searchParams.set('rows', '30');
    url.searchParams.set('output', 'json');
    const res = await fetch(url);
    if (!res.ok) return null;
    const data = await res.json();
    let best: Candidate | null = null;
    for (const row of (Array.isArray(data?.response?.docs) ? data.response.docs : [])) {
      const id = clean(row?.identifier);
      if (!id) continue;
      const text = `${clean(row?.title)} ${clean(row?.description)}`;
      const rightsText = text.toLowerCase();
      if (!(rightsText.includes('public domain') || rightsText.includes('creativecommons') || rightsText.includes('creative commons') || rightsText.includes('cc by') || rightsText.includes('cc0'))) continue;
      const score = scoreCandidate(body, text) * 0.85;
      if (score < 0.18) continue;
      const c: Candidate = {
        imageUrl:`https://archive.org/download/${id}/page/n0.jpg`,
        provider:'internet_archive',
        sourceUrl:`https://archive.org/details/${id}`,
        attribution:'Internet Archive',
        score,
      };
      if (!best || c.score > best.score) best = c;
    }
    return best;
  } catch (_) { return null; }
}

async function pexels(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'pexels')) return null;
  const key = Deno.env.get('PEXELS_API_KEY');
  if (!key) return null;
  try {
    const url = new URL('https://api.pexels.com/v1/search');
    url.searchParams.set('query', [clean(body.title),clean(body.city),clean(body.country)].filter(Boolean).join(' '));
    url.searchParams.set('per_page','30');
    url.searchParams.set('orientation','landscape');
    const res = await fetch(url,{headers:{Authorization:key}});
    if (!res.ok) return null;
    const data = await res.json();
    let best: Candidate | null = null;
    for (const photo of (Array.isArray(data?.photos) ? data.photos : [])) {
      const text = `${clean(photo?.alt)} ${clean(photo?.photographer)}`;
      const score = scoreCandidate(body,text,0.02);
      const imageUrl = clean(photo?.src?.large2x) || clean(photo?.src?.large);
      if (!imageUrl || score < 0.30) continue;
      const c: Candidate = {imageUrl,provider:'pexels',sourceUrl:clean(photo?.url),attribution:`Photo by ${clean(photo?.photographer)||'Pexels'} on Pexels`,score:score+0.55};
      if (!best || c.score > best.score) best=c;
    }
    return best;
  } catch (_) { return null; }
}

async function unsplash(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'unsplash')) return null;
  const key = Deno.env.get('UNSPLASH_ACCESS_KEY');
  if (!key) return null;
  try {
    const url = new URL('https://api.unsplash.com/search/photos');
    url.searchParams.set('query',[clean(body.title),clean(body.city),clean(body.country)].filter(Boolean).join(' '));
    url.searchParams.set('per_page','30');
    const res = await fetch(url,{headers:{Authorization:`Client-ID ${key}`}});
    if (!res.ok) return null;
    const data = await res.json();
    let best: Candidate | null = null;
    for (const photo of (Array.isArray(data?.results) ? data.results : [])) {
      const text = `${clean(photo?.alt_description)} ${clean(photo?.description)}`;
      const score = scoreCandidate(body,text,0.02);
      const imageUrl = clean(photo?.urls?.regular);
      if (!imageUrl || score < 0.30) continue;
      const c: Candidate = {imageUrl,provider:'unsplash',sourceUrl:clean(photo?.links?.html),attribution:`Photo by ${clean(photo?.user?.name)||'Unsplash'} on Unsplash`,score:score+0.55};
      if (!best || c.score > best.score) best=c;
    }
    return best;
  } catch (_) { return null; }
}

async function pixabay(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'pixabay')) return null;
  const key = Deno.env.get('PIXABAY_API_KEY');
  if (!key) return null;
  try {
    const url = new URL('https://pixabay.com/api/');
    url.searchParams.set('key',key);
    url.searchParams.set('q',[clean(body.title),clean(body.city),clean(body.country)].filter(Boolean).join(' '));
    url.searchParams.set('image_type','photo');
    url.searchParams.set('orientation','horizontal');
    url.searchParams.set('safesearch','true');
    url.searchParams.set('per_page','30');
    const res = await fetch(url);
    if (!res.ok) return null;
    const data = await res.json();
    let best: Candidate | null = null;
    for (const photo of (Array.isArray(data?.hits) ? data.hits : [])) {
      const text = `${clean(photo?.tags)} ${clean(photo?.user)}`;
      const score = scoreCandidate(body,text,0.02);
      const imageUrl = clean(photo?.largeImageURL);
      if (!imageUrl || score < 0.30) continue;
      const c: Candidate = {imageUrl,provider:'pixabay',sourceUrl:clean(photo?.pageURL),attribution:`Photo by ${clean(photo?.user)||'Pixabay'} on Pixabay`,score:score+0.50};
      if (!best || c.score > best.score) best=c;
    }
    return best;
  } catch (_) { return null; }
}

async function flickr(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'flickr')) return null;
  const key = Deno.env.get('FLICKR_API_KEY');
  if (!key) return null;
  try {
    const url = new URL('https://www.flickr.com/services/rest/');
    url.searchParams.set('method','flickr.photos.search');
    url.searchParams.set('api_key',key);
    url.searchParams.set('text',[clean(body.title),clean(body.city),clean(body.country)].filter(Boolean).join(' '));
    url.searchParams.set('content_type','1');
    url.searchParams.set('media','photos');
    url.searchParams.set('safe_search','1');
    url.searchParams.set('license','4,5,7,8,9,10');
    url.searchParams.set('extras','url_l,url_o,owner_name,license,tags,title');
    url.searchParams.set('per_page','30');
    url.searchParams.set('format','json');
    url.searchParams.set('nojsoncallback','1');
    const res = await fetch(url);
    if (!res.ok) return null;
    const data = await res.json();
    let best: Candidate | null = null;
    for (const photo of (Array.isArray(data?.photos?.photo) ? data.photos.photo : [])) {
      const imageUrl = clean(photo?.url_l) || clean(photo?.url_o);
      if (!imageUrl) continue;
      const text = `${clean(photo?.title)} ${clean(photo?.tags)}`;
      const score = scoreCandidate(body,text,0.02);
      if (score < 0.18) continue;
      const id = clean(photo?.id);
      const c: Candidate = {
        imageUrl,
        provider:'flickr',
        sourceUrl:id ? `https://www.flickr.com/photos/${clean(photo?.owner)}/${id}` : 'https://www.flickr.com/',
        attribution:`Photo on Flickr · ${clean(photo?.ownername)}`,
        score:score+0.48,
      };
      if (!best || c.score > best.score) best=c;
    }
    return best;
  } catch (_) { return null; }
}

async function europeana(body: Body): Promise<Candidate | null> {
  if (excluded(body, 'europeana')) return null;
  const key = Deno.env.get('EUROPEANA_API_KEY');
  if (!key) return null;
  try {
    const url = new URL('https://api.europeana.eu/record/v2/search.json');
    url.searchParams.set('wskey',key);
    url.searchParams.set('query',[clean(body.title),clean(body.city),clean(body.country)].filter(Boolean).join(' '));
    url.searchParams.set('rows','30');
    url.searchParams.set('qf','TYPE:IMAGE');
    const res = await fetch(url);
    if (!res.ok) return null;
    const data = await res.json();
    let best: Candidate | null = null;
    for (const row of (Array.isArray(data?.items) ? data.items : [])) {
      const previews = Array.isArray(row?.edmPreview) ? row.edmPreview : [];
      const imageUrl = clean(previews[0]) || clean(row?.edmIsShownBy);
      if (!imageUrl) continue;
      const rights = `${clean(row?.rights)} ${clean(row?.edmRights)}`.toLowerCase();
      if (!(rights.includes('creativecommons') || rights.includes('creative commons') || rights.includes('cc by') || rights.includes('public domain') || rights.includes('pdm'))) continue;
      const text = `${clean(row?.title)} ${clean(row?.dcDescription)} ${clean(row?.edmConceptTerm)}`;
      const score = scoreCandidate(body,text);
      if (score < 0.18) continue;
      const c: Candidate = {
        imageUrl,
        provider:'europeana',
        sourceUrl:clean(row?.guid) || 'https://www.europeana.eu/',
        attribution:'Image via Europeana',
        score:score+0.40,
      };
      if (!best || c.score > best.score) best=c;
    }
    return best;
  } catch (_) { return null; }
}



const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  { auth: { persistSession: false, autoRefreshToken: false } },
);

function cacheKey(body: Body): string {
  return [clean(body.title), clean(body.city), clean(body.country)]
    .map(normalize)
    .join('|');
}

async function readCached(body: Body): Promise<Candidate | null> {
  const key = cacheKey(body);
  if (!key || key === '||') return null;
  try {
    const { data, error } = await supabaseAdmin
      .from('image_resolutions')
      .select('image_url,provider,source_url,attribution,score')
      .eq('cache_key', key)
      .maybeSingle();
    if (error || !data) return null;
    return {
      imageUrl: clean(data.image_url),
      provider: clean(data.provider) || 'unknown',
      sourceUrl: clean(data.source_url) || undefined,
      attribution: clean(data.attribution) || undefined,
      score: Number(data.score ?? 0),
    };
  } catch (_) {
    return null;
  }
}

async function writeCached(body: Body, candidate: Candidate): Promise<void> {
  const key = cacheKey(body);
  if (!key || !candidate.imageUrl) return;
  try {
    await supabaseAdmin.from('image_resolutions').upsert({
      cache_key: key,
      title: clean(body.title),
      city: clean(body.city) || null,
      country: clean(body.country) || null,
      image_url: candidate.imageUrl,
      provider: candidate.provider,
      source_url: candidate.sourceUrl ?? null,
      attribution: candidate.attribution ?? null,
      score: candidate.score,
    }, { onConflict: 'cache_key' });
  } catch (_) {}
}

serve(async request => {
  if (request.method === 'OPTIONS') return new Response('ok',{headers:corsHeaders});
  try {
    // Explore is public content and must also work before login. Authentication
    // is therefore optional here. Authenticated callers still get the existing
    // per-user rate limit; anonymous callers can use cached/public resolution.
    let authenticatedUserId: string | null = null;
    const authHeader = request.headers.get('Authorization');
    if (authHeader?.startsWith('Bearer ')) {
      const accessToken = authHeader.slice('Bearer '.length).trim();
      const { data: authData } = await supabaseAdmin.auth.getUser(accessToken);
      authenticatedUserId = authData.user?.id ?? null;
    }

    const body = await request.json() as Body;

    // Best-effort cleanup; it never blocks image resolution.
    await supabaseAdmin
      .from('image_resolution_rate_limits')
      .delete()
      .lt('window_start', new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString());
    if (!clean(body.title)) return new Response(JSON.stringify({error:'title is required'}),{status:400,headers:{...corsHeaders,'Content-Type':'application/json'}});

    const cached = await readCached(body);
    if (cached?.imageUrl) {
      return new Response(JSON.stringify(cached), {
        status: 200,
        headers: {...corsHeaders, 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=86400'},
      });
    }

    if (authenticatedUserId) {
      const { data: allowed, error: rateError } = await supabaseAdmin.rpc(
        'consume_image_resolution_rate_limit',
        { p_user_id: authenticatedUserId, p_limit: 30 },
      );
      if (rateError) throw rateError;
      if (allowed !== true) {
        return new Response(JSON.stringify({ error: 'Rate limit exceeded. Try again later.' }), {
          status: 429,
          headers: { ...corsHeaders, 'Content-Type': 'application/json', 'Retry-After': '3600' },
        });
      }
    }

    const tasks = [
      ['wikimedia', wikimedia(body)],
      ['openverse', openverse(body)],
      ['loc', libraryOfCongress(body)],
      ['internet_archive', internetArchive(body)],
      ['pexels', pexels(body)],
      ['unsplash', unsplash(body)],
      ['pixabay', pixabay(body)],
      ['flickr', flickr(body)],
      ['europeana', europeana(body)],
    ] as const;

    const settled = await Promise.allSettled(tasks.map(([, promise]) => promise));
    const candidates: Candidate[] = [];
    for (const result of settled) {
      if (result.status === 'fulfilled' && result.value) candidates.push(result.value);
    }

    // Prefer reliable/open-license sources when scores are close. This avoids
    // a generic stock result beating a highly relevant Commons/Openverse image.
    const sourceWeight: Record<string, number> = {
      wikimedia: 0.18,
      openverse: 0.16,
      loc: 0.14,
      europeana: 0.12,
      internet_archive: 0.10,
      pixabay: 0.08,
      pexels: 0.07,
      unsplash: 0.06,
      flickr: 0.05,
    };
    candidates.sort((a,b) =>
      (b.score + (sourceWeight[b.provider] ?? 0)) -
      (a.score + (sourceWeight[a.provider] ?? 0))
    );
    const best = candidates[0] ?? null;

    if (best && best.score >= 0.42) {
      await writeCached(body, best);
    }

    return new Response(JSON.stringify(best),{
      status:200,
      headers:{...corsHeaders,'Content-Type':'application/json','Cache-Control':'public, max-age=86400'}
    });
  } catch (error) {
    console.error('resolve-content-image failed',error);
    return new Response(JSON.stringify({error:'image resolution failed'}),{
      status:500,
      headers:{...corsHeaders,'Content-Type':'application/json'}
    });
  }
});
