#include "expander.h"

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

#define EXPANDER_PINS 16 // limits
#define GPIOAB_PINS 8
#define COLUMNS 26

//-------------------------------------------------------------------------------------------------------

SPISettings MCPSPISettings(CLOCK_SPEED, MSBFIRST, SPI_MODE0);
const uint8_t GPIOAB_HexCodes[8] =
{
  0x80, // GPA7 / GPB7
  0x40, // GPA6 / GPB6
  0x20, // GPA5 / GPB5
  0x10, // GPA4 / GPB4
  0x08, // GPA3 / GPB3
  0x04, // GPA2 / GPB2
  0x02, // GPA1 / GPB1
  0x01  // GPA0 / GPB0
};
int cSelectPins[] = {EXPANDER_C_SELECT_1, EXPANDER_C_SELECT_2};

void _cSelect(MCP_DEVICE dev);
void _cDeselect(MCP_DEVICE dev);
void _writeRegister(MCP_DEVICE dev, uint8_t reg, uint8_t val);
uint8_t _readRegister(MCP_DEVICE dev, uint8_t reg);

int maxColumn() { return COLUMNS; }

int maxExpanderIO() { return EXPANDER_PINS; }

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

void activateColumn(int column) {
  _writeRegister(MCP1, OLATA, 0x00);
  _writeRegister(MCP1, OLATB, 0x00);
  _writeRegister(MCP2, OLATA, 0x00);
  _writeRegister(MCP2, OLATB, 0x00);

  // exception cases
  if (column == 21) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[2]); return; }
  else if (column == 22) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[3]); return; }
  else if (column == 23) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[4]); return; }
  else if (column == 24) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[5]); return; }
  else if (column == 25) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[6]); return; }
  else if (column == 26) { _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[7]); return; }

  if (column < 0) return;

  if (column >= COLUMNS) return;
  
  if (column < EXPANDER_PINS) {
    int index = column;
    if (column < GPIOAB_PINS) _writeRegister(MCP1, OLATA, GPIOAB_HexCodes[index]);
    else _writeRegister(MCP1, OLATB, GPIOAB_HexCodes[index - GPIOAB_PINS]);

  } else {
    int index = column - EXPANDER_PINS;
    if (index < GPIOAB_PINS) _writeRegister(MCP2, OLATA, GPIOAB_HexCodes[index]);
    else _writeRegister(MCP2, OLATB, GPIOAB_HexCodes[index - GPIOAB_PINS]);

  }
}
