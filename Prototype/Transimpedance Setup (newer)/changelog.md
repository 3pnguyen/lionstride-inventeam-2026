# Changelog for prototype TIA code

* 4.14.2026 - (For prototype) Modified code for a transimpedance amplifier setup (TIA) while preserving the original voltage divider setup w/ a toggable macro in the .ini file
* 4.16.2026 - (For prototype) Created two seperate versions for the prototype. (Older voltage divider setup & newer TIA setup)
* 4.17.2026 - (For prototype, TIA) Removed experimental macro and old temperature (voltage divider) code, changed TIA reference from GND to 1.65V, modified how reference IC is treated in conversion math, renamed expander + multiplexer header/cpp files
* 4.18.26 - (For prototype, TIA) Replaced the MCP23S17 code with code for the MAX14661 multiplexer (setup will likely be changed later depending on how it is wired on the circuit), fixed ref. IC macro and removed the fixed resistor macro
* 5.14.26 - Made sure the matrix switch time is at least 25 microseconds and mapped the header on the new prototype to the headers of the old prototype/current PCBs
* 5.15.26 - Mapped the column header to the AB pins of the MAX14661s