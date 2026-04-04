#pragma once

#include <Arduino.h>
#include "global.h"
#include "filter.h"

static inline void writeEnablePin(unsigned int enPin, bool enable) {
#if MUX_ENABLE_ACTIVE_LOW
  digitalWrite(enPin, enable ? LOW : HIGH);
#else
  digitalWrite(enPin, enable ? HIGH : LOW);
#endif
}

void setupRows();

void deactivateRows();

void deactivateRows(SenseModes type); // for deactivating rows for a specific matrix

void activateRow(SenseModes type = TEMPERATURE, int row = -1);

int getRefOutput(SenseModes type, bool filter = true); // new function (as of 3/4) to get the output from the reference IC

// ------------------------- Ai-gen (Alice & Ivette) Debug functions -----------------------------------------

void debugTMUXControlLines(Stream& out = Serial, uint16_t delayMs = 120);