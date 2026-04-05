#pragma once

#include <Arduino.h>

int lightMedianFilter(int a, int b, int c);

int ADCMeanFilter(int pin, int samples, bool withMedianFilter = true);