#include "matrix.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define SWITCH_TIME 500 // microseconds
#define INSTRUCTIONS_DATA_LENGTH 100 // also a lot of extra space
#define PRESSURE_TIMEOUT 2000

//-------------------------------------------------------------------------------------------------------

IntervalTimer pressureTimeout(PRESSURE_TIMEOUT);

char matrixBuffer[MATRIX_DATA_LENGTH];
char instructionBuffer[INSTRUCTIONS_DATA_LENGTH];

void setupMatrix() {
  pinMode(ADC_REF_PIN, INPUT);
  pinMode(ADC_GND_PIN, INPUT);

  setupRows();
  setupColumns();
}

void scanMatrix(SenseModes mode) {
  matrixBuffer[0] = '\0';

  if (mode == TEMPERATURE) {
    for (int column = 0; column < maxColumn(); column++) {
      activateColumn(column);
      delayMicroseconds(SWITCH_TIME);

      int code_ref = ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES);
      int code_gnd = ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES);

      for (int row = 0; row < maxRow(); row++) {
        activateRow(row);
        delayMicroseconds(SWITCH_TIME);

        int code_sensor = ADCMeanFilter((row < maxMultiplexerPins()) ? MATRIX_ADC_1 : MATRIX_ADC_2, ADC_SAMPLES);
        float data = readThermistorTemperature(code_sensor, code_gnd, code_ref);

        char dataBuffer[16];
        if (!isnan(data)) snprintf(dataBuffer, sizeof(dataBuffer), "%.2f", data);
        else snprintf(dataBuffer, sizeof(dataBuffer), "NaN");

        strlcat(matrixBuffer, dataBuffer, sizeof(matrixBuffer));

        if (!(column == maxColumn() - 1 && row == maxRow() - 1)) strlcat(matrixBuffer, " ", sizeof(matrixBuffer));
      }
    }

    activateColumn();
    activateRow();

  } else if (mode == PRESSURE) {
    instructionBuffer[0] = '\0';
    pressureTimeout.reset();

    for (int column = 0; column < maxColumn(); column++) {
      int code_ref = ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES);
      int code_gnd = ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES);

      for (int row = 0; row < maxRow(); row++) {
        if (pressureTimeout.isReady()) {
          matrixBuffer[0] = '\0';
          snprintf(matrixBuffer, sizeof(matrixBuffer), "timeout");
          return;
        }

        snprintf(
          instructionBuffer, 
          sizeof(instructionBuffer), 
          "scan matrix individual,%d,%d,%d,%d,p,%s",
          column,
          row,
          code_gnd,
          code_ref,
          (column == maxColumn() - 1 && row == maxRow() - 1) ? "true" : "false"
        );

        sendMessage(instructionBuffer);

        char cellBuffer[32];
        cellBuffer[0] = '\0';
        if (!receiveMessagesPrimary(cellBuffer, sizeof(cellBuffer))) {
          strlcat(matrixBuffer, "0.0", sizeof(matrixBuffer));
        } else {
          strlcat(matrixBuffer, cellBuffer, sizeof(matrixBuffer));
        }

        if (!(column == maxColumn() - 1 && row == maxRow() - 1)) strlcat(matrixBuffer, " ", sizeof(matrixBuffer));
      }
    }
  } else if (mode == PRESSURE_PRIMARY) {
    for (int column = 0; column < maxColumn(); column++) {
      activateColumn(column);
      delayMicroseconds(SWITCH_TIME);

      int code_ref = ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES);
      int code_gnd = ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES);

      for (int row = 0; row < maxRow(); row++) {
        activateRow(row);
        delayMicroseconds(SWITCH_TIME);

        int code_sensor = ADCMeanFilter((row < maxMultiplexerPins()) ? MATRIX_ADC_1 : MATRIX_ADC_2, ADC_SAMPLES);
        float data = readFSRNormalizedFromCodes(code_sensor, code_gnd, code_ref);

        char dataBuffer[16];
        if (!isnan(data)) snprintf(dataBuffer, sizeof(dataBuffer), "%.1f", data);
        else snprintf(dataBuffer, sizeof(dataBuffer), "%.1f", 0.0);

        strlcat(matrixBuffer, dataBuffer, sizeof(matrixBuffer));

        if (!(column == maxColumn() - 1 && row == maxRow() - 1)) strlcat(matrixBuffer, " ", sizeof(matrixBuffer));
      }
    }

    activateColumn();
    activateRow();
  }
}

float scanMatrixIndividual(int column, int row, int code_gnd, int code_ref, SenseModes mode, bool disable) {
  activateColumn(column);
  delayMicroseconds(SWITCH_TIME);

  activateRow(row);
  delayMicroseconds(SWITCH_TIME);

  int code_sensor = ADCMeanFilter((row < maxMultiplexerPins()) ? MATRIX_ADC_1 : MATRIX_ADC_2, ADC_SAMPLES);
  float data;
  if (mode == TEMPERATURE) data = readThermistorTemperature(code_sensor, code_gnd, code_ref);
  else data = readFSRNormalizedFromCodes(code_sensor, code_gnd, code_ref);

  if(!disable) {
    activateColumn();
    activateRow();
  }

  return data;
}