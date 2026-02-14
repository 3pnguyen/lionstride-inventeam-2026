#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"

EspModes mode;

void setup() {
  pinMode(DISCOVER_PIN, INPUT_PULLUP);
  
  mode = discoverMode();
  setupMatrix();

  #ifndef TEST
    if(mode == PRIMARY) setupBluetooth();
    setupSerialCommunication();
  #else
    Serial.begin(115200);
  #endif
}

void loop() {
  #ifndef TEST
    ((mode == PRIMARY) ? handleBluetoothCommands : receiveMessagesSecondary)();
  #else
    if (Serial.available() > 0) {
      switch (TEST) {
        case 0:
          scanMatrix((mode == PRIMARY) ? TEMPERATURE : PRESSURE);
          Serial.println(matrixBuffer);
          break;
        case 1:
          battery(true);
          break;
        default:
          break;
      }
    }
  #endif

  delay(1);
}