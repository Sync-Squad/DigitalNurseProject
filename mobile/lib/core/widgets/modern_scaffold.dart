import 'package:flutter/material.dart';

const _kTeal = Color(0xFF008080);

/// Provides an image-backed scaffold used by all feature screens.
///
/// A teal [_kTeal] layer is placed behind the AppBar area inside a [Stack],
/// so transparent AppBars (set by individual screens) still appear teal
/// without touching any screen file.
class ModernScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final bool extendBodyBehindAppBar;
  final bool safeAreaBottom;
  final bool safeAreaTop;

  const ModernScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
    this.safeAreaBottom = true,
    this.safeAreaTop = true,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final appBarHeight = appBar != null
        ? appBar!.preferredSize.height + topPadding
        : topPadding; // Always cover status bar if it exists

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: body),
    );

    return Stack(
      children: [
        // 1. Permanent background covering the whole screen
        Positioned.fill(
          child: Image.asset(
            'assets/images/cardbackground1.jpeg',
            fit: BoxFit.cover,
          ),
        ),
        // 2. Teal block behind the status bar and app bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: appBarHeight > 0 ? appBarHeight : topPadding,
          child: const ColoredBox(color: _kTeal),
        ),
        // 3. The actual content on top
        Positioned.fill(child: scaffold),
      ],
    );
  }
}
