import {
  batteryCommand,
  commandInput,
  dMatrixCommand,
  debugMcp1Command,
  debugMcp2Command,
  debugRowsCommand,
  iMatrixCommand,
  iPressureCommand,
  iTempCommand,
  pressureCommand,
  tempCommand,
  testAdcCommand,
  testMathCommand,
  walkMcp1Command,
  walkMcp2Command,
} from "./elements.js";
import { columnInput, rowInput } from "./matrix.js";
import { sendCommand } from "./serial.js";

const commandConfigs = [
  { element: tempCommand, command: "temperature", log: "Scanning for temperature", needsMatrixInput: false },
  { element: pressureCommand, command: "pressure", log: "Scanning for pressure", needsMatrixInput: false },
  { element: batteryCommand, command: "battery", log: "Checking battery level", needsMatrixInput: false },
  { element: iTempCommand, command: "i temperature", log: "Individually scanning for temperature", needsMatrixInput: true },
  { element: iPressureCommand, command: "i pressure", log: "Individually scanning for pressure", needsMatrixInput: true },
  { element: testAdcCommand, command: "test adc", log: "Checking ADC outputs", needsMatrixInput: true },
  { element: debugMcp1Command, command: "debug mcp1", log: "Checking connections on MCP1", needsMatrixInput: false },
  { element: debugMcp2Command, command: "debug mcp2", log: "Checking connections on MCP2", needsMatrixInput: false },
  { element: walkMcp1Command, command: "walk mcp1", log: "Walking MCP1", needsMatrixInput: false },
  { element: walkMcp2Command, command: "walk mcp2", log: "Walking MCP2", needsMatrixInput: false },
  { element: debugRowsCommand, command: "debug rows", log: "Checking connections on rows + both TMUXs", needsMatrixInput: false },
  { element: testMathCommand, command: "test math", log: "Testing conversion math", needsMatrixInput: false },
  { element: iMatrixCommand, command: "i matrix", log: "Individually turn on one part of matrix", needsMatrixInput: true },
  { element: dMatrixCommand, command: "d matrix", log: "Disable entire matrix", needsMatrixInput: false },
];

function sendMatrixElement() {
  sendCommand(`${columnInput()}\n${rowInput()}`, false);
}

function bindCommand({ element, command, log, needsMatrixInput }) {
  if (!element) {
    return;
  }

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

  if (!commandInput) {
    return;
  }

  commandInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      console.log(commandInput.value);
      sendCommand(commandInput.value);
      commandInput.value = "";
    }
  });
}
