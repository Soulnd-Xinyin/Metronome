import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:metronome/Views/Components/CustomRythmConstroller.dart';
import 'package:metronome/Views/Components/NewRythmPage.dart';
import 'package:metronome/Views/Components/SpeedUpController.dart';
import 'package:metronome/main.dart';
import '../BeatBox.dart';

import 'Theme.dart';

class SettingsPage extends StatefulWidget {

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final SpeedUpController speedUpController = Get.put(SpeedUpController());
  late TextEditingController _textController;
  Theme theme = Get.put(Theme());
  final customRythmConstroller = Get.put(CustomRythmConstroller());

  // This shows a CupertinoModalPopup with a reasonable fixed height which hosts CupertinoPicker.
  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 136.h,
        padding: EdgeInsets.only(top: 6.h),
        // The Bottom margin is provided to align the popup above the system navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }

  late int id;

  @override
  void initState() {
    _textController = TextEditingController();
    id = GetStorage().read('id') ?? 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: CupertinoNavigationBar(
        middle: Text('设置'),

      ),
      child: SafeArea(
        child: Column(
          children: [
            CupertinoListSection.insetGrouped(
              header: Text('变速英雄', style: TextStyle(color: CupertinoColors.label),),
              children: [
                CupertinoListTile(
                    title: Text('使用乘除变速', style: TextStyle(color: CupertinoColors.label),),
                    trailing: CupertinoSwitch(
                      value: speedUpController.speedUpType.value,
                      onChanged: (value) {
                        setState(() {
                          speedUpController.speedUpType.value = !speedUpController.speedUpType.value;
                        });
                      },
                    ),
                ),
                CupertinoListTile(
                  title: Text('每拍变速', style: TextStyle(color: CupertinoColors.label),),
                  trailing: CupertinoSwitch(
                    value: !speedUpController.speedUpInterval.value,
                    onChanged: (value) {
                      setState(() {
                        speedUpController.speedUpInterval.value = !speedUpController.speedUpInterval.value;
                      });
                    },
                  ),
                ),
                CupertinoListTile(
                  title: Text('变速大小', style: TextStyle(color: CupertinoColors.label),),
                  additionalInfo: Text(speedUpController.speedUp.value.toString(), style: TextStyle(color: CupertinoColors.label),),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    _showDialog(Container(
                      width: double.infinity,
                      height: 64.h,
                      child: Padding(
                        padding: EdgeInsets.only(left: 32.w, right: 32.w, top: 8.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoTextField(
                              controller: _textController,
                              style: TextStyle(color: CupertinoColors.label),
                              placeholder: '请输入变速大小',
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 16.h,),
                            CupertinoButton.filled(
                              child: Text('好'),
                              onPressed: () {
                                setState(() {
                                  speedUpController.speedUp.value = double.parse(_textController.text);
                                });
                                Get.back();
                              },
                            ),
                          ],
                        ),
                      ),
                    ));
                  }
                ),
              ],
            ),
            FutureBuilder(
              future: getRythms(),
              builder: (context, snapshot){
                GetStorage storage = GetStorage();
                if (snapshot.hasData) {
                  var list = snapshot.data;
                  return CupertinoListSection.insetGrouped(
                    header: Text('节奏', style: TextStyle(color: CupertinoColors.label),),
                    children: [
                      CupertinoListTile(
                        title: Text('自定义节奏', style: TextStyle(color: CupertinoColors.label),),
                        additionalInfo: Text((){
                          if (list!.length == 0) {
                            return '无';
                          } else {
                            return list[id]['label'];
                          }
                        }(), style: TextStyle(color: CupertinoColors.label),),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          if (list!.length != 0) {
                            _showDialog(
                                CupertinoPicker(
                                  magnification: 1.22,
                                  squeeze: 1.2,
                                  useMagnifier: true,
                                  itemExtent: 24.h,
                                  scrollController: FixedExtentScrollController(
                                    initialItem: snapshot.data!.length - 1,
                                  ),
                                  onSelectedItemChanged: (int index) async{
                                    id = index;
                                    await storage.write('rythmId', index);
                                    setState(() {
                                      customRythmConstroller.setFromMap(list![index]);
                                      note_type = customRythmConstroller.note_type.value;
                                      beats_per_bar = customRythmConstroller.beats_per_bar.value;
                                      restart();
                                    });
                                    HapticFeedback.selectionClick();
                                  },
                                  children: List<Widget>.generate(snapshot.data!.length, (int index) {
                                    return Center(
                                      child: Text(snapshot.data![index]['label'], style: TextStyle(color: CupertinoColors.label),),
                                    );
                                  }),
                                )
                            );
                          }
                        },
                      ),
                      CupertinoListTile(
                        title: Text('新增节奏', style: TextStyle(color: CupertinoColors.label),),
                        onTap: () async {
                          await Get.to(() => NewRythmPage());
                          setState(() {
                            id = snapshot.data!.length;
                          });
                        },
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Text("${snapshot.error}");
                } else {
                  return CupertinoActivityIndicator();
                }
              }
            ),

          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getRythms() async {
    final db = await database;
    return await db.query('rythm');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}