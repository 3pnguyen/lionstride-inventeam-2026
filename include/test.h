#pragma once

#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"
#include "filter.h"
#include "macros.h" //optimization

static String input;
static int inputRow;
static int inputColumn;
static IntervalTimer hardwareTimeout(60000);

/* ----------------- Testing commands -----------------

* temperature: Scans the entire matrix and returns temperature data

* pressure: Scans the entire matrix and returns pressure data 

* battery: Returns battery percentage

* i temperature: Scans an individual column and row and returns temperature data
  - User input column and row

* i pressure: Scans an individual column and row and returns pressure data
  - User input column and row

* test adc: Tests ADC outputs
  - User input column, row, and "stop" to exit the loop (60 seconds timeout)

* debug mcp1: Tests expander 1

* debug mcp2: Tests expander 2

* walk mcp1: Tests expander 1

* walk mcp2: Tests expander 2

* debug rows: Tests both multiplexers

* test math: Tests the conversion math from ADC to voltage, resistance, and temperature

* i matrix: Activate a specific column and row on the matrix
  - User input column and row

* d matrix: Deactivate the entire matrix

---------------------------------------------------- */

static inline void setupTest() {
    Serial.begin(115200);
    Serial.setTimeout(1000);

    for (int i = 3; i > 0; i--) {
      Serial.println(String(i) + "...");
      delay(1000);
    }

    Serial.println("Testing begun...");
}

static inline void test() {
    auto getInput = []() -> void {
      input = Serial.readStringUntil('\n');
      input.trim();
    };

    auto getMatrixInput = []() -> void {
      Serial.setTimeout(5000);
      
      Serial.println("Column: ");
      inputColumn = Serial.parseInt() - 1; // parseInt -1 reuturns -1 if invalid
      Serial.println("Row: ");
      inputRow = Serial.parseInt() - 1;

      if (inputColumn < 0 || inputColumn >= MATRIX_COLUMNS || inputRow < 0 || inputRow >= MATRIX_ROWS) {
        Serial.println("Invalid input! Disabling columns and rows.");
        inputColumn = -1;
        inputRow = -1;
      }

      Serial.setTimeout(1000);
    };

    if (Serial.available() > 0) {
      getInput();

      if (input.equals("temperature")) { // to test matrix, sensor, and filter
        Serial.println("Temperature matrix:");
        scanMatrix(TEMPERATURE);
        Serial.println(matrixBuffer);

      } else if (input.equals("pressure")) { // to test matrix, sensor, and filter
        Serial.println("Pressure matrix:");
        scanMatrix(PRESSURE_PRIMARY);
        Serial.println(matrixBuffer);

      } else if (input.equals("battery")) { // to test battery
        battery(true);
      } else if (input.equals("i temperature")) { // to test matrix, sensor, and filter
        getMatrixInput();

        Serial.println(
          String(
            scanMatrixIndividual(
              inputColumn,
              inputRow,
              0, //ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES),
              -1, //ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES),
              TEMPERATURE,
              true
            )
          )
        );

      } else if (input.equals("i pressure")) { // to test matrix, sensor, and filter
        getMatrixInput();
        
        Serial.println(
          String(
            scanMatrixIndividual(
              inputColumn,
              inputRow,
              0, //ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES),
              -1, //ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES),
              PRESSURE,
              true
            )
          )
        );

      } else if (input.equals("test adc")) { // to test expander and multiplexer
        getMatrixInput();
        
        activateColumn(inputColumn);
        activateRow(inputRow);
        hardwareTimeout.reset();

        do {
          if (Serial.available() > 0) {
            getInput();

            Serial.println(
              "GND ADC: " +
              String(analogRead(ADC_GND_PIN)) +
              ", REF ADC: " +
              String(analogRead(ADC_REF_PIN)) +
              ", Sensor ADC: " +
              String(analogRead(MATRIX_ADC_1))
            );
          }

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
        
      } else if (input.equals("i matrix")) { // to test matrix
        getMatrixInput();
        activateColumn(inputColumn);
        activateRow(inputRow);

      } else if (input.equals("d matrix")) { // to test matrix
        activateColumn();
        activateRow();

      } else { // for edge cases and errors
        Serial.println("Wdym!?");

      }
    }
}