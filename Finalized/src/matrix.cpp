#include "matrix.h"

void _formatMatrixData(SenseModes mode, IndexingModes readMatrixBy);

char matrixBuffer[MATRIX_DATA_LENGTH];
float matrixData[MATRIX_ROWS][MATRIX_COLUMNS]; 

void setupMatrix() {
  pinMode(ADC_GND_PIN, INPUT);

  setupRows();
  setupColumns();
}

void scanMatrix(SenseModes mode, IndexingModes readMatrixBy) {
  for (int column = 0; column < MATRIX_COLUMNS; column++) {
    activateColumn(mode, column);
    delayMicroseconds(MATRIX_SWITCH_TIME);

    //int code_ref = ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES);
    //int code_gnd = ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES);

    for (int row = 0; row < MATRIX_ROWS; row++) {
      activateRow(mode, row);
      delayMicroseconds(MATRIX_SWITCH_TIME);

      int code_sensor;
      float data;
      if (mode == TEMPERATURE) {
        code_sensor = ADCMeanFilter((row < MUX_PINS) ? MATRIX_ADC_1 : MATRIX_ADC_2, ADC_SAMPLES);
        data = readThermistorTemperature(code_sensor, PULL_DOWN_R);
      } else {
        code_sensor = ADCMeanFilter((row < MUX_PINS) ? MATRIX_ADC_3 : MATRIX_ADC_4, ADC_SAMPLES);
        data = readFSRNormalizedFromCodes(code_sensor);
      }

      matrixData[row][column] = data;
    }
  }

  deactivateColumns();
  deactivateRows();

  _formatMatrixData(mode, readMatrixBy);
}

float scanMatrixIndividual(int column, int row, SenseModes mode, bool disable) {
  activateColumn(mode, column);
  delayMicroseconds(MATRIX_SWITCH_TIME);

  activateRow(mode, row);
  delayMicroseconds(MATRIX_SWITCH_TIME);

  int code_sensor;
  float data;

  if (mode == TEMPERATURE) code_sensor = ADCMeanFilter((row < MUX_PINS) ? MATRIX_ADC_1 : MATRIX_ADC_2, ADC_SAMPLES);
  else code_sensor = ADCMeanFilter((row < MUX_PINS) ? MATRIX_ADC_3 : MATRIX_ADC_4, ADC_SAMPLES);

  if (mode == TEMPERATURE) data = readThermistorTemperature(code_sensor, PULL_DOWN_R);
  else data = readFSRNormalizedFromCodes(code_sensor);

  if(disable) {
    deactivateColumns();
    deactivateRows();
  }

  return data;
}

float scanMatrixIndividual(int column, int row, int code_gnd, int code_ref, SenseModes mode, bool disable) {
  activateColumn(mode, column);
  delayMicroseconds(MATRIX_SWITCH_TIME);

  activateRow(mode, row);
  delayMicroseconds(MATRIX_SWITCH_TIME);

  int code_sensor;
  float data;

  if (mode == TEMPERATURE) code_sensor = ADCMeanFilter((row < MUX_PINS) ? MATRIX_ADC_1 : MATRIX_ADC_2, ADC_SAMPLES);
  else code_sensor = ADCMeanFilter((row < MUX_PINS) ? MATRIX_ADC_3 : MATRIX_ADC_4, ADC_SAMPLES);

  if (mode == TEMPERATURE) data = readThermistorTemperature(code_sensor, code_gnd, code_ref, PULL_DOWN_R);
  else data = readFSRNormalizedFromCodes(code_sensor, code_gnd, code_ref);

  if(disable) {
    deactivateColumns();
    deactivateRows();
  }

  return data;
}

void _formatMatrixData(SenseModes mode, IndexingModes readMatrixBy) {
  matrixBuffer[0] = '\0';

  if (readMatrixBy == READ_BY_COLUMNS) {
    for (int column = 0; column < MATRIX_COLUMNS; column++) {
      for (int row = 0; row < MATRIX_ROWS; row++) {
        char dataBuffer[16];
        float data = matrixData[row][column];

        if (mode == TEMPERATURE) {
          if (!isnan(data)) snprintf(dataBuffer, sizeof(dataBuffer), "%.2f", data);
          else snprintf(dataBuffer, sizeof(dataBuffer), "NaN");
        } else {
          if (!isnan(data)) snprintf(dataBuffer, sizeof(dataBuffer), "%.1f", data);
          else snprintf(dataBuffer, sizeof(dataBuffer), "%.1f", 0.0);
        }

        strlcat(matrixBuffer, dataBuffer, sizeof(matrixBuffer));

        if (!(column == MATRIX_COLUMNS - 1 && row == MATRIX_ROWS - 1)) strlcat(matrixBuffer, " ", sizeof(matrixBuffer));
      }
    }
  } else {
    for (int row = 0; row < MATRIX_ROWS; row++) {
      for (int column = 0; column < MATRIX_COLUMNS; column++) {
        char dataBuffer[16];
        float data = matrixData[row][column];

        if (mode == TEMPERATURE) {
          if (!isnan(data)) snprintf(dataBuffer, sizeof(dataBuffer), "%.2f", data);
          else snprintf(dataBuffer, sizeof(dataBuffer), "NaN");
        } else {
          if (!isnan(data)) snprintf(dataBuffer, sizeof(dataBuffer), "%.1f", data);
          else snprintf(dataBuffer, sizeof(dataBuffer), "%.1f", 0.0);
        }

        strlcat(matrixBuffer, dataBuffer, sizeof(matrixBuffer));

        if (!(column == MATRIX_COLUMNS - 1 && row == MATRIX_ROWS - 1)) strlcat(matrixBuffer, " ", sizeof(matrixBuffer));
      }
    }
  }
}
