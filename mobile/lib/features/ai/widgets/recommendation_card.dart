import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  final String recommendation;
  final String? category;
  final VoidCallback? onAction;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.category,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null)
                    Text(
                      category!,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                    ),
                  Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (onAction != null)
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: onAction,
              ),
          ],
        ),
      ),
    );
  }
}
