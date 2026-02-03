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
      Bluetooth.println(scanMatrix(TEMPERATURE));

    } else if (command == "scan pressure") {
      if (!receiveMessagesPrimary()) {
        _printErrorMessage();
        return;
      }
      Bluetooth.println(scanMatrix(PRESSURE));

    } else if (command == "battery") {
      int battery_level_mean = 0;
      battery_level_mean += battery();
      sendMessage("battery");

      /* old receive code for reference
      battery_level_mean += receiveMessagesPrimary().toInt();
      Bluetooth.println((int) (battery_level_mean / 2));
      */

      if (!receiveMessagesPrimary(battery_level_mean)) {
        Bluetooth.println(battery_level_mean);
        return;
      }
      Bluetooth.println((int) (battery_level_mean) / 2);

    } else if (command == "debug") {
      String random_number = "";
      sendMessage("debug");

      /* old receive code for reference (and when random_number was random_int)
      random_int = receiveMessagesPrimary().toInt();
      Bluetooth.println("Received random variable from secondary ESP: " + String(random_int));
      */

      if (!receiveMessagesPrimary(random_number)) {
        _printErrorMessage();
        return;
      }
      Bluetooth.println("Recieved random variable from secondary ESP: " + random_number);

    }
  }
}