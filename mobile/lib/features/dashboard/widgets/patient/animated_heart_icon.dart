import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedHeartIcon extends StatefulWidget {
  final double percentage;
  final double size;
  final Color fillColor;
  final Color strokeColor;

  const AnimatedHeartIcon({
    super.key,
    required this.percentage,
    this.size = 60.0,
    this.fillColor = Colors.white,
    this.strokeColor = Colors.blue,
  });

  @override
  State<AnimatedHeartIcon> createState() => _AnimatedHeartIconState();
}

class _AnimatedHeartIconState extends State<AnimatedHeartIcon>
    with TickerProviderStateMixin {
  AnimationController? _fillController;
  AnimationController? _pulseController;
  Animation<double>? _fillAnimation;
  Animation<double>? _pulseAnimation;
  Animation<double>? _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Fill animation controller
    _fillController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fillAnimation = Tween<double>(begin: 0.0, end: widget.percentage / 100.0)
        .animate(
          CurvedAnimation(parent: _fillController!, curve: Curves.easeInOut),
        );
    _fillController!.forward();

    // Pulse animation controller (continuous loop)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.3).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _pulseController!.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AnimatedHeartIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage &&
        _fillController != null &&
        _fillAnimation != null) {
      _fillAnimation =
          Tween<double>(
            begin: _fillAnimation!.value,
            end: widget.percentage / 100.0,
          ).animate(
            CurvedAnimation(parent: _fillController!, curve: Curves.easeInOut),
          );
      _fillController!.reset();
      _fillController!.forward();
    }
  }

  @override
  void dispose() {
    _fillController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heartPath = _createHeartPath(widget.size);

    // Return empty container if animations aren't initialized yet
    if (_pulseAnimation == null ||
        _glowAnimation == null ||
        _fillAnimation == null) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _pulseAnimation!,
        // animation: Listenable.merge([_pulseAnimation!, _glowAnimation!]),
        builder: (context, child) {
          final pulseValue = _pulseAnimation!.value;
          // final glowValue = _glowAnimation!.value;

          return Container(
            // decoration: BoxDecoration(
            //   shape: BoxShape.circle,
            //   boxShadow: [
            //     BoxShadow(
            //       color: widget.fillColor.withOpacity(glowValue),
            //       blurRadius: 6 * pulseValue,
            //       spreadRadius: 1 * pulseValue,
            //     ),
            //     BoxShadow(
            //       color: widget.fillColor.withOpacity(glowValue * 0.5),
            //       blurRadius: 10 * pulseValue,
            //       spreadRadius: 0.5 * pulseValue,
            //     ),
            //   ],
            // ),
            child: Transform.scale(
              scale: pulseValue,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Heart shape fill with percentage-based animation
                  AnimatedBuilder(
                    animation: _fillAnimation!,
                    builder: (context, child) {
                      return ClipPath(
                        clipper: _HeartFillClipper(
                          heartPath: heartPath,
                          fillPercentage: _fillAnimation!.value,
                        ),
                        child: CustomPaint(
                          size: Size(widget.size, widget.size),
                          painter: _HeartFillPainter(
                            path: heartPath,
                            fillColor: widget.fillColor,
                          ),
                        ),
                      );
                    },
                  ),
                  // Animated outline/stroke
                  AnimatedBuilder(
                    animation: _pulseAnimation!,
                    builder: (context, child) {
                      return CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _HeartStrokePainter(
                          path: heartPath,
                          strokeColor: widget.strokeColor,
                          strokeWidth:
                              2.0 +
                              (0.3 * (_pulseAnimation!.value - 1.0) / 0.08),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Path _createHeartPath(double size) {
    // Use a mathematically proven heart path formula for perfect heart shape
    final path = Path();
    final centerX = size / 2;
    final centerY = size / 2;
    final scale = size * 0.40; // Adjusted scale for better centering

    // Heart path based on mathematical heart equation
    // This creates a perfect, recognizable heart shape
    final step = 0.05; // Smaller step for smoother curve

    // First pass: collect points to calculate bounding box
    final points = <Offset>[];
    for (double i = 0; i <= 2 * math.pi; i += step) {
      final x = 16 * scale * math.pow(math.sin(i), 3) / 24;
      final y =
          -scale *
          (13 * math.cos(i) -
              5 * math.cos(2 * i) -
              2 * math.cos(3 * i) -
              math.cos(4 * i)) /
          24;
      points.add(Offset(x, y));
    }

    // Calculate bounding box
    if (points.isEmpty) {
      return path;
    }

    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    // Calculate offsets to center the heart
    final offsetX = centerX - (minX + maxX) / 2;
    final offsetY = centerY - (minY + maxY) / 2;

    // Build path with centered coordinates
    bool isFirstPoint = true;
    for (final point in points) {
      if (isFirstPoint) {
        path.moveTo(offsetX + point.dx, offsetY + point.dy);
        isFirstPoint = false;
      } else {
        path.lineTo(offsetX + point.dx, offsetY + point.dy);
      }
    }

    path.close();
    return path;
  }
}

class _HeartFillPainter extends CustomPainter {
  final Path path;
  final Color fillColor;

  _HeartFillPainter({required this.path, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = path.getBounds();

    // 1. Base Gradient (Dark Red to Light Red)
    // We create a more complex gradient for a 3D "spherical" feel
    final baseGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3), // Light source from top-left
      radius: 0.8,
      colors: [
        const Color(0xFFFF5252), // Light Red (Highlight)
        const Color(0xFFD32F2F), // Medium Red
        const Color(0xFF8B0000), // Dark Red
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final basePaint = Paint()
      ..shader = baseGradient.createShader(bounds)
      ..style = PaintingStyle.fill;

    // Draw base heart
    canvas.drawPath(path, basePaint);

    // 2. Inner Shadow/Glow for Depth
    // We draw a slightly smaller path with a blurred shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    canvas.drawPath(path, shadowPaint);

    // 3. Glossy Highlight (Top-Left)
    // Add a subtle white semi-transparent oval to simulate reflection
    final highlightPath = Path();
    final highlightBounds = Rect.fromLTWH(
      bounds.left + bounds.width * 0.15,
      bounds.top + bounds.height * 0.1,
      bounds.width * 0.35,
      bounds.height * 0.25,
    );
    
    highlightPath.addOval(highlightBounds);

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(highlightBounds)
      ..style = PaintingStyle.fill;

    canvas.drawPath(highlightPath, highlightPaint);
    
    // 4. Subtle Outer Glow
    final outerGlowPaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4.0);
      
    canvas.drawPath(path, outerGlowPaint);
  }

  @override
  bool shouldRepaint(_HeartFillPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor;
  }
}

class _HeartFillClipper extends CustomClipper<Path> {
  final Path heartPath;
  final double fillPercentage;

  _HeartFillClipper({required this.heartPath, required this.fillPercentage});

  @override
  Path getClip(Size size) {
    if (fillPercentage <= 0) {
      return Path();
    }
    if (fillPercentage >= 1.0) {
      return heartPath;
    }

    // Get the bounding box of the heart path
    final bounds = heartPath.getBounds();
    final clipHeight = bounds.height * fillPercentage;
    final clipTop = bounds.bottom - clipHeight;

    // Create a clipping path that intersects the heart path with a rectangle
    // from the bottom up to the fill percentage
    final clipRect = Rect.fromLTWH(
      bounds.left,
      clipTop,
      bounds.width,
      clipHeight,
    );

    final clipPath = Path()..addRect(clipRect);

    // Intersect the heart path with the clip rectangle
    final resultPath = Path.combine(
      PathOperation.intersect,
      heartPath,
      clipPath,
    );

    return resultPath;
  }

  @override
  bool shouldReclip(_HeartFillClipper oldClipper) {
    return oldClipper.heartPath != heartPath ||
        (oldClipper.fillPercentage - fillPercentage).abs() > 0.001;
  }
}

class _HeartStrokePainter extends CustomPainter {
  final Path path;
  final Color strokeColor;
  final double strokeWidth;

  _HeartStrokePainter({
    required this.path,
    required this.strokeColor,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeartStrokePainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
