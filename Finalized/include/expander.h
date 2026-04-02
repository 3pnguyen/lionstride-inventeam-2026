#pragma once

#include <Arduino.h>
#include <SPI.h>
#include "macros.h"
#include "matrix.h"

enum MCP_DEVICE {
    MCP1,
    MCP2,
    MCP3,
    MCP4
};

void setupColumns();

void deactivateColumns();

void activateColumn(SenseModes type = TEMPERATURE, int column = -1);

// ------------------------- Ai-gen (Alice & Ivette) Debug functions -----------------------------------------

bool debugMCPConnection(MCP_DEVICE dev, Stream& out = Serial);

void debugMCPWalkOutputs(MCP_DEVICE dev, Stream& out = Serial, uint16_t delayMs = 120);