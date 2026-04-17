#include "pressure.h"

float _adcCodeNormalize(int adc_code, bool clip = true);
float _adcCodeNormalize(int adc_code, int adc_code_gnd, int adc_code_ref, bool clip = true);

float _adcCodeNormalize(
    int adc_code,
    bool clip
) {
    float norm = (float)adc_code / MAX_ADC_CODE;

    if (!clip) return norm;

    if (norm < 0.0f) return 0.0f;
    if (norm > 1.0f) return 1.0f;

    return norm;
}

float _adcCodeNormalize(
    int adc_code,
    int adc_code_gnd,
    int adc_code_ref,
    bool clip
) {
    if (adc_code_ref == adc_code_gnd) return 0.0f; // avoid divide-by-zero
    float norm = (float)(adc_code - adc_code_gnd) / (float)(adc_code_ref - adc_code_gnd);
    if (!clip) return norm;
    if (norm < 0.0f) return 0.0f;
    if (norm > 1.0f) return 1.0f;
    return norm;
}

float readFSRNormalizedFromCodes(
    int adc_code_sensor,
    bool clip
) {
    return _adcCodeNormalize(adc_code_sensor, clip);
}

float readFSRNormalizedFromCodes(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    bool clip
) {
    return _adcCodeNormalize(adc_code_sensor, adc_code_gnd, adc_code_ref, clip);
}
