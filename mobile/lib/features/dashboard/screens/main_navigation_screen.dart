import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'home_dashboard_screen.dart';
import '../../medication/screens/medicine_list_screen.dart';
import '../../health/screens/vitals_list_screen.dart';
import '../../documents/screens/document_list_screen.dart';
import '../../profile/screens/profile_view_screen.dart';
import 'dart:io';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild when locale changes by creating a dependency on the locale
    // ignore: unused_local_variable
    final currentLocale = context.locale;

    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.currentUser?.role ?? UserRole.patient;
    final isCaregiver = userRole == UserRole.caregiver;

    // Rebuild navigation entries when locale changes
    final navigationEntries = _buildNavigationEntries(context, isCaregiver);
    final maxIndex = navigationEntries.length - 1;

    if (_currentIndex > maxIndex && maxIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = maxIndex;
        });
      });
    }

    return PopScope(
      canPop: false, // Always intercept back button
      onPopInvoked: (didPop) async {
        if (!didPop) {
          if (_currentIndex == 0) {
            // Show exit confirmation dialog when on Home tab
            final shouldExit = await _showExitDialog(context);
            if (shouldExit == true) {
              exit(0); // Exit the app
            }
          } else {
            // Navigate back to Home tab from other tabs
            setState(() {
              _currentIndex = 0;
            });
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false, // Let the bottom nav bar handle its own safe area
          child: IndexedStack(
            index: _currentIndex,
            children: navigationEntries.map((entry) => entry.page).toList(),
          ),
        ),
        // Bottom navigation commented out for caregivers
        // bottomNavigationBar: SafeArea(
        //   child: FBottomNavigationBar(
        //     index: _currentIndex,
        //     onChange: (index) {
        //       setState(() {
        //         _currentIndex = index;
        //       });
        //     },
        //     children: [
        //       for (final entry in navigationEntries) entry.navigationItem,
        //     ],
        //   ),
        // ),
        bottomNavigationBar: isCaregiver
            ? null
            : SafeArea(
                child: FBottomNavigationBar(
                  index: _currentIndex,
                  onChange: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    for (final entry in navigationEntries) entry.navigationItem,
                  ],
                ),
              ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('common.exitApp'.tr()),
          content: Text('common.exitConfirm'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('common.exit'.tr()),
            ),
          ],
        );
      },
    );
  }
}

class _NavigationEntry {
  final Widget page;
  final FBottomNavigationBarItem navigationItem;
  final bool hideForCaregiver;

  const _NavigationEntry({
    required this.page,
    required this.navigationItem,
    this.hideForCaregiver = false,
  });
}

List<_NavigationEntry> _buildNavigationEntries(
  BuildContext context,
  bool isCaregiver,
) {
  final entries = <_NavigationEntry>[
    _NavigationEntry(
      page: const HomeDashboardScreen(),
      navigationItem: FBottomNavigationBarItem(
        icon: const Icon(FIcons.house),
        label: Text('navigation.home'.tr()),
      ),
    ),
    _NavigationEntry(
      page: const MedicineListScreen(),
      navigationItem: FBottomNavigationBarItem(
        icon: const Icon(FIcons.pill),
        label: Text('navigation.medicines'.tr()),
      ),
    ),
    _NavigationEntry(
      page: const VitalsListScreen(),
      navigationItem: FBottomNavigationBarItem(
        icon: const Icon(FIcons.activity),
        label: Text('navigation.health'.tr()),
      ),
    ),
    _NavigationEntry(
      page: const DocumentListScreen(),
      navigationItem: FBottomNavigationBarItem(
        icon: const Icon(FIcons.fileText),
        label: Text('navigation.documents'.tr()),
      ),
    ),
    _NavigationEntry(
      page: const ProfileViewScreen(),
      navigationItem: FBottomNavigationBarItem(
        icon: const Icon(FIcons.user),
        label: Text('navigation.profile'.tr()),
      ),
      hideForCaregiver: false,
    ),
  ];

  return entries
      .where((entry) {
        if (isCaregiver && entry.hideForCaregiver) {
          return false;
        }
        return true;
      })
      .toList(growable: false);
}
