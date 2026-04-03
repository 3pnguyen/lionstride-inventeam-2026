#pragma once

#include <Arduino.h>
#include "bluetooth.h"
#include "serial.h"
#include "matrix.h"
#include "macros.h" 

static String input;
static int inputRow;
static int inputColumn;

/* ----------------- Testing commands -----------------

* temperature: Scans the entire matrix and returns temperature data

* pressure: Scans the entire matrix and returns pressure data 

* battery: Returns battery percentage

* i temperature: Scans an individual column and row and returns temperature data
  - User input column and row

* i pressure: Scans an individual column and row and returns pressure data
  - User input column and row

* test adc: Tests ADC outputs
  - User input column and row

* debug mcps: Tests all expanders

* walk mcps: Tests all expanders

* debug rows: Tests both multiplexers

* test math: Tests the conversion math from ADC to voltage, resistance, and temperature

* i matrix: Activate a specific column and row on the matrix
  - User input column and row

* d matrix: Deactivate the entire matrix

---------------------------------------------------- */

static inline void setupTest() {
    Serial.begin(115200);
    Serial.setTimeout(1000);

    #ifdef WEB_MODE
      do {
        input = Serial.readStringUntil('\n');
        input.trim();
        delay(1);
      } while (!input.equals("start"));
    #endif

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

    auto getMatrixInput = []() -> bool {
      Serial.setTimeout(5000);
      #ifndef WEB_MODE
        Serial.println("Column: ");
      #endif
      inputColumn = Serial.parseInt() - 1; // parseInt -1 reuturns -1 if invalid
      #ifndef WEB_MODE
        Serial.println("Row: ");
      #endif
      inputRow = Serial.parseInt() - 1;

      if (inputColumn < 0 || inputColumn >= MATRIX_COLUMNS || inputRow < 0 || inputRow >= MATRIX_ROWS) {
        Serial.println("Invalid input! Disabling columns and rows.");
        inputColumn = -1;
        inputRow = -1;
        deactivateColumns();
        deactivateRows();
        return false;
      }

      Serial.setTimeout(1000);
      return true;
    };

    if (Serial.available() > 0) {
      getInput();

      if (input.equals("temperature")) { // to test matrix, sensor, and filter
        Serial.println("Temperature matrix:");
        scanMatrix(TEMPERATURE, READ_BY_ROWS);
        Serial.println(matrixBuffer);

      } else if (input.equals("pressure")) { // to test matrix, sensor, and filter
        Serial.println("Pressure matrix:");
        scanMatrix(PRESSURE, READ_BY_ROWS);
        Serial.println(matrixBuffer);

      } else if (input.equals("battery")) { // to test battery
        battery(true);
      } else if (input.equals("i temperature")) { // to test matrix, sensor, and filter
        if (!getMatrixInput()) return;

        Serial.println(
          String(
            scanMatrixIndividual(
              inputColumn,
              inputRow,
              TEMPERATURE,
              true
            )
          )
        );

      } else if (input.equals("i pressure")) { // to test matrix, sensor, and filter
        if (!getMatrixInput()) return;
        
        Serial.println(
          String(
            scanMatrixIndividual(
              inputColumn,
              inputRow,
              PRESSURE,
              true
            )
          )
        );

      } else if (input.equals("test adc")) { // to test expander and multiplexer
        if (!getMatrixInput()) return;
        
        int codeRefTemperature = getRefOutput(TEMPERATURE, false);
        int codeRefPressure = getRefOutput(PRESSURE, false);

        activateColumn(TEMPERATURE, inputColumn);
        activateRow(TEMPERATURE, inputRow);
        activateColumn(PRESSURE, inputColumn);
        activateRow(PRESSURE, inputRow);

        Serial.println(
          "GND ADC: " +
          String(analogRead(ADC_GND_PIN)) +
          ", REF (TEMPERATURE) ADC: " +
          String(codeRefTemperature) +
          ", REF (PRESSURE) ADC: " +
          String(codeRefPressure) +
          ", Temperature ADC reading: " +
          String(analogRead((inputRow < MUX_PINS) ? MATRIX_ADC_1 : MATRIX_ADC_2)) + 
          ", Pressure ADC reading: " +
          String(analogRead((inputRow < MUX_PINS) ? MATRIX_ADC_3 : MATRIX_ADC_4))
        );

        deactivateColumns();
        deactivateRows();

      } else if (input.equals("debug mcps")) { // to test expander 
        debugMCPConnections();

      } else if (input.equals("walk mcps")) { // to test expander 
        debugMCPWalkAllOutputs();

      } else if (input.equals("debug rows")) { // to test multiplexer
        debugTMUXControlLines();

      } else if (input.equals("test math")) { // to test sensor
        Serial.println("The inputed sample ADC code is 2555...");
        Serial.println("Which should be about 2.06V (2.059), 6.03k ohms, and 96.8 degrees F...");
        Serial.println("Running math debug function.");
        debugSensorMath(2555);
        
      } else if (input.equals("i matrix")) { // to test matrix
        if (!getMatrixInput()) return;
        activateColumn(TEMPERATURE, inputColumn);
        activateRow(TEMPERATURE, inputRow);
        activateColumn(PRESSURE, inputColumn);
        activateRow(PRESSURE, inputRow);

        Serial.println("Individual column and row activated on both matrices.");

      } else if (input.equals("d matrix")) { // to test matrix
        deactivateColumns();
        deactivateRows();
        
        Serial.println("Matrix deactivated.");

      } else { // for edge cases and errors
        #ifndef WEB_MODE
          Serial.println("Wdym!?");
        #endif
      }
    }
}