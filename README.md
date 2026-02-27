# lionstride-inventeam-2026

## Branch for all of the source code of the circuit and device

![C](https://img.shields.io/badge/c-%2300599C.svg?style=for-the-badge&logo=c&logoColor=white) ![C++](https://img.shields.io/badge/c++-%2300599C.svg?style=for-the-badge&logo=c%2B%2B&logoColor=white) ![Arduino](https://img.shields.io/badge/-Arduino-00979D?style=for-the-badge&logo=Arduino&logoColor=white) ![PlatformIO](https://img.shields.io/badge/PlatformIO-%23222.svg?style=for-the-badge&logo=platformio&logoColor=%23f5822a)

<!-- Proudly created with GPRM ( https://gprm.itsvg.in ) -->

## Purpose

This code is the firmware that we load into ESP32s. It's main purpose is to collect data from the matrix and send it over to the app. It collects data from the matrix by giving special commands to electrical componenets on our schematic, to close a circuit on a certain thermistor that we want. It will read data through analog, and store it for when it needs to send it over to the companion app w/ Bluetooth. While it reads raw data, it is also filtering and calibrating each value in the background.

## Changelog for code

X = (not the main code but related)

* 1.2.2026 - started the code
* 1.10.2026 - first major version (temperature scanning, battery, Bluetooth, etc.)
* X1.10.2026 - Bluetooth test code w/ ESP DEVKIT
* 1.22.2026 - second major version (added force sensing)
* 1.26.2026 - third major version (UART to have two ESPs communicate w/ each other and have one set to each matrix)
* X1.27.2026 - UART test code for ESP DEVKITs
* 1.29.2026 - minor improvements (removed unnecessary variables in header files, removed prototypes of helper functions into CPP files for clarity, added debug code for UART and Bluetooth)
* 2.1.2026 - major improvement where primary receiving UART ESP can timeout if awaiting too long and can now print error messages for that (for both the main and UART testing code)
* 2.2.2026 - minor fix in the battery code fallback w/ UART (final update before PlatformIO switch)
* 2.2.2026 - major switch from Arduino IDE to PlatformIO
* 2.14.2026 - fix for memory fragmentation + more test code
* 2.18.2026 - tested code and modified accordingly 
* 2.19.2026 - written more test code (to test individual matrix location scanning, and column and row code)
* 2.20.2026 - given test code a seperate file because there is so much of it already... it also turns out that I have only tested half of the code, not most :\
* 2.22.2026 - test code + increased scanning time
* 2.23.2026 - Fixed and created test code for the conversion math, and compensated for the pull-down resistors
* 2.24.2026 - Created some alternate code for collecting data without calibration and applied it (calibration hardware is unreliable on the circuit) 
* 2.25.2026 - Made testing code more flexible with user input to enable desired columns and rows on certain commands
* 2.26.2026 - Created helper function to reformat the matrix buffer to be correct with the app (index by columns -> index by rows)
* 2.27.2026 - Fixed timing for when pressure is scanned compared to temperature (made the scanning times the same, pressure used to be longer than it should)
