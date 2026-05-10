import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'services/survey_service.dart';
import 'models/survey_model.dart';
import 'services/file_download_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final SurveyService _surveyService = SurveyService();
  bool _isLoading = true;
  int _totalSurveys = 0;
  int _totalResponses = 0;
  int _syncedResponses = 0;
  int _pendingResponses = 0;
  List<Survey> _surveyStats = [];
  List<SurveyResponse> _allResponsesData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final surveys = await _surveyService.getAllSurveys();
      final responses = await _surveyService.getAllResponses();
      _allResponsesData = responses;
      
      // Calculate sync stats
      int synced = 0;
      int pending = 0;
      for (var r in responses) {
        if (r.syncStatus == SyncStatus.synced) synced++;
        if (r.syncStatus == SyncStatus.pending) pending++;
      }

      // Map responses to surveys for "Reach" per survey
      final List<Survey> stats = [];
      for (var survey in surveys) {
        final surveyResponses = responses.where((r) => r.surveyId == survey.id).length;
        stats.add(survey.copyWith(responseCount: surveyResponses));
      }

      if (mounted) {
        setState(() {
          _totalSurveys = surveys.length;
          _totalResponses = responses.length;
          _syncedResponses = synced;
          _pendingResponses = pending;
          _surveyStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _exportMasterData() {
    if (_allResponsesData.isEmpty) return;

    List<List<dynamic>> rows = [];
    // Header
    rows.add(['Survey Title', 'Submission Date', 'Lat', 'Lng', 'Raw Data JSON']);

    for (var response in _allResponsesData) {
      final surveyTitle = _surveyStats.firstWhere((s) => s.id == response.surveyId, 
          orElse: () => Survey(id: '', title: 'Unknown', createdAt: DateTime.now(), updatedAt: DateTime.now())).title;
      
      rows.add([
        surveyTitle,
        response.createdAt.toIso8601String(),
        response.latitude ?? '',
        response.longitude ?? '',
        response.answers.toString(),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    FileDownloadHelper.downloadCsv(csvData, 'Master_Survey_Data_${DateTime.now().millisecondsSinceEpoch}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Master CSV Exported')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A65FF);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Reach & Analytics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Download Master Data',
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: _allResponsesData.isEmpty ? null : _exportMasterData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global Reach',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Top Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Forms',
                          '$_totalSurveys',
                          Icons.assignment_outlined,
                          primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          'Total Reach',
                          '$_totalResponses',
                          Icons.groups_outlined,
                          const Color(0xFF00C853),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sync Status Section
                  const Text(
                    'Data Transmission',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSyncProgress(),

                  const SizedBox(height: 32),
                  
                  // Per Form Reach Section
                  const Text(
                    'Reach Per Survey',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_surveyStats.isEmpty)
                    _buildEmptyState()
                  else
                    ..._surveyStats.map((survey) => _buildReachItem(survey)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSyncProgress() {
    double percent = _totalResponses == 0 ? 0 : _syncedResponses / _totalResponses;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Synced: $_syncedResponses', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              Text('Pending: $_pendingResponses', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.grey[200],
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text('${(percent * 100).toStringAsFixed(1)}% of data reach secured on cloud', 
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReachItem(Survey survey) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A65FF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined, color: Color(0xFF1A65FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  survey.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Created ${_formatDate(survey.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${survey.responseCount}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A65FF)),
              ),
              const Text('Responses', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('No reach data yet', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF808080),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A65FF).withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics, color: Color(0xFF1A65FF), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF808080),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A94A6),
            ),
          ),
        ],
      ),
    );
  }
}
