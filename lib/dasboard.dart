import 'package:flutter/material.dart';

import 'survey_form.dart';

void main() {
  runApp(const FieldSurveyApp());
}

class FieldSurveyApp extends StatelessWidget {
  const FieldSurveyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field Survey App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        // Removed explicit fontFamily: 'Roboto' to allow Flutter to use its default font
        // which typically handles system fonts or bundles Roboto implicitly for Material Design.
        // This can resolve issues if 'Roboto' isn't available or configured correctly.
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateSurveyScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            title: 'Analytics',
                            icon: Icons.bar_chart,
                            color: const Color(0xFF9B00FF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Recent Surveys',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSurveyItem(
                      title: 'Customer Satisfaction Survey',
                      date: 'Mar 6, 2026',
                      status: 'Completed',
                      statusColor: const Color(0xFFD1F4E0),
                      statusTextColor: const Color(0xFF1E8E3E),
                    ),
                    const SizedBox(height: 12),
                    _buildSurveyItem(
                      title: 'Market Research - Region A',
                      date: 'Mar 5, 2026',
                      status: 'In Progress',
                      statusColor: const Color(0xFFFFEFE0),
                      statusTextColor: const Color(0xFFE67C00),
                    ),
                    const SizedBox(height: 12),
                    _buildSurveyItem(
                      title: 'Product Feedback Q1',
                      date: 'Mar 4, 2026',
                      status: 'Completed',
                      statusColor: const Color(0xFFD1F4E0),
                      statusTextColor: const Color(0xFF1E8E3E),
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
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                // Replaced deprecated .withOpacity with .withAlpha
                color: Colors.white.withAlpha((255 * 0.15).round()), // Alpha for 0.15 opacity is 38
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '12',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'In Progress',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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
                // Replaced deprecated .withOpacity with .withAlpha
                color: Colors.white.withAlpha((255 * 0.15).round()), // Alpha for 0.15 opacity is 38
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '28',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This Week',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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

  Widget _buildSurveyItem({
    required String title,
    required String date,
    required String status,
    required Color statusColor,
    required Color statusTextColor,
  }) {
    return Container(
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
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF808080),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}