import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'services/survey_service.dart';
import 'models/survey_model.dart';
import 'services/location_service.dart';

class FillSurveyScreen extends StatefulWidget {
  final String surveyId;
  const FillSurveyScreen({super.key, required this.surveyId});

  @override
  State<FillSurveyScreen> createState() => _FillSurveyScreenState();
}

class _FillSurveyScreenState extends State<FillSurveyScreen> {
  final SurveyService _surveyService = SurveyService();
  final LocationService _locationService = LocationService();
  final ImagePicker _picker = ImagePicker();
  final Map<String, dynamic> _responses = {};
  final Map<String, XFile?> _pickedImages = {};
  
  Survey? _survey;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    final survey = await _surveyService.getSurvey(widget.surveyId);
    final draft = await _surveyService.getDraft(widget.surveyId);
    
    if (mounted) {
      setState(() {
        _survey = survey;
        if (draft != null) {
          _responses.addAll(draft);
        }
        _isLoading = false;
      });
    }
  }

  void _onAnswerChanged(String questionId, dynamic value) {
    setState(() {
      _responses[questionId] = value;
    });
    // Auto-save draft
    _surveyService.saveDraft(widget.surveyId, _responses);
  }

  Future<String?> _uploadImage(XFile image, String questionId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('survey_images')
          .child('${widget.surveyId}_${questionId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(await image.readAsBytes(), metadata);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _submitResponse() async {
    if (_survey == null) return;

    // Validation: Ensure all questions are answered
    for (var q in _survey!.questions) {
      if (q.type == 'Photo/Image') {
        if (_pickedImages[q.id] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please capture a photo for: ${q.text}'), backgroundColor: Colors.orange),
          );
          return;
        }
      } else {
        if (_responses[q.id] == null || _responses[q.id].toString().trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please answer: ${q.text}'), backgroundColor: Colors.orange),
          );
          return;
        }
      }
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Upload all images first
      for (var entry in _pickedImages.entries) {
        if (entry.value != null) {
          final imageUrl = await _uploadImage(entry.value!, entry.key);
          if (imageUrl != null) {
            _responses[entry.key] = imageUrl;
          }
        }
      }

      // 2. Get location
      final position = await _locationService.getCurrentLocation();
      
      await _surveyService.saveResponse(
        surveyId: widget.surveyId,
        responseData: _responses,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      // Delete draft after successful submission
      await _surveyService.deleteDraft(widget.surveyId);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: const Text(
            'Thank you! Your response has been submitted successfully.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacementNamed(context, '/'); // Go to home
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting response: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A65FF);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_survey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Survey Not Found')),
        body: const Center(child: Text('The requested survey could not be found.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_survey!.title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Show a "Draft Saved" indicator
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.cloud_done_outlined, size: 20, color: Colors.white70),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_survey!.description.isNotEmpty) ...[
              Text(
                _survey!.description,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
            ..._survey!.questions.map((q) => _buildQuestionWidget(q)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitResponse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Response', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Question q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildInputForType(q),
        ],
      ),
    );
  }

  Widget _buildInputForType(Question q) {
    switch (q.type) {
      case 'Number':
        return TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter a number',
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (v) => _onAnswerChanged(q.id, v),
        );
      case 'Date':
        return TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: _responses[q.id] ?? 'Select date',
            suffixIcon: const Icon(Icons.calendar_today),
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              final dateStr = date.toIso8601String().split('T')[0];
              _onAnswerChanged(q.id, dateStr);
            }
          },
        );
      case 'Photo/Image':
        return _buildImagePicker(q.id);
      default:
        return TextField(
          decoration: InputDecoration(
            hintText: 'Your answer',
            filled: true,
            fillColor: const Color(0xFFF8F9FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (v) => _onAnswerChanged(q.id, v),
        );
    }
  }

  Widget _buildImagePicker(String questionId) {
    final image = _pickedImages[questionId];
    return Column(
      children: [
        if (image != null)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Uint8List>(
                future: image.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await _picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _pickedImages[questionId] = picked);
                    // Drafts don't auto-save images easily due to file size, 
                    // but we save the fact that a file was picked if needed.
                  }
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await _picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _pickedImages[questionId] = picked);
                  }
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
