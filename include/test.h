#pragma once

#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"

String input;

static inline void setupTest() {
    Serial.begin(115200);

    for (int i = 5; i > 0; i--) {
      Serial.println(String(i) + "...");
      delay(1000);
    }

    Serial.println("Testing begun...");
}

static inline void test() {
    if (Serial.available() > 0) {
      input = Serial.readStringUntil('\n');
      input.trim();

      if (input.equals("temperature")) { // to test matrix, sensor, and filter
        scanMatrix(TEMPERATURE);
        Serial.println(matrixBuffer);

      } else if (input.equals("pressure")) { // to test matrix, sensor, and filter
        scanMatrix(PRESSURE_PRIMARY);
        Serial.println(matrixBuffer);

      } else if (input.equals("battery")) { // to test battery
        battery(true);
      } else if (input.equals("individual temperature")) { // to test matrix, sensor, and filter
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

      } else if (input.equals("individual pressure")) { // to test matrix, sensor, and filter
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

      } else if (input.equals("test hardware")) { // to test expander and multiplexer
        activateColumn(0);
        activateRow(0);

      } else if (input.equals("disable hardware")) { // disable hardware 
        activateColumn();
        activateRow();

      } else { // for edge cases and errors
        Serial.println("Wdym!?");

      }
    }
}