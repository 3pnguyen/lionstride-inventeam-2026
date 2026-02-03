#include "filter.h"

int lightMedianFilter(int a, int b, int c) {
    if ((a <= b && b <= c) || (c <= b && b <= a)) return b;
    if ((b <= a && a <= c) || (c <= a && a <= b)) return a;
    return c;
}

int ADCMeanFilter(int pin, int samples, bool withMedianFilter) {
  long sum = 0;
  for (int i = 0; i < samples; i += 3) {

      if (withMedianFilter) {
        int r0 = analogRead(pin);
        int r1 = analogRead(pin);
        int r2 = analogRead(pin);
        int median = lightMedianFilter(r0, r1, r2);
        sum += median;
      } else {
        sum += analogRead(pin);
      }
  }
  if (withMedianFilter) return (int) (sum / (samples / 3));
  return (int) sum / samples;
}

IntervalTimer::IntervalTimer(unsigned long intervalMs) : interval(intervalMs) {}

bool IntervalTimer::isReady() {
  unsigned long currentTime = millis();

  if (currentTime - lastTime >= interval) {
    lastTime = currentTime;
    return true;
  }
  return false;
}

void IntervalTimer::reset() {
  lastTime = millis();
}