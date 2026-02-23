#pragma once

#include <Arduino.h>
#include "filter.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define ADC_REF_PIN A4
#define ADC_GND_PIN A1

//-------------------------------------------------------------------------------------------------------

float readThermistorTemperature(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    bool fahrenheit = true
);

// ------------------------- ai-gen code for FSR -------------------------

float readFSRNormalizedFromCodes(int adc_code_sensor,
                                               int adc_code_gnd,
                                               int adc_code_ref,
                                               bool clip = true);