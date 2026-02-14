import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:nocrastinate/ThemeManager.dart';
import 'package:provider/provider.dart';
import 'package:nocrastinate/Screens/CustomTabbar/CustomTabbar.dart';
import 'package:nocrastinate/Screens/Onboarding/OnBoarding1Screen.dart';
import 'package:nocrastinate/Screens/Onboarding/Onboarding2Screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ApiServices/AuthProvider.dart';
import '../../ApiServices/OnBoardingServices.dart';
import '../../ApiServices/InAppPurchaseService.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isOnline = true;
  late ConnectivityResult _connectionStatus;
  final InAppPurchaseService _iapService = InAppPurchaseService();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initConnectivityListener();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    try {
      await _iapService.initialize();
    } catch (e) {
      print('Error initializing IAP in AuthWrapper: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    final List<ConnectivityResult> connectivityResult =
    await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult.first);
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _updateConnectionStatus(result.first);
    });
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _connectionStatus = result;
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show offline mode if no connectivity
        if (!_isOnline) {
          return _buildOfflineMode(context, authProvider);
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Show splash screen while initializing
            if (authProvider.status == AuthStatus.uninitialized) {
              return const SplashScreen();
            }

            // Show loading while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting ||
                authProvider.status == AuthStatus.loading) {
              return const LoadingScreen();
            }

            // If there's an error, try offline mode
            if (snapshot.hasError) {
              return _buildOfflineModeWithError(context, authProvider, snapshot.error.toString());
            }

            // No user signed in - show onboarding
            if (!snapshot.hasData ||
                snapshot.data == null ||
                authProvider.status == AuthStatus.unauthenticated) {
              print('No user signed in - showing onboarding');
              return const OnBoarding1Screen();
            }

            // User is signed in - check onboarding status
            final user = snapshot.data!;
            print('User signed in: ${user.email}');

            return _buildOnboardingCheck(context, authProvider);
          },
        );
      },
    );
  }

  Widget _buildOnboardingCheck(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getOnboardingStatusWithFallback(),
      builder: (context, onboardingSnapshot) {
        // Show loading while checking onboarding status
        if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // If there's an error checking onboarding status
        if (onboardingSnapshot.hasError) {
          print('Error checking onboarding status: ${onboardingSnapshot.error}');
          // Use cached onboarding status or default to showing main app
          return _buildWithCachedOnboardingStatus(context, authProvider);
        }

        final onboardingStatus = onboardingSnapshot.data ?? {};
        return _handleOnboardingStatus(context, authProvider, onboardingStatus);
      },
    );
  }

  Widget _handleOnboardingStatus(
      BuildContext context,
      AuthProvider authProvider,
      Map<String, dynamic> onboardingStatus
      ) {
    final isCompleted = onboardingStatus['isCompleted'] ?? false;
    final isSkipped = onboardingStatus['isSkipped'] ?? false;
    final shouldShowOnboarding = onboardingStatus['shouldShowOnboarding'] ?? true;

    print('Onboarding status: $onboardingStatus');
    print('Is completed: $isCompleted, Is skipped: $isSkipped, Should show: $shouldShowOnboarding');

    // Cache the onboarding status locally
    _cacheOnboardingStatus(onboardingStatus);

    // Only proceed to purchase check if onboarding is actually completed
    if (isCompleted && !isSkipped) {
      // Ensure AuthProvider knows user is fully authenticated
      if (authProvider.status != AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          authProvider.setAuthenticatedStatus();
        });
      }

      print('Onboarding completed - checking subscription status');
      return _buildSubscriptionCheck(context, authProvider);
    }

    // If onboarding was skipped OR not completed, show onboarding flow
    if (isSkipped) {
      print('Onboarding was skipped earlier - showing onboarding flow again');
    } else {
      print('Onboarding needed - showing onboarding flow');
    }

    return const Onboarding2Screen();
  }

  Widget _buildSubscriptionCheck(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<SubscriptionStatus?>(
      future: _getSubscriptionStatus(),
      builder: (context, subscriptionSnapshot) {
        // Show loading while checking subscription
        if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // If there's an error, check cached subscription or show purchase screen
        if (subscriptionSnapshot.hasError) {
          print('Error checking subscription: ${subscriptionSnapshot.error}');
          return _buildWithCachedSubscriptionStatus(context);
        }

        final subscriptionStatus = subscriptionSnapshot.data;

        if (subscriptionStatus != null && subscriptionStatus.isActive && !subscriptionStatus.isExpired) {
          print('Active subscription found - Days remaining: ${subscriptionStatus.daysRemaining}');

          // Cache subscription status
          _cacheSubscriptionStatus(true);

          // Navigate to home instead of showing CustomTabbarView directly
          return _navigateToHome(context);
        } else {
          if (subscriptionStatus != null && subscriptionStatus.isExpired) {
            print('Subscription expired - showing purchase screen');
          } else {
            print('No active subscription - showing purchase screen');
          }

          // Cache subscription status
          _cacheSubscriptionStatus(false);

          return _navigateToPurchaseScreen(context);
        }
      },
    );
  }

  // Get full subscription status instead of just boolean
  Future<SubscriptionStatus?> _getSubscriptionStatus() async {
    try {
      await _iapService.initialize();
      return _iapService.currentSubscription;
    } catch (e) {
      print('Error getting subscription status: $e');
      return null;
    }
  }

  Widget _navigateToHome(BuildContext context) {
    // Navigate to home using named route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/home');
    });

    // Show loading while navigating
    return const LoadingScreen();
  }

  Widget _navigateToPurchaseScreen(BuildContext context) {
    // Navigate to purchase screen using named route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/purchase');
    });

    // Show loading while navigating
    return const LoadingScreen();
  }

  Widget _buildWithCachedSubscriptionStatus(BuildContext context) {
    return FutureBuilder<bool>(
      future: _getCachedSubscriptionStatus(),
      builder: (context, snapshot) {
        final hasSubscription = snapshot.data ?? false;

        if (hasSubscription) {
          print('Cached subscription found - navigating to home');
          return _navigateToHome(context);
        } else {
          print('No cached subscription - showing purchase screen');
          return _navigateToPurchaseScreen(context);
        }
      },
    );
  }

  Widget _buildOfflineMode(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<bool>(
      future: _hasValidCachedAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final hasValidAuth = snapshot.data ?? false;

        if (hasValidAuth) {
          // Check cached subscription status for offline mode
          return FutureBuilder<bool>(
            future: _getCachedSubscriptionStatus(),
            builder: (context, subSnapshot) {
              final hasSubscription = subSnapshot.data ?? false;

              if (hasSubscription) {
                // User has valid cached authentication and subscription, navigate to home
                return Column(
                  children: [
                    _buildOfflineBanner(),
                    Expanded(
                      child: Navigator(
                        onGenerateRoute: (settings) {
                          return MaterialPageRoute(
                            builder: (context) => CustomTabbarView(),
                          );
                        },
                      ),
                    ),
                  ],
                );
              } else {
                // Has auth but no subscription - show offline purchase notice
                return _buildOfflinePurchaseNotice();
              }
            },
          );
        } else {
          // No valid cached auth, show limited offline mode
          return _buildLimitedOfflineMode();
        }
      },
    );
  }

  Widget _buildOfflinePurchaseNotice() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'You\'re Offline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Please connect to the internet to purchase or verify your subscription.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _checkConnectivity(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh),
                  const SizedBox(width: 8),
                  const Text('Try Again'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineModeWithError(
      BuildContext context,
      AuthProvider authProvider,
      String error
      ) {
    return FutureBuilder<bool>(
      future: _hasValidCachedAuth(),
      builder: (context, snapshot) {
        final hasValidAuth = snapshot.data ?? false;

        if (hasValidAuth) {
          // Show main app with offline banner and error notice
          return Column(
            children: [
              _buildOfflineBanner(),
              Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Authentication error, running in offline mode',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(child: CustomTabbarView()),
            ],
          );
        } else {
          return AuthErrorScreen(error: error);
        }
      },
    );
  }

  Widget _buildWithCachedOnboardingStatus(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCachedOnboardingStatus(),
      builder: (context, snapshot) {
        final cachedStatus = snapshot.data ?? {'shouldShowOnboarding': false};
        return _handleOnboardingStatus(context, authProvider, cachedStatus);
      },
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.red.shade700, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re offline. Some features may be limited.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitedOfflineMode() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'You\'re Offline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Please connect to the internet to sign in and access all features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _checkConnectivity(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh),
                  const SizedBox(width: 8),
                  const Text('Try Again'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for caching
  Future<bool> _hasValidCachedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAuth = prefs.getBool('has_valid_auth') ?? false;
      final authTimestamp = prefs.getInt('auth_timestamp') ?? 0;

      // Check if cached auth is not older than 7 days
      final now = DateTime.now().millisecondsSinceEpoch;
      final daysDiff = (now - authTimestamp) / (1000 * 60 * 60 * 24);

      return hasAuth && daysDiff < 7;
    } catch (e) {
      print('Error checking cached auth: $e');
      return false;
    }
  }

  Future<void> _cacheAuthStatus(bool isAuthenticated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_valid_auth', isAuthenticated);
      await prefs.setInt('auth_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching auth status: $e');
    }
  }

  Future<Map<String, dynamic>> _getOnboardingStatusWithFallback() async {
    try {
      // Try to get online status first
      final onlineStatus = await OnboardingService.getOnboardingStatus();
      // Cache the result
      await _cacheOnboardingStatus(onlineStatus);
      return onlineStatus;
    } catch (e) {
      print('Failed to get online onboarding status, using cached: $e');
      // Fallback to cached status
      return await _getCachedOnboardingStatus();
    }
  }

  Future<void> _cacheOnboardingStatus(Map<String, dynamic> status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', status['isCompleted'] ?? false);
      await prefs.setBool('onboarding_skipped', status['isSkipped'] ?? false);
      await prefs.setBool('should_show_onboarding', status['shouldShowOnboarding'] ?? true);
    } catch (e) {
      print('Error caching onboarding status: $e');
    }
  }

  Future<Map<String, dynamic>> _getCachedOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'isCompleted': prefs.getBool('onboarding_completed') ?? false,
        'isSkipped': prefs.getBool('onboarding_skipped') ?? false,
        'shouldShowOnboarding': prefs.getBool('should_show_onboarding') ?? false,
      };
    } catch (e) {
      print('Error getting cached onboarding status: $e');
      return {
        'isCompleted': false,
        'isSkipped': false,
        'shouldShowOnboarding': false,
      };
    }
  }

  Future<void> _cacheSubscriptionStatus(bool hasSubscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_active_subscription', hasSubscription);
      await prefs.setInt('subscription_check_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching subscription status: $e');
    }
  }

  Future<bool> _getCachedSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSubscription = prefs.getBool('has_active_subscription') ?? false;
      final timestamp = prefs.getInt('subscription_check_timestamp') ?? 0;

      // Check if cached subscription check is not older than 1 day
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursDiff = (now - timestamp) / (1000 * 60 * 60);

      // If cache is stale (older than 24 hours), return false to trigger a new check
      if (hoursDiff > 24) {
        return false;
      }

      return hasSubscription;
    } catch (e) {
      print('Error getting cached subscription status: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _iapService.dispose();
    super.dispose();
  }
}

// Keep your existing screens unchanged
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            const SizedBox(height: 24),
            Text(
              'Nocrastinate',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthErrorScreen extends StatelessWidget {
  final String error;

  const AuthErrorScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Authentication Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).initialize();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}