// ------------------------------------------- Connection -------------------------------------------

const connectButton = document.getElementById("connect");
const connectStatus = document.getElementById("connect-status");

let port;
let reader;
let writer;
let isReadLoopRunning = false;

function setConnectStatus(message) {
  if (connectStatus) {
    connectStatus.textContent = message;
  }
}

async function connectSerial() {
  if ("serial" in navigator === false) {
    console.log("Serial API is not available.");
    setConnectStatus("Web Serial API is not available in this browser.");
    return false;
  }

  try {
    port = await navigator.serial.requestPort();
    await port.open({ baudRate: 115200 });

    const encoder = new TextEncoderStream();
    encoder.readable.pipeTo(port.writable);
    writer = encoder.writable.getWriter();

    const decoder = new TextDecoderStream();
    port.readable.pipeTo(decoder.writable);
    reader = decoder.readable.getReader();

    setConnectStatus("Connected");
    console.log("Connected.");
    sendCommand("start");
    startReadLoop();
    return true;
  } catch (e) {
    console.log(e);
    setConnectStatus("Connection failed");
    return false;
  }
}

if (connectButton) {
  connectButton.addEventListener("click", async () => {
    setConnectStatus("Connecting...");
    await connectSerial();
  });
}

// ------------------------------------------- Output helpers -------------------------------------------

const output = document.getElementById("output");
let activeDeviceEntry = null;

function createOutputEntry(type) {
  if (!output) {
    return null;
  }

  const entry = document.createElement("p");
  entry.className = `output-entry ${type}`;
  output.appendChild(entry);
  return entry;
}

function scrollOutputToBottom() {
  if (output) {
    output.scrollTop = output.scrollHeight;
  }
}

function appendCommandOutput(text) {
  if (!output || text === undefined || text === null || text === "") {
    return;
  }

  activeDeviceEntry = null;
  const commandEntry = createOutputEntry("command");
  if (!commandEntry) {
    return;
  }

  commandEntry.textContent = `COMMAND: ${text}`;
  scrollOutputToBottom();
}

function appendDeviceOutput(text) {
  if (!output || text === undefined || text === null || text === "") {
    return;
  }

  if (!activeDeviceEntry) {
    activeDeviceEntry = createOutputEntry("device");
  }

  if (!activeDeviceEntry) {
    return;
  }

  activeDeviceEntry.textContent += text;
  scrollOutputToBottom();
}

function sendCommand(text, commandOutput = true) {
  if (!writer) {
    console.log("Not connected.");
    setConnectStatus("Not connected");
    return;
  }

  if (commandOutput) {
    appendCommandOutput(text);
  }
  writer.write(`${text}\n`);
}

// ------------------------------------------- Matrix console & control -------------------------------------------

const rowInput = () => {
  let row = document.getElementById("rowInput").valueAsNumber;
  if (Number.isNaN(row)) {
    row = -1;
  }
  return row;
};

const columnInput = () => {
  let column = document.getElementById("columnInput").valueAsNumber;
  if (Number.isNaN(column)) {
    column = -1;
  }
  return column;
};

const rowToPin = {
  1: 17, 2: 18, 3: 19, 4: 20,
  5: 40, 6: 39, 7: 38, 8: 37, 9: 36, 10: 35, 11: 34, 12: 33,
};

const colToPin = {
  1: 5, 2: 6, 3: 7, 4: 8, 5: 25, 6: 26, 7: 27, 8: 28,
  9: 24, 10: 23, 11: 22, 12: 21, 13: 4, 14: 3, 15: 2, 16: 1,
  17: 16, 18: 15, 19: 14, 20: 13, 21: 30, 22: 29, 23: 9, 24: 10, 25: 11, 26: 12,
};

const submitButton = document.getElementById("submit");
const matrix = document.getElementById("matrix-console");

if (matrix) {
  matrix.innerHTML = "";
  for (let pin = 1; pin <= 40; pin++) {
    const square = document.createElement("div");
    square.className = "square";
    square.dataset.pin = String(pin);
    matrix.appendChild(square);
  }
}

function showSelection(row, col) {
  document.querySelectorAll(".square.active").forEach((square) => {
    square.classList.remove("active");
  });

  const pins = [rowToPin[row], colToPin[col]].filter(Boolean);

  for (const pin of pins) {
    const square = document.querySelector(`.square[data-pin="${pin}"]`);
    if (square) {
      square.classList.add("active");
    }
  }
}

if (submitButton) {
  submitButton.addEventListener("click", () => {
    const row = rowInput();
    const column = columnInput();
    console.log(row, column);
    showSelection(row, column);
  });
}

/*------------------------------------------- Command consle & controls -------------------------------------------*/

const tempCommand = document.getElementById("temperature");
const pressureCommand = document.getElementById("pressure");
const batteryCommand = document.getElementById("battery");
const iTempCommand = document.getElementById("i-temperature");
const iPressureCommand = document.getElementById("i-pressure");
const testAdcCommand = document.getElementById("test-adc");
const debugMcp1Command = document.getElementById("debug-mcp1");
const debugMcp2Command = document.getElementById("debug-mcp2");
const walkMcp1Command = document.getElementById("walk-mcp1");
const walkMcp2Command = document.getElementById("walk-mcp2");
const debugRowsCommand = document.getElementById("debug-rows");
const testMathCommand = document.getElementById("test-math");
const iMatrixCommand = document.getElementById("i-matrix");
const dMatrixCommand = document.getElementById("d-matrix");
const commandInput = document.getElementById("command-input");

function sendMatrixElement() {
  sendCommand(`${columnInput()}\n${rowInput()}`, false);
}

if (tempCommand) {
  tempCommand.addEventListener("click", () => {
    console.log("Scanning for temperature");
    sendCommand("temperature");
  });
}

if (pressureCommand) {
  pressureCommand.addEventListener("click", () => {
    console.log("Scanning for pressure");
    sendCommand("pressure");
  });
}

if (batteryCommand) {
  batteryCommand.addEventListener("click", () => {
    console.log("Checking battery level");
    sendCommand("battery");
  });
}

if (iTempCommand) {
  iTempCommand.addEventListener("click", () => {
    console.log("Individually scanning for temperature");
    sendCommand("i temperature");
    sendMatrixElement();
  });
}

if (iPressureCommand) {
  iPressureCommand.addEventListener("click", () => {
    console.log("Individually scanning for pressure");
    sendCommand("i pressure");
    sendMatrixElement();
  });
}

if (testAdcCommand) {
  testAdcCommand.addEventListener("click", () => {
    console.log("Checking ADC outputs");
    sendCommand("test adc");
    sendMatrixElement();
  });
}

if (debugMcp1Command) {
  debugMcp1Command.addEventListener("click", () => {
    console.log("Checking connections on MCP1");
    sendCommand("debug mcp1");
  });
}

if (debugMcp2Command) {
  debugMcp2Command.addEventListener("click", () => {
    console.log("Checking connections on MCP2");
    sendCommand("debug mcp2");
  });
}

if (walkMcp1Command) {
  walkMcp1Command.addEventListener("click", () => {
    console.log("Walking MCP1");
    sendCommand("walk mcp1");
  });
}

if (walkMcp2Command) {
  walkMcp2Command.addEventListener("click", () => {
    console.log("Walking MCP2");
    sendCommand("walk mcp2");
  });
}

if (debugRowsCommand) {
  debugRowsCommand.addEventListener("click", () => {
    console.log("Checking connections on rows + both TMUXs");
    sendCommand("debug rows");
  });
}

if (testMathCommand) {
  testMathCommand.addEventListener("click", () => {
    console.log("Testing conversion math");
    sendCommand("test math");
  });
}

if (iMatrixCommand) {
  iMatrixCommand.addEventListener("click", () => {
    console.log("Individually turning on one part of matrix");
    sendCommand("i matrix");
    sendMatrixElement();
  });
}

if (dMatrixCommand) {
  dMatrixCommand.addEventListener("click", () => {
    console.log("Disabling entire matrix");
    sendCommand("d matrix");
  });
}

if (commandInput) {
  commandInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      console.log(commandInput.value);
      sendCommand(commandInput.value);
      commandInput.value = "";
    }
  });
}

/*------------------------------------------- Output console -------------------------------------------*/

async function startReadLoop() {
  if (isReadLoopRunning || !reader || !output) {
    return;
  }

  isReadLoopRunning = true;

  while (true) {
    try {
      const { value, done } = await reader.read();

      if (done) {
        reader.releaseLock();
        console.log("Serial port closed.");
        setConnectStatus("Disconnected");
        break;
      }

      appendDeviceOutput(value ?? "");
    } catch (e) {
      console.log(e);
      setConnectStatus("Read error");
      break;
    }
  }

  isReadLoopRunning = false;
}

