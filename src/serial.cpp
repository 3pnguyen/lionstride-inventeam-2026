#include "serial.h"

//-------------------------------------- Change these as neccesary --------------------------------------

#define RX_PIN 16
#define TX_PIN 17
#define UART 1
#define BAUD_RATE 115200

#define DATA_LENGTH 50

#define TIMEOUT_THRESHOLD 3000 

//-------------------------------------------------------------------------------------------------------

HardwareSerial uart(UART);
IntervalTimer timeout(TIMEOUT_THRESHOLD);

char dataBuffer[DATA_LENGTH];

EspModes discoverMode() {
  if (digitalRead(DISCOVER_PIN) == HIGH) return PRIMARY;
  return SECONDARY;
}

void setupSerialCommunication() {
  uart.begin(BAUD_RATE, SERIAL_8N1, RX_PIN, TX_PIN);
  delay(200);
}

void sendMessage(String message) {
  uart.println(message);
}

void sendMessage(const char* message) {
  uart.println(message);
}

void receiveMessagesSecondary() {
  if (!uart.available()) return;

  char line[128];
  size_t n = uart.readBytesUntil('\n', line, sizeof(line) - 1);
  line[n] = '\0';

  if (n == 0) return;

  char* ctx = nullptr;
  char* action = strtok_r(line, ",", &ctx);
  if (!action) return;

  dataBuffer[0] = '\0';

  if (strcmp(action, "scan matrix individual") == 0) {
    char* p1 = strtok_r(nullptr, ",", &ctx);
    char* p2 = strtok_r(nullptr, ",", &ctx);
    char* p3 = strtok_r(nullptr, ",", &ctx);
    char* p4 = strtok_r(nullptr, ",", &ctx);
    char* p5 = strtok_r(nullptr, ",", &ctx);
    char* p6 = strtok_r(nullptr, ",", &ctx);

    if (!p1 || !p2 || !p3 || !p4 || !p5 || !p6) return;

    float value = scanMatrixIndividual(
      atoi(p1),
      atoi(p2),
      atoi(p3),
      atoi(p4),
      (strcmp(p5, "t") == 0) ? TEMPERATURE : PRESSURE,
      (strcmp(p6, "true") == 0)
    );

    snprintf(dataBuffer, sizeof(dataBuffer), "%.3f", value);
  } else if (strcmp(action, "battery") == 0) {
    snprintf(dataBuffer, sizeof(dataBuffer), "%d", battery());
  } else if (strcmp(action, "debug") == 0) {
    snprintf(dataBuffer, sizeof(dataBuffer), "%ld", (long)random(1, 101));
  } else {
    return;
  }

  sendMessage(dataBuffer);
}

bool receiveMessagesPrimary() {
  //sendMessage("debug");

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

bool receiveMessagesPrimary(char* storage, size_t storageSize) {
  timeout.reset();

  while (uart.available() == 0) {
    if (timeout.isReady()) return false;
    delay(1);
  }

  size_t n = uart.readBytesUntil('\n', storage, storageSize - 1);
  storage[n] = '\0';
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