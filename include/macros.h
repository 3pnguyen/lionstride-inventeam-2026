#pragma once

// ------------------------------------------------------- Matrix -------------------------------------------------------
#define MATRIX_COLUMNS 26
#define MATRIX_ROWS 12

#define MATRIX_ADC_1 A2
#define MATRIX_ADC_2 A3
#define ADC_SAMPLES 15
#define MATRIX_DATA_LENGTH 4096 // a lot of extra space

// ------------------------------------------------------- Multiplexer -------------------------------------------------------
#define MUX_ENABLE_ACTIVE_LOW 0 //TMUX1208 is active high

// ------------------------------------------------------- Sensors ------------------------------------------------------- 
#define ADC_REF_PIN A4
#define ADC_GND_PIN A1

#define PULL_DOWN_R1 1.012e+6f
#define PULL_DOWN_R2 0.991e+6f

// ------------------------------------------------------- Serial -------------------------------------------------------
#define DISCOVER_PIN 21 