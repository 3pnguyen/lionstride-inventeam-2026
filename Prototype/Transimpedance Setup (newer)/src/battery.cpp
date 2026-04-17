#include "battery.h"

//-------------------------------------- Change these as neccesary --------------------------------------

//make sure these values are explicitly float with "f" if changed
#define POWER_VD_R1 100000.0f
#define POWER_VD_R2 100000.0f //resistor values for the internal voltage divider of the HUZZAH32 for measuring the battery
#define ADC_MAX 4095.0f //max ADC resolution for a 12-bit ADC
#define VREF 3.3f

#define BAT_VD_PIN A13 //internal analog pin for the internal voltage divider (for HUZZAH32)
#define IND_LED_PIN 13 //chosen pin for an external LED (if the pin is changed, make sure it has PWM)

//-------------------------------------------------------------------------------------------------------

int _batteryPercent();
void _indicateBatteryLED(int percent);

int _batteryPercent() { 
  pinMode(BAT_VD_PIN, INPUT);

  const int N = 9;
  const float volts[N] = {4.20, 4.00, 3.95, 3.90, 3.85, 3.80, 3.70, 3.60, 3.30};
  const int pct[N] = {100, 85, 75, 60, 50, 35, 20, 10, 0};
  
  float voltage = (ADCMeanFilter(BAT_VD_PIN, 10) / ADC_MAX) * VREF * ((POWER_VD_R1 + POWER_VD_R2) / POWER_VD_R2);

  if (voltage >= volts[0]) return 100;
  if (voltage <= volts[N-1]) return 0;

  for (int i = 0; i < N-1; ++i) {
    if (voltage <= volts[i] && voltage >= volts[i+1]) {
      float t = (voltage - volts[i+1]) / (volts[i] - volts[i+1]); 
      float p = pct[i+1] + t * (pct[i] - pct[i+1]);
      return (int) round(p);
    }
  }
  return 0;
}

void _indicateBatteryLED(int percent) {
  pinMode(IND_LED_PIN, OUTPUT);
  analogWrite(IND_LED_PIN, (int) ((percent / 100.0f) * 255.0f));
}

int battery(bool print_serial) {
  int percent = _batteryPercent();

  //_indicateBatteryLED(percent);
  
  if (print_serial && Serial) Serial.println("Battery percentage: " + String(percent) + "%");
  return percent;
}