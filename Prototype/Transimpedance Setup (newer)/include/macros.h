#pragma once

// ------------------------------------------------------- Expander  -------------------------------------------------------
#define EXPANDER_PINS 16 

// ------------------------------------------------------- Matrix -------------------------------------------------------
#define MATRIX_COLUMNS 26
#define MATRIX_ROWS 12

#define MATRIX_SWITCH_TIME 14000 // microseconds

#define MATRIX_ADC_1 A2
#define MATRIX_ADC_2 A3
#define ADC_SAMPLES 15
#define MATRIX_DATA_LENGTH 4096 // a lot of extra space

// ------------------------------------------------------- Multiplexer -------------------------------------------------------
#define MUX_PINS 8 

#define MUX_ENABLE_ACTIVE_LOW 0 //TMUX1208 is active high

// ------------------------------------------------------- Sensors ------------------------------------------------------- 
#define ADC_GND_PIN A1

// ------------------------------------------------------- Serial -------------------------------------------------------
#define DISCOVER_PIN 21 

// ------------------------------------------------------- Pressure & Temperature -------------------------------------------------------
#define VCC 3.3f
#define VREF_IC 2.36681318681f //should be 2.5V
#define FIXED_R 10000.0f
#define MAX_ADC_CODE 4095.0f

#define TIA_FEEDBACK_R 5100.0f
#define TIA_VIRTUAL_REF 1.65f // set to the divider/reference voltage at the TIA non-inverting input

// ------------------------------------------------------- Test -------------------------------------------------------

#define WEB_MODE
