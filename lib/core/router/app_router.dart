import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:closet_ai/features/outfits/domain/outfit.dart';
import 'package:closet_ai/features/outfits/presentation/screens/add_event_screen.dart';
import 'package:closet_ai/features/closet/presentation/screens/add_garment_screen.dart';
import 'package:closet_ai/features/home/presentation/screens/home_shell.dart';
import 'package:closet_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:closet_ai/features/outfits/presentation/screens/outfit_result_screen.dart';
import 'package:closet_ai/features/auth/presentation/screens/register_screen.dart';
import 'package:closet_ai/features/auth/presentation/screens/splash_screen.dart';
import 'package:closet_ai/features/auth/presentation/controllers/auth_controller.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final atSplash = state.matchedLocation == '/';

      if (auth.isRestoring) {
        return atSplash ? null : '/';
      }
      if (!auth.isAuthenticated) {
        return loggingIn ? null : '/login';
      }
      if (loggingIn || atSplash) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(path: '/add-garment', builder: (context, state) => const AddGarmentScreen()),
      GoRoute(
        path: '/add-event',
        builder: (context, state) => AddEventScreen(day: state.extra as DateTime),
      ),
      GoRoute(
        path: '/outfit-result',
        builder: (context, state) => OutfitResultScreen(outfit: state.extra as Outfit),
      ),
    ],
  );
});
