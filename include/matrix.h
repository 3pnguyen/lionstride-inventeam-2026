#pragma once

#include <Arduino.h>
#include "sensors.h"
#include "expander.h"
#include "multiplexer.h"
#include "serial.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define MATRIX_DATA_LENGTH 4096 // a lot of extra space

//-------------------------------------------------------------------------------------------------------

extern char matrixBuffer[MATRIX_DATA_LENGTH];

enum SenseModes {
  TEMPERATURE,
  PRESSURE
};

void setupMatrix();

void scanMatrix(SenseModes mode);

float scanMatrixIndividual(int column, int row, int code_gnd, int code_ref, SenseModes mode, bool disable);