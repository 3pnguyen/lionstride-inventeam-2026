#include "mcp23s17.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define OPCODE_WRITE 0x40
#define OPCODE_READ 0x41
#define IODIRA 0x00 //sets GPIOA ports as input or output
#define IODIRB 0x01
#define GPIOA 0x12 //can set voltage level
#define GPIOB 0x13
#define OLATA 0x14 //sets voltage level for GPIOA but better...
#define OLATB 0x15
#define CLOCK_SPEED 10000000

#define EXPANDER_MISO 19
#define EXPANDER_MOSI 18
#define EXPANDER_CLOCK 5
#define EXPANDER_C_SELECT_1 12
#define EXPANDER_C_SELECT_2 13

#define GPIOAB_PINS 8

//-------------------------------------------------------------------------------------------------------

SPISettings MCPSPISettings(CLOCK_SPEED, MSBFIRST, SPI_MODE0);
const uint8_t GPIOAB_HexCodes[2][GPIOAB_PINS] =
{
  {
    0x80, // GPA7 / GPB7 (10000000)
    0x40, // GPA6 / GPB6 (01000000)
    0x20, // GPA5 / GPB5 (00100000)
    0x10, // GPA4 / GPB4 (00010000)
    0x08, // GPA3 / GPB3 (00001000)
    0x04, // GPA2 / GPB2 (00000100)
    0x02, // GPA1 / GPB1 (00000010)
    0x01  // GPA0 / GPB0 (00000001)
  }, {
    0x7F, // GPA7 / GPB7 (01111111)
    0xBF, // GPA6 / GPB6 (10111111)
    0xDF, // GPA5 / GPB5 (11011111)
    0xEF, // GPA4 / GPB4 (11101111)
    0xF7, // GPA3 / GPB3 (11110111)
    0xFB, // GPA2 / GPB2 (11111011)
    0xFD, // GPA1 / GPB1 (11111101)
    0xFE  // GPA0 / GPB0 (11111110)
  }
};
int cSelectPins[] = {EXPANDER_C_SELECT_1, EXPANDER_C_SELECT_2};

void _cSelect(MCP_DEVICE dev);
void _cDeselect(MCP_DEVICE dev);
void _writeRegister(MCP_DEVICE dev, uint8_t reg, uint8_t val);
uint8_t _readRegister(MCP_DEVICE dev, uint8_t reg);

void setupColumns() {
  pinMode(EXPANDER_C_SELECT_1, OUTPUT);
  pinMode(EXPANDER_C_SELECT_2, OUTPUT);

  SPI.begin(EXPANDER_CLOCK, EXPANDER_MISO, EXPANDER_MOSI);

  _cDeselect(MCP1);
  _cDeselect(MCP2);

  _writeRegister(MCP1, IODIRA, 0x00);
  _writeRegister(MCP1, IODIRB, 0x00);
  _writeRegister(MCP1, OLATA, 0x00);
  _writeRegister(MCP1, OLATB, 0x00);

  _writeRegister(MCP2, IODIRA, 0x00);
  _writeRegister(MCP2, IODIRB, 0x00);
  _writeRegister(MCP2, OLATA, 0x00);
  _writeRegister(MCP2, OLATB, 0x00);
}

void _cSelect(MCP_DEVICE dev) { digitalWrite(cSelectPins[dev], LOW); }

void _cDeselect(MCP_DEVICE dev) { digitalWrite(cSelectPins[dev], HIGH); }

void _writeRegister(MCP_DEVICE dev, uint8_t reg, uint8_t val) {
  SPI.beginTransaction(MCPSPISettings);
  _cSelect(dev);

  SPI.transfer(OPCODE_WRITE);
  SPI.transfer(reg);
  SPI.transfer(val);

  _cDeselect(dev);
  SPI.endTransaction();
}

uint8_t _readRegister(MCP_DEVICE dev, uint8_t reg) {
  SPI.beginTransaction(MCPSPISettings);
  _cSelect(dev);
  SPI.transfer(OPCODE_READ);
  SPI.transfer(reg);
  uint8_t val = SPI.transfer(0x00);
  _cDeselect(dev);
  SPI.endTransaction();
  return val;
}

void activateColumn(int column, bool invert) {
  _writeRegister(MCP1, OLATA, (invert) ? 0xFF : 0x00);
  _writeRegister(MCP1, OLATB, (invert) ? 0xFF : 0x00);
  _writeRegister(MCP2, OLATA, (invert) ? 0xFF : 0x00);
  _writeRegister(MCP2, OLATB, (invert) ? 0xFF : 0x00);

  // exception cases
  if (column == 20) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[invert][2]); return; }
  else if (column == 21) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[invert][3]); return; }
  else if (column == 22) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[invert][4]); return; }
  else if (column == 23) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[invert][5]); return; }
  else if (column == 24) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[invert][6]); return; }
  else if (column == 25) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[invert][7]); return; }

  if (column < 0) return;

  if (column >= MATRIX_COLUMNS) return;
  
  if (column < EXPANDER_PINS) {
    int index = column;
    if (column < GPIOAB_PINS) _writeRegister(MCP1, OLATA, GPIOAB_HexCodes[invert][index]);
    else _writeRegister(MCP1, OLATB, GPIOAB_HexCodes[invert][index - GPIOAB_PINS]);

  } else {
    int index = column - EXPANDER_PINS;
    if (index < GPIOAB_PINS) _writeRegister(MCP2, OLATA, GPIOAB_HexCodes[invert][index]);
    else _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[invert][index - GPIOAB_PINS]);

  }
}

// ------------------------- Ai-gen Debug functions -----------------------------------------

static bool _writeReadCheck(MCP_DEVICE dev, uint8_t reg, uint8_t value, Stream& out) {
  _writeRegister(dev, reg, value);
  uint8_t readback = _readRegister(dev, reg);
  bool ok = (readback == value);

  out.print("MCP"); out.print((int)dev + 1);
  out.print(" reg 0x"); out.print(reg, HEX);
  out.print(" <= 0x"); out.print(value, HEX);
  out.print(" read 0x"); out.print(readback, HEX);
  out.println(ok ? " [OK]" : " [FAIL]");
  return ok;
}

bool debugMCPConnection(MCP_DEVICE dev, Stream& out) {
  out.print("---- MCP"); out.print((int)dev + 1); out.println(" connection test ----");

  uint8_t oldIODIRA = _readRegister(dev, IODIRA);
  uint8_t oldIODIRB = _readRegister(dev, IODIRB);
  uint8_t oldOLATA  = _readRegister(dev, OLATA);
  uint8_t oldOLATB  = _readRegister(dev, OLATB);

  bool ok = true;
  ok &= _writeReadCheck(dev, IODIRA, 0x00, out);
  ok &= _writeReadCheck(dev, IODIRB, 0x00, out);
  ok &= _writeReadCheck(dev, OLATA,  0xAA, out);
  ok &= _writeReadCheck(dev, OLATA,  0x55, out);
  ok &= _writeReadCheck(dev, OLATB,  0xAA, out);
  ok &= _writeReadCheck(dev, OLATB,  0x55, out);

  // restore
  _writeRegister(dev, IODIRA, oldIODIRA);
  _writeRegister(dev, IODIRB, oldIODIRB);
  _writeRegister(dev, OLATA,  oldOLATA);
  _writeRegister(dev, OLATB,  oldOLATB);

  out.println(ok ? "MCP result: PASS" : "MCP result: FAIL");
  return ok;
}

void debugMCPWalkOutputs(MCP_DEVICE dev, Stream& out, uint16_t delayMs) {
  _writeRegister(dev, IODIRA, 0x00);
  _writeRegister(dev, IODIRB, 0x00);

  out.print("Walking MCP"); out.print((int)dev + 1); out.println(" outputs...");
  for (int i = 0; i < 8; i++) {
    uint8_t v = (1u << i);
    _writeRegister(dev, OLATA, v);
    _writeRegister(dev, OLATB, 0x00);
    out.print("OLATA bit "); out.println(i);
    delay(delayMs);
  }
  for (int i = 0; i < 8; i++) {
    uint8_t v = (1u << i);
    _writeRegister(dev, OLATA, 0x00);
    _writeRegister(dev, OLATB, v);
    out.print("OLATB bit "); out.println(i);
    delay(delayMs);
  }

  _writeRegister(dev, OLATA, 0x00);
  _writeRegister(dev, OLATB, 0x00);
}
