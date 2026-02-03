import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const SceneContainer());

final class SceneContainer extends StatelessWidget {
  const SceneContainer({super.key});
  @override
  Widget build(BuildContext context) {
    /**
     * [screenWidth], [screenHeight] and [centerOffset] have to be initialized
     * before [Ball] get's constructed.
     */
    sceneWidth = MediaQuery.sizeOf(context).width;
    sceneHeight = MediaQuery.sizeOf(context).height;
    centerOffset = Offset(0.455 * sceneWidth, 0.455 * sceneHeight);
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(strokeAlign: 1, color: Colors.black, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          height: sceneHeight * 0.95,
          width: sceneWidth * 0.95,
          child: const Scene(),
        ),
      ),
    );
  }
}

final class Ball {
  late Offset position;
  late Offset direction;
  final double spawnRadius = sceneWidth * 0.1;
  Ball.random() {
    final double radiant = 2 * pi * Random().nextDouble();
    position = centerOffset;
    direction = Offset.zero;
    /// TODO: Punkte auf einem Kreis um das Zentrum (#2)
    position += Offset(spawnRadius * cos(radiant), spawnRadius * sin(radiant));

    /// TODO: Ein Vektor als Direktion und kontinuierliche Bewegung (#3)
    direction = Offset(sceneWidth * Random().nextDouble(), sceneHeight * Random().nextDouble());
  }
}

late double sceneWidth;
late double sceneHeight;
late Offset centerOffset;

final class Scene extends StatefulWidget {
  const Scene({super.key});

  @override
  State<Scene> createState() => _SceneState();
}

class _SceneState extends State<Scene>
    implements SingleTickerProviderStateMixin<Scene> {

  final List<Ball> balls = [];
  @override
  Widget build(BuildContext context) => CustomPaint(
    isComplex: true,
    willChange: true,
    painter: ScenePainter(
      width: sceneWidth,
      height: sceneHeight,
      balls: balls,
    ),
  );

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);


  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();

    /// TODO: Menge der Bälle innerhalb der Simulation (#1)
    const int ballsCount = 5;
    for (int i = 0; i < ballsCount; i++) {
      balls.add(Ball.random());
    }
    /**
     * Scheduler simulation tick loop. [deltaTime] in seconds.
     */
    _ticker = createTicker(
      (elapsed) => setState(() {
        final double deltaTime = (elapsed - _lastElapsed).inMicroseconds / 1e6;
        _lastElapsed = elapsed;
        onTick(deltaTime);
      }),
    );
    _ticker.start();
  }


  void onTick(double deltaTime) {
    for (Ball ball in balls) {
      /// TODO: Aufsummierung eines Teils des Vektors zur Bewegungssimulation (#4)
      ball.position += ball.direction * 0.2 * deltaTime;

      /**
       * Distance between the center and the position of the ball
       * as well as the distance between the center and the position of the
       * vector to determine if the vector has to be inverted to come
       * back in the scene from out-of-bounds.
       */
      final Offset deltaBallVec = (ball.direction + ball.position) - centerOffset;
      final Offset deltaBallPos = ball.position - centerOffset;

      /// TODO: Abstand zwischen zwei Punkten im Raum (#5)
      double vecLen(Offset vec) {
        return sqrt(pow(vec.dy, 2) + pow(vec.dx, 2));
      }

      /// TODO: Invertierung eines Vektors zur Simulation von Abstoßungsprozessen (#6)
      if (vecLen(deltaBallPos) <= vecLen(deltaBallVec)) {
        const double ballRadius = 10.0;
        final double minX = ballRadius;
        final double maxX = sceneWidth * 0.95 - ballRadius;
        final double minY = ballRadius;
        final double maxY = sceneHeight * 0.95 - ballRadius;

        /**
         * On the left and right sides, the vector will be inverted on the opposite
         * side, therefore, only the x-coordinate gets inverted around the y-axis.
         */
        if (ball.position.dx <= minX) {
          ball.position = Offset(minX, ball.position.dy);
          ball.direction = Offset(-ball.direction.dx, ball.direction.dy);
        } else if (ball.position.dx >= maxX) {
          ball.position = Offset(maxX, ball.position.dy);
          ball.direction = Offset(-ball.direction.dx, ball.direction.dy);
        }
        /**
         * On the bottom and top, the vector will be inverted on the opposite,
         * therefore, only the y-coordinate gets inverted around the x-axis.
         */
        if (ball.position.dy <= minY) {
          ball.position = Offset(ball.position.dx, minY);
          ball.direction = Offset(ball.direction.dx, -ball.direction.dy);
        } else if (ball.position.dy >= maxY) {
          ball.position = Offset(ball.position.dx, maxY);
          ball.direction = Offset(ball.direction.dx, -ball.direction.dy);
        }
      }
      /// TODO: Gravitation zwischen den Bällen (#7)
      // for (Ball partner in balls) {
      //   if (vecLen(partner.position - ball.position) > 40) {
      //     partner.direction += ((partner.position - ball.position) * 0.05);
      //   }
      // }
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

      /// TODO: Punkte auf einem Kreis um das Zentrum (#2)
      canvas.drawCircle((ball.direction * 0.3) + ball.position, 3, paint);
      canvas.drawLine((ball.direction * 0.3) + ball.position, ball.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
