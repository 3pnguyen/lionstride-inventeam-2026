export const connectButton = document.getElementById("connect"); // for main.js
export const connectStatus = document.getElementById("connect-status");

export const commandInput = document.getElementById("command-input"); // for commands.js

export const output = document.getElementById("output"); // for output.js

export const submitButton = document.getElementById("submit"); // for matrix.js
export const matrix = document.getElementById("matrix-console");
export const rowInputElement = document.getElementById("rowInput");
export const columnInputElement = document.getElementById("columnInput");

export const darkModeToggle = document.getElementById("dark-mode-toggle"); // for settings.js
export const singleMCUToggle = document.getElementById("single-mcu-toggle");
export const debugRowsCommand = document.getElementById("debug-rows");
export const debugMcp1Command = document.getElementById("debug-mcp1");
export const debugMcp2Command = document.getElementById("debug-mcp2");
export const walkMcp1Command = document.getElementById("walk-mcp1");
export const walkMcp2Command = document.getElementById("walk-mcp2");
export const debugMCPsCommand = document.createElement("button");
debugMCPsCommand.textContent = "Check connections on all MCPs";
debugMCPsCommand.id = "debug-mcps";
debugMCPsCommand.classList.add("command-button");
export const walkMCPsCommand = document.createElement("button");
walkMCPsCommand.textContent = "Walk all MCPs";
walkMCPsCommand.id = "walk-mcps";
walkMCPsCommand.classList.add("command-button");