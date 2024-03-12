import 'dart:convert';

import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class CustomRythmConstroller extends GetxController {
  var _StressRythm = [].obs;
  var _WeakRythm = [].obs;
  var label = 'default'.obs;
  var beats_per_bar = 4.obs;
  var note_type = 4.obs;
  String date = DateTime.now().toString();

  void initRythm(int thirtytwo_notes_per_beat, int beats_per_bar) {
    // 32分音符每拍数 * 拍数
    int total_notes = thirtytwo_notes_per_beat * beats_per_bar;
    _StressRythm.value = List<bool>.filled(total_notes, false);
    _WeakRythm.value = List<bool>.filled(total_notes, false);
  }

  void setStressRythm(int index) {
    _StressRythm.value[index] = !_StressRythm[index];
    update();
  }

  void setWeakRythm(int index) {
    _WeakRythm.value[index] = !_WeakRythm[index];
    update();
  }

  bool checkIfStressRythm(int index) {
    return _StressRythm.value[index];
  }

  bool checkIfWeakRythm(int index) {
    return _WeakRythm.value[index];
  }


  String getLabel(){
    return label.value;
  }

  Map<String, dynamic> toMap(){
    return {
      'label': label.value,
      'beats_per_bar': beats_per_bar.value,
      'note_type': note_type.value,
      'stress_rythm': json.encode(_StressRythm.value),
      'weak_rythm': json.encode(_WeakRythm.value),
      'date': date,
    };
  }

  // construct a fromMap() function to construct a CustomRythmConstroller from a map
  void setFromMap(Map<String, dynamic> map){
    label.value = map['label'];
    beats_per_bar.value = map['beats_per_bar'];
    note_type.value = map['note_type'];
    _StressRythm.value = json.decode(map['stress_rythm']);
    _WeakRythm.value = json.decode(map['weak_rythm']);
    date = map['date'];
  }
}