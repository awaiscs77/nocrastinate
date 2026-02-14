import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  // Product IDs
  static const String monthlyProductId = 'com.nocrastinate.monthly';
  static const String yearlyProductId = 'com.nocrastinate.yearly';

  // Subscription status
  SubscriptionStatus? _currentSubscription;

  // PUBLIC: Expose the purchase stream
  Stream<List<PurchaseDetails>> get purchaseStream => _inAppPurchase.purchaseStream;

  // Initialize the service
  Future<void> initialize() async {
    if (_initialized && _isAvailable && _products.isNotEmpty) {
      print('InAppPurchaseService already initialized with products');
      return;
    }

    try {
      print('Initializing InAppPurchaseService...');

      // Reset state if retrying initialization
      _initialized = false;
      _isAvailable = false;
      _products.clear();

      // Check if IAP is available
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        print('In-app purchases are not available on this device');
        _initialized = true;
        return;
      }

      // Cancel existing subscription if any
      _subscription?.cancel();

      // Set up purchase stream listener
      final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _onPurchaseUpdate,
        onDone: () {
          print('Purchase stream closed');
          _subscription?.cancel();
        },
        onError: (error) {
          print('Purchase stream error: $error');
        },
      );

      // Load products
      await _loadProducts();

      // Load current subscription status
      await _loadSubscriptionStatus();

      // Handle any pending purchases
      await _handlePendingPurchases();

      _initialized = true;
      print('InAppPurchaseService initialized successfully');
      print('_initialized flag: $_initialized');
      print('_isAvailable: $_isAvailable');
      print('Products count: ${_products.length}');

    } catch (e) {
      print('Failed to initialize InAppPurchaseService: $e');
      _initialized = false;
      _subscription?.cancel();
      _subscription = null;
      rethrow;
    }
  }

  // Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;  // Changed from _isInitialized
  }
  void printDetailedStatus() {
    print('=== IAP Service Detailed Status ===');
    print('Initialized: $_initialized');
    print('Available: $_isAvailable');
    print('Products loaded: ${_products.length}');
    print('Products: ${_products.map((p) => '${p.id}: ${p.title} - ${p.price}').toList()}');
    print('Singleton check: ${identical(this, _instance)}');
    print('Current user: ${_auth.currentUser?.uid}');
    print('Current subscription: $_currentSubscription');
    print('Stream subscription active: ${_subscription != null}');
    print('========================');
  }
  // Load products from the store
  Future<void> _loadProducts() async {
    if (!_isAvailable) {
      print('IAP not available on this device');
      return;
    }

    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print('Loading products (attempt ${retryCount + 1}/$maxRetries)...');

        const Set<String> productIds = {monthlyProductId, yearlyProductId};
        final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);

        if (response.notFoundIDs.isNotEmpty) {
          print('Products not found: ${response.notFoundIDs}');
        }

        if (response.error != null) {
          print('Error loading products: ${response.error}');
        }

        _products = response.productDetails;
        print('Loaded ${_products.length} products');

        if (_products.isNotEmpty) {
          for (var product in _products) {
            print('Product: ${product.id} - ${product.title} - ${product.price}');
          }
          return; // Success!
        } else {
          print('No products loaded, retrying...');
          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      } catch (e) {
        print('Error loading products (attempt ${retryCount + 1}): $e');
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    if (_products.isEmpty) {
      print('Failed to load products after $maxRetries attempts');
      throw Exception('Failed to load subscription products');
    }
  }

  // Handle pending purchases on app start
  Future<void> _handlePendingPurchases() async {
    if (!_isAvailable) return;

    try {
      print('Checking for pending purchases...');

      // For iOS, we need to call this to get pending purchases
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatform =
        _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();

        // This will trigger the purchase stream with any pending transactions
         // await iosPlatform.restorePurchases();
      }
    } catch (e) {
      print('Error handling pending purchases: $e');
    }
  }

  // Listen to purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    print('Purchase update received: ${purchaseDetailsList.length} purchases');

    for (var purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  // Handle individual purchase
  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    print('Handling purchase: ${purchaseDetails.productID} - Status: ${purchaseDetails.status}');

    try {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        print('Purchase pending: ${purchaseDetails.productID}');
        // The purchase is pending, user is in the payment flow
        // No action needed here
        return;  // Don't complete pending purchases

      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Purchase error: ${purchaseDetails.error}');
        // Just complete the purchase, the error will be handled in the stream listener

      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        print('Purchase successful: ${purchaseDetails.productID}');

        // Verify the purchase
        bool valid = await _verifyPurchase(purchaseDetails);

        if (valid) {
          // Save to Firebase
          await _savePurchaseToFirebase(purchaseDetails);

          // Deliver the product
          await _deliverProduct(purchaseDetails);

          print('Purchase verified and saved successfully');
        } else {
          print('Purchase verification failed');
          await _handleInvalidPurchase(purchaseDetails);
        }
      }

      // IMPORTANT: Complete the purchase after handling it
      // This tells the store that the purchase has been processed
      if (purchaseDetails.pendingCompletePurchase) {
        print('Completing purchase: ${purchaseDetails.productID}');
        await _inAppPurchase.completePurchase(purchaseDetails);
        print('Purchase completed successfully');
      }

    } catch (e) {
      print('Error handling purchase: $e');

      // Still try to complete the purchase even if there was an error
      if (purchaseDetails.pendingCompletePurchase) {
        try {
          await _inAppPurchase.completePurchase(purchaseDetails);
        } catch (completeError) {
          print('Error completing purchase: $completeError');
        }
      }
    }
  }

  // Verify purchase (implement your own verification logic)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    try {
      print('Verifying purchase: ${purchaseDetails.productID}');

      // For production, you should verify the receipt with Apple's servers
      // or your own backend server

      // Basic validation
      if (purchaseDetails.verificationData.serverVerificationData.isEmpty) {
        print('Warning: No verification data available');
        return false;
      }

      // For now, return true (implement proper verification in production)
      // You should send purchaseDetails.verificationData.serverVerificationData
      // to your backend for verification

      print('Purchase verification successful');
      return true;

    } catch (e) {
      print('Purchase verification error: $e');
      return false;
    }
  }

  // Save purchase to Firebase
  Future<void> _savePurchaseToFirebase(PurchaseDetails purchaseDetails) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      print('Saving purchase to Firebase for user: ${user.uid}');

      // Determine subscription type and duration
      final subscriptionType = purchaseDetails.productID == yearlyProductId ? 'yearly' : 'monthly';
      final now = DateTime.now();
      final expiryDate = subscriptionType == 'yearly'
          ? now.add(const Duration(days: 365))
          : now.add(const Duration(days: 30));

      // Create subscription data
      final subscriptionData = {
        'userId': user.uid,
        'productId': purchaseDetails.productID,
        'subscriptionType': subscriptionType,
        'transactionId': purchaseDetails.purchaseID,
        'purchaseDate': FieldValue.serverTimestamp(),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'status': 'active',
        'platform': Platform.isIOS ? 'ios' : 'android',
        'verificationData': purchaseDetails.verificationData.serverVerificationData,
        'isRestored': purchaseDetails.status == PurchaseStatus.restored,
      };

      // Save to user's subscription collection
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscriptions')
          .doc(purchaseDetails.purchaseID)
          .set(subscriptionData, SetOptions(merge: true));

      // Update user's active subscription
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'subscription': {
          'active': true,
          'type': subscriptionType,
          'productId': purchaseDetails.productID,
          'expiryDate': Timestamp.fromDate(expiryDate),
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      print('Purchase saved to Firebase successfully');

      // Update local subscription status
      await _loadSubscriptionStatus();

    } catch (e) {
      print('Error saving purchase to Firebase: $e');
      throw e;
    }
  }

  // Load subscription status from Firebase
  Future<SubscriptionStatus?> _loadSubscriptionStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _currentSubscription = null;
        return null;
      }

      print('Loading subscription status for user: ${user.uid}');

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        _currentSubscription = null;
        return null;
      }

      final data = doc.data()!;
      if (data['subscription'] == null) {
        _currentSubscription = null;
        return null;
      }

      final subscriptionData = data['subscription'] as Map<String, dynamic>;

      final expiryDate = (subscriptionData['expiryDate'] as Timestamp?)?.toDate();
      final isActive = subscriptionData['active'] as bool? ?? false;

      // Check if subscription is expired
      bool isExpired = false;
      if (expiryDate != null) {
        isExpired = DateTime.now().isAfter(expiryDate);
      }

      _currentSubscription = SubscriptionStatus(
        isActive: isActive && !isExpired,
        subscriptionType: subscriptionData['type'] as String?,
        productId: subscriptionData['productId'] as String?,
        expiryDate: expiryDate,
      );

      print('Subscription status loaded: ${_currentSubscription?.isActive}');

      return _currentSubscription;

    } catch (e) {
      print('Error loading subscription status: $e');
      _currentSubscription = null;
      return null;
    }
  }

  // Deliver product (grant access to subscription)
  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    print('Delivering product: ${purchaseDetails.productID}');
    // The subscription is now active in Firebase
    // You can add additional logic here if needed
  }

  // Handle purchase error
  Future<void> _handlePurchaseError(PurchaseDetails purchaseDetails) async {
    print('Purchase error: ${purchaseDetails.error?.code} - ${purchaseDetails.error?.message}');
  }

  // Handle invalid purchase
  Future<void> _handleInvalidPurchase(PurchaseDetails purchaseDetails) async {
    print('Invalid purchase: ${purchaseDetails.productID}');
  }

  // Public method to initiate purchase
  Future<bool> buyProduct(String productId) async {
    print('buyProduct called for: $productId');
    print('_isAvailable: $_isAvailable');
    print('_initialized: $_initialized');
    print('Products count: ${_products.length}');

    if (!_isAvailable) {
      print('ERROR: In-app purchases are not available');
      throw Exception('In-app purchases are not available');
    }

    if (!_initialized) {
      print('ERROR: InAppPurchaseService not initialized');
      print('This is the singleton instance: ${identical(this, _instance)}');
      throw Exception('InAppPurchaseService not initialized');
    }

    try {
      print('Initiating purchase for: $productId');

      // Find the product
      ProductDetails? product;
      for (var p in _products) {
        if (p.id == productId) {
          product = p;
          break;
        }
      }

      if (product == null) {
        print('ERROR: Product not found: $productId');
        print('Available products: ${_products.map((p) => p.id).toList()}');
        throw Exception('Product not found: $productId');
      }

      print('Product found: ${product.title}');

      // Create purchase param
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Initiate purchase
      print('Calling buyNonConsumable...');
      bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      print('Purchase initiated: $success');
      return success;

    } catch (e) {
      print('Error initiating purchase: $e');
      rethrow;
    }
  }

  void printStatus() {
    print('=== IAP Service Status ===');
    print('Initialized: $_initialized');
    print('Available: $_isAvailable');
    print('Products loaded: ${_products.length}');
    print('Products: ${_products.map((p) => '${p.id}: ${p.price}').toList()}');
    print('Singleton check: ${identical(this, _instance)}');
    print('========================');
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      throw Exception('In-app purchases are not available');
    }

    try {
      print('Restoring purchases...');

      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatform =
        _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();

        // await iosPlatform.restorePurchases();
        print('Purchases restored');
      }

    } catch (e) {
      print('Error restoring purchases: $e');
      throw e;
    }
  }

  // Cancel subscription (just update status, actual cancellation happens in App Store)
  Future<void> cancelSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      print('Marking subscription as cancelled for user: ${user.uid}');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'subscription': {
          'cancellationRequested': true,
          'cancellationDate': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      print('Subscription marked as cancelled');

      // Note: User needs to cancel subscription in App Store settings
      // This just marks it in your database

    } catch (e) {
      print('Error cancelling subscription: $e');
      throw e;
    }
  }

  // Getters
  bool get isAvailable => _isAvailable;
  List<ProductDetails> get products => _products;
  SubscriptionStatus? get currentSubscription => _currentSubscription;

  // Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    await _loadSubscriptionStatus();
    return _currentSubscription?.isActive ?? false;
  }

  // Get product by ID
  ProductDetails? getProduct(String productId) {
    for (var product in _products) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }

  // Get product price
  String getProductPrice(String productId) {
    final product = getProduct(productId);
    if (product != null) {
      return product.price;
    }
    // Fallback prices
    return productId == yearlyProductId ? '£49.99' : '£9.99';
  }

  // Format error message
  String getErrorMessage(IAPError error) {
    switch (error.code) {
      case 'purchase_error':
        return 'Purchase failed. Please try again.';
      case 'purchase_cancelled':
        return 'Purchase was cancelled.';
      case 'network_error':
        return 'Network error. Please check your connection.';
      case 'user_cancelled':
        return 'You cancelled the purchase.';
      case 'payment_invalid':
        return 'Payment method is invalid.';
      case 'payment_not_allowed':
        return 'Payment is not allowed on this device.';
      case 'store_product_not_available':
        return 'This product is not available in your region.';
      case 'duplicate_product':
        return 'You already own this subscription.';
      default:
        return error.message;
    }
  }
}

// Subscription status model
class SubscriptionStatus {
  final bool isActive;
  final String? subscriptionType;
  final String? productId;
  final DateTime? expiryDate;

  SubscriptionStatus({
    required this.isActive,
    this.subscriptionType,
    this.productId,
    this.expiryDate,
  });

  bool get isExpired {
    if (expiryDate == null) return true;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isMonthly => subscriptionType == 'monthly';
  bool get isYearly => subscriptionType == 'yearly';

  int get daysRemaining {
    if (expiryDate == null) return 0;
    final difference = expiryDate!.difference(DateTime.now());
    return difference.inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'subscriptionType': subscriptionType,
      'productId': productId,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SubscriptionStatus(isActive: $isActive, type: $subscriptionType, expiryDate: $expiryDate)';
  }
}