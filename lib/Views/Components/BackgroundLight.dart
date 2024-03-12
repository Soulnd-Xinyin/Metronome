import 'package:flutter/cupertino.dart';

class BackgroundLight extends StatefulWidget {
  ValueNotifier<bool> stress;
  ValueNotifier<bool> isOn;
  BackgroundLight(this.stress, this.isOn);

  @override
  _BackgroundLightState createState() => _BackgroundLightState();
}

class _BackgroundLightState extends State<BackgroundLight>{
  @override
  Widget build(BuildContext context) {
    if (!widget.isOn.value) {
      return Container();
    }
    return Container(
      decoration: BoxDecoration(
        color: widget.stress.value ? CupertinoColors.systemRed :  CupertinoColors.systemGreen,
      ),
    );
  }

}