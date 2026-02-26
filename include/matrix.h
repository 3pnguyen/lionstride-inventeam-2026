#pragma once

#include <Arduino.h>
#include "sensors.h"
#include "expander.h"
#include "multiplexer.h"
#include "serial.h"
#include "filter.h"
#include "macros.h"

enum SenseModes {
    TEMPERATURE,
    PRESSURE,
    PRESSURE_PRIMARY
};

enum IndexingModes {
    ROWS,
    COLUMNS
};

extern char matrixBuffer[MATRIX_DATA_LENGTH];

void setupMatrix();

void scanMatrix(SenseModes mode, IndexingModes readMatrixBy = COLUMNS);

float scanMatrixIndividual(int column, int row, int code_gnd, int code_ref, SenseModes mode, bool disable);