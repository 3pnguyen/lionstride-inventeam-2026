#pragma once

// ------------------------------------------------------- Expander  -------------------------------------------------------
#define EXPANDER_PINS 16 

enum MCP_DEVICE {
    MCP1,
    MCP2,
    MCP3,
    MCP4
};

// ------------------------------------------------------- Matrix -------------------------------------------------------
#define MATRIX_COLUMNS 26
#define MATRIX_ROWS 12

#define MATRIX_SWITCH_TIME 14000 // microseconds

#define MATRIX_ADC_1 A2
#define MATRIX_ADC_2 A3
#define MATRIX_ADC_3 A4
#define MATRIX_ADC_4 A5
#define ADC_SAMPLES 15
#define MATRIX_DATA_LENGTH 4096 // a lot of extra space

enum SenseModes {
    TEMPERATURE,
    PRESSURE,
    PRESSURE_PRIMARY
};

enum IndexingModes {
    READ_BY_ROWS,
    READ_BY_COLUMNS
};

// ------------------------------------------------------- Multiplexer -------------------------------------------------------
#define MUX_PINS 8 

#define MUX_ENABLE_ACTIVE_LOW 0 //TMUX1208 is active high

// ------------------------------------------------------- Sensors ------------------------------------------------------- 
#define ADC_GND_PIN A1

#define PULL_DOWN_R 1.0e+6f // represents all 4 pull-down resistors

// ------------------------------------------------------- Serial -------------------------------------------------------
#define DISCOVER_PIN 21 

// ------------------------------------------------------- Pressure & Temperature -------------------------------------------------------
#define VCC 3.3f
#define VREF_IC 2.36681318681f //should be 2.5V
#define FIXED_R 10000.0f
#define MAX_ADC_CODE 4095.0f

// ------------------------------------------------------- Test -------------------------------------------------------

#define WEB_MODE