# send-daily-discovery

Daily Edible discovery campaign. It creates one in-app notification per user/day and sends the same campaign through FCM to the user's active devices.

Required secret:

- `FCM_SERVICE_ACCOUNT_JSON`

Optional scheduler protection:

- `DAILY_NOTIFICATION_CRON_SECRET`

Recommended schedule: every day at 10:00 Europe/Istanbul.
