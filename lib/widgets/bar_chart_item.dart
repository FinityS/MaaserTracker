import 'package:flutter/material.dart';



class BarChartItem extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;

  const BarChartItem({super.key, required this.label, required this.value, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Changed: safely calculate barWidth avoiding division by zero.
              double barWidth = maxValue > 0 ? (value / maxValue) * constraints.maxWidth : 0;
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Container(
                    width: barWidth,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          // Changed: safely display values to prevent NaN in the label.
          Text("\$${maxValue > 0 ? value.toStringAsFixed(2) : '0.00'} / \$${maxValue > 0 ? maxValue.toStringAsFixed(2) : '0.00'}"),
        ],
      ),
    );
  }
}
