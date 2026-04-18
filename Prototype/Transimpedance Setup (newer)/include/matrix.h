#pragma once

#include <Arduino.h>
#include "temperature.h"
#include "mcp23s17.h"
#include "tmux1208.h"
#include "serial.h"
#include "filter.h"
#include "macros.h"
#include "pressure.h"

enum SenseModes {
    TEMPERATURE,
    PRESSURE,
    PRESSURE_PRIMARY
};

enum IndexingModes {
    READ_BY_ROWS,
    READ_BY_COLUMNS
};

extern char matrixBuffer[MATRIX_DATA_LENGTH];

void setupMatrix();

void scanMatrix(SenseModes mode, IndexingModes readMatrixBy = READ_BY_COLUMNS);

float scanMatrixIndividual(int column, int row, int code_gnd, int code_ref, SenseModes mode, bool disable);