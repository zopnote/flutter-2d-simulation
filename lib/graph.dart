
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'edge.dart';
import 'node.dart';
import 'painter.dart';
import 'tick.dart';


final class DependGraph extends StatefulWidget {

  /// A list of [GraphNode] instances representing all the nodes of the graph.
  /// These nodes interact via attraction and repulsion forces and can be
  /// connected through [GraphEdge] instances.
  final List<GraphNode> nodes;

  /// A list of [GraphEdge] instances representing the edges of the graph.
  /// Edges connect two [GraphNode]s and influence their behavior based on length and strength.
  final List<GraphEdge> edges;

  /// The maximum influence range of a node.
  /// Within this range, attraction or repulsion forces act between nodes.
  final double nodeInfluenceRange;

  /// A friction factor that dampens the velocity of nodes over time.
  /// Helps stabilize the simulation and prevent nodes from accelerating indefinitely.
  final double velocityFriction;

  /// Determines whether the velocity vectors of nodes should be visualized.
  /// If `true`, arrows or lines are drawn to show the current movement direction and speed of nodes.
  final bool showVelocityVector;

  /// A scaling factor used to increase or decrease the size of the displayed velocity vectors.
  /// Helps adjust the visual representation of vectors relative to the simulation.
  final double velocityScaleFactor;

  /// A factor that controls the overall speed of the simulation.
  /// Higher values accelerate the simulation, while lower values slow it down.
  final double simulationSpeed;

  /// If `true`, creates a gravitational center at the middle of the simulation,
  /// pulling nodes inward to create a more stable graph structure.
  final bool center;

  /// The radius within which a node is considered to be "centered."
  /// Once a node is within this radius, the central gravitation stops acting on it.
  final double centerSatisfactionRadius;

  /// A factor that determines the strength of the central gravitational pull.
  /// Higher values result in stronger attraction towards the center.
  final double centerGravitationFactor;

  /// Determines whether rotation is enabled for the graph.
  /// When `true`, nodes and edges can slightly rotate to simulate a dynamic effect.
  final bool enableRotation;

  /// The speed at which the graph rotates when rotation is enabled.
  /// Controls the rate of rotation for nodes and edges in the graph.
  final double rotationSpeed;

  /// The ticker function used to drive the animation of the graph.
  /// It updates the state of the simulation and governs how nodes and edges move and interact.
  final DependGraphTicker animationTicker;

  /// The color used for highlighting nodes when they are focused or interacted with.
  /// Helps differentiate active nodes from inactive ones.
  final Color highlightedNodeColor;

  /// The default color used for nodes when they are not being interacted with.
  /// Defines the standard visual appearance of nodes in the graph.
  final Color defaultNodeColor;

  /// The width of the edges connecting nodes in the graph.
  /// This determines the thickness of the lines drawn between nodes.
  final double edgeStrokeWidth;

  /// The radius of each node in the graph.
  /// Controls the size of the circular representation of nodes.
  final double nodeRadius;

  const DependGraph({
    super.key,

    this.velocityFriction = 0.2,
    this.showVelocityVector = false,
    this.velocityScaleFactor = 14,
    this.simulationSpeed = 1,
    this.rotationSpeed = 1,
    this.center = true,
    this.centerSatisfactionRadius = 300,
    this.enableRotation = false,
    this.animationTicker = DependGraphTick.onTick,
    this.centerGravitationFactor = 1,

    required this.nodes,
    this.nodeRadius = 8,
    this.nodeInfluenceRange = 120,
    this.highlightedNodeColor = const Color(0xFFFFFFFF),
    this.defaultNodeColor = const Color(0xFF9B9B9B),

    this.edges = const [],
    this.edgeStrokeWidth = 1.2,

  });

  @override
  State<DependGraph> createState() => _DependGraphState();
}

final class _DependGraphState extends State<DependGraph> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<GraphEdge> edges = [];
  final List<GraphNode> nodes = [];

  void refresh() => setState(() {});

  @override
  void initState() {
    nodes.addAll(widget.nodes);
    edges.addAll(widget.edges);
    _ticker = createTicker((elapsed) => widget.animationTicker(
        elapsed: elapsed,
        refresh: refresh,
        widget: widget,
        nodes: nodes,
        edges: edges
    ))..start();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        List<Widget> widgets = [];
        for (GraphNode node in nodes) {
          if (node.backgroundWidget != null) widgets.add(
              node.backgroundWidget!(
                  Offset(
                      node.position.dx + constraints.maxWidth / 2,
                      node.position.dy + constraints.maxHeight / 2
                  ),
                  node
              )
          );
        }
        widgets.add(
            MouseRegion(
              onHover: (event) =>
                  _onHover(event, context,
                      Size(constraints.maxWidth, constraints.minHeight)),
              child: GestureDetector(
                onPanStart: (details) =>
                    _onPanStart(details, context,
                        Size(constraints.maxWidth, constraints.minHeight)),
                onPanUpdate: (details) =>
                    _onPanUpdate(details, context,
                        Size(constraints.maxWidth, constraints.minHeight)),
                onPanEnd: (details) => _onPanEnd(details),
                onTapUp: (details) =>
                    _onTap(details, context,
                        Size(constraints.maxWidth, constraints.minHeight)),
                child: CustomPaint(
                  painter: DependGraphPainter(
                      circleRadius: widget.nodeRadius,
                      focus: widget.highlightedNodeColor,
                      idle: widget.defaultNodeColor,
                      strokeWidth: widget.edgeStrokeWidth,
                      nodes: nodes,
                      edges: edges,
                      paintVelocity: widget.showVelocityVector,
                      velocityLengthFactor: widget.velocityScaleFactor,
                      context,
                      Size(constraints.maxWidth, constraints.minHeight)
                  ),
                  isComplex: true,
                  child: SizedBox(height: constraints.minHeight,
                      width: constraints.maxWidth),
                ),
              ),
            )
        );
        for (GraphNode node in nodes) {
          if (node.foregroundWidget != null) widgets.add(
              node.foregroundWidget!(
                  Offset(
                      node.position.dx + constraints.maxWidth / 2,
                      node.position.dy + constraints.maxHeight / 2
                  ),
                  node
              )
          );
        }

        return LimitedBox(
          maxHeight: constraints.maxHeight,
          maxWidth: constraints.maxWidth,
          child: Stack(
            children: widgets,
          ),
        );
      },
    );
  }

  void _onHover(PointerHoverEvent event, BuildContext context, Size widgetSize) {
    Offset touchPosition = event.localPosition - Offset(widgetSize.width/2, widgetSize.height/2);
    for (var node in nodes) {
      setState(() {
        node.isFocus = node.distance(touchPosition) < (node.nodeRadius != null ? node.nodeRadius! * 1.3 : widget.nodeRadius * 1.3);
      });
    }
  }

  void _onTap(TapUpDetails details, BuildContext context, Size widgetSize) {
    Offset touchPosition = details.localPosition - Offset(widgetSize.width/2, widgetSize.height/2);
    for (var node in nodes) {
      if (node.distance(touchPosition) < (node.nodeRadius != null ? node.nodeRadius! * 1.4 : widget.nodeRadius * 1.4) && node.isTouchable) node.click();
    }
  }

  void _onPanStart(DragStartDetails details, BuildContext context, Size widgetSize) {
    Offset touchPosition = details.localPosition - Offset(widgetSize.width/2, widgetSize.height/2);
    for (var node in nodes) {
      setState(() {
        node.isDragged = node.distance(touchPosition) < (node.nodeRadius != null ? node.nodeRadius! * 1.4 : widget.nodeRadius * 1.4) && node.isTouchable;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext context, Size widgetSize) {
    Offset touchPosition = details.localPosition - Offset(widgetSize.width/2, widgetSize.height/2);
    for (var node in nodes) {
      if (node.isDragged) setState(() {
        node.position = touchPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    for (var node in nodes) {
      if (node.isDragged) setState(() {
        node.isDragged = false;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}