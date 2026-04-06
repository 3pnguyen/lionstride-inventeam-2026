import { initCommands } from "./commands.js";
import { initMatrix } from "./matrix.js";
import { initConnectionControls } from "./serial.js";
import { initSettings } from "./settings.js";

/*
Javascript files:

commands.js - for sending commands to the ESP32
elements.js - for getting elements from the DOM
main.js  - for initializing the website
matrix.js - for initializing and handling the matrix header
output.js - for initializing and handling the output console
serial.js - for initializing and handling the serial connection
settings.js - for initializing and handling the settings

*/

initMatrix();
initCommands();
initConnectionControls();
initSettings();
