import 'package:flutter/material.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
import 'package:provider/provider.dart';

class SemanticSearchScreen extends StatefulWidget {
  const SemanticSearchScreen({super.key});

  @override
  State<SemanticSearchScreen> createState() => _SemanticSearchScreenState();
}

class _SemanticSearchScreenState extends State<SemanticSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AIService _aiService = AIService();
  List<dynamic> _results = [];
  bool _isSearching = false;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final careContext = context.read<CareContextProvider>();
      await careContext.ensureLoaded();

      final elderUserId = careContext.selectedElderId != null
          ? int.tryParse(careContext.selectedElderId!)
          : null;

      final results = await _aiService.semanticSearch(
        query: query,
        elderUserId: elderUserId,
      );

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(title: const Text('Semantic Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search your health data...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _performSearch,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          Expanded(
            child: _results.isEmpty && !_isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search your health data',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask questions in natural language',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: Icon(_getEntityIcon(result['entityType'])),
                          title: Text(result['content'] ?? ''),
                          subtitle: Text(
                            '${result['entityType']} • ${(result['similarity'] * 100).toStringAsFixed(0)}% match',
                          ),
                          trailing: Chip(
                            label: Text(
                              '${(result['similarity'] * 100).toStringAsFixed(0)}%',
                            ),
                            backgroundColor: _getSimilarityColor(
                              result['similarity'],
                            ),
                          ),
                          onTap: () {
                            // Navigate to source
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getEntityIcon(String? type) {
    switch (type) {
      case 'caregiver_notes':
        return Icons.note;
      case 'medications':
        return Icons.medication;
      case 'vital_measurements':
        return Icons.favorite;
      case 'diet_logs':
        return Icons.restaurant;
      case 'exercise_logs':
        return Icons.fitness_center;
      default:
        return Icons.description;
    }
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity > 0.8) return Colors.green;
    if (similarity > 0.6) return Colors.orange;
    return Colors.grey;
  }
}
