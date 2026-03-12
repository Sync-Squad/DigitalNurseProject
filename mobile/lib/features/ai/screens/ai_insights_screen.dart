import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/ai_features_navigation.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final AIService _aiService = AIService();
  List<dynamic> _insights = [];
  bool _isLoading = true;
  String? _selectedType;
  String? _selectedPriority;
  bool? _showRead;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    try {
      final careContext = context.read<CareContextProvider>();
      await careContext.ensureLoaded();

      final elderUserId = careContext.selectedElderId != null
          ? int.tryParse(careContext.selectedElderId!)
          : null;

      final insights = await _aiService.getInsights(
        types: _selectedType != null ? [_selectedType!] : null,
        priorities: _selectedPriority != null ? [_selectedPriority!] : null,
        isRead: _showRead,
        elderUserId: elderUserId,
      );

      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.getErrorColor(context),
            content: Text(
              'ai.errors.loadFailed'.tr(namedArgs: {'error': e.toString()}),
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkBackground
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: Text(
          'ai.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.filter_list_rounded,
                color: Colors.white,
                size: 22.w,
              ),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40.w,
                    height: 40.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ModernSurfaceTheme.primaryTeal,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'ai.analyzing'.tr(),
                    style: TextStyle(
                      color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.6),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadInsights,
              color: ModernSurfaceTheme.primaryTeal,
              child: CustomScrollView(
                slivers: [
                  // Active filters bar
                  if (_selectedType != null || _selectedPriority != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                        child: _buildActiveFilters(),
                      ),
                    ),

                  // AI Features navigation
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                      child: const AIFeaturesNavigation(),
                    ),
                  ),

                  // Insights header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
                      child: Row(
                        children: [
                          Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: ModernSurfaceTheme.iconBadge(
                              context,
                              ModernSurfaceTheme.primaryTeal,
                            ),
                            child: Icon(
                              Icons.insights_rounded,
                              color: Colors.white,
                              size: 18.w,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ai.yourInsights'.tr(),
                                  style: TextStyle(
                                    color: ModernSurfaceTheme.deepTeal,
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'ai.insightsAvailable'.tr(namedArgs: {
                                    'count': _insights.length.toString()
                                  }),
                                  style: TextStyle(
                                    color: ModernSurfaceTheme.deepTeal
                                        .withValues(alpha: 0.55),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Insights list or empty state
                  if (_insights.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final insight = _insights[index];
                          return AIInsightCard(
                            id: insight['id']?.toString() ?? '',
                            title: insight['title'] ?? 'Insight',
                            content: insight['content'] ?? '',
                            priority: insight['priority'] ?? 'medium',
                            category: insight['category'],
                            confidence: insight['confidence']?.toDouble(),
                            recommendations: insight['recommendations'],
                            isRead: insight['isRead'] ?? false,
                            generatedAt: insight['generatedAt'] != null
                                ? DateTime.parse(insight['generatedAt'])
                                : DateTime.now(),
                            onTap: () => _showInsightDetails(insight),
                            onMarkRead: insight['isRead'] == false
                                ? () => _markAsRead(insight['id'])
                                : null,
                            onArchive: () => _archiveInsight(insight['id']),
                          );
                        }, childCount: _insights.length),
                      ),
                    ),

                  // Bottom padding
                  SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: ModernSurfaceTheme.glassCard(
        context,
        accent: ModernSurfaceTheme.accentYellow,
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_rounded,
            size: 18.w,
            color: ModernSurfaceTheme.accentYellow,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Wrap(
              spacing: 8.w,
              children: [
                if (_selectedType != null)
                  _FilterTag(
                    label: _selectedType!,
                    onRemove: () {
                      setState(() => _selectedType = null);
                      _loadInsights();
                    },
                  ),
                if (_selectedPriority != null)
                  _FilterTag(
                    label: _selectedPriority!,
                    onRemove: () {
                      setState(() => _selectedPriority = null);
                      _loadInsights();
                    },
                  ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _selectedType = null;
                _selectedPriority = null;
                _showRead = null;
              });
              _loadInsights();
            },
            child: Text(
              'ai.clearAll'.tr(),
              style: TextStyle(
                color: ModernSurfaceTheme.primaryTeal,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: ModernSurfaceTheme.iconBadge(
                context,
                ModernSurfaceTheme.primaryTeal.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.insights_rounded,
                size: 40.w,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'ai.noInsightsYet'.tr(),
              style: TextStyle(
                color: ModernSurfaceTheme.deepTeal,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'ai.noInsightsDescription'.tr(),
              style: TextStyle(
                color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.55),
                fontSize: 14.sp,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        String? tempType = _selectedType;
        String? tempPriority = _selectedPriority;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      margin: EdgeInsets.only(bottom: 20.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'ai.filterInsights'.tr(),
                    style: TextStyle(
                      color: ModernSurfaceTheme.deepTeal,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'ai.type'.tr(),
                    style: TextStyle(
                      color: ModernSurfaceTheme.deepTeal,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _FilterOption(
                        label: 'ai.filterOptions.all'.tr(),
                        isSelected: tempType == null,
                        onTap: () => setSheetState(() => tempType = null),
                      ),
                      _FilterOption(
                        label: 'ai.filterOptions.medication'.tr(),
                        isSelected: tempType == 'medication_adherence',
                        onTap: () => setSheetState(
                          () => tempType = 'medication_adherence',
                        ),
                      ),
                      _FilterOption(
                        label: 'ai.filterOptions.healthTrend'.tr(),
                        isSelected: tempType == 'health_trend',
                        onTap: () =>
                            setSheetState(() => tempType = 'health_trend'),
                      ),
                      _FilterOption(
                        label: 'ai.filterOptions.recommendation'.tr(),
                        isSelected: tempType == 'recommendation',
                        onTap: () =>
                            setSheetState(() => tempType = 'recommendation'),
                      ),
                      _FilterOption(
                        label: 'ai.filterOptions.alert'.tr(),
                        isSelected: tempType == 'alert',
                        onTap: () => setSheetState(() => tempType = 'alert'),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'ai.priorityLabel'.tr(),
                    style: TextStyle(
                      color: ModernSurfaceTheme.deepTeal,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      _FilterOption(
                        label: 'ai.filterOptions.all'.tr(),
                        isSelected: tempPriority == null,
                        onTap: () => setSheetState(() => tempPriority = null),
                      ),
                      _FilterOption(
                        label: 'ai.priority.critical'.tr(),
                        isSelected: tempPriority == 'critical',
                        onTap: () =>
                            setSheetState(() => tempPriority = 'critical'),
                        color: const Color(0xFFFF6B6B),
                      ),
                      _FilterOption(
                        label: 'ai.priority.high'.tr(),
                        isSelected: tempPriority == 'high',
                        onTap: () => setSheetState(() => tempPriority = 'high'),
                        color: const Color(0xFFFF9F43),
                      ),
                      _FilterOption(
                        label: 'ai.priority.medium'.tr(),
                        isSelected: tempPriority == 'medium',
                        onTap: () =>
                            setSheetState(() => tempPriority = 'medium'),
                        color: ModernSurfaceTheme.accentBlue,
                      ),
                      _FilterOption(
                        label: 'ai.priority.low'.tr(),
                        isSelected: tempPriority == 'low',
                        onTap: () => setSheetState(() => tempPriority = 'low'),
                        color: ModernSurfaceTheme.primaryTeal,
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = null;
                              _selectedPriority = null;
                              _showRead = null;
                            });
                            Navigator.pop(ctx);
                            _loadInsights();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ModernSurfaceTheme.deepTeal,
                            side: BorderSide(
                              color: ModernSurfaceTheme.deepTeal.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                          ),
                          child: Text('ai.clear'.tr()),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Container(
                          decoration: ModernSurfaceTheme.pillButton(
                            context,
                            ModernSurfaceTheme.primaryTeal,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                setState(() {
                                  _selectedType = tempType;
                                  _selectedPriority = tempPriority;
                                });
                                Navigator.pop(ctx);
                                _loadInsights();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                alignment: Alignment.center,
                                child: Text(
                                  'ai.apply'.tr(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showInsightDetails(Map<String, dynamic> insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  insight['title'] ?? 'ai.defaultInsightTitle'.tr(),
                  style: TextStyle(
                    color: ModernSurfaceTheme.deepTeal,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (insight['category'] != null) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: ModernSurfaceTheme.primaryTeal.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      insight['category'],
                      style: TextStyle(
                        color: ModernSurfaceTheme.primaryTeal,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
                Text(
                  insight['content'] ?? '',
                  style: TextStyle(
                    color: ModernSurfaceTheme.deepTeal.withValues(alpha: 0.85),
                    fontSize: 15.sp,
                    height: 1.6,
                  ),
                ),
                if (insight['recommendations'] != null) ...[
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: ModernSurfaceTheme.primaryTeal.withValues(
                        alpha: 0.06,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ModernSurfaceTheme.primaryTeal.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              size: 20.w,
                              color: ModernSurfaceTheme.accentYellow,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'ai.recommendations'.tr(),
                              style: TextStyle(
                                color: ModernSurfaceTheme.deepTeal,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ...(insight['recommendations'] as List).map(
                          (rec) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '•  ',
                                  style: TextStyle(
                                    color: ModernSurfaceTheme.primaryTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    rec.toString(),
                                    style: TextStyle(
                                      color: ModernSurfaceTheme.deepTeal
                                          .withValues(alpha: 0.8),
                                      fontSize: 14.sp,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(dynamic insightId) async {
    try {
      await _aiService.markInsightAsRead(int.parse(insightId.toString()));
      _loadInsights();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ai.errors.markReadFailed'.tr(namedArgs: {'error': e.toString()}))));
      }
    }
  }

  Future<void> _archiveInsight(dynamic insightId) async {
    try {
      await _aiService.archiveInsight(int.parse(insightId.toString()));
      _loadInsights();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ai.errors.archiveFailed'.tr(namedArgs: {'error': e.toString()}))));
      }
    }
  }
}

class _FilterTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ModernSurfaceTheme.primaryTeal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ModernSurfaceTheme.primaryTeal.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: ModernSurfaceTheme.primaryTeal,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4.w),
          InkWell(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14.w,
              color: ModernSurfaceTheme.primaryTeal,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? ModernSurfaceTheme.primaryTeal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? resolvedColor.withValues(alpha: 0.15)
              : ModernSurfaceTheme.deepTeal.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? resolvedColor.withValues(alpha: 0.4)
                : ModernSurfaceTheme.deepTeal.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? resolvedColor : ModernSurfaceTheme.deepTeal,
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
