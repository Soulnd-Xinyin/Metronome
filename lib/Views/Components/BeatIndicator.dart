import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'Theme.dart';


class BeatIndicator extends StatefulWidget {
  ValueNotifier<int> beat;
  int beats_per_bar;
  bool active;

  BeatIndicator(this.beat, this.beats_per_bar, this.active);

  @override
  _BeatIndicatorState createState() => _BeatIndicatorState();
}

class _BeatIndicatorState extends State<BeatIndicator> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BeatPainter(widget.beat, widget.beats_per_bar, widget.active),
    );
  }
}

class BeatPainter extends CustomPainter {
  ValueNotifier<int> beat;
  int beats_per_bar;
  bool active;
  BeatPainter(this.beat, this.beats_per_bar, this.active):super(repaint: beat);
  Theme theme = Get.put(Theme());

  @override
  void paint(Canvas canvas, Size size) {
    // 创建画笔
    final Paint inactivePaint = Paint()
      ..color = theme.color4Getter;
    final Paint activePaint = Paint()
      ..color = theme.color3Getter;
    final Paint stressPaint = Paint()
      ..color = theme.color2Getter;
    double xOffset = -15.0.w * (beats_per_bar-1);
    // 绘制圆
    for (int i=0; i<beats_per_bar; i++) {
      if (i == beat?.value && i == 0 && active) {
        canvas.drawCircle(Offset(30.w * i.toDouble() + xOffset, 0), 8.sp, stressPaint);
      } else if (i == beat?.value && active) {
        canvas.drawCircle(Offset(30.w *i.toDouble() + xOffset, 0), 8.sp, activePaint);
      } else {
        canvas.drawCircle(Offset(30.w *i.toDouble() + xOffset, 0), 8.sp, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(BeatPainter oldDelegate) {
    return oldDelegate.active != this.active ||
        oldDelegate.beat != this.beat ||
        oldDelegate.beats_per_bar != this.beats_per_bar;
  }

}