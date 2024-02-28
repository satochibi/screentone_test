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
  DrawingPageState createState() => DrawingPageState();
}

class DrawingPageState extends State<DrawingPage> {
  StrokesModel strokes = StrokesModel();
  final repaint = ValueNotifier<int>(0);

  void refresh(ValueNotifier<int> repaint) {
    repaint.value++;
    setState(() {});
  }

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
                refresh(repaint);
              },
              onPanUpdate: (details) {
                strokes.drawing(details.localPosition);
                refresh(repaint);
              },
              onPanEnd: (details) {
                refresh(repaint);
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

    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = false
      ..strokeWidth = 4.0;

    var path = Path();

    strokes.all.forEach((Stroke stroke) {
      if (stroke.screentoneImage != null) {
        paint = Paint()
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..strokeWidth = 50.0
          ..isAntiAlias = false
          ..shader = ImageShader(stroke.screentoneImage!, TileMode.repeated,
              TileMode.repeated, Matrix4.identity().storage);
      }

      stroke._points.asMap().forEach((int index, Offset anOffset) {
        if (index == 0) {
          path.moveTo(anOffset.dx, anOffset.dy);
        } else {
          path.lineTo(anOffset.dx, anOffset.dy);
        }
      });
    });

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

  final width = 4;

  final aPatternPosition = [
    Offset(2, 0),
    Offset(1, 1),
    Offset(3, 1),
    Offset(0, 2),
    Offset(1, 3),
    Offset(3, 3)
  ];

  var aPatternXPosition =
      aPatternPosition.map((e) => e + Offset(width.toDouble(), 0)).toList();

  var aPatternYPosition =
      aPatternPosition.map((e) => e + Offset(0, width.toDouble())).toList();

  var aPatternXYPosition = aPatternPosition
      .map((e) => e + Offset(width.toDouble(), width.toDouble()))
      .toList();

  patternCanvas.drawPoints(ui.PointMode.points, aPatternPosition, paint);
  patternCanvas.drawPoints(ui.PointMode.points, aPatternXPosition, paint);
  // patternCanvas.drawPoints(ui.PointMode.points, aPatternYPosition, paint);
  // patternCanvas.drawPoints(ui.PointMode.points, aPatternXYPosition, paint);

  final aPatternPicture = pictureRecorder.endRecording();

  return aPatternPicture.toImage(width, width);
}

class StrokesModel {
  List<Stroke> _strokes = [];

  get all => _strokes;

  Future<void> screentoneImage() async {
    var strokesCopy = List<Stroke>.from(_strokes);
    for (var stroke in strokesCopy) {
      stroke.screentoneImage ??= await getPattern();
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
