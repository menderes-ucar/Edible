# Edible — Production Notifications

Bu paket bildirim sisteminin Flutter + Supabase tarafını kurar. FCM'nin gerçek cihazlarda çalışması için Firebase/Apple tarafındaki uygulama dosyalarının da eklenmesi gerekir; bu dosyalar proje kimlik bilgilerine özel olduğu için paket içine uydurma config konulmadı.

## 1. Flutter bağımlılıkları

`pubspec.yaml` içine eklenenler:

- `firebase_core: ^3.15.2`
- `firebase_messaging: ^15.2.10`
- `flutter_local_notifications: ^17.2.4`
- `timezone: ^0.9.4`
- `flutter_timezone: ^2.1.0`

Sonra:

```powershell
flutter pub get
```

## 2. Firebase Android + iOS

Firebase Console'da Edible için Android ve iOS uygulamalarını ekle.

En güvenlisi FlutterFire CLI ile native yapılandırmayı oluşturmaktır:

```powershell
dart pub global activate flutterfire_cli
flutterfire configure
```

Android için oluşan `android/app/google-services.json` dosyasını projede tut.

iOS için oluşan `ios/Runner/GoogleService-Info.plist` dosyasını Xcode'da Runner target'ına ekle.

Firebase Messaging'in çalışması için Firebase'in güncel Flutter kurulumunda Android/iOS native yapılandırması tamamlanmış olmalıdır.

## 3. Android Manifest

`android/app/src/main/AndroidManifest.xml` içinde `<manifest>` altına şunları ekle:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

`flutter_local_notifications` günlük zamanlanmış bildirimleri cihaz yeniden başlatıldığında tekrar kurabilmek için `RECEIVE_BOOT_COMPLETED` iznine ihtiyaç duyar.

Bu kurulumda exact alarm kullanılmadığı için `SCHEDULE_EXACT_ALARM` zorunlu tutulmadı.

## 4. iOS Push Notifications

Xcode → Runner → Signing & Capabilities:

- Push Notifications ekle.
- Background Modes ekle.
- Background fetch'i aç.
- Remote notifications'ı aç.

Firebase Console → Project Settings → Cloud Messaging → Apple app configuration bölümünde APNs Authentication Key (`.p8`) yükle; Key ID ve Apple Team ID gir.

Gerçek iPhone gerekir; simulator FCM/APNs testi için uygun değildir.

## 5. Supabase migration

Şu migration'ı uygula:

```text
supabase/migrations/20260909_notifications_and_push.sql
```

Migration şunları oluşturur:

- `device_push_tokens`
- `app_notifications`
- kendi bildirimlerini okuyabilen/güncelleyebilen RLS
- mesaj geldiğinde otomatik in-app notification oluşturan DB trigger
- notification realtime publication

## 6. Supabase Edge Function secret'ları

Supabase Edge Functions Secrets içine:

```text
FCM_SERVICE_ACCOUNT_JSON=<Firebase service account JSON'unun tamamı>
```

Ek olarak günlük function için:

```text
DAILY_NOTIFICATION_CRON_SECRET=<uzun-rastgele-bir-secret>
```

Service account JSON'u uygulamanın içine, Git'e veya Flutter asset'lerine koyma.

## 7. Edge Function authentication configuration

Supabase'in güncel auth modelinde Edge Function platform JWT kontrolünü kapatıp kullanıcı kimliğini function içinde doğrulamak daha sağlamdır. `supabase/notification_config_snippet.toml` içindeki iki bloğu mevcut `supabase/config.toml` dosyana **merge et**; mevcut ayarlarını silme.

`send-message-notification` gelen Supabase access token'ını function içinde doğrular. `send-daily-discovery` ise cron secret ile korunur.

## 8. Edge Functions deploy

```powershell
supabase functions deploy send-message-notification
supabase functions deploy send-daily-discovery
```

## 9. Günlük Edible bildirimi

Günlük backend bildirimi için Supabase Dashboard → Integrations / Cron (Jobs) bölümünden bir günlük job oluştur ve `send-daily-discovery` Edge Function'ına HTTP POST çağrısı yaptır. Supabase Cron + pg_net, Edge Function'ları zamanlamak için önerilen yöntemdir.

Önerilen saat:

```text
10:00 Europe/Istanbul
```

Function çağrısına şu header'ı ekle:

```text
x-edible-cron-secret: <DAILY_NOTIFICATION_CRON_SECRET>
Content-Type: application/json
```

Bu backend bildirimi FCM gönderir ve aynı zamanda `app_notifications` içine in-app kaydı bırakır.

## 10. Uygulama içi günlük fallback

Backend scheduler geçici olarak çalışmasa bile uygulama, bildirim izni verilmiş cihazlarda günlük yerel keşif bildirimini saat 10:00'a planlar.

Örnek:

> Bugün Edible’da ✨
> Bugün yeni bir yer keşfet, kültürünü öğren ve bir sonraki yolculuğuna ilham kat.

Bu fallback FCM'ye bağımlı değildir.

## 11. Mesaj bildirimi akışı

Bir kullanıcı mesaj gönderdiğinde:

1. `send_direct_message` mesajı Supabase'e kaydeder.
2. DB trigger alıcı için `app_notifications` kaydı oluşturur.
3. Flutter `send-message-notification` Edge Function'ını çağırır.
4. Edge Function alıcının aktif cihaz tokenlarını bulur.
5. Firebase HTTP v1 üzerinden FCM gönderir.
6. Foreground durumda Flutter local notification gösterir.
7. Background/terminated durumda işletim sistemi FCM notification payload'unu gösterir.
8. Bildirime dokunulduğunda ilgili `/messages/chat/<userId>` ekranına gidilir.

## 12. Test sırası

### A. Local notification

Uygulamayı aç → profil → Bildirimler.

### B. FCM token

Log'da token alınabildiğini kontrol et. Supabase'de:

```sql
select user_id, platform, enabled, last_seen_at
from public.device_push_tokens
order by last_seen_at desc;
```

### C. Mesaj

İki farklı hesapla iki gerçek cihaz/kurulum kullan:

- A → B'ye mesaj gönder.
- B foreground: local notification görünmeli.
- B background: FCM/system notification görünmeli.
- B bildirime dokunmalı: ilgili sohbet açılmalı.
- Notifications ekranında mesaj kaydı görünmeli.

### D. Günlük bildirim

Önce local fallback'i test etmek için cihaz saatini kontrollü bir zamana getir veya `scheduleDailyDiscovery` çağrısını geçici olarak birkaç dakika sonrasına ayarla.

Production testinde backend scheduler'ı manuel tetikle ve FCM teslimini kontrol et.

## Önemli

Firebase tarafında `google-services.json`, `GoogleService-Info.plist` ve APNs key proje hesabına özeldir. Bunlar olmadan Flutter kodu derlenebilir ancak gerçek FCM teslimi tamamlanmış sayılmaz.
