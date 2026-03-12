import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/care_context_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/ai_chat_bubble.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/modern_surface_theme.dart';

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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
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
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionButton(
                    label: 'Analyze Health',
                    icon: Icons.analytics_rounded,
                    onTap: () {
                      _messageController.text = 'Analyze my health data';
                      _sendMessage();
                    },
                  ),
                  SizedBox(width: 10.w),
                  _QuickActionButton(
                    label: 'Medications',
                    icon: Icons.medication_rounded,
                    onTap: () {
                      _messageController.text = 'Tell me about my medications';
                      _sendMessage();
                    },
                  ),
                  SizedBox(width: 10.w),
                  _QuickActionButton(
                    label: 'Vitals',
                    icon: Icons.favorite_rounded,
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
                        Container(
                          padding: EdgeInsets.all(24.w),
                          decoration: ModernSurfaceTheme.iconBadge(
                            context,
                            Theme.of(context).colorScheme.primary,
                          ),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            size: 48.w,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Ask me anything about your health',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.w),
                          child: Text(
                            'I can help you understand your medications, vitals, and health trends',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
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
            padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
            decoration: ModernSurfaceTheme.glassCard(context).copyWith(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: ModernSurfaceTheme.frostedChip(context),
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(fontSize: 15.sp),
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    decoration: ModernSurfaceTheme.iconBadge(
                      context,
                      AppTheme.appleGreen,
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: ModernSurfaceTheme.frostedChip(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.w, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
