#pragma once

#include <Arduino.h>
#include "filter.h"
#include "matrix.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define ADC_REF_PIN A4
#define ADC_GND_PIN A1

#define PULL_DOWN_R1 1.012e+6f
#define PULL_DOWN_R2 0.991e+6f

//-------------------------------------------------------------------------------------------------------

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

// ------------------------- ai-gen code for FSR -------------------------

float readFSRNormalizedFromCodes(
    int adc_code_sensor,
    bool clip = false
);

float readFSRNormalizedFromCodes(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    bool clip = false
);

// ------------------------- Debug functions -----------------------------------------

void debugSensorMath(int adcSampleValue, Stream& out = Serial);