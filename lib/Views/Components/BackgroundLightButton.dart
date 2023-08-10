import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BackgroundLightButtonWidget extends StatefulWidget {
  ValueNotifier<bool> isOn;
  BackgroundLightButtonWidget(this.isOn);

  @override
  _BackgroundLightButtonWidgetState createState() => _BackgroundLightButtonWidgetState();
}

class _BackgroundLightButtonWidgetState extends State<BackgroundLightButtonWidget> {

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () {
        widget.isOn.value = !widget.isOn.value;
        setState(() {

        });
        if (widget.isOn.value) {
          Fluttertoast.showToast(
              msg: "屏幕闪烁已开启",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: CupertinoColors.white,
              fontSize: 16.0.sp
          );
        } else {
          Fluttertoast.showToast(
              msg: "屏幕闪烁已关闭",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: CupertinoColors.white,
              fontSize: 16.0.sp
          );
        }
      },
      child: Icon(
        !widget.isOn.value ? CupertinoIcons.circle : CupertinoIcons.circle_filled,
        size: 29.sp,
      ),
    );
  }
}

