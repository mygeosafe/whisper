import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase.dart';
import '../domain/app_user.dart';

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return Stream<AppUser?>.multi((controller) {
    AppUser? mapUser(User? user) {
      if (user == null) return null;
      final email = user.email ?? '';
      return AppUser(id: user.id, email: email);
    }

    controller.add(mapUser(client.auth.currentUser));
    final subscription = client.auth.onAuthStateChange.listen((data) {
      controller.add(mapUser(data.session?.user));
    });
    controller.onCancel = subscription.cancel;
  });
});

final authActionControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthActionController, void>(AuthActionController.new);

class AuthActionController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(email: email, password: password);
      if (!mounted) return;
      state = const AsyncData(null);
    } on AuthException catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signUp(email: email, password: password);
      if (!mounted) return;
      state = const AsyncData(null);
    } on AuthException catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(supabaseClientProvider).auth.signOut();
      if (!mounted) return;
      state = const AsyncData(null);
    } on AuthException catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncError(error, stackTrace);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncError(error, stackTrace);
    }
  }
}
