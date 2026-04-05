import { connectButton, connectStatus } from "./elements.js";
import { appendCommandOutput, appendDeviceOutput } from "./output.js";

let port;
let reader;
let writer;
let isReadLoopRunning = false;
let waitingForStartAck = false;
let startRetryCount = 0;
let startRetryTimer = null;

const BAUD_RATE = 115200;
const START_DELAY_MS = 800;
const START_RETRY_INTERVAL_MS = 800;
const START_RETRY_MAX = 5;

function setConnectStatus(message) {
  if (connectStatus) {
    connectStatus.textContent = message;
  }
}

export function sendCommand(text, commandOutput = true) {
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

function scheduleStartSequence() {
  if (!writer) {
    return;
  }

  waitingForStartAck = true;
  startRetryCount = 0;

  const trySendStart = () => {
    if (!writer || !waitingForStartAck) {
      return;
    }

    if (startRetryCount >= START_RETRY_MAX) {
      waitingForStartAck = false;
      startRetryTimer = null;
      return;
    }

    sendCommand("start", false);
    startRetryCount += 1;
    startRetryTimer = setTimeout(trySendStart, START_RETRY_INTERVAL_MS);
  };

  startRetryTimer = setTimeout(trySendStart, START_DELAY_MS);
}

function handleStartAck(text) {
  if (!waitingForStartAck || !text) {
    return;
  }

  if (String(text).includes("Testing begun")) {
    waitingForStartAck = false;
    if (startRetryTimer) {
      clearTimeout(startRetryTimer);
      startRetryTimer = null;
    }
  }
}

async function startReadLoop() {
  if (isReadLoopRunning || !reader) {
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

      const text = value ?? "";
      handleStartAck(text);
      appendDeviceOutput(text);
    } catch (e) {
      console.log(e);
      setConnectStatus("Read error");
      break;
    }
  }

  isReadLoopRunning = false;
}

export async function connectSerial() {
  if ("serial" in navigator === false) {
    console.log("Serial API is not available.");
    setConnectStatus("Web Serial API is not available in this browser.");
    return false;
  }

  try {
    port = await navigator.serial.requestPort();
    await port.open({ baudRate: BAUD_RATE });

    const encoder = new TextEncoderStream();
    encoder.readable.pipeTo(port.writable);
    writer = encoder.writable.getWriter();

    const decoder = new TextDecoderStream();
    port.readable.pipeTo(decoder.writable);
    reader = decoder.readable.getReader();

    try {
      await port.setSignals({ dataTerminalReady: false, requestToSend: false });
    } catch (e) {
      console.log("setSignals not supported or failed", e);
    }

    setConnectStatus("Connected");
    console.log("Connected.");
    startReadLoop();
    scheduleStartSequence();
    return true;
  } catch (e) {
    console.log(e);
    setConnectStatus("Connection failed");
    return false;
  }
}

export function initConnectionControls() {
  if (!connectButton) {
    return;
  }

  connectButton.addEventListener("click", async () => {
    setConnectStatus("Connecting...");
    await connectSerial();
  });
}
