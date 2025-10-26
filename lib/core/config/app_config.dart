import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application configuration sourced from compile-time environment values.
///
/// Secrets such as the Supabase URL and anon key should be supplied via
/// `--dart-define` at build time so that they are not committed to source
/// control. This approach supports GDPR requirements by keeping credentials
/// out of the binary and allowing per-environment isolation.
class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.supabaseStorageBucket,
  });

  factory AppConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const bucket =
        String.fromEnvironment('SUPABASE_STORAGE_BUCKET', defaultValue: 'loopmind-audio');

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint(
        'Supabase configuration not provided. The app will fall back to local storage.',
      );
    }

    return AppConfig(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      supabaseStorageBucket: bucket,
    );
  }

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String supabaseStorageBucket;

  bool get hasSupabaseConfig => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig has not been initialised.');
});
