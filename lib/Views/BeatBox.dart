import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:metronome/Views/Components/CustomRythmConstroller.dart';
import 'package:metronome/Views/Components/Rythm.dart';
import 'package:metronome/Views/Components/SpeedUpController.dart';
import 'package:soundpool/soundpool.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math';


import 'Components/BackgroundLightButton.dart';
import 'Components/BeatIndicator.dart';
import 'Components/Metronome.dart';
import 'package:metronome/Views/Components/BackgroundLight.dart';
import 'package:metronome/Views/Components/ImpactButton.dart';
import 'package:metronome/Views/Components/LightButton.dart';
import 'package:metronome/Views/Components/SpeedButton.dart';
import 'package:metronome/Views/Components/SpeedDetector.dart';
import '../main.dart';
import 'Components/SettingsPage.dart';
import 'Components/Theme.dart';

late Function restart;

// one beat is a what note?
int note_type = 4;
// how many notes in a bar
int beats_per_bar = 4;

class BeatBox extends StatefulWidget {
  var snapshot;
  var speedUpData;
  BeatBox({Key? key, required this.snapshot, required this.speedUpData}) : super(key: key);

  @override
  _BeatBoxState createState() => _BeatBoxState(snapshot: snapshot, speedUpData: speedUpData);
}

class _BeatBoxState extends State<BeatBox> with WidgetsBindingObserver {
  var snapshot;
  var speedUpData;
  _BeatBoxState({Key? key, required this.snapshot, this.speedUpData});

  double _bpm = 120;
  bool _isPlaying = false;
  late ValueNotifier<double> _bpmListener;



  Soundpool pool = Soundpool(
    streamType: StreamType.notification,
    maxStreams: 100, // otherwise there will only be one sound at a time
  );
  late int tickSoundId;
  late int tackSoundId;
  bool playingBeforeTapDown = false;

  late Timer _secondsTimer;
  ValueNotifier<int> _playingSeconds = ValueNotifier(0);

  ValueNotifier<int> durationListener = ValueNotifier(1000);
  ValueNotifier<bool> isPlayingListener = ValueNotifier(false);
  ValueNotifier<bool> isLightOn = ValueNotifier(false);
  ValueNotifier<bool> isImpactOn = ValueNotifier(false);
  ValueNotifier<int> speed_type = ValueNotifier(0); // 0 for normal, 1 for speed up, 2 for slow down
  double speedUp = 1.2;
  ValueNotifier<bool> doesUserSetBackgroundLightOn = ValueNotifier(false);
  ValueNotifier<bool> isBackgroundActuallyLightOn = ValueNotifier(false);
  ValueNotifier<bool> isStress = ValueNotifier(false);
  ValueNotifier<bool> isCustomRythm = ValueNotifier(false);

  CameraController? controller;
  bool _isCameraInitialized = false;
  bool _isCameraActuallyOn = false;

  late CustomRythmConstroller customRythmConstroller = Get.put(CustomRythmConstroller());

  bool _hasGreeting = false;

  final SpeedUpController speedUpController = Get.put(SpeedUpController());
  final Theme theme = Get.put(Theme());


  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onNewCameraSelected(cameraController.description);
    }
  }


  @override
  void initState() {
    load(); // load audio resources
    beat_notifier = ValueNotifier(note_count);
    if (cameras.isNotEmpty)
      onNewCameraSelected(cameras[0]); // get camera
    // init custom rythm
    _bpmListener = ValueNotifier(_bpm);
    db = database;
    if (snapshot.hasData) {
      if (snapshot.data!.isEmpty) {
        db.insert('basic', {
          'bpm': 130,
          'note_type': 4,
          'beats_per_bar': 4,
          'date': DateTime.now().toString()
        });
        db.insert('settings', {
          'speedUp': 1.2,
          'speedUpType': 0,
          'speedUpInterval': 0,
          'date': DateTime.now().toString()
        });
      } else {
        var length = snapshot.data!.length;
        _bpm = snapshot.data?[length - 1]['bpm'].toDouble();
        _bpmListener.value = _bpm;
        note_type = snapshot.data?[length - 1]['note_type'];
        beats_per_bar = snapshot.data?[length - 1]['beats_per_bar'];
        var speedUp_length = speedUpData.length;
        speedUpController.speedUp.value = speedUpData[speedUp_length - 1]['speedUp'];
        speedUpController.speedUpType.value = (speedUpData[speedUp_length - 1]['speedUpType'] != 0);
        speedUpController.speedUpInterval.value = (speedUpData[speedUp_length - 1]['speedUpInterval'] == 0);
      }
    }
    loadRythm();
    super.initState();
  }

  void load() async {
    tickSoundId = await rootBundle.load("assets/ding.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
    tackSoundId = await rootBundle.load("assets/metronome.mp3").then((ByteData soundData) {
      return pool.load(soundData);
    });
  }

  void loadRythm() async {
    int rythm_id = GetStorage().read('id') ?? 0;
    var db = await database;
    var list = await db.query('rythm');
    customRythmConstroller.setFromMap(list[rythm_id]);
    print(customRythmConstroller.toMap().toString());
    note_type = customRythmConstroller.note_type.value;
    beats_per_bar = customRythmConstroller.beats_per_bar.value;
  }

  // This shows a CupertinoModalPopup with a reasonable fixed height which hosts CupertinoPicker.
  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 216.h,
        padding: EdgeInsets.only(top: 6.h),
        // The Bottom margin is provided to align the popup above the system navigation bar.
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        // Provide a background color for the popup.
        color: theme.color1Getter,
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }

  late Database db;
  var customRythmController;


  @override
  Widget build(BuildContext context) {
    db = database;

    restart = (){
      setState(() {
        if (_isPlaying){
          stopPlaying();
          startPlaying();
        }
      });
    };

    return CupertinoPageScaffold(
      backgroundColor: theme.color1Getter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ValueListenableBuilder(
              valueListenable: isBackgroundActuallyLightOn,
              builder: (Context, value, child) {
                return BackgroundLight(isStress, isBackgroundActuallyLightOn);
              }
          ),
          Positioned(
            right: 16.w,
            top: 100.h,
            child: Column(
              children: [
                LightButtonWidget(isLightOn),
                ImpactButtonWidget(isImpactOn),
                BackgroundLightButtonWidget(doesUserSetBackgroundLightOn),
                CupertinoButton(
                    child: ImageIcon(AssetImage('assets/languageIcon.png'), size: 28.sp),
                    onPressed: (){}
                ),
              ],
              mainAxisSize: MainAxisSize.min,
            ),
          ),
          Positioned(
            left: 16.w,
            top: 100.h,
            child: Column(
              children: [
                SpeedButton(speed_type), // 变速按钮
                CupertinoButton(
                    child: Icon(CupertinoIcons.speedometer, size: 28.sp),
                    onPressed: (){
                      _showDialog(
                          SpeedDetector() // 速度侦探
                      );
                    }
                ),
                RythmButton(isCustomRythm: isCustomRythm),
                CupertinoButton(
                  child: Icon(CupertinoIcons.settings, size: 28.sp),
                  onPressed: (){
                    Get.to(() => SettingsPage());
                  },
                ),
              ],
            ),
          ),
          Positioned(
              left: 16.w,
              bottom: 22.h,
              child: Row(children: [
                Icon(CupertinoIcons.clock, size: 28.sp),
                SizedBox(width: 8.w,),
                ValueListenableBuilder(
                    valueListenable: _playingSeconds,
                    builder: (context, value, child) {
                      return Text('${(_playingSeconds.value/60).toInt()}:${_playingSeconds.value%60}', style: TextStyle(fontSize: 28.sp));
                    }
                ),
              ],)
          ),
          Positioned(
              right: 16.w,
              bottom: 16.h,
              child: CupertinoButton(child: Icon(CupertinoIcons.right_chevron, size: 28.sp), onPressed: (){
                _showDialog(
                    showBPMList()
                );
              },)

          ),
          Column(
            children: [
              Text('BPM', style: TextStyle(fontSize: 16.sp, color: theme.color3Getter)),
              Row(
                children: [
                  CupertinoButton(
                    child: Icon(CupertinoIcons.minus_circle, size: 32.sp),
                    onPressed: () {
                      setState(() {
                        _bpm -= 1;
                        _bpmListener.value = _bpm;
                        if (_isPlaying) {
                          stopPlaying();
                          startPlaying();
                        }
                      });
                    },
                  ),
                  GestureDetector(
                    child: Text(
                        '${_bpm.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 32.sp,

                        )
                    ),
                    onVerticalDragUpdate: (details) {
                      setState(() {
                        if (_bpm - details.delta.dy > 0 && _bpm - details.delta.dy <= 266){
                          _bpm -= details.delta.dy;
                          _bpmListener.value = _bpm;
                        }
                        if (_isPlaying) {
                          stopPlaying();
                          startPlaying();
                        }
                      });
                      HapticFeedback.selectionClick();
                    },
                  ),
                  CupertinoButton(
                    child: Icon(CupertinoIcons.add_circled, size: 32.sp),
                    onPressed: () {
                      setState(() {
                        _bpm += 1;
                        _bpmListener.value = _bpm;
                        if (_isPlaying) {
                          stopPlaying();
                          startPlaying();
                        }
                      });
                    },
                  ),
                ],
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showDialog(
                      CupertinoPicker(
                        magnification: 1.22,
                        squeeze: 1.2,
                        useMagnifier: true,
                        itemExtent: 24.h,
                        scrollController: FixedExtentScrollController(
                            initialItem: beats_per_bar - 1
                        ),
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            beats_per_bar = index + 1;
                          });
                          if (_isPlaying) {
                            stopPlaying();
                            startPlaying();
                          }
                          HapticFeedback.selectionClick();
                        },
                        children: List<Widget>.generate(16, (int index) {
                          final int value = index + 1;
                          return Center(
                            child: Text(value.toString(), style: TextStyle(color: theme.color3Getter),),
                          );
                        }),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('分子', style: TextStyle(fontSize: 16.sp, color: theme.color3Getter)),
                        Text('${beats_per_bar}', style: TextStyle(fontSize: 32.sp)),
                      ],
                    ),
                  ),
                  SizedBox(width: 30.w),
                  GestureDetector(
                    onTap: () => _showDialog(
                      CupertinoPicker(
                        magnification: 1.22,
                        squeeze: 1.2,
                        useMagnifier: true,
                        itemExtent: 24.h,
                        scrollController: FixedExtentScrollController(
                            initialItem: (log(note_type) / log(2)).round()-1
                        ),
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            note_type = 2 << index;
                          });
                          if (_isPlaying) {
                            stopPlaying();
                            startPlaying();
                          }
                          HapticFeedback.selectionClick();
                        },
                        children: List<Widget>.generate(4, (int index) {
                          final int value = 2 << index;
                          return Center(
                            child: Text(value.toString(), style: TextStyle(color: theme.color3Getter)),
                          );
                        }),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('分母', style: TextStyle(fontSize: 16.sp, color: theme.color3Getter)),
                        Text('${note_type}', style: TextStyle(fontSize: 32.sp)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 210.h),
              Metronome(durationListener, isPlayingListener, speed_type.value!=0, _bpmListener!),
              SizedBox(height: 48.h),
              BeatIndicator(beat_notifier!, beats_per_bar, _isPlaying),
              SizedBox(height: 24.h),
              CupertinoButton(
                color: theme.color4Getter,
                child: Icon(!_isPlaying ? CupertinoIcons.play_arrow_solid : CupertinoIcons.stop_fill, size: 24, color: theme.color2Getter,),
                onPressed: () async {
                  await db.insert('basic', {'bpm': _bpm, 'beats_per_bar': beats_per_bar, 'note_type': note_type, 'date': DateTime.now().toString()});
                  await db.insert('settings', {'speedUpType': boolToInt(speedUpController.speedUpType.value==0), 'speedUp': speedUpController.speedUp.value, 'speedUpInterval': boolToInt(speedUpController.speedUpInterval.value==0), 'date': DateTime.now().toString()});
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                  if (_isPlaying) {
                    startPlaying();
                  } else {
                    stopPlaying();
                  }
                  HapticFeedback.heavyImpact();
                },
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ],
      ),
    );
  }

  late Timer _timer;
  int beat_count_32th = 0; // 32th notes' beat
  ValueNotifier<int>? beat_notifier; // beat
  int note_count = 0;

  int boolToInt(bool value){
    if (value){
      return 1;
    }
    return 0;
  }

  void showPlayingGrettings(){
    switch (_playingSeconds.value){
      case 60:
        Fluttertoast.showToast(
            msg: "你已经练习一分钟了，加油！",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            textColor: CupertinoColors.white,
            fontSize: 16.0.sp
        );
        break;

      case 300:
        Fluttertoast.showToast(
            msg: "你已经练习五分钟了，辛苦啦！",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            textColor: CupertinoColors.white,
            fontSize: 16.0.sp
        );
        break;

      case 600:
        Fluttertoast.showToast(
            msg: "你已经坚持练习十分钟了，很棒！",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            textColor: CupertinoColors.white,
            fontSize: 16.0.sp
        );
        break;

      case 1800:
        Fluttertoast.showToast(
            msg: "你已经练习半小时了，加油！",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            textColor: CupertinoColors.white,
            fontSize: 16.0.sp
        );
        break;

      case 3600:
        Fluttertoast.showToast(
            msg: "你已经练习一小时了，注意休息",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            textColor: CupertinoColors.white,
            fontSize: 16.0.sp
        );
        break;

      default:
        break;

    }
  }

  void showDailyGreetings(){
    DateTime now = DateTime.now();
    if (now.hour < 6) {
      Fluttertoast.showToast(
          msg: "凌晨好，注意休息",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: CupertinoColors.white,
          fontSize: 16.0.sp
      );
    } else if (now.hour < 9) {
      Fluttertoast.showToast(
          msg: "早上好，一日之际在于晨",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: CupertinoColors.white,
          fontSize: 16.0.sp
      );
    } else if (now.hour < 12) {
      Fluttertoast.showToast(
          msg: "上午好，祝你练琴有个好心情",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: CupertinoColors.white,
          fontSize: 16.0.sp
      );
    } else if (now.hour < 14) {
      Fluttertoast.showToast(
          msg: "中午好，祝你的心情像阳光一样灿烂",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: CupertinoColors.white,
          fontSize: 16.0.sp
      );
    } else if (now.hour < 17) {
      Fluttertoast.showToast(
          msg: "下午好，练琴愉快",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: CupertinoColors.white,
          fontSize: 16.0.sp
      );
    } else if (now.hour < 19) {
      Fluttertoast.showToast(
          msg: "傍晚好，祝你练琴像晚霞一样开心",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: CupertinoColors.white,
          fontSize: 16.0.sp
      );
    } else if (now.hour < 22) {
      Fluttertoast.showToast(
          msg: "晚上好，为坚持练琴的你感动",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: CupertinoColors.white,
          fontSize: 16.0.sp
      );
    } else {
      Fluttertoast.showToast(
          msg: "夜深了，注意休息",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: CupertinoColors.white,
          fontSize: 16.0.sp
      );
    }
  }

  void startPlaying() {
    beat_count_32th = 0;
    beat_notifier?.value = -1;
    // calculate delay based on BPM, and the delay is of 16th note
    isPlayingListener.value = true;
    durationListener.value = ((60 / _bpm) * 1000 / (32 / note_type)).round() * (32 / note_type).toInt();
    createTimer();
    if (!_hasGreeting){
      showDailyGreetings();
      _hasGreeting = true;
    }
    _secondsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying) {
        _playingSeconds.value++ ;
        showPlayingGrettings();
      }
    });
  }

  void createTimer(){
    final delay = Duration(milliseconds: ((60 / _bpm.toInt()) * 1000 / (32 / note_type)).round());
    _timer = Timer.periodic(delay, (timer) {
      // 强弱弱弱
      if ((beat_count_32th) % (32 / note_type) == 0) {
        if (note_count % beats_per_bar == 0) {
          // strong
          note_count = 0;
          if (!isCustomRythm.value)
            pool.play(tickSoundId);
          if (isLightOn.value){
            if (controller != null) {
              controller?.setFlashMode(FlashMode.torch);
              _isCameraActuallyOn = true;
            } else {
              print('camera is null');
              isLightOn.value =false;
              _isCameraActuallyOn = false;
            }
          }
          if (isImpactOn.value) {
            HapticFeedback.vibrate();
          }
          isStress.value = true;
          // if the user intend to change the speed per bar
          if (speedUpController.speedUpInterval.value){
            if (beat_count_32th != 0){
              switch(speed_type.value){
                case 0:
                  break;
                case 1:
                  setState(() {
                    _bpm = speedUpController.BPMafterSpeedUP(_bpm);
                    _bpmListener.value = _bpm;
                  });
                  timer.cancel();
                  createTimer();
                  durationListener.value = ((60 / _bpm) * 1000 / (32 / note_type)).round() * (32 / note_type).toInt();
                  break;
                case 2:
                  setState(() {
                    _bpm = speedUpController.BPMafterSpeedDOWN(_bpm);
                    _bpmListener.value = _bpm;
                  });
                  timer.cancel();
                  createTimer();
                  durationListener.value = ((60 / _bpm.toInt()) * 1000 / (32 / note_type)).round() * (32 / note_type).toInt();
                  break;
              }
            }
          }
        } else {
          // weak
          if (!isCustomRythm.value)
            pool.play(tackSoundId);
          if (_isCameraActuallyOn){
            _isCameraActuallyOn = false;
            controller?.setFlashMode(FlashMode.off);
          }
          isStress.value = false;
        }
        note_count++;
        beat_notifier?.value = note_count - 1;

        // if the user intend to change the speed per beat
        if (speedUpController.speedUpInterval.value == false){
          if (beat_count_32th != 0){
            switch(speed_type.value){
              case 0:
                break;
              case 1:
                setState(() {
                  _bpm = speedUpController.BPMafterSpeedUP(_bpm);
                  _bpmListener.value = _bpm;
                });
                timer.cancel();
                createTimer();
                durationListener.value = ((60 / _bpm) * 1000 / (32 / note_type)).round() * (32 / note_type).toInt();
                break;
              case 2:
                setState(() {
                  _bpm = speedUpController.BPMafterSpeedDOWN(_bpm);
                  _bpmListener.value = _bpm;
                });
                timer.cancel();
                createTimer();
                durationListener.value = ((60 / _bpm.toInt()) * 1000 / (32 / note_type)).round() * (32 / note_type).toInt();
                break;
            }
          }
        }

        if (doesUserSetBackgroundLightOn.value)
          isBackgroundActuallyLightOn.value = true;
      }

      beat_count_32th++;
      if (beat_count_32th % beats_per_bar == 0) {
        isBackgroundActuallyLightOn.value = false;
      }

      if (isCustomRythm.value){
        if (customRythmConstroller.checkIfStressRythm((beat_count_32th%(32/note_type * beats_per_bar)).toInt())){
          pool.play(tickSoundId);
        }
        if (customRythmConstroller.checkIfWeakRythm((beat_count_32th%(32/note_type * beats_per_bar)).toInt())){
          pool.play(tackSoundId);
        }
      }
    }


    );
  }

  void stopPlaying() {
    _timer.cancel();
    _secondsTimer.cancel();
    beat_notifier?.value = 0;
    isPlayingListener.value = false;
    beat_count_32th = 0;
    note_count = 0;
  }

  Future<List<Map<String, dynamic>>> getBPMList(){
    return db.query('basic');
  }

  Widget showBPMList(){
    return FutureBuilder(
      future: getBPMList(),
      builder: (context, snapshot){
        if (snapshot.hasError) {
          print(snapshot.error);
          return CupertinoPageScaffold(child: CupertinoActivityIndicator(), backgroundColor: theme.color1,);
        } else if (snapshot.hasData){
          return CupertinoPicker(
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 24.h,
            scrollController: FixedExtentScrollController(
                initialItem: snapshot.data!.length - 1,
            ),
            onSelectedItemChanged: (int index) {
              setState(() {
                _bpm = snapshot.data?[index]['bpm'].toDouble();
                _bpmListener.value = _bpm;
                note_type = snapshot.data?[index]['note_type'];
                beats_per_bar = snapshot.data?[index]['beats_per_bar'];
              });
              if (_isPlaying) {
                stopPlaying();
                startPlaying();
              }
              HapticFeedback.selectionClick();
            },
            children: List<Widget>.generate(snapshot.data!.length, (int index) {
              String text = "BPM: " + snapshot.data![index]['bpm'].round().toString() + "  " + snapshot.data![index]['beats_per_bar'].toString() + "/"  + snapshot.data![index]['note_type'].toString();
              return Center(
                child: Text(text, style: TextStyle(color: theme.color3Getter),),
              );
            }),
          );
        } else {
          return CupertinoPageScaffold(child: CupertinoActivityIndicator(), backgroundColor: theme.color1,);
        }
      }
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secondsTimer?.cancel();
    controller?.dispose();
    super.dispose();
  }
}