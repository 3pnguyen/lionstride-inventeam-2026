#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"
#include "test.h"

EspModes mode;

void setup() {
  setupMatrix();

  #ifndef TEST
    pinMode(DISCOVER_PIN, INPUT_PULLUP);
    mode = discoverMode();

    if(mode == PRIMARY) setupBluetooth();
    setupSerialCommunication();
  #else
    setupTest();
  #endif
}

void loop() {
  #ifndef TEST
    ((mode == PRIMARY) ? handleBluetoothCommands : receiveMessagesSecondary)();
  #else
    test();
  #endif

  delay(1);
}