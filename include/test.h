#pragma once

#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"
#include "filter.h"

String input;
IntervalTimer hardwareTimeout(60000);

/*

Testing commands:

* temperature
* pressure
* battery
* i temperature (individual temperature)
* i pressure (individual pressure)
* test hardware
* debug mcp1
* debug mcp2
* walk mcp1
* walk mcp2
* debug rows
* test math

*/

static inline void setupTest() {
    Serial.begin(115200);

    for (int i = 3; i > 0; i--) {
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
      } else if (input.equals("i temperature")) { // to test matrix, sensor, and filter
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

      } else if (input.equals("i pressure")) { // to test matrix, sensor, and filter
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

          Serial.println(
            "GND ADC: " +
            String(analogRead(ADC_GND_PIN)) +
            ", REF ADC: " +
            String(analogRead(ADC_REF_PIN)) +
            ", Sensor ADC: " +
            String(analogRead(MATRIX_ADC_1))
          );

          delay(100);
        } while (!hardwareTimeout.isReady() && input != "stop");

        activateColumn();
        activateRow();

      } else if (input.equals("debug mcp1")) { // to test expander
        debugMCPConnection(MCP1);

      } else if (input.equals("debug mcp2")) { // to test expander
        debugMCPConnection(MCP2);

      } else if (input.equals("walk mcp1")) { // to test expander
        debugMCPWalkOutputs(MCP1);

      } else if (input.equals("walk mcp2")) { // to test expander
        debugMCPWalkOutputs(MCP2);

      } else if (input.equals("debug rows")) { // to test multiplexer
        debugTMUXControlLines();

      } else if (input.equals("test math")) { // to test sensor
        Serial.println("The inputed sample ADC code is 2555...");
        Serial.println("Which should be about 2.06V (2.059), 6.03k ohms, and 96.8 degrees F...");
        Serial.println("Running math debug function.");
        debugSensorMath(2555);
        
      } else { // for edge cases and errors
        Serial.println("Wdym " + input + "!?");

      }
    }
}