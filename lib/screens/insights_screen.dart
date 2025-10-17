import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final insights = provider.generateMonthlyInsights();
          final anomalies = provider.detectAnomalies();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Monthly Summary',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          insights.getSummaryText(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Category Breakdown Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pie_chart,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Category Breakdown',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (insights.categoryBreakdown.isNotEmpty) ...[
                          ...insights.categoryBreakdown.entries.map((entry) {
                            final percentage =
                                (entry.value / insights.totalSpent) * 100;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(entry.key),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: Colors.grey[300],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '₹${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ] else ...[
                          const Text('No category data available'),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Anomaly Detection Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Anomaly Detection',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (anomalies.isNotEmpty) ...[
                          ...anomalies.map((anomaly) {
                            Color severityColor;
                            IconData severityIcon;
                            switch (anomaly.severity) {
                              case 'high':
                                severityColor = Colors.red;
                                severityIcon = Icons.error;
                                break;
                              case 'medium':
                                severityColor = Colors.orange;
                                severityIcon = Icons.warning;
                                break;
                              case 'low':
                                severityColor = Colors.blue;
                                severityIcon = Icons.info;
                                break;
                              default:
                                severityColor = Colors.grey;
                                severityIcon = Icons.info;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.1),
                                border: Border.all(
                                    color: severityColor.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(severityIcon, color: severityColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          anomaly.description,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: severityColor,
                                          ),
                                        ),
                                        Text(
                                          '₹${anomaly.amount.toStringAsFixed(2)} on ${_formatDate(anomaly.date)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'No anomalies detected in your spending patterns',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Spending Trends Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.trending_up,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Spending Trends',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTrendRow(
                          'Month-over-Month Change',
                          insights.spendingChange,
                          '${insights.spendingChange > 0 ? '+' : ''}${insights.spendingChange.toStringAsFixed(1)}%',
                        ),
                        _buildTrendRow(
                          'Daily Average',
                          null,
                          '₹${insights.dailyAverage.toStringAsFixed(2)}',
                        ),
                        _buildTrendRow(
                          'Tiffin Spending',
                          null,
                          '₹${insights.tiffinSpent.toStringAsFixed(2)} (${insights.tiffinDays} days)',
                        ),
                        _buildTrendRow(
                          'Transaction Count',
                          null,
                          '${insights.transactionCount} transactions',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendRow(String label, double? value, String displayValue) {
    Color? color;
    if (value != null) {
      color = value > 0 ? Colors.red : Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            displayValue,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
