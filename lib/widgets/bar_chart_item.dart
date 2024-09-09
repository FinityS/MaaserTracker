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
              // Calculate the width of the green bar based on the max width
              double barWidth = (value / maxValue) * constraints.maxWidth;
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
          Text("\$$value / \$$maxValue"),
        ],
      ),
    );
  }
}