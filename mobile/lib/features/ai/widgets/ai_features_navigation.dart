import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AIFeaturesNavigation extends StatelessWidget {
  const AIFeaturesNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'AI Features',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _AIFeatureCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'AI Assistant',
                  description: 'Chat with AI about health questions',
                  route: '/ai/assistant',
                  color: AppTheme.teal,
                ),
                const SizedBox(width: 12),
                _AIFeatureCard(
                  icon: Icons.analytics_outlined,
                  title: 'Health Analysis',
                  description: 'Get comprehensive health analysis',
                  route: '/ai/analysis',
                  color: AppTheme.appleGreen,
                ),
                const SizedBox(width: 12),
                _AIFeatureCard(
                  icon: Icons.search,
                  title: 'Semantic Search',
                  description: 'Search health data semantically',
                  route: '/ai/search',
                  color: AppTheme.blueTertiary,
                ),
                const SizedBox(width: 12),
                _AIFeatureCard(
                  icon: Icons.description_outlined,
                  title: 'Document QA',
                  description: 'Ask questions about uploaded documents',
                  route: '/ai/document-qa',
                  color: AppTheme.tealLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AIFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String route;
  final Color color;

  const _AIFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.appleGreen,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.buttonTextColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.buttonTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.buttonTextColor.withOpacity(0.9),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
