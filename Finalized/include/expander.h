#pragma once

#include <Arduino.h>
#include <SPI.h>
#include "global.h"

void setupColumns();

void deactivateColumns();

void deactivateColumns(SenseModes type); // for deactivating columns for a specific matrix

void activateColumn(SenseModes type, int column);

// ------------------------- Ai-gen (Alice & Ivette) Debug functions -----------------------------------------

bool debugMCPConnection(MCP_DEVICE dev, Stream& out = Serial);

bool debugMCPConnections(Stream& out = Serial);

void debugMCPWalkOutputs(MCP_DEVICE dev, Stream& out = Serial, uint16_t delayMs = 120);

void debugMCPWalkAllOutputs(Stream& out = Serial, uint16_t delayMs = 120);