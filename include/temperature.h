#pragma once

#include <Arduino.h>
#include "filter.h"
#include "macros.h"

float readThermistorTemperature( // read thermistor wihtout calibration but with pull-down conpensaton
    int adc_code_sensor,
    float pull_down_r,
    bool fahrenheit = true
);

float readThermistorTemperature( // read thermistor with calibration and pull-down conpensation
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    float pull_down_r,
    bool fahrenheit = true
);

// ------------------------- Debug functions -----------------------------------------

void debugSensorMath(int adcSampleValue, Stream& out = Serial);