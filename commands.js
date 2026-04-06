import {
  commandInput,
} from "./elements.js";
import { columnInput, rowInput } from "./matrix.js";
import { sendCommand } from "./serial.js";

const boundCommandElements = new WeakSet();
let commandInputBound = false;

const commandConfigs = [
  { id: "temperature", command: "temperature", log: "Scanning for temperature", needsMatrixInput: false },
  { id: "pressure", command: "pressure", log: "Scanning for pressure", needsMatrixInput: false },
  { id: "battery", command: "battery", log: "Checking battery level", needsMatrixInput: false },
  { id: "i-temperature", command: "i temperature", log: "Individually scanning for temperature", needsMatrixInput: true },
  { id: "i-pressure", command: "i pressure", log: "Individually scanning for pressure", needsMatrixInput: true },
  { id: "test-adc", command: "test adc", log: "Checking ADC outputs", needsMatrixInput: true },
  { id: "debug-rows", command: "debug rows", log: "Checking connections on rows + both TMUXs", needsMatrixInput: false },
  { id: "test-math", command: "test math", log: "Testing conversion math", needsMatrixInput: false },
  { id: "i-matrix", command: "i matrix", log: "Individually turn on one part of matrix", needsMatrixInput: true },
  { id: "d-matrix", command: "d matrix", log: "Disable entire matrix", needsMatrixInput: false },

  // prototype schematic specific commands
  { id: "debug-mcp1", command: "debug mcp1", log: "Checking connections on MCP1", needsMatrixInput: false }, 
  { id: "debug-mcp2", command: "debug mcp2", log: "Checking connections on MCP2", needsMatrixInput: false },
  { id: "walk-mcp1", command: "walk mcp1", log: "Walking MCP1", needsMatrixInput: false },
  { id: "walk-mcp2", command: "walk mcp2", log: "Walking MCP2", needsMatrixInput: false },
  
  // finalized (PCB board) schematic specific commands
  { id: "debug-mcps", command: "debug mcps", log: "Checking connections on all MCPs", needsMatrixInput: false }, 
  { id: "walk-mcps", command: "walk mcps", log: "Walking all MCPs", needsMatrixInput: false },
];

function sendMatrixElement() {
  sendCommand(`${columnInput()}\n${rowInput()}`, false);
}

function bindCommand({ id, command, log, needsMatrixInput }) {
  const element = document.getElementById(id);

  if (!element || boundCommandElements.has(element)) {
    return;
  }

  boundCommandElements.add(element);

  element.addEventListener("click", () => {
    console.log(log);
    sendCommand(command);

    if (needsMatrixInput) {
      sendMatrixElement();
    }
  });
}

export function initCommands() {
  commandConfigs.forEach(bindCommand);

  if (!commandInput || commandInputBound) {
    return;
  }

  commandInputBound = true;

  commandInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      console.log(commandInput.value);
      sendCommand(commandInput.value);
      commandInput.value = "";
    }
  });
}
