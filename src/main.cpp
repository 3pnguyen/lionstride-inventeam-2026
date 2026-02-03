#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"

EspModes mode;

void setup() {
  mode = discoverMode();

  setupMatrix();
  if(mode == PRIMARY) setupBluetooth();
  setupSerialCommunication();
}

void loop() {
  ((mode == PRIMARY) ? handleBluetoothCommands : receiveMessagesSecondary)();
  delay(1);
}