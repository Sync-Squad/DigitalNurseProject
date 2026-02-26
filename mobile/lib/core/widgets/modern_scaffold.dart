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
    final topPadding = MediaQuery.of(context).padding.top;
    final appBarHeight = appBar != null
        ? appBar!.preferredSize.height + topPadding
        : 0.0;

    final scaffold = Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/cardbackground1.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: body),
      ),
    );

    if (appBar == null) return scaffold;

    // Stack: teal block behind the appbar, then the scaffold on top.
    // Because the scaffold has extendBodyBehindAppBar = true and
    // the AppBar is transparent, the teal block shows through the AppBar.
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: appBarHeight,
          child: ColoredBox(color: _kTeal),
        ),
        scaffold,
      ],
    );
  }
}
