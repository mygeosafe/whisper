import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/config/app_config.dart';
import 'core/theme/theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/loopmind/presentation/loopmind_page.dart';
import 'features/notes/presentation/note_detail_page.dart';
import 'features/notes/presentation/timeline_page.dart';
import 'features/settings/presentation/settings_page.dart';

ThemeData buildLoopMindTheme() => LoopMindTheme.build();

final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  if (!config.hasSupabaseConfig) {
    return GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/timeline',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => ProviderScope(
            parent: ProviderScope.containerOf(context, listen: false),
            child: LoopMindScaffold(shell: navigationShell),
          ),
          branches: [
            StatefulShellBranch(
              navigatorKey: _shellKey,
              routes: [
                GoRoute(
                  path: '/timeline',
                  name: TimelinePage.routeName,
                  builder: (context, state) => const TimelinePage(),
                  routes: [
                    GoRoute(
                      path: 'note/:id',
                      name: NoteDetailPage.routeName,
                      builder: (context, state) => NoteDetailPage(
                        noteId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/loopmind',
                  name: LoopMindPage.routeName,
                  builder: (context, state) => const LoopMindPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  name: SettingsPage.routeName,
                  builder: (context, state) => const SettingsPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  final authState = ref.watch(authStateProvider);
  final authChanges = ref.watch(authStateProvider.stream);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/timeline',
    refreshListenable: GoRouterRefreshStream(authChanges),
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isAuthenticated = authState.value != null;
      final loggingIn = state.matchedLocation == '/auth';

      if (!isAuthenticated) {
        return loggingIn ? null : '/auth';
      }

      if (loggingIn) {
        return '/timeline';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        name: AuthPage.routeName,
        builder: (context, state) => const AuthPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ProviderScope(
          parent: ProviderScope.containerOf(context, listen: false),
          child: LoopMindScaffold(shell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/timeline',
                name: TimelinePage.routeName,
                builder: (context, state) => const TimelinePage(),
                routes: [
                  GoRoute(
                    path: 'note/:id',
                    name: NoteDetailPage.routeName,
                    builder: (context, state) => NoteDetailPage(
                      noteId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/loopmind',
                name: LoopMindPage.routeName,
                builder: (context, state) => const LoopMindPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: SettingsPage.routeName,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class LoopMindScaffold extends StatelessWidget {
  const LoopMindScaffold({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.view_timeline_outlined),
            selectedIcon: Icon(Icons.view_timeline),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'LoopMind',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
