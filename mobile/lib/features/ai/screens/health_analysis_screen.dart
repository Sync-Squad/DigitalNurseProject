import 'package:flutter/material.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
import 'package:provider/provider.dart';
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
    return ModernScaffold(
      appBar: AppBar(
        title: const Text('Health Analysis'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAnalysis),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null
          ? const Center(child: Text('No analysis available'))
          : RefreshIndicator(
              onRefresh: _loadAnalysis,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication Adherence Section
                    if (_analysis!['medicationAdherence'] != null)
                      _buildMedicationAdherenceSection(
                        _analysis!['medicationAdherence'],
                      ),
                    // Health Trends Section
                    if (_analysis!['healthTrends'] != null)
                      _buildHealthTrendsSection(_analysis!['healthTrends']),
                    // Lifestyle Section
                    if (_analysis!['lifestyleCorrelation'] != null)
                      _buildLifestyleSection(
                        _analysis!['lifestyleCorrelation'],
                      ),
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
    final adherence = data['overallPercentage'] ?? 0.0;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medication Adherence',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              value: adherence / 100,
              semanticsLabel: 'Adherence: $adherence%',
            ),
            const SizedBox(height: 8),
            Text(
              '${adherence.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (data['recommendations'] != null) ...[
              const SizedBox(height: 16),
              ...(data['recommendations'] as List).map(
                (rec) => RecommendationCard(recommendation: rec.toString()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTrendsSection(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Trends',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (data['vitals'] != null)
              ...(data['vitals'] as List).map(
                (vital) => ListTile(
                  title: Text(vital['type'] ?? ''),
                  subtitle: Text('Trend: ${vital['trend'] ?? ''}'),
                  trailing: Chip(
                    label: Text(vital['concernLevel'] ?? 'low'),
                    backgroundColor: _getConcernColor(vital['concernLevel']),
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
      ),
    );
  }

  Widget _buildLifestyleSection(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lifestyle',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (data['diet'] != null)
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Diet'),
                subtitle: Text(
                  'Avg Calories: ${data['diet']['averageCalories'] ?? 0}',
                ),
              ),
            if (data['exercise'] != null)
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: const Text('Exercise'),
                subtitle: Text(
                  'Avg Minutes: ${data['exercise']['averageMinutes'] ?? 0}',
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
      ),
    );
  }

  Widget _buildRiskFactorsSection(List<dynamic> riskFactors) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Factors',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...riskFactors.map(
              (risk) => Card(
                color: _getRiskColor(risk['severity']).withOpacity(0.1),
                child: ListTile(
                  leading: Icon(
                    Icons.warning,
                    color: _getRiskColor(risk['severity']),
                  ),
                  title: Text(risk['type'] ?? ''),
                  subtitle: Text(risk['description'] ?? ''),
                  trailing: Chip(
                    label: Text(risk['severity'] ?? ''),
                    backgroundColor: _getRiskColor(risk['severity']),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConcernColor(String? level) {
    switch (level) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color _getRiskColor(String? severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
