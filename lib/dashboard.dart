import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'survey_form.dart';
import 'fill_survey.dart';
import 'responses_screen.dart';
import 'analytic.dart';
import 'models/survey_model.dart';
import 'models/user_session.dart';
import 'services/survey_service.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'package:geolocator/geolocator.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final SurveyService _surveyService = SurveyService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _syncData();
      }
    });
  }

  Future<void> _syncData() async {
    final session = await AuthService.instance.currentSession();
    if (session != null) {
      await _surveyService.syncAllData(session.token);
      // If we are on the home tab, we might want to refresh the list
      if (mounted) {
        setState(() {}); // This might not be enough if it's in a different State object
      }
    }
  }

  Future<void> _checkAuth() async {
    final session = await AuthService.instance.currentSession();
    if (session == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  final List<Widget> _tabs = [
    const _HomeTab(),
    const _ScannerTab(),
    const _MapTab(),
    const _SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1A65FF),
        unselectedItemColor: const Color(0xFF8A94A6),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final SurveyService _surveyService = SurveyService();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSyncing = false;
  
  late Future<List<Survey>> _surveysFuture;
  List<Survey> _allSurveys = [];
  List<Survey> _filteredSurveys = [];
  String _selectedFilter = 'All';
  
  int _pendingCount = 0;
  int _thisWeekCount = 0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
    _updateLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _surveyService.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  Future<void> _loadData() async {
    final surveys = await _surveyService.getAllSurveys();
    final pending = await _surveyService.getUnsyncedResponses();
    
    // Calculate surveys from this week
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekCount = surveys.where((s) => s.createdAt.isAfter(weekAgo)).length;
    
    if (mounted) {
      setState(() {
        _allSurveys = surveys;
        _pendingCount = pending.length;
        _thisWeekCount = weekCount;
        _applyFilters();
      });
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSurveys = _allSurveys.where((survey) {
        bool matchesSearch = survey.title.toLowerCase().contains(query) || 
                           survey.description.toLowerCase().contains(query);
        
        bool matchesFilter = true;
        if (_selectedFilter == 'Synced') {
          matchesFilter = survey.syncStatus == SyncStatus.synced;
        } else if (_selectedFilter == 'Pending') {
          matchesFilter = survey.syncStatus == SyncStatus.pending;
        }
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _updateLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentPosition = pos;
      });
    }
  }

  Widget _buildLocationStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Icon(
            _currentPosition != null ? Icons.location_on : Icons.location_off,
            color: _currentPosition != null ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPosition != null 
                      ? 'Location Captured' 
                      : 'Capturing Location...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_currentPosition != null)
                  Text(
                    'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _updateLocation,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }



  void _reloadSurveys() {
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildLocationStatus(),
              _buildSearchAndFilters(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            title: 'New Survey',
                            icon: Icons.add,
                            color: const Color(0xFF1A65FF),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateSurveyScreen(),
                                ),
                              );
                              if (mounted) _reloadSurveys();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            title: 'Analytics',
                            icon: Icons.bar_chart,
                            color: const Color(0xFF1A65FF),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AnalyticsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Surveys',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '${_filteredSurveys.length} total',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_filteredSurveys.isEmpty)
                      _buildEmptyState(
                        icon: _searchController.text.isNotEmpty || _selectedFilter != 'All'
                            ? Icons.search_off
                            : Icons.assignment_outlined,
                        title: _searchController.text.isNotEmpty || _selectedFilter != 'All'
                            ? 'No matches found'
                            : 'No saved surveys yet',
                        message: _searchController.text.isNotEmpty || _selectedFilter != 'All'
                            ? 'Try changing your search query or filter.'
                            : 'Create a survey and it will appear here automatically.',
                      )
                    else
                      Column(
                        children: [
                          for (final survey in _filteredSurveys) ...[
                            _buildSurveyItem(survey),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search surveys...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: ['All', 'Synced', 'Pending'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedFilter = filter);
                    _applyFilters();
                  },
                  selectedColor: const Color(0xFF1A65FF).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF1A65FF),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF1A65FF) : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF1A65FF) : const Color(0xFFEAEAEA),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1A65FF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Surveys',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _isSyncing 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.sync, color: Colors.white),
                    onPressed: () async {
                      setState(() => _isSyncing = true);
                      final session = await AuthService.instance.currentSession();
                      if (session != null) {
                        await _surveyService.syncAllData(session.token);
                        await _loadData();
                      }
                      if (mounted) setState(() => _isSyncing = false);
                    },
                  ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.15).round()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Unsynced',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((255 * 0.15).round()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_thisWeekCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This Week',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyItem(Survey survey) {
    final statusStyle = _statusStyle(survey.syncStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showSurveyDetails(survey),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    survey.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDate(survey.createdAt)} • ${survey.questionCount} questions',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF808080),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.qr_code, color: Color(0xFF1A65FF)),
              onPressed: () => _showShareQR(survey),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusStyle.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusStyle.label,
                style: TextStyle(
                  color: statusStyle.foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFF1A65FF)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF808080)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSurvey(Survey survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Survey?'),
        content: Text('This will permanently delete "${survey.title}" and all its collected responses. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _surveyService.deleteSurvey(survey.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                _reloadSurveys();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Survey deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showSurveyDetails(Survey survey) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  survey.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (survey.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    survey.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Saved on ${_formatDate(survey.createdAt)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF808080),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1A65FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SurveyResponsesScreen(survey: survey),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list_alt, semanticLabel: 'View responses'),
                        label: const Text('View All Responses'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      tooltip: 'Edit survey template',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        foregroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateSurveyScreen(survey: survey),
                          ),
                        ).then((_) => _reloadSurveys());
                      },
                      icon: const Icon(Icons.edit_outlined, semanticLabel: 'Edit'),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Delete this survey permanently',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _confirmDeleteSurvey(survey),
                      icon: const Icon(Icons.delete_outline, semanticLabel: 'Delete'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Questions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                if (survey.questions.isEmpty)
                  const Text(
                    'No questions saved for this survey.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF808080)),
                  )
                else
                  for (final entry in survey.questions.asMap().entries) ...[
                    _QuestionPreview(
                      number: entry.key + 1,
                      question: entry.value,
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        );
      },
    );
  }

  void _showShareQR(Survey survey) {
    // Generate the URL for this specific survey
    // Note: Use your actual Firebase URL here
    final surveyUrl = 'https://survey-app-767fc.web.app/#/fill?id=${survey.id}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share "${survey.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Anyone can scan this code to fill out your survey.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: QrImageView(
                data: surveyUrl,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              surveyUrl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: surveyUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  _SurveyStatusStyle _statusStyle(SyncStatus status) {
    return switch (status) {
      SyncStatus.synced => const _SurveyStatusStyle(
        label: 'Synced',
        background: Color(0xFFD1F4E0),
        foreground: Color(0xFF1E8E3E),
      ),
      SyncStatus.failed => const _SurveyStatusStyle(
        label: 'Failed',
        background: Color(0xFFFFE4E0),
        foreground: Color(0xFFD93025),
      ),
      SyncStatus.pending => const _SurveyStatusStyle(
        label: 'Saved',
        background: Color(0xFFFFEFE0),
        foreground: Color(0xFFE67C00),
      ),
    };
  }
}

class _SurveyStatusStyle {
  const _SurveyStatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

class _QuestionPreview extends StatelessWidget {
  const _QuestionPreview({required this.number, required this.question});

  final int number;
  final Question question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF1A65FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  question.type,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF808080),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  UserSession? _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await AuthService.instance.currentSession();
    if (mounted) {
      setState(() {
        _session = session;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A65FF);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 40,
                  bottom: 32,
                ),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 50, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _session?.name ?? 'Surveyor',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _session?.email ?? 'Loading...',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      icon: Icons.person_outline,
                      title: 'Profile Details',
                      subtitle: 'Name, Email, and Role',
                      onTap: () => _showProfileInfo(),
                    ),
                    _buildSettingsItem(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Configure app alerts',
                      onTap: () => _showNotImplemented('Notifications'),
                    ),
                    _buildSettingsItem(
                      icon: Icons.lock_outline,
                      title: 'Privacy & Security',
                      subtitle: 'Security preferences',
                      onTap: () => _showNotImplemented('Security'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'App Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'Get assistance',
                      onTap: () => _showNotImplemented('Help & Support'),
                    ),
                    _buildSettingsItem(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'Version 1.1.0-NEW',
                      onTap: () => _showAbout(),
                    ),
                    const SizedBox(height: 32),
                    _buildSettingsItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      iconColor: Colors.red,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await AuthService.instance.logout();
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _infoRow('Name', _session?.name ?? 'N/A'),
            const Divider(),
            _infoRow('Email', _session?.email ?? 'N/A'),
            const Divider(),
            _infoRow('Role', _session?.role ?? 'Field Worker'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A65FF)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Field Survey App',
      applicationVersion: '1.1.0-NEW',
      applicationLegalese: '© 2024 Field Survey Team',
      children: [
        const SizedBox(height: 12),
        const Text('This app allows field surveyors to collect data offline and sync it whenever they have a stable internet connection.'),
      ],
    );
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature settings will be available in the next update.')),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    const primaryColor = Color(0xFF1A65FF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? primaryColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: iconColor ?? const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF808080),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: iconColor ?? const Color(0xFF8A94A6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerTab extends StatefulWidget {
  const _ScannerTab();

  @override
  State<_ScannerTab> createState() => _ScannerTabState();
}

class _ScannerTabState extends State<_ScannerTab> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  String? _lastScannedValue;

  @override
  void dispose() {
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .firstOrNull;

    if (value == null || value == _lastScannedValue) return;

    setState(() {
      _lastScannedValue = value;
    });

    // Smart Detection: If it's one of our survey links, offer to open it
    if (value.contains('/#/fill?id=')) {
      final surveyId = value.split('id=').last;
      _promptOpenSurvey(surveyId);
    }
  }

  void _promptOpenSurvey(String surveyId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📋 Survey detected!'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OPEN',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FillSurveyScreen(surveyId: surveyId),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyLastScan() async {
    final value = _lastScannedValue;
    if (value == null || value.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('QR code copied')));
  }

  Future<void> _restartScanner() async {
    await _scannerController.stop();
    await _scannerController.start();
  }

  String _scannerErrorMessage(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera permission was blocked. Allow camera access for this site, then reopen the scanner.',
      MobileScannerErrorCode.unsupported =>
        'Camera scanning is not supported in this browser or device.',
      _ => error.errorDetails?.message ?? error.errorCode.message,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Scanner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A65FF),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () => unawaited(_scannerController.switchCamera()),
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Restart scanner',
            onPressed: () => unawaited(_restartScanner()),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _scannerController,
                          fit: BoxFit.cover,
                          onDetect: _handleDetect,
                          placeholderBuilder: (context) =>
                              const _ScannerLoadingView(),
                          errorBuilder: (context, error) => _ScannerErrorView(
                            message: _scannerErrorMessage(error),
                            onRetry: () => unawaited(_restartScanner()),
                          ),
                        ),
                        const _ScannerFrame(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _ScanResultCard(
                value: _lastScannedValue,
                onCopy: _copyLastScan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 3),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerLoadingView extends StatelessWidget {
  const _ScannerLoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white, size: 44),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({required this.value, required this.onCopy});

  final String? value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1A65FF).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasValue ? Icons.qr_code_2 : Icons.qr_code_scanner,
              color: const Color(0xFF1A65FF),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasValue ? 'Scanned QR Code' : 'Waiting for QR code',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? value! : 'Point the camera at a QR code.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF808080),
                  ),
                ),
              ],
            ),
          ),
          if (hasValue) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Copy result',
              onPressed: onCopy,
              icon: const Icon(Icons.copy),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapTab extends StatefulWidget {
  const _MapTab();

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  final SurveyService _surveyService = SurveyService();
  final LocationService _locationService = LocationService();
  Set<Marker> _markers = {};
  bool _isLoading = true;
  GoogleMapController? _mapController;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load survey markers
    final responses = await _surveyService.getAllResponses();
    final markers = responses
        .where((r) => r.latitude != null && r.longitude != null)
        .map((r) => Marker(
              markerId: MarkerId(r.id),
              position: LatLng(r.latitude!, r.longitude!),
              onTap: () => _showResponseDetailOnMap(r),
              // Remove the old infoWindow so it doesn't block our card
            ))
        .toSet();

    // Get current device location
    final position = await _locationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _markers = markers;
        _currentPosition = position;
        _isLoading = false;
      });

      // Move camera to user if they have no markers yet
      if (position != null && markers.isEmpty && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    }
  }

  void _showResponseDetailOnMap(SurveyResponse response) async {
    final survey = await _surveyService.getSurvey(response.surveyId);
    if (!mounted || survey == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        survey.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Captured on ${_formatDate(response.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 32),
            const Text('Submission Data:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A65FF))),
            const SizedBox(height: 12),
            // Show a summary of answers
            ...survey.questions.take(3).map((q) {
              final answer = response.answers[q.id] ?? 'N/A';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('${q.text}: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    Text(answer.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
            if (survey.questions.length > 3)
              const Text('...', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A65FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurveyResponsesScreen(survey: survey),
                    ),
                  );
                },
                child: const Text('View Full Submission'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Survey Locations', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A65FF),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _markers.isNotEmpty
                    ? _markers.first.position
                    : (_currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : const LatLng(28.6139, 77.2090)), // New Delhi as final fallback
                zoom: 14,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPosition != null && _markers.isEmpty) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    ),
                  );
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
