#pragma once

#include <Arduino.h>
#include "filter.h"
#include "macros.h"
#include "tmux1208.h" // to get ref. IC output

float readThermistorTemperatureTIA(
    int adc_code_sensor,
    bool fahrenheit = true
);

float readThermistorTemperatureTIA(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    bool fahrenheit = true
);

// ------------------------- Debug functions -----------------------------------------

void debugSensorMath(int adcSampleValue, Stream& out = Serial);
