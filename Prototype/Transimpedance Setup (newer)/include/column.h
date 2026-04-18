#pragma once

#include <Arduino.h>
#include <SPI.h>
#include "macros.h"

void setupMax14661();

void activateColumn(int column = -1);

// ------------------------- Ai-gen (Alice & Ivette) Debug functions -----------------------------------------

void debugMaxWalkOutputs(Stream& out = Serial, uint16_t delayMs = 120);