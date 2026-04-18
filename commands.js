import {
  commandConsole,
  commandInput,
} from "./elements.js";
import { columnInput, rowInput } from "./matrix.js";
import { sendCommand } from "./serial.js";

// Module state
let commandInputBound = false;
const DEFAULT_COMMAND_SET = "prototype-vd";
let commandSetName = DEFAULT_COMMAND_SET;
let commandSetsPromise;

// ------------------------------------------------------------ Active command set helpers ------------------------------------------------------------

function getActiveCommandSetName() {
  return commandSetName;
}

export function setCommandSet(name) {
  // Allows other modules to switch between board-specific command profiles.
  commandSetName = name || DEFAULT_COMMAND_SET;
}

// ------------------------------------------------------------ Command set loading ------------------------------------------------------------

async function loadCommandSets() {
  if (!commandSetsPromise) {
    // Cache the JSON fetch so we only load and parse the file once per page session.
    commandSetsPromise = fetch("./command-sets.json").then(async (response) => {
      if (!response.ok) {
        throw new Error(`Unable to load command sets: ${response.status}`);
      }

      return response.json();
    });
  }

  return commandSetsPromise;
}

// ------------------------------------------------------------ Command execution helpers ------------------------------------------------------------

function sendMatrixElement() {
  sendCommand(`${columnInput()}\n${rowInput()}`, false);
}

function getButtonLabel({ label, log }) {
  return label || log;
}

function bindCommand({ id, command, log, needsMatrixInput }) {
  const element = document.getElementById(id);

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

// ------------------------------------------------------------ Command console rendering ------------------------------------------------------------

function renderCommandButtons(commandConfigs) {
  if (!commandConsole || !commandInput) {
    return;
  }

  commandConsole.replaceChildren();

  commandConfigs.forEach((commandConfig) => {
    const button = document.createElement("button");
    button.id = commandConfig.id;
    button.className = "command-button";
    button.textContent = getButtonLabel(commandConfig);
    commandConsole.appendChild(button);
    bindCommand(commandConfig);
  });

  commandConsole.appendChild(commandInput);
}

// ------------------------------------------------------------ Public initialization ------------------------------------------------------------

export async function initCommands() {
  const commandSets = await loadCommandSets();
  const activeCommandSetName = getActiveCommandSetName();
  // Pull just the active board's commands out of the full JSON map.
  const commandConfigs = commandSets[activeCommandSetName];

  if (!Array.isArray(commandConfigs)) {
    console.warn(`Command set "${activeCommandSetName}" was not found in command-sets.json.`);
    return;
  }

  // Rebuild the visible button list from the active JSON config.
  renderCommandButtons(commandConfigs);

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
