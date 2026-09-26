import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const expectedAuthorization =
  Deno.env.get("REVENUECAT_WEBHOOK_AUTH") ?? "";

const supabase = createClient(
  supabaseUrl,
  serviceRoleKey,
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  },
);

type RevenueCatEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string | null;

  event_timestamp_ms?: number;
  expiration_at_ms?: number | null;

  entitlement_ids?: string[] | null;
  product_id?: string | null;
};

type RevenueCatPayload = {
  api_version?: string;
  event?: RevenueCatEvent;
};

Deno.serve(async (request) => {
  // --------------------------------------------------
  // 1. HTTP method
  // --------------------------------------------------

  if (request.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
    });
  }

  // --------------------------------------------------
  // 2. RevenueCat webhook authentication
  // --------------------------------------------------

  const authHeader =
    request.headers.get("authorization") ?? "";

  if (
    !expectedAuthorization ||
    authHeader !== expectedAuthorization
  ) {
    return new Response("Unauthorized", {
      status: 401,
    });
  }

  // --------------------------------------------------
  // 3. Parse JSON
  // --------------------------------------------------

  let payload: RevenueCatPayload;

  try {
    payload = await request.json();
  } catch {
    return new Response("Invalid JSON", {
      status: 400,
    });
  }

  const event = payload.event;

  if (!event) {
    return new Response("Missing event", {
      status: 400,
    });
  }

  // --------------------------------------------------
  // 4. Required RevenueCat fields
  // --------------------------------------------------

  const userId = event.app_user_id;
  const eventId = event.id;
  const eventType = event.type ?? "";

  if (!userId || !eventId) {
    return new Response(
      "Missing event/app_user_id or event id",
      {
        status: 400,
      },
    );
  }

  if (
    event.event_timestamp_ms == null ||
    !Number.isFinite(event.event_timestamp_ms)
  ) {
    return new Response(
      "Missing event_timestamp_ms",
      {
        status: 400,
      },
    );
  }

  // --------------------------------------------------
  // 5. Determine subscription status
  // --------------------------------------------------

  const activeEvents = new Set([
    "INITIAL_PURCHASE",
    "RENEWAL",
    "PRODUCT_CHANGE",
    "UNCANCELLATION",
    "SUBSCRIPTION_EXTENDED",
    "TEMPORARY_ENTITLEMENT_GRANT",
  ]);

  let status: string | null = null;

  if (eventType === "EXPIRATION") {
    status = "expired";
  } else if (eventType === "CANCELLATION") {
    status = "cancelled";
  } else if (activeEvents.has(eventType)) {
    status = "active";
  }

  // --------------------------------------------------
  // 6. Ignore unsupported events
  // --------------------------------------------------

  if (status === null) {
    return Response.json({
      ok: true,
      ignored: eventType,
    });
  }

  // --------------------------------------------------
  // 7. Convert timestamps
  // --------------------------------------------------

  const eventAt =
    new Date(
      event.event_timestamp_ms,
    ).toISOString();

  const expiresAt =
    event.expiration_at_ms != null
      ? new Date(
          event.expiration_at_ms,
        ).toISOString()
      : null;

  // --------------------------------------------------
  // 8. Entitlement
  // --------------------------------------------------

  const entitlementId =
    event.entitlement_ids?.length
      ? event.entitlement_ids.join(",")
      : null;

  // --------------------------------------------------
  // 9. Subscription plan
  // --------------------------------------------------

  const plan =
    status === "expired"
      ? "free"
      : "premium";

  // --------------------------------------------------
  // 10. Apply event atomically
  // --------------------------------------------------

  const { data, error } =
    await supabase.rpc(
      "apply_revenuecat_subscription_event",
      {
        p_user_id: userId,
        p_event_id: eventId,
        p_event_at: eventAt,
        p_status: status,
        p_plan: plan,
        p_provider: "revenuecat",
        p_product_id:
          event.product_id ?? null,
        p_entitlement_id:
          entitlementId,
        p_original_app_user_id:
          event.original_app_user_id ??
          userId,
        p_expires_at:
          expiresAt,
      },
    );

  // --------------------------------------------------
  // 11. Database error
  // --------------------------------------------------

  if (error) {
    console.error(
      "RevenueCat webhook sync failed",
      error,
    );

    return Response.json(
      {
        ok: false,
        error:
          "Subscription synchronization failed",
      },
      {
        status: 500,
      },
    );
  }

  // --------------------------------------------------
  // 12. Success
  // --------------------------------------------------

  return Response.json({
    ok: true,
    processed: data === true,
    event: eventType,
    event_id: eventId,
    user_id: userId,
  });
});