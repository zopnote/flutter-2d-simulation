import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/src/scheduler/ticker.dart';

void main() => runApp(const SceneContainer());

final class SceneContainer extends StatelessWidget {
  const SceneContainer({super.key});
  @override
  Widget build(BuildContext context) {
    /**
     * [screenWidth], [screenHeight] and [centerOffset] have to be initialized
     * before [Ball] get's constructed.
     */
    screenWidth = MediaQuery.sizeOf(context).width;
    screenHeight = MediaQuery.sizeOf(context).height;
    centerOffset = Offset(0.45 * screenWidth, 0.45 * screenHeight);
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(strokeAlign: 1, color: Colors.black, width: 1),
          ),
          height: screenHeight * 0.95,
          width: screenWidth * 0.95,
          child: const Scene(),
        ),
      ),
    );
  }
}

final class Ball {
  late Offset position;
  late Offset v;
  Ball.random() {
    position = Offset(
      screenWidth * Random().nextDouble(),
      screenHeight * Random().nextDouble(),
    );
    v = position - centerOffset;
  }
}

late double screenWidth;
late double screenHeight;
late Offset centerOffset;

final class Scene extends StatefulWidget {
  const Scene({super.key});

  @override
  State<Scene> createState() => _SceneState();
}

class _SceneState extends State<Scene>
    implements SingleTickerProviderStateMixin<Scene> {
  final List<Ball> balls = [];
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 1; i++) {
      balls.add(Ball.random());
    }
    _ticker = createTicker(
      (elapsed) => setState(() {
        final double deltaTime = (elapsed - _lastElapsed).inMicroseconds / 1e6;
        _lastElapsed = elapsed;
        onTick(deltaTime);
      }),
    );
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    isComplex: true,
    willChange: true,
    painter: ScenePainter(
      width: screenWidth,
      height: screenHeight,
      balls: balls,
    ),
  );

  void onTick(double deltaTime) {
    return;
    for (Ball ball in balls) {
      ball.position += ball.v * 0.5 * deltaTime;
      ball.v *= 0.99;
      final Offset deltaBallVec = (ball.v + ball.position) - centerOffset;
      final Offset deltaBallPos = ball.position - centerOffset;

      double vecLen(Offset vec) {
        return sqrt(pow(vec.dy, 2) + pow(vec.dx, 2));
      }
      if (vecLen(deltaBallPos) <= vecLen(deltaBallVec)) {
        if (ball.position.dx < 0) {
          ball.v = Offset(ball.v.dx * -1, ball.v.dy);
        } else if (ball.position.dx > screenWidth * 0.95) {
          ball.v = Offset(ball.v.dx * -1, ball.v.dy);
        }
        if (ball.position.dy < 0) {
          ball.v = Offset(ball.v.dx, ball.v.dy * -1);
        } else if (ball.position.dy > screenHeight * 0.95) {
          ball.v = Offset(ball.v.dx, ball.v.dy * -1);
        }
      }
    }
  }
}

final class ScenePainter extends CustomPainter {
  final double width;
  final double height;
  final Iterable<Ball> balls;
  const ScenePainter({
    required this.height,
    required this.width,
    required this.balls,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = Colors.black;
    for (Ball ball in balls) {
      canvas.drawCircle(ball.position, 10, paint);

      canvas.drawCircle((ball.v * 0.3) + ball.position, 2, paint);
      canvas.drawLine((ball.v * 0.3) + ball.position, ball.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
