import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

// Class to get an imega from other object
// Used like a reference parameter
class ImageAccess {
  Image imagen;
}

class Blackboard extends StatefulWidget {
  // The image can be accessed by this property
  ImageAccess aImagen = new ImageAccess();

  @override
  _BlackboardState createState() => new _BlackboardState();
}

class _BlackboardState extends State<Blackboard> {
  List<Offset> points; //List of points in one Tap or Pan
  List<List<Offset>> paths =
      new List<List<Offset>>(); // Every point or path is kept here

  /*
  *  Tap and Pan behaviour:
  *
  *  Touch the screen throws tapDown.
  *  If up the finger tapUp and then onTap,
  *   if not and begin drag throws tapCancel, panStart and panUpdate
  *    and when stop drag and up the finger throws panEnd
  *
  * */

  // Not used
  void _tapDown(TapDownDetails details) {
    print('tapDown');
  }

  // User tap one point
  void _tapUp(TapUpDetails details) {
    print('tapUp');
    setState(() {
      var object = this.contexto.findRenderObject();
      var translation = object?.getTransformTo(null)?.getTranslation();
      // translation.y have the offset from the top of the screen to the "canvas".

      points = [
        new Offset(details.globalPosition.dx,
            details.globalPosition.dy - translation.y)
      ];
      paths.add(points);
    });
  }

  // Not used
  void _tapCancel() {
    print('tapCancel');
  }

  // User touch and drag over the screen
  void _panStart(DragStartDetails details) {
    print('panStart');
    setState(() {
      var object = this.contexto.findRenderObject();
      var translation = object?.getTransformTo(null)?.getTranslation();
      points = [
        new Offset(details.globalPosition.dx,
            details.globalPosition.dy - translation.y)
      ];
      paths.add(points);
      // Add here to refresh the screen. If paths.add is only in panEnd
      // only update the screen when finger is up
    });
  }

  // User drag over screen
  void _panUpdate(DragUpdateDetails details) {
    // print('panUpdate'); //Lot of prints :-/
    setState(() {
      var object = this.contexto.findRenderObject();
      var translation = object?.getTransformTo(null)?.getTranslation();
      points.add(new Offset(details.globalPosition.dx,
          details.globalPosition.dy - translation.y));
    });
  }

  // Not use because in panStart and tapUp initialize a new path of points
  void _panEnd(DragEndDetails details) {
    print('panEnd');
  }

  double _w, _h;
  BuildContext contexto;

  @override
  Widget build(BuildContext context) {
    contexto = context;
    _w = MediaQuery.of(context).size.width;
    _h = MediaQuery.of(context).size.height;

    return GestureDetector(
      //  behavior: HitTestBehavior.translucent,
      onTap: () {
        print('tap');
      },
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: _tapCancel,
      onPanStart: _panStart,
      onPanEnd: _panEnd,
      onPanUpdate: _panUpdate,
      child: Container(
        color: Colors.black,
        height: _h,
        width: _w,
        child: new CustomPaint(
          foregroundPainter: new MyPainter(
            lineColor: Colors.white,
            aImg: widget.aImagen,
            width: 4.0,
            canvasWidth: _w.toInt(),
            canvasHeight: _h.toInt(),
            paths: paths,
          ),
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  Color lineColor; //Line color

  ImageAccess aImg; // Image in png
  double width; // Pen thickness
  int canvasWidth;
  int canvasHeight;
  List<List<Offset>> paths; // paths to draw

  MyPainter(
      {this.lineColor,
      this.aImg,
      this.width,
      this.paths,
      this.canvasWidth,
      this.canvasHeight});

  Future<void> _capturePng(ui.Image img) async {
    ByteData byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    aImg.imagen = new Image.memory(new Uint8List.view(pngBytes.buffer));

  }

  @override
  void paint(Canvas canvasFinal, Size size) {
    final recorder = new ui.PictureRecorder(); // dart:ui
    final canvas = new Canvas(recorder);
    if (paths == null || paths.isEmpty) return;
    for (List<Offset> points in paths) {
      if (points.length > 1) {
        Path path = Path();
        Offset origin = points[0];
        path.moveTo(origin.dx, origin.dy);
        for (Offset o in points) {
          path.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = this.width,
        );
      } else {
        canvas.drawPoints(
          ui.PointMode.points,
          points,
          Paint()
            ..color = lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = this.width,
        );
      }
    }
    // Storing image
    ui.Picture picture = recorder.endRecording();
    ui.Image imagen = picture.toImage(canvasWidth, canvasWidth);
    _capturePng(imagen);
    canvasFinal.drawPicture(picture);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
