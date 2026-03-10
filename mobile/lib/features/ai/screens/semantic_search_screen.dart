import 'package:flutter/material.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';

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
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.getErrorColor(context),
            content: Text(
              'Search failed: $e',
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
        title: const Text('Semantic Search'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Container(
              decoration: ModernSurfaceTheme.frostedChip(context),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: TextField(
                controller: _searchController,
                style: TextStyle(height: 1.2, fontSize: 16.sp),
                decoration: InputDecoration(
                  hintText: 'Search your health data...',
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: _isSearching
                      ? Padding(
                          padding: EdgeInsets.all(12.w),
                          child: SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: _performSearch,
                        ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
          Expanded(
            child: _results.isEmpty && !_isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: ModernSurfaceTheme.iconBadge(
                            context,
                            Theme.of(context).colorScheme.primary,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            size: 48.w,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Search your health data',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Ask questions in natural language',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: ModernSurfaceTheme.screenPadding(),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: ModernSurfaceTheme.glassCard(context),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          leading: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: ModernSurfaceTheme.iconBadge(
                              context,
                              _getSimilarityColor(result['similarity']),
                            ),
                            child: Icon(
                              _getEntityIcon(result['entityType']),
                              color: Colors.white,
                              size: 20.w,
                            ),
                          ),
                          title: Text(
                            result['content'] ?? '',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 4.h),
                            child: Text(
                              '${result['entityType'].toString().replaceAll('_', ' ')} • ${(result['similarity'] * 100).toStringAsFixed(0)}% match',
                              style: TextStyle(fontSize: 13.sp),
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
