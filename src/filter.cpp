#include "filter.h"

int lightMedianFilter(int a, int b, int c) {
    if ((a <= b && b <= c) || (c <= b && b <= a)) return b;
    if ((b <= a && a <= c) || (c <= a && a <= b)) return a;
    return c;
}

int ADCMeanFilter(int pin, int samples, bool withMedianFilter) {
  if (samples <= 0) return 0;
  long sum = 0;

  if (withMedianFilter) {
    int groups = samples / 3;
    if (groups <= 0) groups = 1;
    for (int i = 0; i < groups; i++) {
      int r0 = analogRead(pin);
      int r1 = analogRead(pin);
      int r2 = analogRead(pin);
      sum += lightMedianFilter(r0, r1, r2);
    }
    return (int)(sum / groups);
  }

  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
  }
  return (int)(sum / samples);
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