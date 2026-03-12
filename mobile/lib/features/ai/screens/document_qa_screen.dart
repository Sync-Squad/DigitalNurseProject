import 'package:flutter/material.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/modern_surface_theme.dart';

class DocumentQAScreen extends StatefulWidget {
  const DocumentQAScreen({super.key});

  @override
  State<DocumentQAScreen> createState() => _DocumentQAScreenState();
}

class _DocumentQAScreenState extends State<DocumentQAScreen> {
  final TextEditingController _questionController = TextEditingController();
  final AIService _aiService = AIService();
  int? _selectedDocumentId;
  Map<String, dynamic>? _answer;
  bool _isLoading = false;
  List<dynamic> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id ?? '';
      final documentProvider = context.read<DocumentProvider>();
      await documentProvider.loadDocuments(userId);
      if (mounted) {
        setState(() {
          _documents = documentProvider.documents
              .map(
                (doc) => {
                  'id': doc.id,
                  'title': doc.title,
                  'documentType': doc.type.toString(),
                },
              )
              .toList();
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _askQuestion() async {
    if (_selectedDocumentId == null ||
        _questionController.text.trim().isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final answer = await _aiService.askDocument(
        documentId: _selectedDocumentId!,
        question: _questionController.text.trim(),
      );

      setState(() {
        _answer = answer;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.getErrorColor(context),
            content: Text(
              'Failed to get answer: $e',
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
        title: const Text('Document Q&A'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Document selector
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: Container(
              decoration: ModernSurfaceTheme.frostedChip(context),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: DropdownButtonFormField<int>(
                value: _selectedDocumentId,
                dropdownColor: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.darkSurface
                    : Colors.white,
                decoration: const InputDecoration(
                  labelText: 'Select Document',
                  border: InputBorder.none,
                ),
                items: _documents.map((doc) {
                  return DropdownMenuItem<int>(
                    value: int.tryParse(doc['id']?.toString() ?? ''),
                    child: Text(
                      doc['title'] ?? 'Untitled',
                      style: TextStyle(fontSize: 15.sp),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDocumentId = value;
                    _answer = null;
                  });
                },
              ),
            ),
          ),
          // Question input
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Container(
              decoration: ModernSurfaceTheme.glassCard(context),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: TextField(
                controller: _questionController,
                maxLines: 2,
                style: TextStyle(fontSize: 15.sp),
                decoration: InputDecoration(
                  hintText: 'Ask a question about the document...',
                  suffixIcon: _isLoading
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
                          onPressed: _askQuestion,
                        ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _askQuestion(),
              ),
            ),
          ),
          // Answer display
          Expanded(
            child: _answer == null
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
                            Icons.question_answer_rounded,
                            size: 48.w,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Ask a question about your document',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: ModernSurfaceTheme.screenPadding(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Answer:',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: ModernSurfaceTheme.glassCard(context),
                          child: Text(
                            _answer!['answer'] ?? '',
                            style: TextStyle(
                              fontSize: 16.sp,
                              height: 1.5,
                            ),
                          ),
                        ),
                        if (_answer!['sources'] != null &&
                            (_answer!['sources'] as List).isNotEmpty) ...[
                          SizedBox(height: 24.h),
                          Text(
                            'Sources:',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          ...(_answer!['sources'] as List).map(
                            (source) => Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              decoration: ModernSurfaceTheme.glassCard(context),
                              child: ListTile(
                                leading: Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: ModernSurfaceTheme.iconBadge(
                                    context,
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                  child: Icon(
                                    Icons.description,
                                    color: Colors.white,
                                    size: 20.w,
                                  ),
                                ),
                                title: Text(
                                  source['text'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                                subtitle: Text(
                                  'Similarity: ${(source['similarity'] * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
