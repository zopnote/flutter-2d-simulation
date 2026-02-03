import 'dart:math';

import 'package:flutter/material.dart';

import 'edge.dart';
import 'graph.dart';
import 'node.dart';


typedef DependGraphTicker = void Function({
required DependGraph widget,
required Duration elapsed,
required List<GraphNode> nodes,
required List<GraphEdge> edges,
required VoidCallback refresh,
});

abstract final class DependGraphTick {
  static Duration lastElapsed = Duration(milliseconds: 0);
  static void onTick({
    required DependGraph widget,
    required Duration elapsed,
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
    required VoidCallback refresh,
  }) {
    final double deltaTime = (elapsed.inMilliseconds - lastElapsed.inMilliseconds) / 40;
    lastElapsed = elapsed;
    for (GraphNode node in nodes) {
      if (node.isDragged) continue;

      for (GraphNode index in nodes) {
        final double distance = node.distance(index.position);
        if (!(distance > widget.nodeInfluenceRange) && node != index) {
          final double distanceFactor = (1 - (distance / widget.nodeInfluenceRange));
          node.repulse(cause: index, distanceFactor);
        }
      }

      if (widget.center) {
        final double distance = node.distance(const Offset(0, 0));
        if (!(distance < widget.centerSatisfactionRadius)) {
          final double distanceFactor = (1 - (distance / widget.centerSatisfactionRadius));
          node.repulse(offset: const Offset(0, 0), distanceFactor*widget.centerGravitationFactor);
        }
      }
      if (widget.enableRotation) {
        bool stop = false;
        for (GraphNode other in nodes) {
          if (other.isFocus) {
            stop = true;
          }
        }
        if (!stop) {
          Offset directionToCenter = node.position - const Offset(0, 0);
          double angle = (0.0004 * widget.rotationSpeed) * deltaTime;
          double sinAngle = sin(angle);
          double cosAngle = cos(angle);

          double rotatedX = directionToCenter.dx * cosAngle - directionToCenter.dy * sinAngle;
          double rotatedY = directionToCenter.dx * sinAngle + directionToCenter.dy * cosAngle;
          node.position = Offset(rotatedX, rotatedY);
        }
      }

      node.position += (node.velocity * widget.simulationSpeed) * deltaTime;

      for (var edge in edges) {
        if (edge.source == node) {
          node.attract(edge.target, edge);
        }
        if (edge.target == node) {
          node.attract(edge.source, edge);
        }
      }
    }
    refresh();
    for (GraphNode node in nodes) {
      if (node.isDragged) continue;
      node.slow(widget.velocityFriction);
    }
  }
}
