#pragma once

#include <Arduino.h>
#include "macros.h"
#include "filter.h"

static inline void writeEnablePin(unsigned int enPin, bool enable) {
#if MUX_ENABLE_ACTIVE_LOW
  digitalWrite(enPin, enable ? LOW : HIGH);
#else
  digitalWrite(enPin, enable ? HIGH : LOW);
#endif
}

void setupTmux1208();

void activateRow(int row = -1);

int getRefOutput(bool filter = true); // new function (as of 3/4) to get the output from the reference IC

// ------------------------- Ai-gen (Alice & Ivette) Debug functions -----------------------------------------

void debugTMUXControlLines(Stream& out = Serial, uint16_t delayMs = 120);