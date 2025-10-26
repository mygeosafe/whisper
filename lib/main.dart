import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  if (config.hasSupabaseConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
        persistSession: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(heartbeatIntervalMs: 5000),
    );
  }

  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
    ],
  );
  await container.read(appBootstrapProvider.future);
  runApp(UncontrolledProviderScope(
    container: container,
    child: const LoopMindApp(),
  ));
}

class LoopMindApp extends ConsumerWidget {
  const LoopMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Whispair LoopMind',
      theme: buildLoopMindTheme(),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
    );
  }
}
