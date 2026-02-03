import 'dart:math';

import 'package:flutter/material.dart';

import 'edge.dart';

typedef NodeWidgetBuilder = Widget Function(Offset offset, GraphNode node);

typedef NodeCallback = void Function(GraphNode node);

/// A [GraphNode] represents an entity in a [DependGraph] simulation.
///
/// Each [GraphNode] has a position, velocity, and optional visual representation.
/// Nodes interact with each other through forces like attraction and repulsion
/// controlled by methods such as [attract], [repulse], and [slow].
///
/// [GraphNode] instances can be connected by [GraphEdge]s, which represent relationships
/// or interactions between nodes.
class GraphNode {

  /// The current location relative to a center 0, 0 of this node in the 2D space.
  Offset position;

  /// True when this node is currently being dragged in the [DependGraph] simulation.
  bool isDragged = false;

  /// True when this node is focused (hovered or dragged) within the simulation.
  bool isFocus = false;

  /// Determines if this node is interactive (can respond to touches).
  /// If [false], the node cannot be interacted with by the user.
  bool _touchable;

  /// The velocity of this node, representing its direction and speed.
  /// It is updated during the simulation, influenced by attraction, repulsion, and other forces.
  Offset velocity = const Offset(0, 0);

  /// A multiplier that influences the effect this node has on other nodes,
  /// such as attraction or repulsion strength.
  double impact;

  /// Optional color for the node in its default state.
  /// This color is also used to affect the appearance of connected edges.
  Color? defaultNodeColor;

  /// Optional color for the node when it is highlighted (e.g., when focused).
  /// This color is also used to affect the appearance of connected edges.
  Color? highlightedNodeColor;

  /// The radius of the node's visual representation. If not specified,
  /// [DependGraph] will use its default node radius.
  double? nodeRadius;

  /// Callback function triggered when the node is clicked.
  NodeCallback? onClick;

  /// Optional background widget for this node, which can be rendered behind the node.
  NodeWidgetBuilder? backgroundWidget;

  /// Optional foreground widget for this node, which can be rendered above the node.
  NodeWidgetBuilder? foregroundWidget;

  /// Private constructor to initialize a [GraphNode] with specific properties.
  GraphNode._internal({
    required this.position,
    this.impact = 1,
    this.defaultNodeColor,
    this.highlightedNodeColor,
    this.onClick,
    this.backgroundWidget,
    this.foregroundWidget,
    this.nodeRadius,
    bool touchable = true
  }) : _touchable = touchable;


  /// Factory method to create a [GraphNode] positioned in a circular pattern
  /// around the origin, based on a radius and angle.
  ///
  /// [minDistance] and [maxDistance] determine the distance from the origin,
  /// and [angleDegree] specifies the angle of placement.
  factory GraphNode.spawn({
    required double minDistance,
    required double maxDistance,
    required double radiusFactor,
    required double angleDegree,
    double impact = 1,
    NodeCallback? onClick,
    NodeWidgetBuilder? backgroundWidget,
    NodeWidgetBuilder? foregroundWidget,
    Color? highlightedNodeColor,
    Color? defaultNodeColor,
    bool touchable = true,
    double? nodeRadius
  }) {
    final double radius = (radiusFactor * (maxDistance - minDistance)) +
        minDistance;
    final double radiant = angleDegree / 180 * pi;
    return GraphNode._internal(
        position: Offset(
            sin(radiant) * radius,
            cos(radiant) * radius
        ),
        impact: impact,
        highlightedNodeColor: highlightedNodeColor,
        defaultNodeColor: defaultNodeColor,
        onClick: onClick,
        nodeRadius: nodeRadius,
        backgroundWidget: backgroundWidget,
        foregroundWidget: foregroundWidget,
        touchable: touchable
    );
  }


  /// Factory method to create a randomly positioned [GraphNode] within a
  /// circular area determined by [minDistance] and [maxDistance].
  factory GraphNode.drop({
    required double minDistance,
    required double maxDistance,
    double impact = 1,
    NodeWidgetBuilder? backgroundWidget,
    NodeWidgetBuilder? foregroundWidget,
    Color? highlightedNodeColor,
    Color? defaultNodeColor,
    NodeCallback? onClick,
    bool touchable = true,
    double? nodeRadius
  }) {
    final double radiusFactor = Random().nextDouble();
    final double angleDegree = Random().nextDouble() * 360;
    final double radius = (radiusFactor * (maxDistance - minDistance)) +
        minDistance;
    final double radiant = angleDegree / 180 * pi;
    return GraphNode._internal(
        position: Offset(
            sin(radiant) * radius,
            cos(radiant) * radius
        ),
        impact: impact,
        highlightedNodeColor: highlightedNodeColor,
        defaultNodeColor: defaultNodeColor,
        onClick: onClick,
        nodeRadius: nodeRadius,
        backgroundWidget: backgroundWidget,
        foregroundWidget: foregroundWidget,
        touchable: touchable
    );
  }

  /// Whether the node is interactable (i.e., can respond to touches).
  bool get isTouchable => foregroundWidget == null || _touchable;


  /// Whether the node has a visual widget representation (either background or foreground).
  bool get hasWidget => backgroundWidget != null || foregroundWidget != null;


  /// Calculates the distance between this node's position and another [Offset].
  double distance(Offset other) => sqrt(pow(position.dx -other.dx, 2) + pow(position.dy-other.dy, 2));


  /// Applies an attractive force towards [cause] (another node), adjusted by [GraphEdge].
  /// The force depends on the distance and strength of the edge.
  void attract(GraphNode cause, GraphEdge edge) {
    Offset direction = cause.position - position;
    double distance = direction.distance;
    double force = (distance - edge.length) * edge.strength;
    velocity += direction / distance * force;
  }


  /// Repels this node from another node or position, applying a force based on [factor].
  /// Either [cause] (another node) or [offset] must be provided as the repulsion source.
  void repulse(double factor, {GraphNode? cause, Offset? offset}) {
    if (offset == null && cause == null) {
      print('You must set at least one of offset or cause.');
    }
    if (offset != null) {
      Offset direction = offset - position;
      double length = direction.distance;
      if (length == 0) return;
      velocity += (direction / length) * -factor;
      return;
    }
    if (cause != null) {
      Offset direction = cause.position - position;
      double length = direction.distance;
      if (length == 0) return;
      velocity += (direction / length * cause.impact) * -factor;
      return;
    }
  }


  /// Reduces the node's velocity by applying the passed [factor].
  void slow(double factor) {
    velocity *= (1-factor);
  }


  /// Triggers the [onClick] callback if defined and returns `true` if the callback was executed.
  bool click() {
    if (onClick != null) onClick!(this);
    return onClick != null;
  }


  /// Creates a new [GraphEdge] between this node and [other].
  GraphEdge connect(GraphNode other) => GraphEdge(source: this, target: other);
}