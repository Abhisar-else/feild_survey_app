import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
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

                  const SizedBox(height: 32),

                  // Chart Section
                  if (_totalResponses > 0 && _surveyStats.any((s) => s.responseCount > 0)) ...[
                    const Text(
                      'Survey Distribution',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildPieChart(),
                    const SizedBox(height: 24),
                  ],
                  
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

  int _touchedIndex = -1;

  Widget _buildPieChart() {
    final sortedStats = List<Survey>.from(_surveyStats)
      ..sort((a, b) => b.responseCount.compareTo(a.responseCount));
    final topSurveys = sortedStats.take(5).toList();
    
    final List<Color> chartColors = [
      const Color(0xFF1A65FF),
      const Color(0xFF00C853),
      const Color(0xFFFFB300),
      const Color(0xFFFF5252),
      const Color(0xFF9C27B0),
    ];

    return Container(
      height: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: topSurveys.asMap().entries.map((entry) {
                      final index = entry.key;
                      final isTouched = index == _touchedIndex;
                      final survey = entry.value;
                      final fontSize = isTouched ? 16.0 : 12.0;
                      final radius = isTouched ? 70.0 : 60.0;
                      final double percentage = (survey.responseCount / _totalResponses) * 100;
                      
                      return PieChartSectionData(
                        color: chartColors[index % chartColors.length],
                        value: survey.responseCount.toDouble(),
                        title: isTouched ? '${survey.responseCount}' : '${percentage.toStringAsFixed(0)}%',
                        radius: radius,
                        titleStyle: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_totalResponses',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: topSurveys.asMap().entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: chartColors[entry.key % chartColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.value.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: entry.key == _touchedIndex ? FontWeight.bold : FontWeight.normal,
                      color: entry.key == _touchedIndex ? const Color(0xFF1A1A1A) : Colors.grey[700],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
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
