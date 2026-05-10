import 'package:flutter/material.dart';
import 'models/survey_model.dart';
import 'services/survey_service.dart';
import 'services/auth_service.dart';

class QuestionModel {
  String? id;
  String text;
  String type;
  QuestionModel({this.id, this.text = '', this.type = 'Text Input'});
}

class CreateSurveyScreen extends StatefulWidget {
  final Survey? survey;
  const CreateSurveyScreen({super.key, this.survey});

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  List<QuestionModel> _questions = [QuestionModel()];
  final SurveyService _surveyService = SurveyService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.survey != null) {
      _titleController.text = widget.survey!.title;
      _descController.text = widget.survey!.description;
      _questions = widget.survey!.questions.map((q) => QuestionModel(
        id: q.id,
        text: q.text,
        type: q.type,
      )).toList();
      if (_questions.isEmpty) _questions = [QuestionModel()];
    }
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = await AuthService.instance.currentSession();
    if (session == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  final List<String> _questionTypes = [
    'Text Input',
    'Multiple Choice',
    'Checkbox',
    'Rating',
    'Date',
    'Number',
    'Photo/Image',
  ];

  void _addQuestion() {
    setState(() => _questions.add(QuestionModel()));
  }

  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() => _questions.removeAt(index));
    }
  }

  void _savesurvey() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a survey title'), backgroundColor: Colors.red),
      );
      return;
    }

    final validQuestions = _questions.where((q) => q.text.trim().isNotEmpty).toList();
    if (validQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one question with text'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final session = await AuthService.instance.currentSession();
      
      if (widget.survey != null) {
        // Update existing survey
        final updatedQuestions = validQuestions.asMap().entries.map((entry) {
          return Question(
            id: entry.value.id ?? SurveyService.uuid.v4(),
            surveyId: widget.survey!.id,
            text: entry.value.text.trim(),
            type: entry.value.type,
            order: entry.key,
          );
        }).toList();

        final updatedSurvey = widget.survey!.copyWith(
          title: title,
          description: _descController.text.trim(),
          questions: updatedQuestions,
          questionCount: updatedQuestions.length,
          syncStatus: SyncStatus.pending,
          updatedAt: DateTime.now(),
        );

        await _surveyService.updateSurvey(updatedSurvey);
      } else {
        // Create new survey
        final questionDrafts = validQuestions
            .map(
              (question) => SurveyQuestionDraft(
                text: question.text.trim(),
                type: question.type,
              ),
            )
            .toList();

        await _surveyService.createSurvey(
          title: title,
          description: _descController.text.trim(),
          creatorName: session?.name,
          token: session?.token,
          questions: questionDrafts,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.survey != null ? 'Survey updated successfully!' : 'Survey saved successfully offline!'),
          backgroundColor: const Color(0xFF1A65FF),
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving survey: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1B1F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Survey',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1B1F),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _savesurvey,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A65FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Survey Info Card ──────────────────────────────────────
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel('Survey Title'),
                  const SizedBox(height: 8),
                  _StyledTextField(
                    controller: _titleController,
                    hint: 'Enter survey title',
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Description'),
                  const SizedBox(height: 8),
                  _StyledTextField(
                    controller: _descController,
                    hint: 'Enter survey description',
                    maxLines: 4,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Questions Header ──────────────────────────────────────
            const Text(
              'Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1B1F),
              ),
            ),
            const SizedBox(height: 12),

            // ── Question Cards ────────────────────────────────────────
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _questions.removeAt(oldIndex);
                  _questions.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  key: ValueKey('question_$index'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuestionCard(
                    index: index,
                    question: _questions[index],
                    questionTypes: _questionTypes,
                    canDelete: _questions.length > 1,
                    onDelete: () => _removeQuestion(index),
                    onTextChanged: (v) =>
                        setState(() => _questions[index].text = v),
                    onTypeChanged: (v) =>
                        setState(() => _questions[index].type = v!),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ── Add Question Button ───────────────────────────────────
            GestureDetector(
              onTap: _addQuestion,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: const Color(0xFF1A65FF).withOpacity(0.5),
                    width: 1.5,
                    // dashed border via custom painter below
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A65FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Add Question',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A65FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Widgets ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF444444),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1B1F)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A65FF), width: 1.5),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuestionModel question;
  final List<String> questionTypes;
  final bool canDelete;
  final VoidCallback onDelete;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<String?> onTypeChanged;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.questionTypes,
    required this.canDelete,
    required this.onDelete,
    required this.onTextChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${index + 1}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              if (canDelete)
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Question Text
          const Text(
            'Question Text',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: onTextChanged,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1C1B1F)),
            decoration: InputDecoration(
              hintText: 'Enter your question',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1A65FF),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Question Type
          const Text(
            'Question Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: question.type,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF1A65FF),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1C1B1F),
                  fontWeight: FontWeight.w500,
                ),
                onChanged: onTypeChanged,
                items: questionTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
