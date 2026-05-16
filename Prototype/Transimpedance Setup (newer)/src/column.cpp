#include "column.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define CLOCK_SPEED 1000000

#define MISO 19
#define MOSI 18
#define CLOCK 5
#define C_SELECT 12

//-------------------------------------------------------------------------------------------------------

SPISettings maxSPISettings(CLOCK_SPEED, MSBFIRST, SPI_MODE0);
int columnMapping[] = 
{
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, // maps the pins on the MAX14661 to the columns on the physical header
    14, 15, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27 // column 16 skips AB16 on the first chip and jumps to AB1 on the second
};

void _max14661WriteTwo(uint32_t farChip, uint32_t nearChip);
uint32_t _oneHot(uint8_t index);
void _setSingleSwitch(bool isFarChip, uint8_t switchIndex);
void _allChannelsOff();

void setupMax14661() {
    pinMode(C_SELECT, OUTPUT);
    digitalWrite(C_SELECT, HIGH);
    SPI.begin(CLOCK, MISO, MOSI);
}

void _max14661WriteTwo(uint32_t farChip, uint32_t nearChip) {
    SPI.beginTransaction(maxSPISettings);
    digitalWrite(C_SELECT, LOW);

    SPI.transfer((farChip >> 24) & 0xFF);
    SPI.transfer((farChip >> 16) & 0xFF);
    SPI.transfer((farChip >> 8)  & 0xFF);
    SPI.transfer((farChip)       & 0xFF);

    SPI.transfer((nearChip >> 24) & 0xFF);
    SPI.transfer((nearChip >> 16) & 0xFF);
    SPI.transfer((nearChip >> 8)  & 0xFF);
    SPI.transfer((nearChip)       & 0xFF);

    digitalWrite(C_SELECT, HIGH); 
    SPI.endTransaction();
}

// Turn ON exactly one switch (0–31)
uint32_t _oneHot(uint8_t index) {
    if (index > 31) return 0;
    return (uint32_t(1) << index);
}

void _setSingleSwitch(bool isFarChip, uint8_t switchIndex) {
    uint32_t word = _oneHot(switchIndex);

    if (isFarChip) {
        _max14661WriteTwo(word, 0x00000000);
    } else {
        _max14661WriteTwo(0x00000000, word);
    }
}

void _allChannelsOff() {
    _max14661WriteTwo(0x00000000, 0x00000000);
}

void activateColumn(int column) {
    if (column < 0 || column > 25) {
        _allChannelsOff();
        return;
    }

    int chipPhysicalPin = columnMapping[column];

    if (column > 15) {
        uint32_t word = _oneHot(chipPhysicalPin - 16);
        _max14661WriteTwo(word, 0x00000000);
    } else {
        uint32_t word = _oneHot(chipPhysicalPin);
        _max14661WriteTwo(0x00000000, word);
    }
}

// ------------------------- Ai-gen (Alice & Ivette) Debug functions -----------------------------------------

void debugMaxWalkOutputs(Stream& out, uint16_t delayMs) {
    out.println("Walking through near chips...");
    for (int i = 0; i < 32; i++) {
        activateColumn(i);
        out.print("Channel: ");
        out.println(i);
        delay(delayMs);
    }

    out.println("All off...");
    activateColumn();
    delay(500);
}
