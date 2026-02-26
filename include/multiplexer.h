#pragma once

#include <Arduino.h>

//-------------------------------------- Change these as neccesary --------------------------------------

#define MUX_ENABLE_ACTIVE_LOW 0 //TMUX1208 is active high

//-------------------------------------------------------------------------------------------------------

static inline void writeEnablePin(unsigned int enPin, bool enable) {
#if MUX_ENABLE_ACTIVE_LOW
  digitalWrite(enPin, enable ? LOW : HIGH);
#else
  digitalWrite(enPin, enable ? HIGH : LOW);
#endif
}

int maxRow();

int maxMultiplexerPins();

void setupRows();

void activateRow(int row = -1);

// ------------------------- Ai-gen (Alice & Ivette) Debug functions -----------------------------------------

void debugTMUXControlLines(Stream& out = Serial, uint16_t delayMs = 120);