import 'package:flutter/material.dart';

class AIChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isLoading;
  final bool hasError;
  final List<dynamic>? sources;

  const AIChatBubble({
    super.key,
    required this.message,
    this.isUser = false,
    this.isLoading = false,
    this.hasError = false,
    this.sources,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: hasError
                    ? Border.all(
                        color: Theme.of(context).colorScheme.error,
                        width: 1,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      message,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  if (sources != null && sources!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Divider(
                      height: 1,
                      color: isUser
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sources:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUser
                            ? Colors.white.withOpacity(0.9)
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...sources!
                        .take(3)
                        .map(
                          (source) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${source['text'] ?? 'Source'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isUser
                                    ? Colors.white.withOpacity(0.8)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
