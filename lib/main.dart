import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      body: SizedBox(
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
          child: FutureBuilder(
              future: strokes.screentoneImage(),
              builder: (context, snapshot) {
                return CustomPaint(
                  painter: _DrawingPainter(strokes),
                );
              }),
        ),
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
          ..strokeWidth = 3.0
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
  final data = await rootBundle.load('img/beads4x4.png');
  final bytes = data.buffer.asUint8List();
  return decodeImageFromList(bytes);
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
