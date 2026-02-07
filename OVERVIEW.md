# Overview

This file is for giving people general info about how the firmware works. Every level in overview gets more complex.

## Overview Level 1

This code is the firmware that we load into small microcontrollers. It's main purpose is to collect data from the matrix and send it over to the app. It collects data from the matrix by giving special commands to electrical componenets on our schematic, to close a circuit on a certain thermistor that we want. It will read data through analog, and store it for when it needs to send it over to the companion app w/ Bluetooth. While it reads raw data, it is also filtering and calibrating each value in the background.

Misc. stuff that it can also do: retrieve its own battery information, and communicate with identical circuit boards to scan different things.

## Overview Level 2

The code is seperated into header and cpp file pairs for what they are designed for and what they do:

* battery .h and .cpp: Handles getting information from the battery.
* bluetooth .h and .cpp: Handles receiving and sending data over bluetooth.
* expander .h and .cpp: Handles sending commands to the IO expanders through 8-bit data transfer (SPI), to enable/disable GPIO, etc.
* filter .h and .cpp: Gives filtering functions and helper classes to other header-cpp pairs
* main .cpp: Main file that is running the code, deals with bluetooth and/or UART
* matrix .h and .cpp: Has functions that will scan the matrix and store data
* multiplexer .h and .cpp: Handles sending commands to the multiplexers through several GPIO, to select what pin will intake power from the matrix
* sensors .h and .cpp: Has functions that can scan thermistors and FSRs (will filter and calibrate readings)
* serial .h and .cpp: Handles serial (UART) communication between two microcontrollers, spefically one handling temperature and one on pressure readings

## Overview Level 3

I don't have the time to explain everything to you, but I can give you general things that I did while coding:

* Any function name that starts with "_" and has their prototype inside the cpp files means that it is only used inside that file for helping out the other functions.
* Macros are defined inside the cpp files generally, with a few exceptions. This is so that their purpose stays inside the file they are for.
* Header files are in the include folder and cpp files are in the source folder.
* All of the seperate files were made to work together. If a header-cpp pair requires functions from another pair, they call the preprosessor #include in their header files. (main is an exception)