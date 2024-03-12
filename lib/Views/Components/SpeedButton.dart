import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeedButton extends StatefulWidget{
  ValueNotifier<int> speed_type;
  SpeedButton(this.speed_type);

  @override
  _SpeedButtonState createState() => _SpeedButtonState();

}

class _SpeedButtonState extends State<SpeedButton> {
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () {
        widget.speed_type.value = (widget.speed_type.value + 1) % 3;
        setState(() {

        });
      },
      child: Icon(
        widget.speed_type.value == 0 ? CupertinoIcons.nosign : widget.speed_type.value == 1 ? CupertinoIcons.up_arrow : CupertinoIcons.down_arrow,
        size: 28.sp,
      ),
    );
  }
}
