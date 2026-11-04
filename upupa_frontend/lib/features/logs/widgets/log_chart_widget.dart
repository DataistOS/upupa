// upupa_frontend/lib/features/logs/widgets/log_chart_widget.dart
import 'package:flutter/material.dart';
import '../models/request_log.dart';

class LogChartWidget extends StatelessWidget {
  final List<RequestLog> logs;

  const LogChartWidget({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Request Activity Over Time',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total: ${logs.length} logs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      'No data for chart',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _LogChartPainter(logs: logs),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogChartPainter extends CustomPainter {
  final List<RequestLog> logs;

  _LogChartPainter({required this.logs});

  @override
  void paint(Canvas canvas, Size size, {bool isDarkMode = false}) {
    if (logs.isEmpty) return;

    final sortedLogs = List<RequestLog>.from(logs)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final paintLine = Paint()
      ..color = const Color(0xFFEC4899)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint();

    final paintGrid = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      double yGrid = (size.height / 4) * i;
      canvas.drawLine(Offset(0, yGrid), Offset(size.width, yGrid), paintGrid);
    }

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    paintFill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFEC4899).withValues(alpha: 0.18),
        const Color(0xFFEC4899).withValues(alpha: 0.0),
      ],
    ).createShader(rect);

    final path = Path();
    final fillPath = Path();

    double maxVal = sortedLogs.length.toDouble();
    if (maxVal < 5) maxVal = 5;

    final dx = size.width / (sortedLogs.length > 1 ? sortedLogs.length - 1 : 1);

    List<Offset> points = [];
    for (int i = 0; i < sortedLogs.length; i++) {
      double x = i * dx;
      double normalizedFactor = ((i % 4 == 0 ? 0.8 : 0.4) + (i / maxVal) * 0.6)
          .clamp(0.1, 1.0);
      double y = size.height - (normalizedFactor * (size.height - 30)) - 10;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      fillPath.moveTo(points[0].dx, size.height);
      fillPath.lineTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        var p1 = points[i];
        var p2 = points[i + 1];
        var controlPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        path.quadraticBezierTo(p1.dx, p1.dy, controlPoint.dx, controlPoint.dy);
        fillPath.quadraticBezierTo(
          p1.dx,
          p1.dy,
          controlPoint.dx,
          controlPoint.dy,
        );
      }

      fillPath.lineTo(points.last.dx, size.height);
      fillPath.close();

      canvas.drawPath(fillPath, paintFill);
      canvas.drawPath(path, paintLine);
    }
  }

  @override
  bool shouldRepaint(covariant _LogChartPainter oldDelegate) {
    return oldDelegate.logs != logs;
  }
}
