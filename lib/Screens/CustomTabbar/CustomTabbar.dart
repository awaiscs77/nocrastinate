import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart' hide Trans, ContextExtensionss;
import 'package:get/get_core/src/get_main.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Focus/FocusScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/InSight/InsightScreen.dart';
import 'package:nocrastinate/Screens/CustomTabbar/Quote/QuotesScreen.dart';
import 'package:easy_localization/easy_localization.dart';

import 'Home/HomeScreen.dart';

class CustomTabbarView extends StatefulWidget {
  final int initialIndex;

  const CustomTabbarView({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _CustomTabbarViewState createState() => _CustomTabbarViewState();
}

class _CustomTabbarViewState extends State<CustomTabbarView> {
  late int _selectedIndex;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();

    // Set initial index from widget or Get arguments
    _selectedIndex = widget.initialIndex;

    // Check if index was passed from Get arguments
    final args = Get.arguments;
    print('CustomTabbarView initState - Arguments received: $args');

    if (args != null && args is Map && args.containsKey('selectedIndex')) {
      _selectedIndex = args['selectedIndex'] as int;
    }

    // Initialize all 4 pages
    _pages = [
      HomeScreen(),
      FocusScreen(),
      InsightScreen(),
      QuotesScreen(),
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: AnimatedBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          TabBarItem(
            icon: SvgPicture.asset("assets/svg/Home.svg"),
            selectedIcon: SvgPicture.asset("assets/svg/HomeSelected.svg"),
            label: 'Home'.tr(),
          ),
          TabBarItem(
            icon: SvgPicture.asset("assets/svg/Brain.svg"),
            selectedIcon: SvgPicture.asset("assets/svg/BrainSelected.svg"),
            label: 'Focus'.tr(),
          ),
          TabBarItem(
            icon: SvgPicture.asset("assets/svg/insightSelected.svg"),
            selectedIcon: SvgPicture.asset("assets/svg/chartSelected.svg"),
            label: 'Insights'.tr(),
          ),
          TabBarItem(
            icon: SvgPicture.asset("assets/svg/quote-up.svg"),
            selectedIcon: SvgPicture.asset("assets/svg/quoteSelected.svg"),
            label: 'Quotes'.tr(),
          ),
        ],
      ),
    );
  }
}

class AnimatedBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<TabBarItem> items;

  AnimatedBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  _AnimatedBottomNavigationBarState createState() =>
      _AnimatedBottomNavigationBarState();
}

class _AnimatedBottomNavigationBarState
    extends State<AnimatedBottomNavigationBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late double _width = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _animateSelection();
    }
  }

  void _animateSelection() {
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF303030) : Colors.white;
    final selectedColor = isDarkMode ? Colors.white : Color(0xFF1F1F1F);
    final unselectedColor = isDarkMode
        ? Colors.white.withOpacity(0.60)
        : Color(0xFF1F1F1F).withOpacity(0.60);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(16.0),
        topRight: Radius.circular(16.0),
      ),
      child: Stack(
        children: [
          BottomNavigationBar(
            currentIndex: widget.currentIndex,
            onTap: widget.onTap,
            backgroundColor: backgroundColor,
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            selectedFontSize: 14.0,
            unselectedFontSize: 12.0,
            type: BottomNavigationBarType.fixed,
            items: widget.items.map((item) {
              int index = widget.items.indexOf(item);
              bool isSelected = index == widget.currentIndex;
              return BottomNavigationBarItem(
                icon: _buildThemedIcon(item.icon, isSelected, isDarkMode),
                activeIcon: _buildThemedIcon(item.selectedIcon, true, isDarkMode),
                label: item.label,
              );
            }).toList(),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                color: (isDarkMode ? Colors.black : Colors.white).withOpacity(0.3),
                height: kBottomNavigationBarHeight,
                width: _width,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemedIcon(SvgPicture svgIcon, bool isSelected, bool isDarkMode) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected
            ? (isDarkMode ? Colors.white : Color(0xFF1F1F1F))
            : (isDarkMode ? Colors.white.withOpacity(0.60) : Color(0xFF1F1F1F).withOpacity(0.60)),
        BlendMode.srcIn,
      ),
      child: svgIcon,
    );
  }
}

class TabBarItem {
  final SvgPicture icon;
  final SvgPicture selectedIcon;
  final String label;

  TabBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}