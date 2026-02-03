#pragma once

#include <BluetoothSerial.h>
#include <Arduino.h>
#include "battery.h"
#include "matrix.h"
#include "serial.h"

#if !defined(CONFIG_BT_ENABLED) || !defined(CONFIG_BLUEDROID_ENABLED)
#error Bluetooth is not enabled, please run `make menuconfig` to enable it
#endif

void setupBluetooth();

void handleBluetoothCommands();