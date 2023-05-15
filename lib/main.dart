import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DrawingPage(),
    );
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  _DrawingPageState createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  StrokesModel strokes = StrokesModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing App'),
      ),
      body: FutureBuilder(
        future: strokes.screentoneImage(),
        builder: (context, snapshot) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: GestureDetector(
              onPanDown: (details) {
                strokes.onPress(details.localPosition);
                setState(() {});
              },
              onPanUpdate: (details) {
                strokes.drawing(details.localPosition);
                setState(() {});
              },
              onPanEnd: (details) {
                setState(() {});
              },
              child: CustomPaint(
                painter: _DrawingPainter(strokes),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final StrokesModel strokes;

  _DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.all.isEmpty) return;
    var path = Path();

    strokes.all.forEach((Stroke stroke) {
      stroke._points.asMap().forEach((int index, Offset anOffset) {
        if (index == 0) {
          path.moveTo(anOffset.dx, anOffset.dy);
        } else {
          path.lineTo(anOffset.dx, anOffset.dy);
        }
      });
    });

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false
      ..strokeWidth = 4.0;

/*
    if (strokes.screentoneImage != null) {
      paint = Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..isAntiAlias = false
        ..shader = ImageShader(strokes.screentoneImage as ui.Image,
            TileMode.repeated, TileMode.repeated, Matrix4.identity().storage);
    }
    */

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) {
    return true;
  }
}

Future<ui.Image> getPattern() async {
  var pictureRecorder = ui.PictureRecorder();
  Canvas patternCanvas = Canvas(pictureRecorder);

  final paint = Paint()
    ..color = Colors.black
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = false;

  patternCanvas.drawPoints(
      ui.PointMode.points, [const Offset(0, 0), const Offset(1, 1)], paint);

  final aPatternPicture = pictureRecorder.endRecording();

  return aPatternPicture.toImage(2, 2);
}

class StrokesModel {
  List<Stroke> _strokes = [];

  get all => _strokes;

  Future<void> screentoneImage() async {
    for (var stroke in _strokes) {
      // stroke.screentoneImage ??= await getPattern();
    }
  }

  void onPress(Offset offset) {
    _strokes.add(Stroke()..add(offset));
  }

  void drawing(Offset offset) {
    _strokes.last.add(offset);
  }

  void clear() {
    _strokes = [];
  }
}

class Stroke {
  final List<Offset> _points = [];
  ui.Image? screentoneImage;

  Stroke();

  add(Offset offset) {
    _points.add(offset);
  }

  all() {
    return _points;
  }
}
