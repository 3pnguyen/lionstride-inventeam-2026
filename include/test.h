#pragma once

#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"
#include "filter.h"

String input;
IntervalTimer hardwareTimeout(60000);

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
              ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES),
              ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES),
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
              ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES),
              ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES),
              PRESSURE,
              true
            )
          )
        );

      } else if (input.equals("test hardware")) { // to test expander and multiplexer
        activateColumn(0);
        activateRow(0);
        hardwareTimeout.reset();

        do {
          input = Serial.readStringUntil('\n');
          input.trim();

          Serial.println(ADCMeanFilter(MATRIX_ADC_1, ADC_SAMPLES));

          delay(100);
        } while (!hardwareTimeout.isReady() && input != "stop");

        activateColumn();
        activateRow();

      } else { // for edge cases and errors
        Serial.println("Wdym!?");

      }
    }
}