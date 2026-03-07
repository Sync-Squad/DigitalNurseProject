import 'package:flutter/material.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load insights: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insights.isEmpty
          ? Column(
              children: [
                const AIFeaturesNavigation(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insights,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No insights yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI insights will appear here as we analyze your health data',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _loadInsights,
              child: Column(
                children: [
                  const AIFeaturesNavigation(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _insights.length,
                      itemBuilder: (context, index) {
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
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Insights'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Types')),
                DropdownMenuItem(
                  value: 'medication_adherence',
                  child: Text('Medication Adherence'),
                ),
                DropdownMenuItem(
                  value: 'health_trend',
                  child: Text('Health Trend'),
                ),
                DropdownMenuItem(
                  value: 'recommendation',
                  child: Text('Recommendation'),
                ),
                DropdownMenuItem(value: 'alert', child: Text('Alert')),
              ],
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Priorities')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'low', child: Text('Low')),
              ],
              onChanged: (value) => setState(() => _selectedPriority = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedPriority = null;
                _showRead = null;
              });
              Navigator.pop(context);
              _loadInsights();
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _loadInsights();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showInsightDetails(Map<String, dynamic> insight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'] ?? 'Insight',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(insight['content'] ?? ''),
                if (insight['recommendations'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Recommendations:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...(insight['recommendations'] as List).map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(child: Text(rec.toString())),
                        ],
                      ),
                    ),
                  ),
                ],
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
        ).showSnackBar(SnackBar(content: Text('Failed to mark as read: $e')));
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
        ).showSnackBar(SnackBar(content: Text('Failed to archive: $e')));
      }
    }
  }
}
