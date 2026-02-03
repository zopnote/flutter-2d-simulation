
import 'node.dart';

class GraphEdge {
  final GraphNode source;
  final GraphNode target;
  final double strength;
  final double length;
  GraphEdge({
    required this.source,
    required this.target,
    this.strength = 0.005,
    this.length = 140
  });
}