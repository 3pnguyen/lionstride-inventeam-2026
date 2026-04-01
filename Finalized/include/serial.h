#pragma once

#include <Arduino.h>
#include <vector>
#include "matrix.h"
#include "battery.h"
#include "filter.h"
#include "macros.h"

enum EspModes { 
    PRIMARY,
    SECONDARY
};

EspModes discoverMode();

void setupSerialCommunication();

void sendMessage(String message);

void sendMessage(const char* message);

void receiveMessagesSecondary();

bool receiveMessagesPrimary(); // original version, modified to check if it can receive data from the other ESP32

bool receiveMessagesPrimary(char* storage, size_t storageSize); // overload original function (for matrix and bluetooth)

bool receiveMessagesPrimary(String &storage); // overload original function (USED to be for matrix and bluetooth)

bool receiveMessagesPrimary(int &storage); // extra overload if an integer is expected (for bluetooth)