#include "serial.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define DISCOVER_PIN 21

#define RX_PIN 16
#define TX_PIN 17
#define UART 1
#define BAUD_RATE 115200

#define TIMEOUT_THRESHOLD 3 // in seconds

//-------------------------------------------------------------------------------------------------------

HardwareSerial uart(UART);
IntervalTimer timeout(TIMEOUT_THRESHOLD);

String data;

std::vector<String> splitString(const String &input, char delimiter, bool keepEmpty) { // ai-gen
  std::vector<String> parts;
  int start = 0;
  int len = input.length();

  while (start <= len) {
    int idx = input.indexOf(delimiter, start);
    if (idx == -1) idx = len;            // treat end of string as delimiter
    int partLen = idx - start;

    if (partLen > 0) {
      parts.push_back(input.substring(start, idx));
    } else if (partLen == 0 && keepEmpty) {
      // empty token between delimiters or leading/trailing delimiter
      parts.push_back(String());
    }

    start = idx + 1; // move past delimiter
  }

  return parts;
}

EspModes discoverMode() {
  if (digitalRead(DISCOVER_PIN) == HIGH) return PRIMARY;
  return SECONDARY;
}

void setupSerialCommunication() {
  pinMode(DISCOVER_PIN, INPUT_PULLUP);

  uart.begin(BAUD_RATE, SERIAL_8N1, RX_PIN, TX_PIN);
  delay(200);

  data.reserve(100);
}

void sendMessage(String message) {
  uart.println(message);
}

void receiveMessagesSecondary() {
  if(uart.available()) {
    auto message = splitString(uart.readStringUntil('\n'), ',');
    String action = message[0];

    data = "";
    
    if (action == "scan matrix individual") {
      data += scanMatrixIndividual(message[1].toInt(), message[2].toInt(), message[3].toInt(), message[4].toInt(), (message[5] == "t") ? TEMPERATURE : PRESSURE, (message[6] == "true"));
    } else if (action == "battery") {
      data += battery();
    } else if (action == "debug") {
      data += random(1, 101);
    }

    sendMessage(data);
  }
}

bool receiveMessagesPrimary() {
  sendMessage("debug");

  timeout.reset();

  while (uart.available() == 0) {
    if (timeout.isReady()) return false;
    delay(1);
  }

  return true;
}

bool receiveMessagesPrimary(String &storage) {
  timeout.reset();

  while (uart.available() == 0) {
    if (timeout.isReady()) return false;
    delay(1);
  }

  storage += uart.readStringUntil('\n');
  return true;
}

bool receiveMessagesPrimary(int &storage) {
  timeout.reset();

  while (uart.available() == 0) {
    if (timeout.isReady()) return false;
    delay(1);
  }

  storage += uart.readStringUntil('\n').toInt();
  return true;
}