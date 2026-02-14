import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final bool isAnonymous;
  final DateTime? creationTime;
  final DateTime? lastSignInTime;
  final DateTime? firestoreCreatedAt; // NEW: Store Firestore createdAt
  final List<UserProvider> providers;

  // Use Firestore createdAt if available, otherwise fall back to Firebase Auth creationTime
  DateTime? get registrationDate => firestoreCreatedAt ?? creationTime;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
    required this.isAnonymous,
    this.creationTime,
    this.lastSignInTime,
    this.firestoreCreatedAt, // NEW
    required this.providers,
  });

  // Create UserModel from Firebase User only (fallback)
  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      isAnonymous: firebaseUser.isAnonymous,
      creationTime: firebaseUser.metadata.creationTime,
      lastSignInTime: firebaseUser.metadata.lastSignInTime,
      firestoreCreatedAt: null, // Will be populated when Firestore data is loaded
      providers: firebaseUser.providerData
          .map<UserProvider>((info) => UserProvider.fromProviderData(info))
          .toList(),
    );
  }

  // NEW: Create UserModel from Firebase User + Firestore data
  factory UserModel.fromFirebaseUserWithFirestore(
      dynamic firebaseUser,
      Map<String, dynamic>? firestoreData,
      ) {
    DateTime? firestoreCreatedAt;

    // Extract createdAt from Firestore if available
    if (firestoreData != null && firestoreData.containsKey('createdAt')) {
      final createdAtValue = firestoreData['createdAt'];
      if (createdAtValue is Timestamp) {
        firestoreCreatedAt = createdAtValue.toDate();
      } else if (createdAtValue is String) {
        try {
          firestoreCreatedAt = DateTime.parse(createdAtValue);
        } catch (e) {
          print('Error parsing createdAt string: $e');
        }
      }
    }

    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      isAnonymous: firebaseUser.isAnonymous,
      creationTime: firebaseUser.metadata.creationTime,
      lastSignInTime: firebaseUser.metadata.lastSignInTime,
      firestoreCreatedAt: firestoreCreatedAt,
      providers: firebaseUser.providerData
          .map<UserProvider>((info) => UserProvider.fromProviderData(info))
          .toList(),
    );
  }

  // Create UserModel from Map (for local storage/serialization)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      emailVerified: map['emailVerified'] ?? false,
      isAnonymous: map['isAnonymous'] ?? false,
      creationTime: map['creationTime'] != null
          ? DateTime.parse(map['creationTime'])
          : null,
      lastSignInTime: map['lastSignInTime'] != null
          ? DateTime.parse(map['lastSignInTime'])
          : null,
      firestoreCreatedAt: map['firestoreCreatedAt'] != null
          ? DateTime.parse(map['firestoreCreatedAt'])
          : null,
      providers: (map['providers'] as List<dynamic>?)
          ?.map((provider) => UserProvider.fromMap(provider))
          .toList() ?? [],
    );
  }

  // Convert to Map (for local storage/serialization)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'isAnonymous': isAnonymous,
      'creationTime': creationTime?.toIso8601String(),
      'lastSignInTime': lastSignInTime?.toIso8601String(),
      'firestoreCreatedAt': firestoreCreatedAt?.toIso8601String(),
      'providers': providers.map((provider) => provider.toMap()).toList(),
    };
  }

  // Check if user signed in with specific provider
  bool isSignedInWithProvider(String providerId) {
    return providers.any((provider) => provider.providerId == providerId);
  }

  // Get display name or email or uid as fallback
  String get displayIdentifier {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (email != null && email!.isNotEmpty) {
      return email!;
    }
    return uid;
  }

  // Get first name from display name
  String? get firstName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!.split(' ').first;
    }
    return null;
  }

  // Check if user is signed in with Google
  bool get isGoogleUser => isSignedInWithProvider('google.com');

  // Check if user is signed in with Apple
  bool get isAppleUser => isSignedInWithProvider('apple.com');

  // Check if user is signed in with email/password
  bool get isEmailUser => isSignedInWithProvider('password');

  // Copy with method for updating user data
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    bool? isAnonymous,
    DateTime? creationTime,
    DateTime? lastSignInTime,
    DateTime? firestoreCreatedAt,
    List<UserProvider>? providers,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      creationTime: creationTime ?? this.creationTime,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
      firestoreCreatedAt: firestoreCreatedAt ?? this.firestoreCreatedAt,
      providers: providers ?? this.providers,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

class UserProvider {
  final String providerId;
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoURL;

  UserProvider({
    required this.providerId,
    required this.uid,
    this.displayName,
    this.email,
    this.photoURL,
  });

  factory UserProvider.fromProviderData(dynamic providerData) {
    return UserProvider(
      providerId: providerData.providerId,
      uid: providerData.uid,
      displayName: providerData.displayName,
      email: providerData.email,
      photoURL: providerData.photoURL,
    );
  }

  factory UserProvider.fromMap(Map<String, dynamic> map) {
    return UserProvider(
      providerId: map['providerId'] ?? '',
      uid: map['uid'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      photoURL: map['photoURL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
    };
  }
}