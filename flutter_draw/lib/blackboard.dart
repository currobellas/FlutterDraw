import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

enum Answer { ACEPTAR, CANCELAR }


// Clase parapoder obtener una imagen de un
//objeto distinto (una especie de paso por referencia)
class AccesoAImagen{
  Image imagen;
}

class Blackboard extends StatefulWidget {
//  String prueba = 'hola';
  // Image imagenFinal = null;
  AccesoAImagen aImagen = new AccesoAImagen();
  @override
  _BlackboardState createState() => new _BlackboardState();
}

class _BlackboardState extends State<Blackboard> {

  List<Offset> points;

  List<List<Offset>> paths = new List<List<Offset>>();

  /*
  *  Funcionamiento de los taps y pans:
  *
  *  Al tocar la pantalla se lanza tapdown
  *  Si se suelta se lanza tapup y luego tap
  *  si no se suelta y se empieza  a arrastrar se lanza tapcancel, panstart y panupdate
  *  al soltar tras los pan se lanza panend
  *
  *
  * */

  void _tapDown(TapDownDetails details) {
    // TODO eliminar si no lo usamos
    print('tapdown');
    setState(() {
      //  _tapInProgress = true;
      print(details.globalPosition.toString());

      var object = this.contexto.findRenderObject();
      var translation = object?.getTransformTo(null)?.getTranslation();
      var size = object?.semanticBounds?.size;

      if (translation != null && size != null) {
        print(Rect.fromLTWH(
            translation.x, translation.y, size.width, size.height));
      } else {
        print('nada');
      }
    });
  }

  void _tapUp(TapUpDetails details) {
    print('tapup');
    setState(() {
      // _tapInProgress = false;

      points = [
        new Offset(details.globalPosition.dx - _offsetX,
            details.globalPosition.dy - _offsetY)
      ]; //details.globalPosition]; //Si el usuario toca solo para un punto
      paths.add(points);
    });
  }

  void _tapCancel() {
    // TODO eliminar si no lo usamos
    print('tapcancel');
    setState(() {
      //    _tapInProgress = false;
    });
  }

  void _panStart(DragStartDetails details) {
    print('panstart');
    setState(() {
      // print('v start ${details.toString()}');
      //Como aquí creamos un nuevo points, ya no es necesario tener en cuenta el fin, pues el fin de un camino se establece
      //al empezar otro
      points = [
        new Offset(details.globalPosition.dx - _offsetX,
            details.globalPosition.dy - _offsetY)
      ];
      paths.add(points); // Añadimos aquí para que la pantalla se actualice a
      // a medida que pinta. Si lo metemos en end, solo pinta al levantar el dedo
    });
  }

  void _panUpdate(DragUpdateDetails details) {
    //print('pan');
    setState(() {
//      print('v update ${details.globalPosition}');
//      RenderBox getBox = context.findRenderObject();
//      var local = getBox.globalToLocal(details.globalPosition);
//      print(local.dx.toString() + "|" + local.dy.toString());
      points.add(new Offset(details.globalPosition.dx - _offsetX,
          details.globalPosition.dy - _offsetY));
    });
  }

  void _panEnd(DragEndDetails details) {
    // TODO eliminar si no lo usamos
    setState(() {
      print('panend ${details.toString()}');
    });
  }

  double _w, _h, _hExterno, _wExterno, _hFirma, _wFirma, _offsetX, _offsetY;
  BuildContext contexto;



  @override
  Widget build(BuildContext context) {
    contexto = context;

//    var object = this.contexto.findRenderObject();
//    var translation = object?.getTransformTo(null)?.getTranslation();
    //print(context.findRenderObject().describeApproximatePaintClip(context.findRenderObject()).top);
    _w = MediaQuery.of(context).size.width;

    _h = MediaQuery.of(context).size.height;

    _hExterno = _h * 0.7; //H ext
    _wExterno = _w * 0.79;
    //Hacemos al final la zona cuadrada
    _hFirma = _wExterno;//_hExterno * 0.6;
    _wFirma = _wExterno;

    _offsetX = 0.0;//(_w - _wExterno) / 2;
    _offsetY = 0.0;//(_h - _hExterno) / 2;

    print(_h* MediaQuery.of(context).devicePixelRatio);
    //print('estado'+widget?.aImagen?.imagen?.toString());
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
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
        //H ext
        width: _w,
        //W ext Es el máximo de w que se puede poner el el iphone 10,
        child: new CustomPaint(
          foregroundPainter: new MyPainter(
            lineColor: Colors.white,
            completeColor: Colors.red,
            aImg: widget.aImagen,
            width: 4.0,
            //Grosor de la línea
            anchoZonaFirma: (_wFirma* (Theme.of(context).platform == TargetPlatform.iOS?MediaQuery.of(context).devicePixelRatio:1)).toInt() ,
            paths: paths,
          ),
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  Color lineColor;
  Color completeColor;
  Image img;
  AccesoAImagen aImg;
  double width; //grosor lapiz
  int anchoZonaFirma; //en pixels
  List<List<Offset>> paths;

  MyPainter(
      {this.lineColor, this.completeColor, this.aImg, this.width, this.paths, this.anchoZonaFirma});

  Future<void> _capturePng(imagen) async {
    ByteData byteData = await imagen.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    aImg.imagen = new Image.memory(new Uint8List.view(pngBytes.buffer));
    print('future'+aImg.imagen.toString());
  }

  @override
  void paint(Canvas canvasFinal, Size size) {

    final recorder = new ui.PictureRecorder(); //está en dart:ui
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
    ui.Picture picture = recorder.endRecording();
    ui.Image imagen = picture.toImage(anchoZonaFirma,anchoZonaFirma);
    // print('picture $picture');
    // print('img $img');
    //  final pngBytes = await img.toByteData(format: new ui.EncodingFormat.png());
    _capturePng(imagen);
    canvasFinal.drawPicture(picture);

//    Paint line = new Paint()
//      ..color = lineColor
//      ..strokeCap = StrokeCap.round
//      ..style = PaintingStyle.stroke
//      ..strokeWidth = width;
//    Paint complete = new Paint()
//      ..color = completeColor
//      ..strokeCap = StrokeCap.round
//      ..style = PaintingStyle.stroke
//      ..strokeWidth = width;
//    Offset center = new Offset(size.width / 2, size.height / 2);
//    double radius = min(size.width / 2, size.height / 2);
//    canvas.drawCircle(center, radius, line);
//    double arcAngle = 2 * pi * (completePercent / 100);
//    canvas.drawArc(new Rect.fromCircle(center: center, radius: radius), -pi / 2,
//        arcAngle, false, complete);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
