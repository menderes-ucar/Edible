# send-message-notification

Authenticated Edge Function. The Flutter client calls this after a direct message is persisted. The function discovers the recipient's active FCM tokens and sends Firebase HTTP v1 notifications.

Required secrets:

- `FCM_SERVICE_ACCOUNT_JSON`

The Supabase service role key is supplied by the Edge Function runtime.
