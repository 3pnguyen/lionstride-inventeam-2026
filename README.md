# lionstride-inventeam-2026

## Changelog for code:

X = (not the main code but related)

* 1.2.2026 - started the code
* 1.10.2026 - first major version (temperature scanning, battery, Bluetooth, etc.)
* X1.10.2026 - Bluetooth test code w/ ESP DEVKIT
* 1.22.2026 - second major version (added force sensing)
* 1.26.2026 - third major version (UART to have two ESPs communicate w/ each other and have one set to each matrix)
* X1.27.2026 - UART test code for ESP DEVKITs
* 1.29.2026 - minor improvements (removed unnecessary variables in header files, removed prototypes of helper functions into CPP files for clarity, added debug code for UART and Bluetooth)
* 2.1.2026 - major improvement where primary receiving UART ESP can timeout if awaiting too long and can now print error messages for that (for both the main and UART testing code)
* 2.2.2026 - minor fix in the battery code fallback w/ UART (final update before PlatformIO switch)
