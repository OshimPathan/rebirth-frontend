import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rebirth_draft_2/Components/app_colors.dart';
import 'package:rebirth_draft_2/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _loading = true;
  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _progressData;
  late TabController _tabController;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([_loadEmotionAnalytics(), _loadProgressData()]);
    setState(() => _loading = false);
  }

  Future<void> _loadEmotionAnalytics() async {
    try {
      final uri = Uri.parse(
        '${_authService.baseUrl}/chat/analytics/emotions?days=$_selectedDays',
      );
      final headers = {
        'Content-Type': 'application/json',
        if (_authService.token != null)
          'Authorization': 'Bearer ${_authService.token}',
      };
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() {
            _analyticsData = data['analytics'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    }
  }

  Future<void> _loadProgressData() async {
    try {
      final uri = Uri.parse('${_authService.baseUrl}/chat/analytics/progress');
      final headers = {
        'Content-Type': 'application/json',
        if (_authService.token != null)
          'Authorization': 'Bearer ${_authService.token}',
      };
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() {
            _progressData = data['progress'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return Scaffold(
      backgroundColor: colors.backgroundColor,
      appBar: AppBar(
        backgroundColor: colors.backgroundColor,
        foregroundColor: colors.textColor,
        elevation: 0,
        title: Text(
          'Insights & Analytics',
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.accentColor,
          unselectedLabelColor: colors.hintColor,
          indicatorColor: colors.accentColor,
          tabs: const [
            Tab(text: 'Emotions', icon: Icon(Icons.mood)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body:
          _loading
              ? Center(
                child: CircularProgressIndicator(color: colors.accentColor),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildEmotionsTab(colors),
                  _buildProgressTab(colors),
                ],
              ),
    );
  }

  Widget _buildEmotionsTab(ThemeColors colors) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            _buildPeriodSelector(colors),
            const SizedBox(height: 20),

            // Overall Stats Cards
            _buildOverallStats(colors),
            const SizedBox(height: 24),

            // Emotion Distribution Pie Chart
            Text(
              'Emotion Distribution',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildEmotionPieChart(colors),
            const SizedBox(height: 24),

            // Mental Health Progress Chart
            Text(
              'Mental Health Progress',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track how you\'re overcoming challenges',
              style: TextStyle(color: colors.hintColor, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildMentalHealthProgressChart(colors),
            const SizedBox(height: 24),

            // Daily Trend Line Chart
            Text(
              'Mood Trend',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildMoodTrendChart(colors),
            const SizedBox(height: 24),

            // Recent Emotions
            Text(
              'Recent Emotions',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentEmotions(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeColors colors) {
    return Row(
      children: [
        Text(
          'Period: ',
          style: TextStyle(color: colors.textColor, fontSize: 16),
        ),
        const SizedBox(width: 8),
        ...([7, 14, 30]).map((days) {
          final isSelected = _selectedDays == days;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$days days'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedDays = days);
                  _loadEmotionAnalytics();
                }
              },
              selectedColor: colors.accentColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : colors.textColor,
              ),
              backgroundColor: colors.surfaceColor,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOverallStats(ThemeColors colors) {
    final analytics = _analyticsData;
    if (analytics == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No data available yet. Start chatting to see your emotional insights!',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.hintColor),
          ),
        ),
      );
    }

    final avgConfidence = (analytics['averageConfidence'] ?? 0.0) * 100;
    final dominantEmotion = analytics['dominantEmotion'] ?? 'neutral';
    final positivityRatio = (analytics['positivityRatio'] ?? 0.5) * 100;
    final stabilityScore = analytics['stabilityScore'] ?? 50;
    final totalMessages = analytics['totalMessages'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colors,
                'Dominant Emotion',
                dominantEmotion.toString().toUpperCase(),
                AppColors.getEmotionColor(dominantEmotion),
                Icons.psychology,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colors,
                'Avg Confidence',
                '${avgConfidence.toStringAsFixed(1)}%',
                colors.accentColor,
                Icons.verified,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colors,
                'Positivity',
                '${positivityRatio.toStringAsFixed(0)}%',
                AppColors.emotionJoy,
                Icons.sentiment_satisfied,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colors,
                'Messages',
                totalMessages.toString(),
                colors.primaryColor,
                Icons.message,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStabilityBar(colors, stabilityScore.toDouble()),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeColors colors,
    String label,
    String value,
    Color valueColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: valueColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: colors.hintColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityBar(ThemeColors colors, double score) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emotional Stability',
                style: TextStyle(
                  color: colors.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: colors.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: colors.hintColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                score >= 70
                    ? AppColors.emotionJoy
                    : score >= 40
                    ? AppColors.emotionSurprise
                    : AppColors.emotionSadness,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionPieChart(ThemeColors colors) {
    final distribution =
        _analyticsData?['emotionDistribution'] as Map<String, dynamic>?;
    if (distribution == null || distribution.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No emotion data yet',
            style: TextStyle(color: colors.hintColor),
          ),
        ),
      );
    }

    final total = distribution.values.fold<int>(
      0,
      (sum, val) => sum + (val as int),
    );
    final sections =
        distribution.entries.map((entry) {
          final percentage = (entry.value as int) / total * 100;
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            color: AppColors.getEmotionColor(entry.key),
            radius: 60,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children:
                distribution.keys.map((emotion) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.getEmotionColor(emotion),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        emotion,
                        style: TextStyle(color: colors.textColor, fontSize: 12),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalHealthProgressChart(ThemeColors colors) {
    final dailyTrend = _analyticsData?['dailyTrend'] as List<dynamic>?;
    if (dailyTrend == null || dailyTrend.length < 2) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, color: colors.hintColor, size: 48),
              const SizedBox(height: 12),
              Text(
                'Keep chatting to see your progress!',
                style: TextStyle(color: colors.hintColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'We need at least 2 days of data',
                style: TextStyle(color: colors.hintColor, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate wellness score: positive emotions vs negative
    final positiveEmotions = ['joy', 'love', 'surprise'];
    final wellnessSpots =
        dailyTrend.asMap().entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          final dominantEmotion =
              (data['dominantEmotion'] ?? 'neutral').toString().toLowerCase();
          final confidence =
              ((data['averageConfidence'] ?? 0.5) * 100).toDouble();

          // Wellness score:
          // Positive emotions = higher score (confidence-based)
          // Negative emotions = lower score
          // Neutral = middle
          double wellnessScore;
          if (positiveEmotions.contains(dominantEmotion)) {
            wellnessScore = 50.0 + (confidence * 0.5);
          } else if (dominantEmotion == 'neutral') {
            wellnessScore = 50.0;
          } else {
            wellnessScore = 50.0 - (confidence * 0.5);
          }

          return FlSpot(entry.key.toDouble(), wellnessScore);
        }).toList();

    // Calculate improvement
    final firstScore = wellnessSpots.first.y;
    final lastScore = wellnessSpots.last.y;
    final improvement = lastScore - firstScore;
    final isImproving = improvement > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Improvement indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isImproving
                      ? AppColors.emotionJoy.withOpacity(0.15)
                      : improvement < 0
                      ? AppColors.emotionSadness.withOpacity(0.15)
                      : colors.hintColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isImproving
                      ? Icons.trending_up
                      : improvement < 0
                      ? Icons.trending_down
                      : Icons.trending_flat,
                  color:
                      isImproving
                          ? AppColors.emotionJoy
                          : improvement < 0
                          ? AppColors.emotionSadness
                          : colors.hintColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isImproving
                      ? 'Great progress! +${improvement.toStringAsFixed(0)}% wellness improvement'
                      : improvement < 0
                      ? 'Hang in there! We\'re here to help'
                      : 'Steady progress - keep going!',
                  style: TextStyle(
                    color:
                        isImproving
                            ? AppColors.emotionJoy
                            : improvement < 0
                            ? AppColors.emotionSadness
                            : colors.hintColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // The chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: colors.hintColor.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        String label;
                        if (value <= 25) {
                          label = 'Struggling';
                        } else if (value <= 50) {
                          label = 'Coping';
                        } else if (value <= 75) {
                          label = 'Good';
                        } else {
                          label = 'Thriving';
                        }
                        return Text(
                          label,
                          style: TextStyle(
                            color: colors.hintColor,
                            fontSize: 9,
                          ),
                        );
                      },
                      interval: 25,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= dailyTrend.length)
                          return const Text('');
                        final data =
                            dailyTrend[value.toInt()] as Map<String, dynamic>;
                        final date = DateTime.parse(data['date']);
                        return Text(
                          DateFormat('M/d').format(date),
                          style: TextStyle(
                            color: colors.hintColor,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: wellnessSpots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.emotionSadness,
                        AppColors.emotionSurprise,
                        AppColors.emotionJoy,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        Color dotColor;
                        if (spot.y <= 35) {
                          dotColor = AppColors.emotionSadness;
                        } else if (spot.y <= 65) {
                          dotColor = AppColors.emotionSurprise;
                        } else {
                          dotColor = AppColors.emotionJoy;
                        }
                        return FlDotCirclePainter(
                          radius: 4,
                          color: dotColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.emotionJoy.withOpacity(0.3),
                          AppColors.emotionJoy.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Struggling', AppColors.emotionSadness),
              _buildLegendItem('Coping', AppColors.emotionSurprise),
              _buildLegendItem('Thriving', AppColors.emotionJoy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }

  Widget _buildMoodTrendChart(ThemeColors colors) {
    final dailyTrend = _analyticsData?['dailyTrend'] as List<dynamic>?;
    if (dailyTrend == null || dailyTrend.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Not enough data for trend analysis',
            style: TextStyle(color: colors.hintColor),
          ),
        ),
      );
    }

    final spots =
        dailyTrend.asMap().entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;
          final confidence = (data['averageConfidence'] ?? 0.5) * 100;
          return FlSpot(entry.key.toDouble(), confidence);
        }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine:
                  (value) => FlLine(
                    color: colors.hintColor.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget:
                      (value, meta) => Text(
                        '${value.toInt()}%',
                        style: TextStyle(color: colors.hintColor, fontSize: 10),
                      ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= dailyTrend.length)
                      return const Text('');
                    final data =
                        dailyTrend[value.toInt()] as Map<String, dynamic>;
                    final date = DateTime.parse(data['date']);
                    return Text(
                      DateFormat('M/d').format(date),
                      style: TextStyle(color: colors.hintColor, fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: colors.accentColor,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: colors.accentColor.withOpacity(0.1),
                ),
              ),
            ],
            minY: 0,
            maxY: 100,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentEmotions(ThemeColors colors) {
    final recentEmotions = _analyticsData?['recentEmotions'] as List<dynamic>?;
    if (recentEmotions == null || recentEmotions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No recent emotions detected',
            style: TextStyle(color: colors.hintColor),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentEmotions.length,
        separatorBuilder:
            (_, __) =>
                Divider(height: 1, color: colors.hintColor.withOpacity(0.2)),
        itemBuilder: (context, index) {
          final emotion = recentEmotions[index] as Map<String, dynamic>;
          final emotionName = emotion['emotion'] ?? 'neutral';
          final confidence = ((emotion['confidence'] ?? 0.0) * 100)
              .toStringAsFixed(0);
          final timestamp = DateTime.tryParse(emotion['timestamp'] ?? '');
          final timeStr =
              timestamp != null
                  ? DateFormat('MMM d, h:mm a').format(timestamp)
                  : '';

          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.getEmotionColor(emotionName).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getEmotionEmoji(emotionName),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Text(
              emotionName.toString().toUpperCase(),
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              timeStr,
              style: TextStyle(color: colors.hintColor, fontSize: 12),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.getEmotionColor(emotionName),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$confidence%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressTab(ThemeColors colors) {
    final progress = _progressData;
    if (progress == null) {
      return Center(
        child: Text(
          'Loading progress data...',
          style: TextStyle(color: colors.hintColor),
        ),
      );
    }

    final goals = progress['goals'] as Map<String, dynamic>?;
    final weeklyMood = progress['weeklyMood'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly Mood Score
            _buildMoodScoreCard(colors, weeklyMood),
            const SizedBox(height: 24),

            // Goals Progress
            Text(
              'Goals Progress',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildGoalsProgress(colors, goals),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodScoreCard(
    ThemeColors colors,
    Map<String, dynamic>? weeklyMood,
  ) {
    final score = weeklyMood?['score'] ?? 50;
    final totalMessages = weeklyMood?['totalMessages'] ?? 0;

    Color scoreColor;
    String moodLabel;
    if (score >= 70) {
      scoreColor = AppColors.emotionJoy;
      moodLabel = 'Great!';
    } else if (score >= 50) {
      scoreColor = AppColors.emotionSurprise;
      moodLabel = 'Good';
    } else if (score >= 30) {
      scoreColor = AppColors.emotionNeutral;
      moodLabel = 'Okay';
    } else {
      scoreColor = AppColors.emotionSadness;
      moodLabel = 'Needs attention';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.8), scoreColor.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Mood Score',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  moodLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  '/100',
                  style: TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalMessages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'messages this week',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsProgress(ThemeColors colors, Map<String, dynamic>? goals) {
    if (goals == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No goals set yet',
            style: TextStyle(color: colors.hintColor),
          ),
        ),
      );
    }

    // final total = goals['total'] ?? 0;
    final active = goals['active'] ?? 0;
    final completed = goals['completed'] ?? 0;
    final completionRate = (goals['completionRate'] ?? 0.0) * 100;
    final goalList = goals['list'] as List<dynamic>? ?? [];

    return Column(
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                colors,
                'Active',
                active.toString(),
                colors.accentColor,
                Icons.flag,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colors,
                'Completed',
                completed.toString(),
                AppColors.emotionJoy,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                colors,
                'Rate',
                '${completionRate.toStringAsFixed(0)}%',
                AppColors.emotionSurprise,
                Icons.trending_up,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Goal list
        if (goalList.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: goalList.length,
              separatorBuilder:
                  (_, __) => Divider(
                    height: 1,
                    color: colors.hintColor.withOpacity(0.2),
                  ),
              itemBuilder: (context, index) {
                final goal = goalList[index] as Map<String, dynamic>;
                final status = goal['status'] ?? 'active';
                final progress = (goal['progress'] ?? 0) / 100;

                return ListTile(
                  leading: Icon(
                    status == 'completed'
                        ? Icons.check_circle
                        : status == 'paused'
                        ? Icons.pause_circle
                        : Icons.flag,
                    color:
                        status == 'completed'
                            ? AppColors.emotionJoy
                            : status == 'paused'
                            ? colors.hintColor
                            : colors.accentColor,
                  ),
                  title: Text(
                    goal['title'] ?? 'Untitled Goal',
                    style: TextStyle(
                      color: colors.textColor,
                      decoration:
                          status == 'completed'
                              ? TextDecoration.lineThrough
                              : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['category'] ?? 'other',
                        style: TextStyle(color: colors.hintColor, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: colors.hintColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(
                            status == 'completed'
                                ? AppColors.emotionJoy
                                : colors.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: colors.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return '😊';
      case 'sadness':
        return '😢';
      case 'anger':
        return '😠';
      case 'fear':
        return '😨';
      case 'love':
        return '❤️';
      case 'surprise':
        return '😮';
      case 'disgust':
        return '🤢';
      default:
        return '😐';
    }
  }
}
