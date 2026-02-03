#include "sensors.h"

//-------------------------------------- Change these as neccesary --------------------------------------

// ±0.1–0.3 °C (±0.18–0.54 °F)

static constexpr float SH_A = 0.0011252935711115418f;
static constexpr float SH_B = 0.0002347147730973799f;
static constexpr float SH_C = 8.565018940064752e-08f; //Steinhart-Hart values for the chosen thermistor

#define THERM_VCC 3.3f
#define VREF_IC 2.5f
#define THERM_FIXED_R 10000.0f

//-------------------------------------------------------------------------------------------------------

float _adcCodeToVoltage(int adc_code, int adc_code_gnd, int adc_code_ref, float vref = 2.5f);
float _voltageToResistance(float v_meas, float vcc, float r_fixed);
float _resistanceToTemperatureC(float r_therm);

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

float _resistanceToTemperatureC(
    float r_therm
) {
    if (r_therm <= 0.0f) {
        return NAN;
    }

    // Steinhart-Hart: 1/T = A + B*ln(R) + C*(ln(R))^3
    float lnR = logf(r_therm);
    float invT = SH_A + SH_B * lnR + SH_C * lnR * lnR * lnR; // 1/K
    float tempK = 1.0f / invT;
    return tempK - 273.15f;
}

float readThermistorTemperature(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    bool fahrenheit
) {

    // Step 1: ADC correction
    float v_sensor = _adcCodeToVoltage(
        adc_code_sensor,
        adc_code_gnd,
        adc_code_ref,
        VREF_IC
    );

    // Step 2: Voltage → resistance
    float r_therm = _voltageToResistance(v_sensor, THERM_VCC, THERM_FIXED_R);

    // Step 3: Resistance → temperature (Steinhart-Hart)
    float tempC = _resistanceToTemperatureC(r_therm);

    if (fahrenheit) return tempC * 9.0f / 5.0f + 32.0f;
    else return tempC;
}
