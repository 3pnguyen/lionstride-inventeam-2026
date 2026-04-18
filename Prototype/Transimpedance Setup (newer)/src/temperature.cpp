#include "temperature.h"

//-------------------------------------- Change these as neccesary --------------------------------------

// ±0.1–0.3 °C (±0.18–0.54 °F)
static constexpr float SH_A = 0.0011252935711115418f;
static constexpr float SH_B = 0.0002347147730973799f;
static constexpr float SH_C = 8.565018940064752e-08f; //Steinhart-Hart values for the chosen thermistor

//-------------------------------------------------------------------------------------------------------

float _adcCodeToVoltage(int adc_code, float vin); // base conversion function for ADC code to voltage, assuming ideal linear relationship and no calibration offsets
float _adcCodeToVoltage(int adc_code, int adc_code_gnd, int adc_code_ref, float vref = VREF_IC); // conversion function for ADC code to voltage, applying calibration offsets from GND and REF ADC readings
float _tiaVoltageToResistance(float v_out, float v_excitation, float r_feedback, float v_tia_ref = TIA_VIRTUAL_REF);
float _resistanceToTemperatureC(float r_therm);

float _adcCodeToVoltage(int adc_code, float vin) {
    // Assuming a simple linear relationship: voltage = (adc_code / max_adc_code) * vref
    return (adc_code / MAX_ADC_CODE) * vin;
}

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

float _tiaVoltageToResistance(
    float v_out,
    float v_excitation,
    float r_feedback,
    float v_tia_ref
) {
    float v_sensor = v_excitation - v_tia_ref;
    float v_feedback = fabsf(v_out - v_tia_ref);
    if (v_sensor <= 0.0f || v_feedback <= 0.0f || r_feedback <= 0.0f) {
        return NAN;
    }

    return (v_sensor * r_feedback) / v_feedback;
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

float readThermistorTemperatureTIA(
    int adc_code_sensor,
    bool fahrenheit
) {
    float v_out = _adcCodeToVoltage(adc_code_sensor, VCC);

    float r_therm = _tiaVoltageToResistance(
        v_out,
        VCC,
        TIA_FEEDBACK_R,
        TIA_VIRTUAL_REF
    );

    float tempC = _resistanceToTemperatureC(r_therm);
    return fahrenheit ? (tempC * 9.0f / 5.0f + 32.0f) : tempC;
}

float readThermistorTemperatureTIA(
    int adc_code_sensor,
    int adc_code_gnd,
    int adc_code_ref,
    bool fahrenheit
) {
    float v_out = _adcCodeToVoltage(adc_code_sensor, adc_code_gnd, adc_code_ref, VREF_IC);

    float r_therm = _tiaVoltageToResistance(
        v_out,
        VCC,
        TIA_FEEDBACK_R,
        TIA_VIRTUAL_REF
    );

    float tempC = _resistanceToTemperatureC(r_therm);
    return fahrenheit ? (tempC * 9.0f / 5.0f + 32.0f) : tempC;
}

// ------------------------- Debug functions -----------------------------------------

void debugSensorMath(int adcSampleValue, Stream& out) {
    int adcGnd = ADCMeanFilter(ADC_GND_PIN, ADC_SAMPLES);
    int adcRef = getRefOutput();

    // Path 1: raw ADC-to-TIA conversion without calibration offsets.
    float rawVoltage = _adcCodeToVoltage(adcSampleValue, VCC); 
    float rawResistance = _tiaVoltageToResistance(rawVoltage, VCC, TIA_FEEDBACK_R, TIA_VIRTUAL_REF);
    float rawTemperatureC = _resistanceToTemperatureC(rawResistance);
    float rawTemperatureF = rawTemperatureC * 9.0f / 5.0f + 32.0f;

    // Path 2: calibrated ADC-to-TIA conversion using live GND/REF ADC readings.
    float calibratedVoltage = _adcCodeToVoltage(adcSampleValue, adcGnd, adcRef);
    float calibratedResistance = _tiaVoltageToResistance(calibratedVoltage, VCC, TIA_FEEDBACK_R, TIA_VIRTUAL_REF);
    float calibratedTemperatureF = readThermistorTemperatureTIA(adcSampleValue, adcGnd, adcRef, true);

    out.println("Debugging sensor math...");
    out.println("The inputed ADC sample value is: " + String(adcSampleValue));
    out.println("Calibration inputs -> GND ADC: " + String(adcGnd) + ", REF ADC: " + String(adcRef));
    out.println("TIA virtual reference: " + String(TIA_VIRTUAL_REF) + "V");
    out.println("Raw path -> Voltage: " + String(rawVoltage) + "V, Resistance: " + String(rawResistance) + " ohms, Temperature: " + String(rawTemperatureF) + " degrees F");
    out.println("Calibrated path -> Voltage: " + String(calibratedVoltage) + "V, Resistance: " + String(calibratedResistance) + " ohms, Temperature: " + String(calibratedTemperatureF) + " degrees F");
}
