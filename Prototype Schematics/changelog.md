# Prototype design changelog:

(Version descriptions have been added since V16 minor 1, so older version descriptions may be inaccurate.)

* V1 - 10.25.25: Original, early concept of the matrix design w/ the hardware to drive it
* V2 - 10.26.25: KiCad representation of V1
* V3 - 10.26.25: Concept for bigger matrix
* V4 - 10.26.25:  V2 refined with filtering and battery power
* V5 - 10.27.25: V4 but doubled matrix for two feet design
* V6 - 11.5.25: Revert back to one matrix and increase matrix size with more hardware
* V7 - 11.5.25: Revisions of V6 with better and more hardware
* V8 - 11.6.25: KiCad representation of V7
* V9 - 11.12.25: Separated V8 setup into hierarchical sheets for modular setup
* V10 - 11.14.25: Moved matrix into hierarchical sheet + more revisions
* V11 - 11.20.25: Refined hierarchical schematics more
* V12 - 11.27.25: More refinement w/ filtering on the ADCs
* V13 - 12.1.25: Added more decoupling and added more protection w/ polyfuses
	* V13 minor 1 - 12.7.25: Added operational-amplifiers as voltage followers
	* V13 minor 2 - 12.26.25: Added reference IC
* V14 - 1.1.26: Combine row and column hierarchical schematics together
	* V14 minor 1 - 1.2.26: Switched row and column terminals to headers
	* V14 minor 2 - 1.9.26: Combine row and column headers into one
	* V14 minor 3 - 1.10.26: Removed external LED in favor of code
* V15 - 1.25.26: Added back the second matrix for pressure, created a logic schematic for pressure too
	* V15 minor 1 - 2.13.26: Change decoupler on ref. IC output from 1uf to 10uf (no recording because I forgot)
	* V15 minor 2 - 2.19.26: Added missing row 12 on the main header
* V16 - 2.22.26: Added RC filters and pull-down resistors between MUX drain pins and OP AMP non-inverting inputs
	* V16 minor 1 - 3.2.26: Fixed reference designator conflicts and updated file names
* V17 - 3.3.26: Made universal version of logic schematic and moved reference IC to spare MUX pin
	* V17 minor 1 - 3.19.26 - grounded one of the pins on the header