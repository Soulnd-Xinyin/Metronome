import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'dart:math';

import 'package:metronome/Views/Components/Theme.dart';


class Metronome extends StatefulWidget {
  ValueNotifier<bool> active;
  ValueNotifier<int> duration;
  ValueNotifier<double> bpm;
  bool speedUp;

  Metronome(this.duration, this.active, this.speedUp, this.bpm);

  @override
  _MetronomeState createState() => _MetronomeState();
}

class _MetronomeState extends State<Metronome> with SingleTickerProviderStateMixin {
  double angle = 3*pi/4;
  AnimationController? _controller;
  Animation<double>? angleController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration.value),
      vsync: this,
    );
    angleController = _controller?.drive(Tween(begin: 7*pi/8, end: 9*pi/8));
  }

  @override
  Widget build(BuildContext context) {
    // _controller?.stop(canceled: false);
    if(widget.active.value){
      _controller?.duration = Duration(milliseconds: widget.duration.value);
      // _controller?.repeat(reverse: true);
      if (angleController!.value > 4*pi/4){
        _controller?.forward();
      } else {
        _controller?.reset();
      }

      _controller?.repeat(reverse: true);

    } else {
      _controller?.stop(canceled: false);
      _controller?.reset();
    }

    return CustomPaint(
      painter: MetronomePainter(angle: angleController!, active: widget.active.value, bpm: widget.bpm.value),
    );
  }
}



class MetronomePainter extends CustomPainter {
  Animation<double> angle;
  bool active;
  double bpm;

  MetronomePainter({required this.angle, required this.active, required this.bpm}) : super(repaint: angle);

  @override
  void paint(Canvas canvas, Size size) {
    Theme theme = Get.put(Theme());
    final Paint m_paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.sp
      ..color = theme.color4Getter;

    final Paint l_paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.sp
      ..color = theme.color3Getter;

    final Paint c_paint = Paint()
      ..strokeWidth = 6.sp
      ..color = theme.color2Getter;

    Path path = Path();
    path.lineTo(-88.w, 0);
    path.lineTo(88.w, 0);
    path.lineTo(100.w,-24.h);
    path.lineTo(24.w, -196.h);
    path.lineTo(-24.w, -196.h);
    path.lineTo(-100.w, -24.h);
    path.lineTo(-88.w, 0);
    path.close();
    canvas.drawPath(path, m_paint);

    canvas.drawLine(Offset(-24.w, -144.h), Offset(-6.w, -144.h), m_paint);
    canvas.drawLine(Offset(-24.w, -136.h), Offset(-6.w, -136.h), m_paint);
    canvas.drawLine(Offset(-24.w, -124.h), Offset(-6.w, -124.h), m_paint);
    canvas.drawLine(Offset(-24.w, -108.h), Offset(-6.w, -108.h), m_paint);
    canvas.drawLine(Offset(-24.w, -88.h), Offset(-6.w, -88.h), m_paint);
    canvas.drawLine(Offset(-24.w, -64.h), Offset(-6.w, -64.h), m_paint);
    canvas.drawLine(Offset(-24.w, -32.h), Offset(-6.w, -32.h), m_paint);
    canvas.drawLine(Offset(-8.w, -144.h), Offset(-8.w, -32.h), m_paint);
    canvas.drawLine(Offset(24.w, -140.h), Offset(6.w, -140.h), m_paint);
    canvas.drawLine(Offset(24.w, -132.h), Offset(6.w, -132.h), m_paint);
    canvas.drawLine(Offset(24.w, -116.h), Offset(6.w, -116.h), m_paint);
    canvas.drawLine(Offset(24.w, -100.h), Offset(6.w, -100.h), m_paint);
    canvas.drawLine(Offset(24.w, -78.h), Offset(6.w, -78.h), m_paint);
    canvas.drawLine(Offset(24.w, -32.h), Offset(6.w, -32.h), m_paint);
    canvas.drawLine(Offset(8.w, -140.h), Offset(8.w, -32.h), m_paint);

    // 绘制指针
    canvas.save();
    canvas.rotate(angle.value);
    canvas.drawLine(Offset(0, 0), Offset(0, 196.h), l_paint);
    canvas.drawCircle(Offset(0, 196.h * bpm/266), 8.sp, c_paint);
    canvas.restore();

  }

  @override
  bool shouldRepaint(MetronomePainter oldDelegate) {
    return oldDelegate.active != active;
  }

}