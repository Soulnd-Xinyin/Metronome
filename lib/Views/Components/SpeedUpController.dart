import 'package:get/get.dart';

class SpeedUpController extends GetxController {
  var speedUp = 1.2.obs;
  var speedUpType = false.obs; // false means +-, true means */
  var speedUpInterval = true.obs; // false means per beat, true means per bar

  void setSpeedUp(double speedUp) {
    this.speedUp = speedUp.obs;
    update();
  }

  void setSpeedUpType(bool speedUpType) {
    this.speedUpType = speedUpType.obs;
    update();
  }

  double BPMafterSpeedUP(double bpm){
    if(speedUpType.value == false) {
      if (bpm + speedUp.value <= 266){
        return bpm + speedUp.value;
      }
      return bpm;
    } else {
      if (bpm * speedUp.value <= 266){
        return bpm * speedUp.value;
      }
      return bpm;
    }
  }

  double BPMafterSpeedDOWN(double bpm){
    if(speedUpType.value == false) {
      if (bpm - speedUp.value <= 0){
        return bpm;
      }
      return bpm - speedUp.value;
    } else {
      if (bpm / speedUp.value <= 0){
        return bpm;
      }
      return bpm / speedUp.value;
    }
  }

}