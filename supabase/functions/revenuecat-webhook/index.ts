import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const expectedAuthorization = Deno.env.get("REVENUECAT_WEBHOOK_AUTH") ?? "";

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

type RevenueCatEvent = {
  type?: string;
  app_user_id?: string;
  expiration_at_ms?: number | null;
  purchased_at_ms?: number | null;
  entitlement_ids?: string[] | null;
  product_id?: string | null;
};

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = request.headers.get("authorization") ?? "";

  if (!expectedAuthorization || authHeader !== expectedAuthorization) {
    return new Response("Unauthorized", { status: 401 });
  }

  let payload: { event?: RevenueCatEvent };

  try {
    payload = await request.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const event = payload.event;
  const userId = event?.app_user_id;
  const eventType = event?.type ?? "";

  if (!event || !userId) {
    return new Response("Missing event/app_user_id", { status: 400 });
  }

  const activeEvents = new Set([
    "INITIAL_PURCHASE",
    "RENEWAL",
    "PRODUCT_CHANGE",
    "UNCANCELLATION",
    "SUBSCRIPTION_EXTENDED",
    "TEMPORARY_ENTITLEMENT_GRANT",
  ]);

  const status = eventType === "EXPIRATION"
    ? "expired"
    : eventType === "CANCELLATION"
    ? "cancelled"
    : activeEvents.has(eventType)
    ? "active"
    : null;

  if (status == null) {
    return Response.json({ ok: true, ignored: eventType });
  }

  const expiresAt = event.expiration_at_ms
    ? new Date(event.expiration_at_ms).toISOString()
    : null;

  const startedAt = event.purchased_at_ms
    ? new Date(event.purchased_at_ms).toISOString()
    : null;

  const plan = status === "active" || status === "cancelled"
    ? "premium"
    : "free";

  const { error } = await supabase
    .from("user_subscriptions")
    .upsert(
      {
        user_id: userId,
        plan,
        status,
        provider: "revenuecat",
        provider_customer_id: userId,
        provider_entitlement_id:
          event.entitlement_ids?.join(",") ?? null,
        started_at: startedAt,
        expires_at: expiresAt,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id" },
    );

  if (error) {
    console.error("RevenueCat webhook sync failed", error);
    return Response.json(
      { ok: false, error: error.message },
      { status: 500 },
    );
  }

  return Response.json({
    ok: true,
    event: eventType,
    user_id: userId,
  });
});
