import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../../app.dart';
import '../theme/app_theme.dart';
import 'app_bootstrap.dart';

class EdibleBootstrapRoot extends StatefulWidget {
  const EdibleBootstrapRoot({
    super.key,
    this.bootstrap = const AppBootstrap(),
  });

  final AppBootstrap bootstrap;

  @override
  State<EdibleBootstrapRoot> createState() => _EdibleBootstrapRootState();
}

class _EdibleBootstrapRootState extends State<EdibleBootstrapRoot> {
  AppBootstrapResult? _result;
  bool _isRunning = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    if (_isRunning) return;

    final generation = ++_generation;
    setState(() => _isRunning = true);

    final result = await widget.bootstrap.initialize();

    if (!mounted || generation != _generation) return;

    setState(() {
      _result = result;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result?.isReady == true) {
      return const EdibleApp();
    }

    return _BootstrapMaterialApp(
      failure: _result?.failure,
      isRunning: _isRunning,
      onRetry: _isRunning ? null : _run,
    );
  }
}

class _BootstrapMaterialApp extends StatelessWidget {
  const _BootstrapMaterialApp({
    required this.failure,
    required this.isRunning,
    required this.onRetry,
  });

  final AppBootstrapFailure? failure;
  final bool isRunning;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final languageCode =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    final copy = _BootstrapCopy.forLanguage(languageCode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Edible',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: isRunning && failure == null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 18),
                        Text(copy.starting),
                      ],
                    )
                  : _BootstrapFailureView(
                      failure: failure,
                      copy: copy,
                      onRetry: onRetry,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BootstrapFailureView extends StatelessWidget {
  const _BootstrapFailureView({
    required this.failure,
    required this.copy,
    required this.onRetry,
  });

  final AppBootstrapFailure? failure;
  final _BootstrapCopy copy;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final missing =
        failure?.type == AppBootstrapFailureType.missingConfiguration;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 64),
        const SizedBox(height: 18),
        Text(
          missing ? copy.configurationTitle : copy.connectionTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          missing ? copy.configurationMessage : copy.connectionMessage,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(copy.retry),
        ),
      ],
    );
  }
}

class _BootstrapCopy {
  const _BootstrapCopy({
    required this.starting,
    required this.configurationTitle,
    required this.configurationMessage,
    required this.connectionTitle,
    required this.connectionMessage,
    required this.retry,
  });

  final String starting;
  final String configurationTitle;
  final String configurationMessage;
  final String connectionTitle;
  final String connectionMessage;
  final String retry;

  static _BootstrapCopy forLanguage(String languageCode) =>
      _values[languageCode] ?? _values['en']!;

  static const _values = <String, _BootstrapCopy>{
    'en': _BootstrapCopy(
      starting: 'Starting Edible…',
      configurationTitle: 'Edible is not configured yet',
      configurationMessage:
          'The public Supabase client configuration is missing. Add the publishable/anon key and try again.',
      connectionTitle: 'Edible could not start',
      connectionMessage:
          'The service could not be initialized. Check your internet connection and try again.',
      retry: 'Try again',
    ),
    'tr': _BootstrapCopy(
      starting: 'Edible başlatılıyor…',
      configurationTitle: 'Edible henüz yapılandırılmadı',
      configurationMessage:
          'Supabase public istemci yapılandırması eksik. Publishable/anon key bilgisini ekleyip tekrar dene.',
      connectionTitle: 'Edible başlatılamadı',
      connectionMessage:
          'Servis başlatılamadı. İnternet bağlantını kontrol edip tekrar dene.',
      retry: 'Tekrar dene',
    ),
    'de': _BootstrapCopy(
      starting: 'Edible wird gestartet…',
      configurationTitle: 'Edible ist noch nicht konfiguriert',
      configurationMessage:
          'Die öffentliche Supabase-Clientkonfiguration fehlt. Füge den Publishable-/Anon-Key hinzu und versuche es erneut.',
      connectionTitle: 'Edible konnte nicht gestartet werden',
      connectionMessage:
          'Der Dienst konnte nicht initialisiert werden. Prüfe deine Internetverbindung und versuche es erneut.',
      retry: 'Erneut versuchen',
    ),
    'fr': _BootstrapCopy(
      starting: 'Démarrage d’Edible…',
      configurationTitle: 'Edible n’est pas encore configuré',
      configurationMessage:
          'La configuration publique du client Supabase est manquante. Ajoute la clé publishable/anon puis réessaie.',
      connectionTitle: 'Impossible de démarrer Edible',
      connectionMessage:
          'Le service n’a pas pu être initialisé. Vérifie ta connexion internet et réessaie.',
      retry: 'Réessayer',
    ),
    'es': _BootstrapCopy(
      starting: 'Iniciando Edible…',
      configurationTitle: 'Edible aún no está configurado',
      configurationMessage:
          'Falta la configuración pública del cliente Supabase. Añade la clave publishable/anon e inténtalo de nuevo.',
      connectionTitle: 'No se pudo iniciar Edible',
      connectionMessage:
          'No se pudo inicializar el servicio. Comprueba tu conexión a internet e inténtalo de nuevo.',
      retry: 'Intentar de nuevo',
    ),
    'it': _BootstrapCopy(
      starting: 'Avvio di Edible…',
      configurationTitle: 'Edible non è ancora configurato',
      configurationMessage:
          'Manca la configurazione pubblica del client Supabase. Aggiungi la chiave publishable/anon e riprova.',
      connectionTitle: 'Impossibile avviare Edible',
      connectionMessage:
          'Il servizio non è stato inizializzato. Controlla la connessione internet e riprova.',
      retry: 'Riprova',
    ),
    'ar': _BootstrapCopy(
      starting: 'جارٍ تشغيل Edible…',
      configurationTitle: 'لم يتم إعداد Edible بعد',
      configurationMessage:
          'إعداد عميل Supabase العام غير موجود. أضف مفتاح publishable/anon ثم حاول مرة أخرى.',
      connectionTitle: 'تعذر تشغيل Edible',
      connectionMessage:
          'تعذر تهيئة الخدمة. تحقق من اتصال الإنترنت وحاول مرة أخرى.',
      retry: 'حاول مرة أخرى',
    ),
  };
}
