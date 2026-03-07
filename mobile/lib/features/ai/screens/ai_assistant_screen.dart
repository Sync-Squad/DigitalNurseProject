import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/ai_chat_bubble.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  List<Map<String, dynamic>> _messages = [];
  int? _conversationId;
  bool _isLoading = false;
  int? _elderUserId;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    final careContext = context.read<CareContextProvider>();
    await careContext.ensureLoaded();
    if (mounted) {
      setState(() {
        _elderUserId = careContext.selectedElderId != null
            ? int.tryParse(careContext.selectedElderId!)
            : null;
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.chat(
        message: message,
        conversationId: _conversationId,
        elderUserId: _elderUserId,
      );

      setState(() {
        _conversationId = response['conversationId'];
        _messages.add({
          'role': 'assistant',
          'content': response['message'],
          'sources': response['sources'],
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Sorry, I encountered an error. Please try again.',
          'error': true,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionButton(
                    label: 'Analyze Health',
                    icon: Icons.analytics,
                    onTap: () {
                      _messageController.text = 'Analyze my health data';
                      _sendMessage();
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    label: 'Medications',
                    icon: Icons.medication,
                    onTap: () {
                      _messageController.text = 'Tell me about my medications';
                      _sendMessage();
                    },
                  ),
                  const SizedBox(width: 8),
                  _QuickActionButton(
                    label: 'Vitals',
                    icon: Icons.favorite,
                    onTap: () {
                      _messageController.text = 'How are my vital signs?';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask me anything about your health',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'I can help you understand your medications, vitals, and health trends',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const AIChatBubble(
                          message: 'Thinking...',
                          isUser: false,
                          isLoading: true,
                        );
                      }
                      final message = _messages[index];
                      return AIChatBubble(
                        message: message['content'],
                        isUser: message['role'] == 'user',
                        sources: message['sources'],
                        hasError: message['error'] == true,
                      );
                    },
                  ),
          ),
          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.appleGreen,
                      foregroundColor: AppTheme.buttonTextColor,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.buttonTextColor,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.appleGreen,
        foregroundColor: AppTheme.buttonTextColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
