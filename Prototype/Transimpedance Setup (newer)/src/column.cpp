#include "column.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define CLOCK_SPEED 1000000

#define DIR0 0x00 // direct access to COM1-8 on A bus
#define DIR1 0x01 // direct access to COM9-16 on A bus
#define DIR2 0x02 // direct access to COM1-8 on B bus
#define DIR3 0x03 // direct access to COM9-16 on B bus

#define MISO 19
#define MOSI 18
#define CLOCK 5
#define C_SELECT 12

//-------------------------------------------------------------------------------------------------------

SPISettings maxSPISettings(CLOCK_SPEED, MSBFIRST, SPI_MODE0);

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
    if (column < 0 || column > 31) {
        _allChannelsOff();
        return;
    }

    if (column > 15) {
        uint32_t word = _oneHot(column - 16);
        _max14661WriteTwo(word, 0x00000000);
    } else {
        uint32_t word = _oneHot(column);
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
