#pragma once

#include <Arduino.h>
#include <SPI.h>

enum MCP_DEVICE {
  MCP1,
  MCP2
};

int maxColumn();

int maxExpanderIO();

void setupColumns();

void activateColumn(int column = -1);

// ------------------------- Ai-gen Debug functions -----------------------------------------

bool debugMCPConnection(MCP_DEVICE dev, Stream& out = Serial);

void debugMCPWalkOutputs(MCP_DEVICE dev, Stream& out = Serial, uint16_t delayMs = 120);