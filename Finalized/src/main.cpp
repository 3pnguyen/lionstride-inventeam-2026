#include <Arduino.h>
#include "bluetooth.h"
#include "matrix.h"
#include "test.h"
#include "global.h" //optimization

void setup() {
  setupMatrix();

  #ifndef TEST
    setupBluetooth();
  #else
    setupTest();
  #endif
}

void loop() {
  #ifndef TEST
    handleBluetoothCommands();
  #else
    test();
  #endif

  delay(1);
}