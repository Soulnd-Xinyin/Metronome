import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';

class Theme extends GetxController {
  Color color1 = const Color(0xff333333); // background
  Color color2 = const Color(0xffffffff); // text
  Color color3 = const Color(0xffe1f4f3); // light
  Color color4 = const Color(0xff706c61); // dark light
  Color color5 = Color.fromARGB(255, 94, 94, 94); // grey
  Color color6 = Color.fromARGB(255, 0, 0, 0); // white
  Color get color1Getter => color1;
  Color get color2Getter => color2;
  Color get color3Getter => color3;
  Color get color4Getter => color4;
  Color get color5Getter => color5;
  Color get color6Getter => color6;

  void setTheme(int n){
    //TODO
  }

}