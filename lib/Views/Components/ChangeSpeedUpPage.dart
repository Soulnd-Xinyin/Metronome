import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'SpeedUpController.dart';

class ChangeSpeedUpPage extends StatefulWidget {
  const ChangeSpeedUpPage({Key? key}) : super(key: key);

  @override
  _ChangeSpeedUpPageState createState() => _ChangeSpeedUpPageState();
}

class _ChangeSpeedUpPageState extends State<ChangeSpeedUpPage> {
  late TextEditingController _textController;
  final speedUpController = Get.put(SpeedUpController());

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        middle: Text('修改变速大小'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('变速大小', style: TextStyle(color: CupertinoColors.label, fontSize: 16.sp),),
          CupertinoTextField(
            controller: _textController,
            keyboardType: TextInputType.number,
          ),
          CupertinoButton.filled(
            child: Text('确定'),
            onPressed: () {
              speedUpController.speedUp.value = double.parse(_textController.text);
              Get.back();
            },
          ),

        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}