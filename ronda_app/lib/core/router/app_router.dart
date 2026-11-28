import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ronda_app/domain/models/enums.dart';
import 'package:ronda_app/domain/models/site.dart';
import 'package:ronda_app/presentation/auth/create_site_screen.dart';
import 'package:ronda_app/presentation/auth/login_screen.dart';
import 'package:ronda_app/presentation/auth/pending_approval_screen.dart';
import 'package:ronda_app/presentation/auth/register_screen.dart';
import 'package:ronda_app/presentation/auth/site_onboarding_screen.dart';
import 'package:ronda_app/presentation/shared/role_shell.dart';
import 'package:ronda_app/presentation/shared/state_views.dart';
import 'package:ronda_app/providers/auth_site_providers.dart';

abstract final class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String createSite = '/onboarding/create-site';
  static const String pendingApproval = '/pending-approval';
  static const String adminHome = '/admin';
  static const String officerHome = '/officer';
  static const String residentHome = '/resident';
  static const String sosDetailPattern = '/sos/:sosId';

  static String sosDetail(String sosId) => '/sos/$sosId';

  static String homeForRole(SiteRole role) => switch (role) {
    SiteRole.admin => adminHome,
    SiteRole.officer => officerHome,
    SiteRole.resident => residentHome,
  };
}

/// Bridges Riverpod auth and membership updates into GoRouter's refreshListenable.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _ref.listen(authSessionProvider, (_, _) => notifyListeners());
    _ref.listen(mySitesProvider, (_, _) => notifyListeners());
    _ref.listen(selectedSiteIdProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}

/// Pure redirect resolver enforcing auth, active-site, pending-approval, and RBAC guards.
String? resolveAppRedirect({
  required String location,
  required bool isAuthLoading,
  required bool isAuthenticated,
  required bool isSitesLoading,
  required SiteMembershipWithSite? activeMembership,
  required bool hasPendingMembership,
}) {
  if (isAuthLoading) {
    return location == AppRoutes.root ? null : AppRoutes.root;
  }

  final isAuthRoute =
      location == AppRoutes.login || location == AppRoutes.register;
  if (!isAuthenticated) {
    return isAuthRoute ? null : AppRoutes.login;
  }

  if (isSitesLoading) {
    if (location == AppRoutes.root) {
      return null;
    }
    return isAuthRoute ? AppRoutes.root : null;
  }

  final destinationForUser = activeMembership != null
      ? AppRoutes.homeForRole(activeMembership.membership.role)
      : (hasPendingMembership ? AppRoutes.pendingApproval : AppRoutes.onboarding);

  if (location == AppRoutes.root || isAuthRoute) {
    return destinationForUser;
  }

  // Always allow authenticated users to switch, create, or join sites.
  if (location == AppRoutes.onboarding || location == AppRoutes.createSite) {
    return null;
  }

  if (location == AppRoutes.pendingApproval) {
    if (activeMembership != null) {
      return AppRoutes.homeForRole(activeMembership.membership.role);
    }
    return hasPendingMembership ? null : AppRoutes.onboarding;
  }

  if (location.startsWith('/sos/')) {
    return activeMembership != null ? null : destinationForUser;
  }

  final isRoleRoute =
      location == AppRoutes.adminHome ||
      location == AppRoutes.officerHome ||
      location == AppRoutes.residentHome;
  if (isRoleRoute) {
    if (activeMembership == null) {
      return destinationForUser;
    }
    final expectedHome = AppRoutes.homeForRole(activeMembership.membership.role);
    if (location != expectedHome) {
      return expectedHome;
    }
    return null;
  }

  return destinationForUser;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.root,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authSessionProvider);
      final sitesState = ref.read(mySitesProvider);
      final sites = sitesState.asData?.value;
      final selectedSiteId = ref.read(selectedSiteIdProvider);
      final activeMembership = resolveActiveMembership(sites, selectedSiteId);
      final hasPending =
          sites?.any((item) => item.membership.isPending) ?? false;

      return resolveAppRedirect(
        location: state.matchedLocation,
        isAuthLoading: authState.isLoading && !authState.hasValue,
        isAuthenticated: authState.asData?.value != null,
        isSitesLoading: sitesState.isLoading,
        activeMembership: activeMembership,
        hasPendingMembership: hasPending,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const Scaffold(
          body: SafeArea(
            child: LoadingStateView(
              message: 'Memeriksa sesi dan wilayah aktif...',
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const SiteOnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.createSite,
        builder: (context, state) => const CreateSiteScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const RoleShell(role: SiteRole.admin),
      ),
      GoRoute(
        path: AppRoutes.officerHome,
        builder: (context, state) => const RoleShell(role: SiteRole.officer),
      ),
      GoRoute(
        path: AppRoutes.residentHome,
        builder: (context, state) => const RoleShell(role: SiteRole.resident),
      ),
      GoRoute(
        path: AppRoutes.sosDetailPattern,
        builder: (context, state) {
          final sosId = state.pathParameters['sosId'] ?? '';
          return _SosDeepLinkPlaceholderScreen(sosId: sosId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
      body: EmptyStateView(
        title: 'Tautan tidak dikenali',
        description:
            'Halaman yang diminta tidak tersedia di aplikasi RondaDigital.',
        icon: Icons.wrong_location_outlined,
        actionLabel: 'Kembali ke Beranda',
        onAction: () => context.go(AppRoutes.onboarding),
      ),
    ),
  );

  ref.onDispose(router.dispose);
  return router;
});

class _SosDeepLinkPlaceholderScreen extends ConsumerWidget {
  const _SosDeepLinkPlaceholderScreen({required this.sosId});

  final String sosId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeMembershipProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tautan Darurat SOS')),
      body: SafeArea(
        child: EmptyStateView(
          title: 'Pelacak SOS #$sosId',
          description:
              'Tautan notifikasi darurat SOS sudah terhubung. Tampilan pelacakan langsung akan dilengkapi pada modul SOS.',
          icon: Icons.emergency_outlined,
          actionLabel: 'Kembali ke Beranda',
          onAction: () {
            final target = active != null
                ? AppRoutes.homeForRole(active.membership.role)
                : AppRoutes.onboarding;
            context.go(target);
          },
        ),
      ),
    );
  }
}
