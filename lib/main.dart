import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wakelock/wakelock.dart';

import 'Views/BeatBox.dart';
import 'Views/Components/Theme.dart';


List<CameraDescription> cameras = [];
late Database database;

Future<void> main() async{
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
    database = await openDatabase(
      join(await getDatabasesPath(), 'doggie_database.db'),
      onCreate: (db, version) async {
        // create tables for past basic, rythms, and settings
        // basic: id, bpm, beats_per_bar, note_type, date
        // rythm: id, bpm, beats_per_bar, note_type, label, stress_rythm, weak_rythm, date
        // settings: id, speedUpType, speedUpInterval, speedUp
        await db.execute(
'''
create table basic(
  id integer primary key autoincrement,
  bpm integer not null,
  beats_per_bar integer not null,
  note_type integer not null,
  date text not null
);
'''
        );

        await db.execute("""
        create table rythm(
  id integer primary key autoincrement,
  beats_per_bar integer not null,
  note_type integer not null,
  label text not null,
  stress_rythm text not null,
  weak_rythm text not null,
  date text not null
);
        """);

        await db.execute("""
        create table settings(
  id integer primary key autoincrement,
  speedUpType integer not null,
  speedUpInterval integer not null,
  speedUp real not null,
  date text not null
);
        """);
      },
      version: 1,
    );
  } catch (e) {
    print(e);
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  Wakelock.enable();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  late var speedUpData;

  Future<CameraDescription> getCamera() async {
    final cameras = await availableCameras();
    return cameras.first;
  }

  Future<List<Map<String, dynamic>>> getBasic() async{
    var db = await database;
    final List<Map<String, dynamic>> maps = await db.query('basic');
    speedUpData = await db.query('settings');
    return maps;
  }

  @override
  Widget build(BuildContext context) {
    Theme theme = Get.put(Theme());

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context , child) {
        return GetCupertinoApp(
          home: FutureBuilder(
            future: getBasic(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return BeatBox(snapshot: snapshot, speedUpData: speedUpData,);
              } else if (snapshot.hasError) {
                return CupertinoActivityIndicator();
              } else {
                return CupertinoPageScaffold(child: CupertinoActivityIndicator());
              }
            },
          ),
          theme: CupertinoThemeData(
            primaryColor: theme.color3Getter,
            textTheme: CupertinoTextThemeData(
              textStyle: TextStyle(
                fontFamily: GoogleFonts.getFont('Noto Sans').fontFamily,
                color: theme.color2Getter,
              ),
            ),
          ),
        );
      },
    );


  }
}

