#include "bluetooth.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define DEVICE_NAME "ESP32_FootBox"

//-------------------------------------------------------------------------------------------------------

BluetoothSerial Bluetooth;

void setupBluetooth() {
  Bluetooth.begin(DEVICE_NAME);
}

void _printErrorMessage() {
  Bluetooth.println("No data received");
}

void handleBluetoothCommands() {
  if (Bluetooth.available()) {
    String command = Bluetooth.readStringUntil('\n');
    command.trim();

    if (command == "scan temperature") {
      scanMatrix(TEMPERATURE, READ_BY_ROWS);
      Bluetooth.println(matrixBuffer);

    } else if (command == "scan pressure") {
      scanMatrix(PRESSURE, READ_BY_ROWS);
      Bluetooth.println(matrixBuffer);

    } else if (command == "battery") {
      Bluetooth.println(battery());

    } else if (command == "debug") {
      Bluetooth.println(random(1, 101));

    }
  }
}