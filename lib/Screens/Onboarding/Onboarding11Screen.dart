import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nocrastinate/ThemeManager.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../ApiServices/InAppPurchaseService.dart';

class Onboarding11Screen extends StatefulWidget {
  const Onboarding11Screen({Key? key}) : super(key: key);

  @override
  State<Onboarding11Screen> createState() => _Onboarding11ScreenState();
}

class _Onboarding11ScreenState extends State<Onboarding11Screen> {
  bool isYearlySelected = false;
  bool _purchasePending = false;
  bool _isLoading = true;
  bool _isIAPReady = false;
  final InAppPurchaseService _iapService = InAppPurchaseService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
    _listenToPurchaseUpdates();
  }

  void _listenToPurchaseUpdates() {
    _purchaseSubscription = _iapService.purchaseStream.listen(
          (purchaseDetailsList) async {  // Make this async
        for (var purchaseDetails in purchaseDetailsList) {
          print('Purchase update: ${purchaseDetails.productID} - ${purchaseDetails.status}');

          if (purchaseDetails.status == PurchaseStatus.pending) {
            // Show pending UI
            if (mounted) {
              setState(() {
                _purchasePending = true;
              });
            }
          } else {
            // Handle completed purchase states
            if (purchaseDetails.status == PurchaseStatus.error) {
              // Purchase failed
              if (mounted) {
                setState(() {
                  _purchasePending = false;
                });

                String errorMsg = 'Purchase failed. Please try again.';
                if (purchaseDetails.error?.code == 'user_cancelled' ||
                    purchaseDetails.error?.code == '2') {
                  errorMsg = 'Purchase was cancelled.';
                }

                _showErrorDialog('Purchase Error', errorMsg);
              }
            } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                purchaseDetails.status == PurchaseStatus.restored) {
              // Purchase successful - verify and deliver
              print('Purchase successful, verifying...');

              // The verification and delivery is handled in the service
              // Just show success and navigate
              if (mounted) {
                setState(() {
                  _purchasePending = false;
                });
                _showSuccessDialog();
              }
            } else if (purchaseDetails.status == PurchaseStatus.canceled) {
              // Purchase cancelled
              if (mounted) {
                setState(() {
                  _purchasePending = false;
                });
              }
            }
          }
        }
      },
      onError: (error) {
        print('Purchase stream error: $error');
        if (mounted) {
          setState(() {
            _purchasePending = false;
          });
        }
      },
    );
  }

  Future<void> _initializeIAP() async {
    try {
      setState(() {
        _isLoading = true;
        _isIAPReady = false;
      });

      print('Initializing IAP from screen...');

      // Always reinitialize to ensure we have fresh state
      await _iapService.initialize();

      // Wait a bit and verify products are loaded
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if products were loaded
      if (_iapService.products.isEmpty) {
        print('Warning: No products loaded, but service is initialized');
        // Even if products are empty, if service is initialized we can try
      }

      print('IAP service state after initialization:');
      _iapService.printStatus();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isIAPReady = _iapService.isInitialized;
        });
      }

    } catch (e) {
      print('Error initializing IAP: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isIAPReady = false;
        });

        _showErrorDialog(
          'Initialization Error',
          'Failed to initialize in-app purchases. Please restart the app and try again.',
        );
      }
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    if (_purchasePending) {
      print('Purchase already pending');
      return;
    }

    // Debug: Print service status
    print('=== Before Purchase ===');
    _iapService.printStatus();

    // Check if IAP is initialized
    if (!_iapService.isInitialized) {
      print('IAP service not initialized, attempting to initialize...');
      await _initializeIAP();

      if (!_iapService.isInitialized) {
        _showErrorDialog(
          'Service Not Ready',
          'Unable to connect to the store. Please check your internet connection and try again.',
        );
        return;
      }
    }

    // Check if IAP is available
    if (!_iapService.isAvailable) {
      _showErrorDialog(
        'Not Available',
        'In-app purchases are not available on this device.',
      );
      return;
    }

    setState(() {
      _purchasePending = true;
    });

    try {
      final productId = isYearlySelected
          ? InAppPurchaseService.yearlyProductId
          : InAppPurchaseService.monthlyProductId;

      print('Starting purchase for: $productId');

      // Use the service's getProduct method
      final product = _iapService.getProduct(productId);
      if (product == null) {
        throw Exception('Product $productId not found in loaded products. Available: ${_iapService.products.map((p) => p.id).toList()}');
      }

      print('Product found: ${product.title} - ${product.price}');

      // Initiate purchase through service
      print('Calling buyProduct on service...');
      final success = await _iapService.buyProduct(productId);

      print('Purchase initiation result: $success');

      if (!success) {
        throw Exception('Failed to initiate purchase');
      }

      // Purchase stream will handle the rest
      print('Purchase initiated successfully, waiting for confirmation...');

    } catch (e) {
      print('Purchase error: $e');
      print('Error type: ${e.runtimeType}');

      if (mounted) {
        setState(() {
          _purchasePending = false;
        });

        String errorMessage = 'An error occurred during purchase.';

        if (e.toString().contains('not found')) {
          errorMessage = 'This subscription option is not available. Please try the other option or contact support.';
        } else if (e.toString().contains('not initialized')) {
          errorMessage = 'Service is still loading. Please wait a moment and try again.';
        } else if (e.toString().contains('not available')) {
          errorMessage = 'In-app purchases are not available on this device.';
        } else {
          errorMessage = 'Purchase failed: ${e.toString().replaceAll('Exception: ', '')}';
        }

        _showErrorDialog('Purchase Failed', errorMessage);
      }
    }
  }

  Future<void> _retryIAPInitialization() async {
    await _initializeIAP();
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success!'),
          content: const Text('Your subscription has been activated. Welcome to Nocrastinate!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: const Text('Get Started'),
            ),
          ],
        );
      },
    );
  }

  String _getProductPrice(String productId) {
    if (!_isIAPReady || _iapService.products.isEmpty) {
      // Return fallback prices while loading
      return productId == InAppPurchaseService.yearlyProductId ? '\$49.99' : '\$9.99';
    }
    return _iapService.getProductPrice(productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.blackSectionColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Top section with title and timeline
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          'Begin your Free Week and start reaching your goals!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildTimelineStep(
                          'assets/svg/blueTick.svg',
                          'Get your mental health diagnosis done',
                          'You successfully started your journey.',
                          isFirst: true,
                        ),
                        _buildTimelineStep(
                          'assets/svg/lock.svg',
                          'Today: Improve your focus',
                          'Reflect on yourself and stay on track.',
                        ),
                        _buildTimelineStep(
                          'assets/svg/next.svg',
                          'Day 6: See your first results',
                          'We\'ll prepare a report on your improvement.',
                        ),
                        _buildTimelineStep(
                          'assets/svg/results.svg',
                          'Day 7: Take your next steps',
                          'Improve further with Nocrastinate\'s features.',
                          isLast: true,
                        ),
                        const SizedBox(height: 40),
                        SvgPicture.asset(
                          'assets/svg/stars.svg',
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Bottom section
                  ThemedContainer(
                    useSecondaryBackground: false,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 40),

                        // Pricing toggle buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Monthly button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isYearlySelected = false;
                                });
                              },
                              child: Container(
                                height: 21,
                                width: 58,
                                decoration: BoxDecoration(
                                  color: !isYearlySelected
                                      ? context.borderColor.withOpacity(0.3)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                ),
                                child: Center(
                                  child: Text(
                                    'Monthly',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: !isYearlySelected ? FontWeight.w600 : FontWeight.w400,
                                      color: context.primaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Yearly button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isYearlySelected = true;
                                });
                              },
                              child: Container(
                                height: 21,
                                width: 58,
                                decoration: BoxDecoration(
                                  color: isYearlySelected
                                      ? context.borderColor.withOpacity(0.3)
                                      : Colors.transparent,
                                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                                ),
                                child: Center(
                                  child: Text(
                                    'Yearly',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: isYearlySelected ? FontWeight.w600 : FontWeight.w400,
                                      color: context.primaryTextColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Pricing display
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (!_isIAPReady)
                          Column(
                            children: [
                              Text(
                                'Unable to load subscription options',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _retryIAPInitialization,
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        else if (!isYearlySelected)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getProductPrice(InAppPurchaseService.monthlyProductId),
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                                Text(
                                  '/month',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Text(
                                        '-58%',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getProductPrice(InAppPurchaseService.yearlyProductId),
                                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    Text(
                                      '/yearly',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                        const SizedBox(height: 30),

                        // Bottom button section
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 168,
                                height: 45,
                                child: ElevatedButton(
                                  onPressed:
                                       _handlePurchase,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.primaryTextColor,
                                    disabledBackgroundColor: context.primaryTextColor.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    elevation: 0,
                                  ),
                                  child:
                                   _purchasePending
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        context.isDarkMode ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  )
                                      :  Text(
                                    'Confirm',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: context.isDarkMode ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      color: context.primaryTextColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'No commitment. Cancel anytime.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: context.primaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: MediaQuery.of(context).padding.bottom),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Loading overlay
            // if (_purchasePending)
            //   Container(
            //     color: Colors.black54,
            //     child: const Center(
            //       child: Column(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           CircularProgressIndicator(
            //             color: Colors.white,
            //           ),
            //           SizedBox(height: 16),
            //           Text(
            //             'Processing purchase...',
            //             style: TextStyle(
            //               color: Colors.white,
            //               fontSize: 16,
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleText(String title) {
    if (title.startsWith('Today:') || title.startsWith('Day 6:') || title.startsWith('Day 7:')) {
      int colonIndex = title.indexOf(':');
      String boldPart = title.substring(0, colonIndex + 1);
      String normalPart = title.substring(colonIndex + 1);

      return RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            color: Colors.white,
          ),
          children: [
            TextSpan(
              text: boldPart,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: normalPart,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      );
    } else {
      return Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      );
    }
  }

  Widget _buildTimelineStep(
      String iconPath,
      String title,
      String subtitle, {
        bool isFirst = false,
        bool isLast = false,
      }) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isFirst ? AppColors.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isFirst ? null : Border.all(
                    color: AppColors.accent,
                    width: 4.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isFirst ? Icons.check : Icons.lock,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleText(title),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}