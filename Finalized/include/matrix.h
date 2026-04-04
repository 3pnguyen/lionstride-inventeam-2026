#pragma once

#include <Arduino.h>
#include "temperature.h"
#include "expander.h"
#include "multiplexer.h"
#include "filter.h"
#include "global.h"
#include "pressure.h"

extern char matrixBuffer[MATRIX_DATA_LENGTH];

void setupMatrix();

void scanMatrix(SenseModes mode, IndexingModes readMatrixBy = READ_BY_COLUMNS);

float scanMatrixIndividual(int column, int row, SenseModes mode, bool disable);

float scanMatrixIndividual(int column, int row, int code_gnd, int code_ref, SenseModes mode, bool disable);