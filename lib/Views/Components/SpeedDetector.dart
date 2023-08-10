import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'Theme.dart';

class SpeedDetector extends StatefulWidget {
  @override
  _SpeedDetectorState createState() => _SpeedDetectorState();
}

class _SpeedDetectorState extends State<SpeedDetector> {
  late Timer _timer;
  bool begin = false;
  int time = 0; // the time of tapping on the button
  double milli_time = 0; // the time of tapping on the button in milliseconds
  double _bpm = 0;
  Theme theme = Get.put(Theme());

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
      setState(() {
        milli_time += 10;
      });
    });
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360.w,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          CupertinoButton.filled(
              minSize: 128.sp,
              child: Icon(CupertinoIcons.speedometer, size: 96.sp, color: theme.color4Getter,),
              onPressed: () {
                time += 1;
                if (!begin){
                  milli_time = 0;
                  begin = true;
                } else {
                  setState(() {
                    double everage = milli_time / (time-1); // average time of tapping on the button
                    _bpm = 60000 / everage; // bpm
                  });
                }
              }
          ),
          SizedBox(height: 16.h,),
          Text((){
              if (!begin){
                return "请点击按钮以开始检测BPM";
              } else {
                if (time == 1){
                  return "请再次点击按钮";
                } else {
                  return "BPM: ${_bpm.toInt()}";
                }
              }
            }(),
            style: TextStyle(fontSize: 24.sp, color: theme.color2Getter),),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}