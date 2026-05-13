import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'services/survey_service.dart';
import 'models/survey_model.dart';
import 'services/file_download_helper.dart';

class SurveyResponsesScreen extends StatefulWidget {
  final Survey survey;
  const SurveyResponsesScreen({super.key, required this.survey});

  @override
  State<SurveyResponsesScreen> createState() => _SurveyResponsesScreenState();
}

class _SurveyResponsesScreenState extends State<SurveyResponsesScreen> {
  final SurveyService _surveyService = SurveyService();
  late Future<List<SurveyResponse>> _responsesFuture;
  List<SurveyResponse> _allResponses = [];

  @override
  void initState() {
    super.initState();
    _responsesFuture = _loadResponses();
  }

  Future<List<SurveyResponse>> _loadResponses() async {
    final responses = await _surveyService.getResponsesBySurvey(widget.survey.id);
    _allResponses = responses;
    return responses;
  }

  void _exportToCsv() {
    if (_allResponses.isEmpty) return;

    List<List<dynamic>> rows = [];

    // Header row
    List<dynamic> header = [
      'Submission Date', 
      'ISO Timestamp',
      'Surveyor Name', 
      'Surveyor Email', 
      'Latitude', 
      'Longitude'
    ];
    for (var q in widget.survey.questions) {
      header.add(q.text);
    }
    rows.add(header);

    // Data rows
    for (var response in _allResponses) {
      List<dynamic> row = [
        response.createdAt.toIso8601String(),
        response.answers['_iso_timestamp'] ?? response.createdAt.toIso8601String(),
        response.answers['_surveyor_name'] ?? 'N/A',
        response.answers['_surveyor_email'] ?? 'N/A',
        response.latitude ?? '',
        response.longitude ?? '',
      ];
      for (var q in widget.survey.questions) {
        row.add(response.answers[q.id] ?? 'N/A');
      }
      rows.add(row);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    FileDownloadHelper.downloadCsv(
      csvData, 
      '${widget.survey.title.replaceAll(' ', '_')}_responses'
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV Export Started')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A65FF);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('${widget.survey.title} - Data'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Export to CSV',
            icon: const Icon(Icons.download_rounded),
            onPressed: _allResponses.isEmpty ? null : _exportToCsv,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<SurveyResponse>>(
        future: _responsesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final responses = snapshot.data ?? [];
          if (responses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No responses collected yet for this survey.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final response = responses[index];
              return _ResponseCard(
                response: response,
                questions: widget.survey.questions,
                index: index + 1,
              );
            },
          );
        },
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final SurveyResponse response;
  final List<Question> questions;
  final int index;

  const _ResponseCard({
    required this.response,
    required this.questions,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: ExpansionTile(
        title: Text(
          'Submission #$index',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Submitted: ${_formatDate(response.createdAt)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1A65FF).withOpacity(0.1),
          child: const Icon(Icons.person_outline, color: Color(0xFF1A65FF), size: 20),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildMetadataRow(Icons.person, 'Surveyor', response.answers['_surveyor_name'] ?? 'Anonymous'),
                _buildMetadataRow(Icons.email, 'Email', response.answers['_surveyor_email'] ?? 'Unknown'),
                _buildMetadataRow(Icons.access_time, 'ISO Time', response.answers['_iso_timestamp'] ?? response.createdAt.toIso8601String()),
                if (response.latitude != null)
                   _buildMetadataRow(Icons.location_on, 'Location', '${response.latitude!.toStringAsFixed(4)}, ${response.longitude!.toStringAsFixed(4)}', color: Colors.red),
                const SizedBox(height: 8),
                const Text('Responses:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...questions.map((q) {
                  final answer = response.answers[q.id] ?? 'N/A';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.text,
                          style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          answer.toString(),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMetadataRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
