import 'package:flutter/material.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';
import '../widgets/recommendation_card.dart';

class HealthAnalysisScreen extends StatefulWidget {
  const HealthAnalysisScreen({super.key});

  @override
  State<HealthAnalysisScreen> createState() => _HealthAnalysisScreenState();
}

class _HealthAnalysisScreenState extends State<HealthAnalysisScreen> {
  final AIService _aiService = AIService();
  Map<String, dynamic>? _analysis;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final careContext = context.read<CareContextProvider>();
      await careContext.ensureLoaded();

      final elderUserId = careContext.selectedElderId != null
          ? int.tryParse(careContext.selectedElderId!)
          : null;

      final analysis = await _aiService.analyzeHealth(elderUserId: elderUserId);

      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load analysis: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return ModernScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Health Analysis',
          style: textTheme.titleLarge?.copyWith(
            color: onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: onPrimary),
            onPressed: _loadAnalysis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null
          ? const Center(child: Text('No analysis available'))
          : RefreshIndicator(
              onRefresh: _loadAnalysis,
              child: SingleChildScrollView(
                padding: ModernSurfaceTheme.screenPadding(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication Adherence Section
                    if (_analysis!['medicationAdherence'] != null)
                      _buildMedicationAdherenceSection(
                        _analysis!['medicationAdherence'],
                      ),
                    SizedBox(height: 16.h),
                    // Health Trends Section
                    if (_analysis!['healthTrends'] != null)
                      _buildHealthTrendsSection(_analysis!['healthTrends']),
                    SizedBox(height: 16.h),
                    // Lifestyle Section
                    if (_analysis!['lifestyleCorrelation'] != null)
                      _buildLifestyleSection(
                        _analysis!['lifestyleCorrelation'],
                      ),
                    SizedBox(height: 16.h),
                    // Risk Factors Section
                    if (_analysis!['riskFactors'] != null)
                      _buildRiskFactorsSection(_analysis!['riskFactors']),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMedicationAdherenceSection(Map<String, dynamic> data) {
    final adherence = (data['overallPercentage'] as num?)?.toDouble() ?? 0.0;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medication Adherence',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100.w,
                  height: 100.w,
                  child: CircularProgressIndicator(
                    value: adherence / 100,
                    strokeWidth: 10,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.getSuccessColor(context),
                    ),
                  ),
                ),
                Text(
                  '${adherence.toStringAsFixed(0)}%',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if (data['recommendations'] != null) ...[
            const SizedBox(height: 24),
            ...(data['recommendations'] as List).map(
              (rec) => RecommendationCard(recommendation: rec.toString()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthTrendsSection(Map<String, dynamic> data) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Trends',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (data['vitals'] != null)
            ...(data['vitals'] as List).map(
              (vital) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (vital['type'] ?? '').toString().toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          Text(
                            'Trend: ${vital['trend'] ?? ''}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _getConcernColor(vital['concernLevel']).withOpacity(0.15),
                      ),
                      child: Text(
                        (vital['concernLevel'] ?? 'low').toString().toUpperCase(),
                        style: TextStyle(
                          color: _getConcernColor(vital['concernLevel']),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (data['recommendations'] != null) ...[
            const SizedBox(height: 16),
            ...(data['recommendations'] as List).map(
              (rec) => RecommendationCard(recommendation: rec.toString()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLifestyleSection(Map<String, dynamic> data) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifestyle',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (data['diet'] != null)
            _buildLifestyleItem(
              icon: Icons.restaurant,
              title: 'Diet',
              subtitle: 'Avg Calories: ${data['diet']['averageCalories'] ?? 0}',
            ),
          if (data['exercise'] != null)
            _buildLifestyleItem(
              icon: Icons.fitness_center,
              title: 'Exercise',
              subtitle: 'Avg Minutes: ${data['exercise']['averageMinutes'] ?? 0}',
            ),
          if (data['recommendations'] != null) ...[
            const SizedBox(height: 16),
            ...(data['recommendations'] as List).map(
              (rec) => RecommendationCard(recommendation: rec.toString()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLifestyleItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFactorsSection(List<dynamic> riskFactors) {
    return Container(
      decoration: ModernSurfaceTheme.glassCard(context),
      padding: ModernSurfaceTheme.cardPadding(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Factors',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...riskFactors.map(
            (risk) => Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _getRiskColor(risk['severity']).withOpacity(0.1),
                border: Border.all(
                  color: _getRiskColor(risk['severity']).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _getRiskColor(risk['severity']),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          risk['type'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          risk['description'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
  }

  Color _getConcernColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      default:
        return AppTheme.getSuccessColor(context);
    }
  }

  Color _getRiskColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }
}
