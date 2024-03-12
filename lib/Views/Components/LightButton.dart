import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LightButtonWidget extends StatefulWidget {
  ValueNotifier<bool> isOn;
  LightButtonWidget(this.isOn);

  @override
  _LightButtonWidgetState createState() => _LightButtonWidgetState();
}

class _LightButtonWidgetState extends State<LightButtonWidget> {

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () {
        widget.isOn.value = !widget.isOn.value;
        setState(() {

        });
        if (widget.isOn.value){
          Fluttertoast.showToast(
              msg: "灯光已开启",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: CupertinoColors.white,
              fontSize: 16.0.sp
          );
        } else {
          Fluttertoast.showToast(
              msg: "灯光已关闭",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: CupertinoColors.white,
              fontSize: 16.0.sp
          );
        }
      },
      child: Icon(
        !widget.isOn.value ? CupertinoIcons.lightbulb_slash : CupertinoIcons.lightbulb,
        size: 28.sp,
      ),
    );
  }
}

