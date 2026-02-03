#include "matrix.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define SWITCH_TIME 500 // microseconds
#define MATRIX_ADC_1 A2
#define MATRIX_ADC_2 A3
#define MATRIX_DATA_LENGTH 4096 // a lot of extra space
#define INSTRUCTIONS_DATA_LENGTH 100 // also a lot of extra space
#define ADC_SAMPLES 15

//-------------------------------------------------------------------------------------------------------

String matrixData;
String instructionsData;

void setupMatrix() {
  pinMode(ADC_REF_PIN, INPUT);
  pinMode(ADC_GND_PIN, INPUT);

  setupRows();
  setupColumns();
  matrixData.reserve(MATRIX_DATA_LENGTH);
  instructionsData.reserve(INSTRUCTIONS_DATA_LENGTH);
}

String scanMatrix(SenseModes mode) {
  matrixData = "";

  if(mode == TEMPERATURE) {

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

        char dataText[16];
        if (!isnan(data)) snprintf(dataText, sizeof(dataText), "%.2f", data);
        else snprintf(dataText, sizeof(dataText), "NaN");

        matrixData += dataText;

        if (!(column == maxColumn() - 1 && row == maxRow() - 1)) matrixData += ' ';
      }
    }

    activateColumn();
    activateRow();

  } else {
    instructionsData = "";

    for (int column = 0; column < maxColumn(); column++) {
      int code_ref = ADCMeanFilter(ADC_REF_PIN, ADC_SAMPLES);
      int code_gnd = ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES);

      for (int row = 0; row < maxRow(); row++) {
        instructionsData = "";
        instructionsData += "scan matrix individual,";
        instructionsData += column; instructionsData += ",";
        instructionsData += row; instructionsData += ",";
        instructionsData += code_gnd; instructionsData += ",";
        instructionsData += code_ref; instructionsData += ",";
        instructionsData += "p,";
        instructionsData += (!(column == maxColumn() - 1 && row == maxRow() - 1)) ? false : true;

        sendMessage(instructionsData);
        //matrixData += receiveMessagesPrimary();
        if (!receiveMessagesPrimary(matrixData)) matrixData += "0.0";

        if (!(column == maxColumn() - 1 && row == maxRow() - 1)) matrixData += ' ';
      }
    }

  }

  return matrixData;
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