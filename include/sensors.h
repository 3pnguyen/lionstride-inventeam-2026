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

// ai-gen code for FSR

static inline float _adcCodeNormalize(int adc_code,
                                     int adc_code_gnd,
                                     int adc_code_ref,
                                     bool clip = true) {
  if (adc_code_ref == adc_code_gnd) return 0.0f; // avoid divide-by-zero
  float norm = (float)(adc_code - adc_code_gnd) / (float)(adc_code_ref - adc_code_gnd);
  if (!clip) return norm;
  if (norm < 0.0f) return 0.0f;
  if (norm > 1.0f) return 1.0f;
  return norm;
}

static inline float readFSRNormalizedFromCodes(int adc_code_sensor,
                                               int adc_code_gnd,
                                               int adc_code_ref,
                                               bool clip = true) {
  return _adcCodeNormalize(adc_code_sensor, adc_code_gnd, adc_code_ref, clip);
}