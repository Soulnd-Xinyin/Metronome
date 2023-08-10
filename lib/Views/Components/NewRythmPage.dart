import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:metronome/Views/Components/CustomRythmConstroller.dart';

import '../../main.dart';
import '../BeatBox.dart';

class NewRythmPage extends StatefulWidget {
  @override
  _NewRythmPageState createState() => _NewRythmPageState();
}

class _NewRythmPageState extends State<NewRythmPage> {
  late TextEditingController _textController;
  var stress;
  var weak;

  @override
  void initState() {
    _textController = TextEditingController();
    stress = List.generate(beats_per_bar * ((32/note_type).toInt()), (index) => false);
    weak = List.generate(beats_per_bar * ((32/note_type).toInt()), (index) => false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        middle: Text('增加节奏型'),
      ),
      child: ListView(
        children: [
          CupertinoListSection.insetGrouped(
            header: Text('节奏型名称', style: TextStyle(color: CupertinoColors.label),),
            children: [
              CupertinoTextFormFieldRow(
                controller: _textController,
                style: TextStyle(color: CupertinoColors.label),
                cursorColor: CupertinoColors.systemBlue,
                placeholder: '节奏型名称',
              ),

            ],
          ),
          CupertinoListSection.insetGrouped(
            header: Text('重音位置', style: TextStyle(color: CupertinoColors.label),),
            children: List.generate(beats_per_bar * ((32/note_type).toInt()), (index) => (){
              return CupertinoListTile(
                title: Text('第${index+1}个32分音符', style: TextStyle(color: CupertinoColors.label),),
                trailing: CupertinoSwitch(
                  value: stress[index],
                  onChanged: (value) {
                    setState(() {
                      stress[index] = !stress[index];
                    });
                  },
                ),
              );
            }()
            ),
          ),
          CupertinoListSection.insetGrouped(
            header: Text('弱音位置', style: TextStyle(color: CupertinoColors.label),),
            children: List.generate(beats_per_bar * ((32/note_type).toInt()), (index) => (){
              return CupertinoListTile(
                title: Text('第${index+1}个32分音符', style: TextStyle(color: CupertinoColors.label),),
                trailing: CupertinoSwitch(
                  value: weak[index],
                  onChanged: (value) {
                    setState(() {
                      weak[index] = !weak[index];
                    });
                  },
                ),
              );
            }()
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h),
            child: CupertinoButton(
              color: CupertinoColors.systemBlue,
              child: Text('确定', style:TextStyle(color: CupertinoColors.white,)),
              onPressed: () async {
                CustomRythmConstroller customRythmConstroller = new CustomRythmConstroller();
                customRythmConstroller.initRythm((32/note_type).toInt(), beats_per_bar);
                for (int i=0; i<stress.length; i++){
                  if (stress[i] == true){
                    customRythmConstroller.setStressRythm(i);
                  }
                  if (weak[i] == true){
                    customRythmConstroller.setWeakRythm(i);
                  }
                }
                customRythmConstroller.label.value = _textController.text;
                var db = await database;
                db.insert('rythm', customRythmConstroller.toMap());
                Get.back();
              },
            ),
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