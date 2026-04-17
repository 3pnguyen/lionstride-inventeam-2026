#pragma once

#include <Arduino.h>
#include "filter.h"
#include "macros.h"

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