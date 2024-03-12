import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import '../BeatBox.dart';
import '../Components/CustomRythmConstroller.dart';

class RythmButton extends StatefulWidget {
  ValueNotifier<bool> isCustomRythm;
  RythmButton({Key? key, required this.isCustomRythm}) : super(key: key);

  @override
  _RythmButtonState createState() => _RythmButtonState();
}

class _RythmButtonState extends State<RythmButton> {
  @override
  Widget build(BuildContext context) {
    final customRythmConstroller = Get.put(CustomRythmConstroller());

    return CupertinoButton(
      onPressed: () {
        setState(() {
          widget.isCustomRythm.value = !widget.isCustomRythm.value;
          note_type = customRythmConstroller.note_type.value;
          beats_per_bar = customRythmConstroller.beats_per_bar.value;
          restart();
        });
        if (widget.isCustomRythm.value){
          Fluttertoast.showToast(
              msg: "自定义节奏已开启",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: CupertinoColors.white,
              fontSize: 16.0.sp
          );
        } else {
          Fluttertoast.showToast(
              msg: "自定义节奏已关闭",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: CupertinoColors.white,
              fontSize: 16.0.sp
          );
        }
      },
      child: Icon(
            !widget.isCustomRythm.value?CupertinoIcons.music_note
            :CupertinoIcons.music_note_list,
            size: 28.sp,
          ),
    );
  }
}