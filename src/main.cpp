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

    for (int i = 5; i > 0; i--) {
      Serial.println(String(i) + "...");
      delay(1000);
    }

    Serial.println("Testing begun...");
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
        scanMatrix(PRESSURE_PRIMARY);
        Serial.println(matrixBuffer);
      } else if (input.equals("battery")) {
        battery(true);
      } else if (input.equals("individual temperature")) {
        Serial.println(
          String(
            scanMatrixIndividual(
              0,
              0,
              ADCMeanFilter(ADC_GND_PIN, 15),
              ADCMeanFilter(ADC_REF_PIN, 15),
              TEMPERATURE,
              true
            )
          )
        );
      } else if (input.equals("individual pressure")) {
        Serial.println(
          String(
            scanMatrixIndividual(
              0,
              0,
              ADCMeanFilter(ADC_GND_PIN, 15),
              ADCMeanFilter(ADC_REF_PIN, 15),
              PRESSURE,
              true
            )
          )
        );
      } else {
        Serial.println("Wdym!?");
      }
    }
  #endif

  delay(1);
}