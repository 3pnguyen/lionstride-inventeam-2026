# lionstride-inventeam-2026

## Branch for all of the source code of the circuit and device

[![C](https://img.shields.io/badge/c-%2300599C.svg?style=for-the-badge&logo=c&logoColor=white)](#lionstride-inventeam-2026) <!-- - --> [![C++](https://img.shields.io/badge/c++-%2300599C.svg?style=for-the-badge&logo=c%2B%2B&logoColor=white)](#lionstride-inventeam-2026) <!-- - --> [![Arduino](https://img.shields.io/badge/-Arduino-00979D?style=for-the-badge&logo=Arduino&logoColor=white)](#lionstride-inventeam-2026) <!-- - --> [![PlatformIO](https://img.shields.io/badge/PlatformIO-%23222.svg?style=for-the-badge&logo=platformio&logoColor=%23f5822a)](#lionstride-inventeam-2026) 

<!-- Badeges from https://gprm.itsvg.in and https://github.com/Ileriayo/markdown-badges  -->

## Purpose

This code is the firmware that we load into ESP32s. It's main purpose is to collect data from the matrix and send it over to the app. It collects data from the matrix by giving special commands to electrical componenets on our schematic, to close a circuit on a certain thermistor that we want. It will read data through analog, and store it for when it needs to send it over to the companion app w/ Bluetooth. While it reads raw data, it is also filtering and calibrating each value in the background.

## Terminology

* "Prototype" - The firmware for our prototype circuits 
    * "Voltage Divider setup" - The original design of measuring temperature & pressure w/ voltage dividers
    * "Transimpedance setup" - The newer design of measuring using a transimpedance (TIA) op-amp
* "Finalized" - The firmware for our circuit using a customized PCB

## Changelogs

[Prototype VD](Prototype/Voltage%20Divider%20Setup%20(older)/changelog.md)

[Prototype TIA](Prototype/Transimpedance%20Setup%20(newer)/changelog.md)

[Finalized](Finalized/changelog.md)
