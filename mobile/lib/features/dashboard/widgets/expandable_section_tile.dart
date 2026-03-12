import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

enum InteractionMode { standard, hybrid }

class ExpandableSectionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String count;
  final Color titleColor;
  final VoidCallback? onViewDetails;
  final Widget? expandedChild;
  final String? routeForViewDetails;
  final InteractionMode interactionMode;

  const ExpandableSectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.titleColor,
    this.onViewDetails,
    this.expandedChild,
    this.routeForViewDetails,
    this.interactionMode = InteractionMode.standard,
  });

  @override
  State<ExpandableSectionTile> createState() => _ExpandableSectionTileState();
}

class _ExpandableSectionTileState extends State<ExpandableSectionTile>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleViewDetails() {
    if (widget.routeForViewDetails != null) {
      context.push(widget.routeForViewDetails!);
    } else if (widget.onViewDetails != null) {
      widget.onViewDetails!();
    }
  }

  Widget _buildHeader(BuildContext context) {
    if (widget.interactionMode == InteractionMode.hybrid) {
      return _buildHybridHeader(context);
    } else {
      return _buildStandardHeader(context);
    }
  }

  Widget _buildStandardHeader(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: context.theme.colors.foreground,
                size: 28,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: widget.titleColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildViewDetailsButton(context),
                  ],
                ),
              ),
              _buildCountBadge(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHybridHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          // Left side - expandable area
          Expanded(
            flex: 3,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        widget.icon,
                        color: context.theme.colors.foreground,
                        size: 28,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: widget.titleColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.theme.colors.mutedForeground,
                                    fontSize: 14,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right side - navigation area
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleViewDetails,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 12.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.theme.colors.mutedForeground,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: context.theme.colors.mutedForeground,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    _buildCountBadge(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewDetailsButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleViewDetails,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.theme.colors.mutedForeground,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                color: context.theme.colors.mutedForeground,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.theme.colors.foreground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.count,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.colors.muted,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Subtle shadow
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          if (widget.expandedChild != null)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: context.theme.colors.border,
                      width: 1,
                    ),
                  ),
                ),
                child: widget.expandedChild,
              ),
            ),
        ],
      ),
    );
  }
}
