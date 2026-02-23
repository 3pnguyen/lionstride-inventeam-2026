#include "sensors.h"

//-------------------------------------- Change these as neccesary --------------------------------------

// ±0.1–0.3 °C (±0.18–0.54 °F)
static constexpr float SH_A = 0.0011252935711115418f;
static constexpr float SH_B = 0.0002347147730973799f;
static constexpr float SH_C = 8.565018940064752e-08f; //Steinhart-Hart values for the chosen thermistor

#define PULL_DOWN_R1 1.012e+6f
#define PULL_DOWN_R2 0.991e+6f

#define THERM_VCC 3.3f
#define VREF_IC 2.5f
#define THERM_FIXED_R 10000.0f

//-------------------------------------------------------------------------------------------------------

float _adcCodeToVoltage(int adc_code, int adc_code_gnd, int adc_code_ref, float vref = VREF_IC);
float _voltageToResistance(float v_meas, float vcc, float r_fixed);
float _voltageToResistanceCompensated(float v_meas, float vcc, float r_fixed, float r_pull);
float _resistanceToTemperatureC(float r_therm);
float _adcCodeNormalize(int adc_code, int adc_code_gnd, int adc_code_ref, bool clip = true);
float _readSensorResistanceFromCodes(int adc_code_sensor, int adc_code_gnd, int adc_code_ref, float vref, float vcc, float r_fixed, float r_pull);

float _adcCodeToVoltage(
    int adc_code,
    int adc_code_gnd,
    int adc_code_ref,
    float vref
) {
    // Protect against division by zero
    if (adc_code_ref == adc_code_gnd) {
        return 0.0f;
    }

    // Gain (codes per volt)
    float a = (adc_code_ref - adc_code_gnd) / vref;

    // Offset (codes)
    float b = adc_code_gnd;

    // Corrected voltage
    return (adc_code - b) / a;
}

float _voltageToResistance(
    float v_meas,
    float vcc,
    float r_fixed
) {
    if (v_meas <= 0.0f || v_meas >= vcc) {
        return 0.0f;  // invalid
    }

    return r_fixed * v_meas / (vcc - v_meas);
}

float _voltageToResistanceCompensated(
    float v_meas,
    float vcc,
    float r_fixed,
    float r_pull
) {
    // sanity checks
    if (!(v_meas > 0.0f && v_meas < vcc)) return NAN;
    if (!(r_fixed > 0.0f && r_pull > 0.0f)) return NAN;

    float denom = (vcc - v_meas);
    if (denom == 0.0f) return NAN; // avoid div-by-zero

    // Equivalent bottom resistance seen by divider (R_par)
    float Rpar = r_fixed * (v_meas / denom);

    // Now derive the true sensor resistance Rt
    // Rt = (Rpar * Rpull) / (Rpull - Rpar)
    if (r_pull <= Rpar) {
        // physically impossible (pull too small or measurement inconsistent)
        return NAN;
    }

    float Rt = (Rpar * r_pull) / (r_pull - Rpar);
    if (!isfinite(Rt) || Rt <= 0.0f) return NAN;
    return Rt;
}

float _resistanceToTemperatureC(
    float r_therm
) {
    if (r_therm <= 0.0f) {
        return NAN;
    }

    // Steinhart-Hart: 1/T = A + Bln(R) + C(ln(R))^3
    float lnR = logf(r_therm);
    float invT = SH_A + SH_B * lnR + SH_C * lnR * lnR * lnR; // 1/K
    if (invT == 0.0f) return NAN;
    float tempK = 1.0f / invT;
    return tempK - 273.15f;
}

float _readSensorResistanceFromCodes(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    float vref,
    float vcc,
    float r_fixed,
    float r_pull
) {
    float v_meas = _adcCodeToVoltage(adc_code_sensor, adc_code_gnd, adc_code_ref, vref);
    if (!(v_meas > 0.0f && v_meas < vcc)) {
        return NAN;
    }

    if (r_pull > 0.0f) {
        float rt = _voltageToResistanceCompensated(v_meas, vcc, r_fixed, r_pull);
        if (isfinite(rt) && rt > 0.0f) return rt;
        // fallback to uncompensated if compensated failed
    }
    // fallback:
    return _voltageToResistance(v_meas, vcc, r_fixed);
}

float readThermistorTemperature(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    bool fahrenheit
) {
    // Compute sensor resistance from ADC codes, applying pull-down compensation.
    float r_therm = _readSensorResistanceFromCodes(
        adc_code_sensor,
        adc_code_gnd,
        adc_code_ref,
        VREF_IC,
        THERM_VCC,
        THERM_FIXED_R,
        PULL_DOWN_R1  // use measured pull-down value for thermistor bank
    );

    // Convert to temperature
    float tempC = _resistanceToTemperatureC(r_therm);

    if (fahrenheit) return tempC * 9.0f / 5.0f + 32.0f;
    else return tempC;
}

// ------------------------- FSR / pressure helpers -------------------------

float _adcCodeNormalize(int adc_code,
                        int adc_code_gnd,
                        int adc_code_ref,
                        bool clip) {
  if (adc_code_ref == adc_code_gnd) return 0.0f; // avoid divide-by-zero
  float norm = (float)(adc_code - adc_code_gnd) / (float)(adc_code_ref - adc_code_gnd);
  if (!clip) return norm;
  if (norm < 0.0f) return 0.0f;
  if (norm > 1.0f) return 1.0f;
  return norm;
}

float readFSRNormalizedFromCodes(int adc_code_sensor,
                                 int adc_code_gnd,
                                 int adc_code_ref,
                                 bool clip) {
  return _adcCodeNormalize(adc_code_sensor, adc_code_gnd, adc_code_ref, clip);
}

float readPressureResistanceFromCodes(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    float vref = VREF_IC,
    float vcc = THERM_VCC,
    float r_fixed = THERM_FIXED_R,
    float r_pull = PULL_DOWN_R2
) {
    return _readSensorResistanceFromCodes(adc_code_sensor, adc_code_gnd, adc_code_ref, vref, vcc, r_fixed, r_pull);
}