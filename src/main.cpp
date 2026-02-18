#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"

EspModes mode;
String input;

void setup() {
  setupMatrix();

  #ifndef TEST
    pinMode(DISCOVER_PIN, INPUT_PULLUP);
    mode = discoverMode();

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
      input = Serial.readStringUntil('\n');
      input.trim();

      if (input.equals("temperature")) {
        scanMatrix(TEMPERATURE);
        Serial.println(matrixBuffer);
      } else if (input.equals("pressure")) {
        scanMatrix(PRESSURE);
        Serial.println(matrixBuffer);
      } else if (input.equals("battery")) {
        battery(true);
      }
    }
  #endif

  delay(1);
}