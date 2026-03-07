import 'package:flutter/material.dart';
import '../../../core/widgets/modern_scaffold.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/providers/document_provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'package:provider/provider.dart';

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
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get answer: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernScaffold(
      appBar: AppBar(title: const Text('Document Q&A')),
      body: Column(
        children: [
          // Document selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              value: _selectedDocumentId,
              decoration: const InputDecoration(
                labelText: 'Select Document',
                border: OutlineInputBorder(),
              ),
              items: _documents.map((doc) {
                return DropdownMenuItem<int>(
                  value: int.tryParse(doc['id']?.toString() ?? ''),
                  child: Text(doc['title'] ?? 'Untitled'),
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
          // Question input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a question about the document...',
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _askQuestion,
                      ),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              onSubmitted: (_) => _askQuestion(),
            ),
          ),
          // Answer display
          Expanded(
            child: _answer == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.question_answer,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ask a question about your document',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Answer:',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _answer!['answer'] ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (_answer!['sources'] != null &&
                            (_answer!['sources'] as List).isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Sources:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...(_answer!['sources'] as List).map(
                            (source) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(Icons.description),
                                title: Text(
                                  source['text'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Similarity: ${(source['similarity'] * 100).toStringAsFixed(0)}%',
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
