#include "multiplexer.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define MUX_A0_PIN 14
#define MUX_A1_PIN 32
#define MUX_A2_PIN 15
#define MUX_EN_1 33
#define MUX_EN_2 27

#define MUX_PINS 8 // limits
#define ROWS 12

//-------------------------------------------------------------------------------------------------------

void _muxPinSelect(unsigned int enable_pin, int select_pin = -1);

int maxRow() { return ROWS; }

int maxMultiplexerPins() { return MUX_PINS; }

void setupRows() {
  pinMode(MUX_A0_PIN, OUTPUT);
  pinMode(MUX_A1_PIN, OUTPUT);
  pinMode(MUX_A2_PIN, OUTPUT);
  pinMode(MUX_EN_1, OUTPUT);
  pinMode(MUX_EN_2, OUTPUT);

  writeEnablePin(MUX_EN_1, false);
  writeEnablePin(MUX_EN_2, false);

  digitalWrite(MUX_A0_PIN, LOW);
  digitalWrite(MUX_A1_PIN, LOW);
  digitalWrite(MUX_A2_PIN, LOW);
}

void _muxPinSelect(unsigned int enable_pin, int select_pin) {
  if (select_pin != -1) {
    digitalWrite(MUX_A0_PIN, bitRead(select_pin, 0));
    digitalWrite(MUX_A1_PIN, bitRead(select_pin, 1));
    digitalWrite(MUX_A2_PIN, bitRead(select_pin, 2));

    writeEnablePin(enable_pin, true);
  } else {
    writeEnablePin(enable_pin, false);
  }
}

void activateRow(int row) {
  _muxPinSelect(MUX_EN_1);
  _muxPinSelect(MUX_EN_2);

  if (row < 0) return;

  if (row >= ROWS) return;

  if (row < MUX_PINS) _muxPinSelect(MUX_EN_1, row);
  else _muxPinSelect(MUX_EN_2, row - MUX_PINS);
}

// ------------------------- Ai-gen Debug functions -----------------------------------------

void debugTMUXControlLines(Stream& out, uint16_t delayMs) {
  out.println("---- TMUX1208 control-line test ----");
  out.println("row, EN1, EN2, A2, A1, A0");

  for (int row = -1; row < ROWS; row++) {
    activateRow(row);
    delay(delayMs);

    out.print(row); out.print(", ");
    out.print(digitalRead(MUX_EN_1)); out.print(", ");
    out.print(digitalRead(MUX_EN_2)); out.print(", ");
    out.print(digitalRead(MUX_A2_PIN)); out.print(", ");
    out.print(digitalRead(MUX_A1_PIN)); out.print(", ");
    out.println(digitalRead(MUX_A0_PIN));
  }

  activateRow(-1);
}
