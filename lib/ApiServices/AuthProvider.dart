import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADD THIS IMPORT
import 'dart:async';

import '../Models/UserModel.dart';
import 'AuthService.dart';
import 'OnBoardingServices.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ADD THIS

  DateTime? get userRegistrationDate {
    return _user?.registrationDate;
  }

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isUninitialized => _status == AuthStatus.uninitialized;

  AuthProvider() {
    _initializeAuth();
  }

  // ADD THIS METHOD - Calculate member duration
  String getMemberDuration() {
    final registrationDate = userRegistrationDate;

    if (registrationDate == null) {
      return '0 days';
    }

    final now = DateTime.now();
    final difference = now.difference(registrationDate);

    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? "day" : "days"}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"}';
    } else {
      final years = (difference.inDays / 365).floor();
      final remainingMonths = ((difference.inDays % 365) / 30).floor();

      if (remainingMonths == 0) {
        return '$years ${years == 1 ? "year" : "years"}';
      } else {
        return '$years ${years == 1 ? "year" : "years"}, $remainingMonths ${remainingMonths == 1 ? "month" : "months"}';
      }
    }
  }

  // UPDATED METHOD - Initialize authentication state with Firestore data
  void _initializeAuth() {
    _setStatus(AuthStatus.loading);

    // Listen to Firebase auth state changes
    _authSubscription = _authService.authStateChanges.listen(
          (User? firebaseUser) async {
        if (firebaseUser != null) {
          // Initialize onboarding data for new or existing users
          await OnboardingService.initializeUserOnboarding();

          // Load user data from Firestore to get accurate createdAt
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .get();

            final firestoreData = userDoc.exists ? userDoc.data() : null;

            // Create UserModel with Firestore data
            _setUser(UserModel.fromFirebaseUserWithFirestore(
              firebaseUser,
              firestoreData,
            ));

            print('User loaded with registration date: ${_user?.registrationDate}');
          } catch (e) {
            print('Failed to load Firestore data: $e');
            // Fallback to basic user model if Firestore fails
            _setUser(UserModel.fromFirebaseUser(firebaseUser));
          }

          _setStatus(AuthStatus.authenticated);
        } else {
          _setUser(null);
          _setStatus(AuthStatus.unauthenticated);
        }
      },
      onError: (error) {
        _setError('Authentication state error: $error');
        _setStatus(AuthStatus.unauthenticated);
      },
    );
  }

  // Initialize the AuthProvider (can be called to reinitialize)
  void initialize() {
    _initializeAuth();
  }

  // Set authentication status - used by AuthWrapper after onboarding check
  void setAuthenticatedStatus() {
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // Set authentication status
  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  // Set user data
  void _setUser(UserModel? user) {
    _user = user;
    _clearError();
    notifyListeners();
  }

  // Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      final userCredential = await _authService.signInWithGoogle();


      if (userCredential?.user != null) {
        final user = userCredential!.user!;

        // Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          // Save user data to Firestore with createdAt timestamp
          await _firestore.collection('users').doc(user.uid).set({
            'createdAt': FieldValue.serverTimestamp(),
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          }, SetOptions(merge: true));
        } else {
          // For existing users, ensure createdAt exists
          final userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (!userDoc.exists || !userDoc.data()!.containsKey('createdAt')) {
            // Set createdAt to Firebase Auth creation time as fallback
            await _firestore.collection('users').doc(user.uid).set({
              'createdAt': user.metadata.creationTime ?? DateTime.now(),
            }, SetOptions(merge: true));
          }
        }

        return true;
      }
       else {
        _setError('Google Sign In was cancelled');
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setStatus(AuthStatus.unauthenticated);
      return false;
    }
  }

  // Apple Sign In
  Future<bool> signInWithApple() async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      final userCredential = await _authService.signInWithApple();

      if (userCredential?.user != null) {
        final user = userCredential!.user!;

        // Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          print('New Apple user detected, saving to Firestore...');

          // Save user data to Firestore with createdAt timestamp
          await _firestore.collection('users').doc(user.uid).set({
            'createdAt': FieldValue.serverTimestamp(),
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
            'provider': 'apple.com',
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          print('Existing Apple user detected, updating Firestore...');

          // For existing users, update last login and ensure createdAt exists
          final userDoc = await _firestore.collection('users').doc(user.uid).get();

          final updateData = {
            'lastLogin': FieldValue.serverTimestamp(),
            'email': user.email,
            'displayName': user.displayName,
            'photoURL': user.photoURL,
          };

          if (!userDoc.exists || !userDoc.data()!.containsKey('createdAt')) {
            // Set createdAt to Firebase Auth creation time as fallback
            updateData['createdAt'] = user.metadata.creationTime ?? DateTime.now();
          }

          await _firestore.collection('users').doc(user.uid).set(
            updateData,
            SetOptions(merge: true),
          );
        }

        return true;
      } else {
        print('Apple Sign In returned null user credential');
        _setStatus(AuthStatus.unauthenticated);
        return false;
      }
    }
    catch (e) {
      print('Sign out failed: $e');

      _setStatus(AuthStatus.unauthenticated);
      return false;

    }
  }


  // Sign Out
  Future<void> signOut() async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      await _authService.signOut();
      // The auth state listener will handle clearing the user
    } catch (e) {
      _setError('Sign out failed: $e');
      // Even if sign out fails, we should probably clear the local state
      _setUser(null);
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  // Re-authenticate user (needed before sensitive operations)
  Future<bool> reauthenticate() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('No user signed in');
        return false;
      }

      // Check which provider the user is signed in with
      final providerData = currentUser.providerData;

      for (final provider in providerData) {
        if (provider.providerId == 'google.com') {
          // Re-authenticate with Google
          final credential = await _authService.signInWithGoogle();
          if (credential != null) {
            await currentUser.reauthenticateWithCredential(credential.credential!);
            return true;
          }
        } else if (provider.providerId == 'apple.com') {
          // Re-authenticate with Apple
          final credential = await _authService.signInWithApple();
          if (credential != null) {
            await currentUser.reauthenticateWithCredential(credential.credential!);
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      _setError('Re-authentication failed: $e');
      return false;
    }
  }

  // Delete Account with re-authentication handling
  Future<bool> deleteAccount() async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      await _authService.deleteAccount();

      // Clear local state immediately after deletion
      _setUser(null);
      _setStatus(AuthStatus.unauthenticated);

      return true;
    } catch (e) {
      // Check if it's a requires-recent-login error
      if (e.toString().contains('requires-recent-login')) {
        _setError('This operation requires recent authentication. Please sign in again.');

        // Attempt re-authentication
        final reauthSuccess = await reauthenticate();

        if (reauthSuccess) {
          // Try delete again after re-authentication
          try {
            await _authService.deleteAccount();
            _setUser(null);
            _setStatus(AuthStatus.unauthenticated);
            return true;
          } catch (deleteError) {
            _setError('Delete account failed after re-authentication: $deleteError');
            return false;
          }
        } else {
          return false;
        }
      } else {
        _setError('Delete account failed: $e');

        // Check if user still exists, if not, clear state anyway
        final currentUser = _authService.currentUser;
        if (currentUser == null) {
          _setUser(null);
          _setStatus(AuthStatus.unauthenticated);
          return true; // Account was actually deleted
        } else {
          _setStatus(AuthStatus.authenticated); // Restore previous state
          return false;
        }
      }
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        _setError('No user signed in');
        return false;
      }

      _clearError();

      if (displayName != null) {
        await currentUser.updateDisplayName(displayName);
      }

      if (photoURL != null) {
        await currentUser.updatePhotoURL(photoURL);
      }

      // Reload user data to get updated info
      await currentUser.reload();
      final updatedUser = _authService.currentUser;

      if (updatedUser != null) {
        // Reload with Firestore data
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(updatedUser.uid)
              .get();

          final firestoreData = userDoc.exists ? userDoc.data() : null;
          _setUser(UserModel.fromFirebaseUserWithFirestore(updatedUser, firestoreData));
        } catch (e) {
          _setUser(UserModel.fromFirebaseUser(updatedUser));
        }
      }

      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        final refreshedUser = _authService.currentUser;
        if (refreshedUser != null) {
          // Reload with Firestore data
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(refreshedUser.uid)
                .get();

            final firestoreData = userDoc.exists ? userDoc.data() : null;
            _setUser(UserModel.fromFirebaseUserWithFirestore(refreshedUser, firestoreData));
          } catch (e) {
            _setUser(UserModel.fromFirebaseUser(refreshedUser));
          }
        }
      }
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    }
  }

  // Check if user has specific provider
  bool hasProvider(String providerId) {
    return _user?.isSignedInWithProvider(providerId) ?? false;
  }

  // Get user's display identifier
  String get userDisplayName {
    return _user?.displayIdentifier ?? 'User';
  }

  // Check if email is verified
  bool get isEmailVerified {
    return _user?.emailVerified ?? false;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}