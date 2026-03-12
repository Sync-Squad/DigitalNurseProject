import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/modern_surface_theme.dart';

class AIChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isLoading;
  final bool hasError;
  final List<dynamic>? sources;

  const AIChatBubble({
    super.key,
    required this.message,
    this.isUser = false,
    this.isLoading = false,
    this.hasError = false,
    this.sources,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              decoration: ModernSurfaceTheme.iconBadge(
                context,
                Theme.of(context).colorScheme.primary,
              ),
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.smart_toy_rounded, size: 18.w, color: Colors.white),
            ),
            SizedBox(width: 10.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: isUser
                  ? BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(4.r),
                        bottomLeft: Radius.circular(20.r),
                        bottomRight: Radius.circular(20.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    )
                  : ModernSurfaceTheme.glassCard(context).copyWith(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4.r),
                        topRight: Radius.circular(20.r),
                        bottomLeft: Radius.circular(20.r),
                        bottomRight: Radius.circular(20.r),
                      ),
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUser ? Colors.white : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.4,
                        color: isUser
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  if (sources != null && sources!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: isUser
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sources:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUser
                            ? Colors.white.withOpacity(0.9)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...sources!
                        .take(3)
                        .map(
                          (source) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${source['text'] ?? 'Source'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isUser
                                    ? Colors.white.withOpacity(0.8)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 10.w),
            Container(
              decoration: ModernSurfaceTheme.iconBadge(
                context,
                Theme.of(context).colorScheme.secondary,
              ),
              padding: EdgeInsets.all(8.w),
              child: Icon(Icons.person_rounded, size: 18.w, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
