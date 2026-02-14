import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Home/MoodScreens/CheckInBahavior/DescribeFeelingScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Settings/AppGuideScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Settings/NotificationDetailScreen.dart';
import 'package:nocrastinate/ThemeManager.dart';

import '../../../ApiServices/AuthProvider.dart';
import '../../../ApiServices/AuthService.dart';
import '../Quote/QuoteCategoryScreen.dart';
import '../Settings/LanguageSelectionScreen.dart';
import 'EditProfileScreen.dart';
import 'IconsAppearenceScreen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isDeleting = false;
  bool _isLoggingOut = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }



  // Navigation functions for each option
  void _navigateToIconAppearance() {
    showIconAppearenceScreen(context);
  }

  // Helper method to launch URLs
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  void _showLogoutDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text(
            'Logout'.tr(),
            style: TextStyle(color: context.primaryTextColor),
          ),
          content: Text(
            'Are you sure you want to logout?'.tr(),
            style: TextStyle(color: context.primaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(
                'Cancel'.tr(),
                style: TextStyle(color: context.primaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog first
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                // Then perform logout
                _performLogout();
              },
              child: Text('Logout'.tr(), style: TextStyle(color: Color(0xFF1D79ED))),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    if (!mounted) return;

    setState(() {
      _isLoggingOut = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: context.cardBackgroundColor,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Logging out...'.tr(),
                  style: TextStyle(color: context.primaryTextColor),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      // Close loading dialog safely
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged out successfully'.tr()),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog safely
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      print('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to logout: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showDeleteDataDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: context.cardBackgroundColor,
          title: Text(
            'Delete Your Data',
            style: TextStyle(color: context.primaryTextColor),
          ),
          content: Text(
            'Are you sure you want to delete all your data? This action cannot be undone.'.tr(),
            style: TextStyle(color: context.primaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(
                'Cancel'.tr(),
                style: TextStyle(color: context.primaryTextColor),
              ),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog first
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
                // Then perform deletion
                _performAccountDeletion();
              },
              child: Text('Delete'.tr(), style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performAccountDeletion() async {
    if (!mounted) return;

    setState(() {
      _isDeleting = true;
    });



    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.deleteAccount();

      // Close loading dialog safely
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      if (success) {
        print('Account deleted successfully');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(Duration(seconds: 1));

        if (mounted) {
          // Clear the entire navigation stack and go to login screen
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
                (Route<dynamic> route) => false,
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${authProvider.errorMessage ?? "Unknown error"}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog safely
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      print('Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // Updated share function with native share
  Future<void> _shareApp() async {
    try {
      final result = await Share.share(
        'Check out Nocrastinate! Download it here:'.tr() +  'https://apple.com',
        subject: 'Nocrastinate',
      );

      if (result.status == ShareResultStatus.success) {
        print('App shared successfully');
      }
    } catch (e) {
      print('Error sharing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToFeedback() {
    Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => AppGuideScreen())
    );
  }

  Future<void> _openInstagram() async {
    const String username = '';

    final Uri instagramAppUrl = Uri.parse('instagram://user?username=$username');
    final Uri instagramWebUrl = Uri.parse('https://www.instagram.com/$username');

    try {
      if (await canLaunchUrl(instagramAppUrl)) {
        await launchUrl(instagramAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(instagramWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening Instagram: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Instagram'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTikTok() async {
    const String username = '';

    final Uri tiktokAppUrl = Uri.parse('snssdk1233://user/profile/$username');
    final Uri tiktokWebUrl = Uri.parse('https://www.tiktok.com/@$username');

    try {
      if (await canLaunchUrl(tiktokAppUrl)) {
        await launchUrl(tiktokAppUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(tiktokWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening TikTok: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open TikTok'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTermsOfService() async {
    const String termsUrl = 'https://nocrastinate.com/terms';
    await _launchUrl(termsUrl);
  }

  // Safe SVG widget with fallback
  Widget _buildSvgIcon(String assetPath, {Color? color, double? height}) {
    return SvgPicture.asset(
      assetPath,
      fit: BoxFit.contain,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color, BlendMode.srcIn)
          : null,
      placeholderBuilder: (context) => Icon(
        Icons.image_not_supported,
        color: color ?? context.primaryTextColor,
        size: height ?? 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final userName = authProvider.userDisplayName.isNotEmpty
                ? authProvider.userDisplayName
                : 'User'.tr();

            return Scaffold(
              backgroundColor: context.blackSectionColor,
              appBar: AppBar(
                backgroundColor: context.blackSectionColor,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    child: _buildSvgIcon('assets/svg/BackBlack.svg'),
                  ),
                ),
                centerTitle: true,
                title: Text(
                  'Settings'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              body: Column(
                children: [
                  const SizedBox(height: 20),
                  // Top content
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        userName,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Align(
                    alignment: Alignment.center,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(text: 'Member since'.tr() + ' '),
                          TextSpan(
                            text: authProvider.getMemberDuration(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // White container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? context.cardBackgroundColor : context.backgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Scrollable content area
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                                child: Column(
                                  children: [
                                    SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        "Preferences".tr(),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16),

                                    // Notifications button
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) => NotificationDetailScreen())
                                        );
                                      },
                                      child: ThemedContainer(
                                        height: 55,
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(horizontal: 20),
                                        child: Row(
                                          children: [
                                            _buildSvgIcon(
                                              context.isDarkMode ? 'assets/svg/noti_dark.svg' : 'assets/svg/notification.svg',
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Notifications'.tr(),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: context.primaryTextColor,
                                              ),
                                            ),
                                            Spacer(),
                                            Switch(
                                              value: _notificationsEnabled,
                                              onChanged: (value) {
                                                setState(() {
                                                  _notificationsEnabled = value;
                                                });
                                              },
                                              activeColor: Color(0xFF1D79ED),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),

                                    // Dark Mode button
                                    ThemedContainer(
                                      height: 55,
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        children: [
                                          _buildSvgIcon(
                                            'assets/svg/Dark Mode.svg',
                                            color: context.primaryTextColor,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Dark Mode'.tr(),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: context.primaryTextColor,
                                            ),
                                          ),
                                          Spacer(),
                                          Switch(
                                            value: themeManager.isDarkMode,
                                            onChanged: (value) {
                                              themeManager.toggleTheme();
                                            },
                                            activeColor: Color(0xFF1D79ED),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),


                                    // App Language button
                                    GestureDetector(
                                      onTap: () => showLanguageScreen(context),
                                      child: ThemedContainer(
                                        height: 55,
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(horizontal: 20),
                                        child: Row(
                                          children: [
                                            _buildSvgIcon(
                                              'assets/svg/App Language.svg',
                                              color: context.primaryTextColor,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'App Language'.tr(),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: context.primaryTextColor,
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(
                                              Icons.chevron_right,
                                              color: context.primaryTextColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),

                                    // Logout button
                                    GestureDetector(
                                      onTap: _isLoggingOut ? null : _showLogoutDialog,
                                      child: Opacity(
                                        opacity: _isLoggingOut ? 0.5 : 1.0,
                                        child: ThemedContainer(
                                          height: 55,
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(horizontal: 20),
                                          child: Row(
                                            children: [
                                              _isLoggingOut
                                                  ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1D79ED)),
                                                ),
                                              )
                                                  : Icon(
                                                Icons.logout,
                                                color: Color(0xFF1D79ED),
                                                size: 24,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                _isLoggingOut ? 'Logging out...'.tr() : 'Logout'.tr(),
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF1D79ED),
                                                ),
                                              ),
                                              Spacer(),
                                              if (!_isLoggingOut)
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: Color(0xFF1D79ED),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),

                                    // Delete Your Data button
                                    GestureDetector(
                                      onTap: _isDeleting ? null : _showDeleteDataDialog,
                                      child: Opacity(
                                        opacity: _isDeleting ? 0.5 : 1.0,
                                        child: ThemedContainer(
                                          height: 55,
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(horizontal: 20),
                                          child: Row(
                                            children: [
                                              _isDeleting
                                                  ? SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4B4B)),
                                                ),
                                              )
                                                  : _buildSvgIcon(
                                                'assets/svg/Delete Your Data.svg',
                                                color: Color(0xFFFF4B4B),
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                _isDeleting ? 'Deleting...'.tr() : 'Delete Your Data'.tr(),
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFFFF4B4B),
                                                ),
                                              ),
                                              Spacer(),
                                              if (!_isDeleting)
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: Color(0xFFFF4B4B),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),

                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        "Community".tr(),
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),

                                    // Share App button
                                    GestureDetector(
                                      onTap: _shareApp,
                                      child: ThemedContainer(
                                        height: 55,
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(horizontal: 20),
                                        child: Row(
                                          children: [
                                            _buildSvgIcon(
                                              'assets/svg/Share App with friends.svg',
                                              color: context.primaryTextColor,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Share App with friends'.tr(),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: context.primaryTextColor,
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(
                                              Icons.chevron_right,
                                              color: context.primaryTextColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10),

                                    // App Guide & Feedback button
                                    GestureDetector(
                                      onTap: _navigateToFeedback,
                                      child: ThemedContainer(
                                        height: 55,
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(horizontal: 20),
                                        child: Row(
                                          children: [
                                            _buildSvgIcon(
                                              'assets/svg/App Guide & Feedback.svg',
                                              color: context.primaryTextColor,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'App Guide & Feedback'.tr(),
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: context.primaryTextColor,
                                              ),
                                            ),
                                            Spacer(),
                                            Icon(
                                              Icons.chevron_right,
                                              color: context.primaryTextColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: _openInstagram,
                                          child: Container(
                                            child: Row(
                                              children: [
                                                _buildSvgIcon(
                                                  'assets/svg/instagram.svg',
                                                  color: context.primaryTextColor,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Instagram',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: context.primaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Text(
                                          '|',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: context.primaryTextColor,
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        GestureDetector(
                                          onTap: _openTikTok,
                                          child: Container(
                                            child: Row(
                                              children: [
                                                _buildSvgIcon(
                                                  'assets/svg/tiktok.svg',
                                                  color: context.primaryTextColor,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'TikTok',
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: context.primaryTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),

                                    // Footer text
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Made with'.tr() + ' ',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: context.primaryTextColor,
                                              ),
                                            ),
                                            _buildSvgIcon(
                                              context.isDarkMode
                                                  ? 'assets/svg/whiteHeart.svg'
                                                  : 'assets/svg/blackHeart.svg',
                                              height: 12,
                                            ),
                                            Text(
                                              ' by the Nocrastinate Team ©️2025.',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: context.primaryTextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),
                                        GestureDetector(
                                          onTap: _openTermsOfService,
                                          child: Text(
                                            'Terms of Service'.tr(),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: context.primaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Fixed bottom buttons
                          Container(
                            padding: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.of(context).padding.bottom + 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 15),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}