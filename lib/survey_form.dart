import 'package:flutter/material.dart';

class QuestionModel {
  String text;
  String type;
  QuestionModel({this.text = '', this.type = 'Text Input'});
}

class CreateSurveyScreen extends StatefulWidget {
  const CreateSurveyScreen({super.key});

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<QuestionModel> _questions = [QuestionModel()];

  final List<String> _questionTypes = [
    'Text Input',
    'Multiple Choice',
    'Checkbox',
    'Rating',
    'Date',
    'Number',
  ];

  void _addQuestion() {
    setState(() => _questions.add(QuestionModel()));
  }

  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() => _questions.removeAt(index));
    }
  }

  void _savesurvey() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a survey title')),
      );
      return;
    }
    // TODO: integrate with API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Survey saved successfully!'),
        backgroundColor: Color(0xFF1A73E8),
      ),
    );
    Navigator.pop(context);
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
              onPressed: _savesurvey,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _QuestionCard(
                  index: index,
                  question: _questions[index],
                  questionTypes: _questionTypes,
                  canDelete: _questions.length > 1,
                  onDelete: () => _removeQuestion(index),
                  onTextChanged: (v) =>
                      setState(() => _questions[index].text = v),
                  onTypeChanged: (v) =>
                      setState(() => _questions[index].type = v!),
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
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.5),
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
                        color: Color(0xFF1A73E8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Add Question',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A73E8),
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
            color: Colors.black.withValues(alpha: 0.05),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                borderSide:
                    const BorderSide(color: Color(0xFF1A73E8), width: 1.5),
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
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF1A73E8)),
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