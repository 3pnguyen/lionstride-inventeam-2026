import { output } from "./elements.js";

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

export function appendCommandOutput(text) {
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

export function appendDeviceOutput(text) {
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
