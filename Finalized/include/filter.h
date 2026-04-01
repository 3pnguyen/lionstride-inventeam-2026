#pragma once

#include <Arduino.h>

int lightMedianFilter(int a, int b, int c);

int ADCMeanFilter(int pin, int samples, bool withMedianFilter = true);

class IntervalTimer {
  private:
    unsigned long lastTime = 0;
    unsigned long interval;

  public:
    IntervalTimer(unsigned long intervalMs);
    bool isReady();
    void reset();
};

template <typename T>
class Debounce {
  public:
    T firstValue;
    T secondValue;

    Debounce(T initialState);
    Debounce(T initialState, T secondState);
    bool hasChanged(T currentState);
    bool lastState(T state);
};