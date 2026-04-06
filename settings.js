import {
    darkModeToggle, 
    singleMCUToggle,
    debugRowsCommand,
    debugMcp1Command,
    debugMcp2Command,
    walkMcp1Command,
    walkMcp2Command,
    debugMCPsCommand,
    walkMCPsCommand
} from "./elements.js";
import { initCommands } from "./commands.js";

export function initSettings() {
    if (!darkModeToggle || !singleMCUToggle) {
        return;
    };

    darkModeToggle.addEventListener("change", () => {
        if (darkModeToggle.checked) {
            document.body.classList.add("dark-mode");
        } else {
            document.body.classList.remove("dark-mode");
        }
    });

    singleMCUToggle.addEventListener("change", () => {
        if (singleMCUToggle.checked) {
            debugMcp1Command.remove();
            debugMcp2Command.remove();
            walkMcp1Command.remove();
            walkMcp2Command.remove();
            
            debugRowsCommand.parentNode.insertBefore(debugMCPsCommand, debugRowsCommand);
            debugRowsCommand.parentNode.insertBefore(walkMCPsCommand, debugRowsCommand);

        } else {
            debugRowsCommand.parentNode.insertBefore(debugMcp1Command, debugRowsCommand);
            debugRowsCommand.parentNode.insertBefore(debugMcp2Command, debugRowsCommand);
            debugRowsCommand.parentNode.insertBefore(walkMcp1Command, debugRowsCommand);
            debugRowsCommand.parentNode.insertBefore(walkMcp2Command, debugRowsCommand);

            debugMCPsCommand.remove();
            walkMCPsCommand.remove();

        }

        initCommands(); // to bind new commands
    });
}
