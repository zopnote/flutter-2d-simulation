import 'package:flutter/material.dart';

import 'edge.dart';
import 'node.dart';

class DependGraphPainter extends CustomPainter {
  final Size widgetSize;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final bool paintVelocity;
  final Color focus;
  final Color idle;
  final double strokeWidth;
  final double circleRadius;
  final double velocityLengthFactor;
  final BuildContext context;
  DependGraphPainter(
      this.context,
      this.widgetSize,
      {
        super.repaint,
        required this.nodes,
        required this.edges,
        required this.paintVelocity,
        required this.focus,
        required this.idle,
        required this.strokeWidth,
        required this.circleRadius,
        required this.velocityLengthFactor,
      });

  @override
  void paint(Canvas canvas, Size size) {

    Offset center = Offset(widgetSize.width/2, widgetSize.height/2);

    for (GraphNode node in nodes) {
      final Offset point = Offset(center.dx+node.position.dx, center.dy+node.position.dy);
      final bool shouldFocus = node.isDragged || node.isFocus;
      final Color finalFocusColor = node.highlightedNodeColor != null ? node.highlightedNodeColor! : focus;
      final Color finalIdleColor = node.defaultNodeColor != null ? node.defaultNodeColor! : idle;
      final double finalCircleRadius = node.nodeRadius != null ? node.nodeRadius! : circleRadius;
      final Paint paint = Paint()..color = shouldFocus ? finalFocusColor : finalIdleColor;
      canvas.drawCircle(point, shouldFocus ? finalCircleRadius * 1.2 : finalCircleRadius, paint);

      if (paintVelocity) {
        Offset velocity = Offset(center.dx+node.position.dx+(node.velocity.dx*velocityLengthFactor), center.dy+node.position.dy+(node.velocity.dy*velocityLengthFactor));
        canvas.drawLine(point, velocity, paint);
        canvas.drawCircle(velocity, finalCircleRadius*0.4, paint);
      }

    }
    for (GraphEdge edge in edges) {
      bool focused = false;
      if (edge.source.isDragged || edge.target.isDragged || edge.target.isFocus || edge.source.isFocus) {
        focused = true;
      }
      canvas.drawLine(center+edge.source.position, center+edge.target.position, Paint()..color = focused ? focus : idle ..strokeWidth = strokeWidth);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}