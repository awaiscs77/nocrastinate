import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  bool _isInitialized = false;

  // Initialize with platform-specific configuration
  void initialize({String? googleClientId}) {
    try {
      if (Platform.isIOS) {
        // iOS requires explicit client ID for Google Sign In
        if (googleClientId == null || googleClientId.isEmpty) {
          print('Warning: Google Client ID not provided for iOS. Google Sign In may not work.');
          // Initialize without Google Sign In for iOS if client ID is missing
          _googleSignIn = null;
        } else {
          _googleSignIn = GoogleSignIn(
            clientId: googleClientId,
            scopes: ['email', 'profile'],
          );
          print('AuthService initialized for iOS with Google Sign In');
        }
      } else if (Platform.isAndroid) {
        // Android uses google-services.json automatically
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        print('AuthService initialized for Android with Google Sign In');
      } else {
        throw Exception('Unsupported platform');
      }

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize AuthService: $e');
      _isInitialized = false;
    }
  }

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Get auth state stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Check which sign-in methods are available
  bool get isGoogleSignInAvailable => _googleSignIn != null;
  bool get isAppleSignInAvailable => Platform.isIOS;

  // Google Sign In - Works on both iOS and Android
  Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    try {
      // Check if Google Sign In is available
      if (!_isInitialized || _googleSignIn == null) {
        throw Exception('Google Sign In not available. Please check initialization.');
      }

      print('Starting Google Sign In...');

      // Sign out first to ensure clean state
      await _googleSignIn!.signOut();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        print('Google Sign In was cancelled by user');
        return null;
      }

      print('Google account selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to obtain Google authentication tokens');
      }

      print('Google tokens obtained, creating Firebase credential...');

      // Create a new credential for Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      print('Google Sign In successful: ${userCredential.user?.email}');
      print('User display name: ${userCredential.user?.displayName}');

      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error during Google Sign In: ${e.code} - ${e.message}');
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      print('Google Sign In Error: $e');
      throw Exception('Google Sign In failed: $e');
    }
  }

  // Apple Sign In - iOS only
  Future<firebase_auth.UserCredential?> signInWithApple() async {
    try {
      if (!Platform.isIOS) {
        throw Exception('Apple Sign In is only available on iOS devices');
      }

      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      print('Starting Apple Sign In...');

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      print('Requesting Apple ID credential...');

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      print('Apple credential received');
      print('Identity token present: ${appleCredential.identityToken != null}');
      print('Authorization code present: ${appleCredential.authorizationCode != null}');

      if (appleCredential.identityToken == null) {
        throw Exception('Failed to obtain Apple identity token');
      }

      // IMPORTANT: Create OAuth credential with BOTH idToken and accessToken
      final oauthCredential = firebase_auth.OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode, // ADD THIS
      );

      print('Created OAuth credential, signing in to Firebase...');

      // Sign in to Firebase with retry logic
      firebase_auth.UserCredential? userCredential;
      int retryCount = 0;
      const maxRetries = 2;

      while (retryCount <= maxRetries) {
        try {
          userCredential = await _auth.signInWithCredential(oauthCredential);
          print('Apple Sign In successful: ${userCredential.user?.email}');
          break;
        } on firebase_auth.FirebaseAuthException catch (e) {
          if (e.code == 'invalid-credential' && retryCount < maxRetries) {
            print('Invalid credential error, retrying... (${retryCount + 1}/$maxRetries)');
            retryCount++;
            await Future.delayed(Duration(milliseconds: 500));
          } else {
            rethrow;
          }
        }
      }

      if (userCredential == null) {
        throw Exception('Failed to sign in after retries');
      }

      return userCredential;

    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error during Apple Sign In: ${e.code} - ${e.message}');

      // Handle specific error cases
      if (e.code == 'invalid-credential') {
        throw Exception(
            'Apple Sign In failed due to invalid credentials. This can happen if:\n'
                '• Your device date/time is incorrect\n'
                '• Apple Sign In capability is not properly configured\n'
                '• The Apple token expired\n\n'
                'Please ensure your device time is set to automatic and try again.'
        );
      }

      throw Exception(_handleFirebaseAuthError(e));
    } on SignInWithAppleAuthorizationException catch (e) {
      print('Apple Authorization Error: ${e.code} - ${e.message}');

      if (e.code == AuthorizationErrorCode.canceled) {
        print('User canceled Apple Sign In');
        return null;
      }

      throw Exception('Apple Sign In authorization failed: ${e.message}');
    } catch (e) {
      print('Apple Sign In Error: $e');
      throw Exception('Apple Sign In failed: $e');
    }
  }

  // Sign out from all providers
  Future<void> signOut() async {
    try {
      print('Signing out...');

      // Sign out from Google if available and signed in
      if (_googleSignIn != null) {
        final isSignedIn = await _googleSignIn!.isSignedIn();
        if (isSignedIn) {
          await _googleSignIn!.signOut();
          print('Signed out from Google');
        }
      }

      // Sign out from Firebase (this handles Apple and other providers)
      await _auth.signOut();
      print('Signed out from Firebase');

    } catch (e) {
      print('Error during sign out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Delete account with automatic re-authentication
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      print('Starting account deletion process...');
      print('User: ${user.email}');
      print('Providers: ${user.providerData.map((p) => p.providerId).join(', ')}');

      // Check if recent authentication is needed
      final lastSignIn = user.metadata.lastSignInTime;
      final now = DateTime.now();
      bool needsReauth = false;

      if (lastSignIn != null) {
        final timeSinceLastSignIn = now.difference(lastSignIn);
        needsReauth = timeSinceLastSignIn.inMinutes > 5;
        print('Time since last sign-in: ${timeSinceLastSignIn.inMinutes} minutes');
      } else {
        needsReauth = true;
        print('No last sign-in time available, requiring re-authentication');
      }

      // Attempt to delete without re-authentication first
      if (!needsReauth) {
        try {
          await _performAccountDeletion();
          return;
        } on firebase_auth.FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            print('Recent authentication required, proceeding with re-auth...');
            needsReauth = true;
          } else {
            throw e;
          }
        }
      }

      // If re-authentication is needed, perform it before deletion
      if (needsReauth) {
        print('Re-authentication required before account deletion');
        await _reauthenticateUser();
        print('Re-authentication successful, proceeding with deletion...');
      }

      // Now perform the account deletion
      await _performAccountDeletion();

    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error during account deletion: ${e.code} - ${e.message}');
      throw Exception(_handleFirebaseAuthError(e));
    } catch (e) {
      print('Account deletion error: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  // Perform the actual account deletion
  Future<void> _performAccountDeletion() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    print('Starting account deletion process...');

    // Disconnect from external providers first
    await _disconnectExternalProviders();

    // Delete the Firebase user account
    await user.delete();

    print('Account deleted from Firebase');

    // Force sign out to clear any cached state
    try {
      await _auth.signOut();
      print('Forced sign out completed');
    } catch (e) {
      print('Sign out after deletion failed (this might be expected): $e');
    }


    // Additional cleanup - clear any remaining Google Sign In state
    if (_googleSignIn != null) {
      try {
        await _googleSignIn!.signOut();
        await _googleSignIn!.disconnect();
        print('Google Sign In state cleared');
      } catch (e) {
        print('Google cleanup failed (might be expected): $e');
      }
    }

    print('Account deletion completed successfully');


  }
  // Re-authenticate user based on their sign-in provider
  Future<void> _reauthenticateUser() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final providers = user.providerData.map((info) => info.providerId).toList();
    print('Re-authenticating with providers: $providers');

    if (providers.contains('google.com')) {
      await _reauthenticateWithGoogle();
    } else if (providers.contains('apple.com')) {
      await _reauthenticateWithApple();
    } else {
      throw Exception('Unable to determine re-authentication method for providers: $providers');
    }
  }

  // Re-authenticate with Google
  Future<void> _reauthenticateWithGoogle() async {
    if (_googleSignIn == null) {
      throw Exception('Google Sign In not available');
    }

    print('Re-authenticating with Google...');

    // Sign out first to ensure clean re-authentication
    await _googleSignIn!.signOut();

    final googleUser = await _googleSignIn!.signIn();
    if (googleUser == null) {
      throw Exception('Google re-authentication was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw Exception('Failed to obtain Google authentication tokens for re-auth');
    }

    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _auth.currentUser?.reauthenticateWithCredential(credential);
    print('Google re-authentication successful');
  }

  // Re-authenticate with Apple
  Future<void> _reauthenticateWithApple() async {
    if (!Platform.isIOS) {
      throw Exception('Apple Sign In only available on iOS');
    }

    print('Re-authenticating with Apple...');

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = firebase_auth.OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    await _auth.currentUser?.reauthenticateWithCredential(oauthCredential);
    print('Apple re-authentication successful');
  }

  // Disconnect from external providers
  Future<void> _disconnectExternalProviders() async {
    try {
      // Disconnect from Google
      if (_googleSignIn != null) {
        final isSignedIn = await _googleSignIn!.isSignedIn();
        if (isSignedIn) {
          await _googleSignIn!.disconnect();
          print('Disconnected from Google');
        }
      }

      // Note: Apple doesn't have a disconnect method
      // The account will be automatically unlinked when Firebase account is deleted

    } catch (e) {
      print('Warning: Failed to disconnect from external providers: $e');
      // Don't throw here as it shouldn't prevent account deletion
    }
  }

  // Get comprehensive user data
  Map<String, dynamic>? getUserData() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'emailVerified': user.emailVerified,
      'isAnonymous': user.isAnonymous,
      'creationTime': user.metadata.creationTime?.toIso8601String(),
      'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      'providers': user.providerData.map((info) => {
        'providerId': info.providerId,
        'uid': info.uid,
        'displayName': info.displayName,
        'email': info.email,
        'photoURL': info.photoURL,
      }).toList(),
      'isGoogleUser': user.providerData.any((p) => p.providerId == 'google.com'),
      'isAppleUser': user.providerData.any((p) => p.providerId == 'apple.com'),
    };
  }

  // Check if user signed in with specific provider
  bool isSignedInWithProvider(String providerId) {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == providerId);
  }

  // Convenience methods
  bool get isGoogleUser => isSignedInWithProvider('google.com');
  bool get isAppleUser => isSignedInWithProvider('apple.com');

  // Get all linked providers
  List<String> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];
    return user.providerData.map((info) => info.providerId).toList();
  }

  // Generate a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  // Generate SHA256 hash of input string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Handle Firebase Auth errors with user-friendly messages
  String _handleFirebaseAuthError(firebase_auth.FirebaseAuthException e) {
    print('Firebase Auth Error Code: ${e.code}');
    print('Firebase Auth Error Message: ${e.message}');
    print('Full Error: ${e.toString()}');

    switch (e.code) {
      case 'invalid-credential':
        return 'Apple Sign In credentials are invalid or have expired. This could be due to:'
            '\n1. Device time not being synced'
            '\n2. Apple Sign In not properly configured'
            '\n3. Expired Apple token'
            '\n\nPlease try signing in again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in method. Try signing in with a different method.';
      case 'invalid-credential':
        return 'The sign-in credentials are invalid or have expired.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No user found with these credentials.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please sign in again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'popup-closed-by-user':
        return 'The sign-in popup was closed before completing the process.';
      case 'cancelled-popup-request':
        return 'The sign-in process was cancelled.';
      case 'popup-blocked':
        return 'The sign-in popup was blocked by the browser.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}