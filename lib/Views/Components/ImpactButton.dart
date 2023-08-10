import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ImpactButtonWidget extends StatefulWidget {
  ValueNotifier<bool> isOn;
  ImpactButtonWidget(this.isOn);

  @override
  _ImpactButtonWidgetState createState() => _ImpactButtonWidgetState();
}

class _ImpactButtonWidgetState extends State<ImpactButtonWidget> {

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () {
        widget.isOn.value = !widget.isOn.value;
        setState(() {

        });
        if (widget.isOn.value) {
          Fluttertoast.showToast(
              msg: "震动已开启",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: CupertinoColors.white,
              fontSize: 16.0.sp
          );
        } else {
          Fluttertoast.showToast(
              msg: "震动已关闭",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              timeInSecForIosWeb: 1,
              textColor: CupertinoColors.white,
              fontSize: 16.0.sp
          );
        }
      },
      child: Icon(
        widget.isOn.value ? CupertinoIcons.burst_fill : CupertinoIcons.burst,
        size: 28.sp,
      ),
    );
  }
}

