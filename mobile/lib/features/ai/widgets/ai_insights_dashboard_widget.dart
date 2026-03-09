import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../dashboard/widgets/patient/expandable_patient_card.dart';
import 'ai_insight_card.dart';

class AIInsightsDashboardWidget extends StatefulWidget {
  final int? elderUserId;
  final int limit;

  const AIInsightsDashboardWidget({
    super.key,
    this.elderUserId,
    this.limit = 3,
  });

  @override
  State<AIInsightsDashboardWidget> createState() =>
      _AIInsightsDashboardWidgetState();
}

class _AIInsightsDashboardWidgetState extends State<AIInsightsDashboardWidget> {
  final AIService _aiService = AIService();
  List<dynamic> _insights = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get elderUserId from care context if not provided
      int? elderUserId = widget.elderUserId;
      if (elderUserId == null && mounted) {
        final careContext = context.read<CareContextProvider>();
        await careContext.ensureLoaded();
        if (careContext.selectedElderId != null) {
          elderUserId = int.tryParse(careContext.selectedElderId!);
        }
      }

      final insights = await _aiService.getInsights(
        elderUserId: elderUserId,
        limit: widget.limit,
        isRead: false,
      );

      if (mounted) {
        setState(() {
          _insights = insights;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _generateInsights() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get elderUserId from care context if not provided
      int? elderUserId = widget.elderUserId;
      if (elderUserId == null && mounted) {
        final careContext = context.read<CareContextProvider>();
        await careContext.ensureLoaded();
        if (careContext.selectedElderId != null) {
          elderUserId = int.tryParse(careContext.selectedElderId!);
        }
      }

      if (elderUserId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'No elder user selected';
          });
        }
        return;
      }

      // Generate insights for the user
      await _aiService.generateInsightsForUser(elderUserId: elderUserId);

      // Reload insights after generation
      await _loadInsights();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpandablePatientCard(
      icon: Icons.auto_awesome_outlined,
      title: 'ai.title'.tr(),
      subtitle: _insights.isEmpty
          ? 'ai.subtitleEmpty'.tr()
          : 'ai.subtitle'.tr(),
      count: '${_insights.length}',
      accentColor: ModernSurfaceTheme.primaryTeal,
      routeForViewDetails: '/ai/insights',
      expandedChild: _buildExpandedContent(),
    );
  }

  Widget _buildExpandedContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'ai.failedToLoad'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadInsights,
              child: Text('ai.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_insights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(
              Icons.insights_outlined,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'ai.noInsightsYet'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'ai.noInsightsDescription'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _generateInsights,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: Text('ai.generateInsights'.tr()),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.appleGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: _insights
          .take(widget.limit)
          .map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AIInsightCard(
                id: insight['id']?.toString() ?? '',
                title: insight['title'] ?? 'ai.defaultInsightTitle'.tr(),
                content: insight['content'] ?? '',
                priority: insight['priority'] ?? 'medium',
                category: insight['category'],
                isRead: insight['isRead'] ?? false,
                generatedAt: insight['generatedAt'] != null
                    ? DateTime.parse(insight['generatedAt'])
                    : DateTime.now(),
                onTap: () => context.push('/ai/insights'),
              ),
            ),
          )
          .toList(),
    );
  }
}
