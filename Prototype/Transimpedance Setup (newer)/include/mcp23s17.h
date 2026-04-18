#pragma once

#include <Arduino.h>
#include <SPI.h>
#include "macros.h"

enum MCP_DEVICE {
    MCP1,
    MCP2
};

void setupColumns();

void activateColumn(int column = -1, bool invert = true);

// ------------------------- Ai-gen (Alice & Ivette) Debug functions -----------------------------------------

bool debugMCPConnection(MCP_DEVICE dev, Stream& out = Serial);

void debugMCPWalkOutputs(MCP_DEVICE dev, Stream& out = Serial, uint16_t delayMs = 120);