#pragma once

#include <Arduino.h>
#include "sensors.h"
#include "expander.h"
#include "multiplexer.h"
#include "serial.h"

enum SenseModes {
  TEMPERATURE,
  PRESSURE
};

void setupMatrix();

String scanMatrix(SenseModes mode);

float scanMatrixIndividual(int column, int row, int code_gnd, int code_ref, SenseModes mode, bool disable);