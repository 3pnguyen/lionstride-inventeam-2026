import {
    darkModeToggle, 
    commandSetSelect
} from "./elements.js";
import { initCommands, setCommandSet } from "./commands.js";

export function initSettings() {
    if (!darkModeToggle || !commandSetSelect) {
        return;
    };

    darkModeToggle.addEventListener("change", () => {
        if (darkModeToggle.checked) {
            document.body.classList.add("dark-mode");
        } else {
            document.body.classList.remove("dark-mode");
        }
    });

    setCommandSet(commandSetSelect.value);

    commandSetSelect.addEventListener("change", async () => {
        setCommandSet(commandSetSelect.value);
        await initCommands();
    });
}
