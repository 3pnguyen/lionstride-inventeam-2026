# lionstride-inventeam-2026

## Branch for the schematic files of the circuit and device

## Prototype changelog:

(Version descriptions have been added since V16 minor 1, so older version descriptions may be inaccurate.)

* v1 - 10.25.25: Original, early concept of the matrix design w/ the hardware to drive it
* v2 - 10.26.25: KiCad representation of V1
* v3 - 10.26.25: Concept for bigger matrix
* v4 - 10.26.25:  V2 refined with filtering and battery power
* v5 - 10.27.25: V4 but doubled matrix for two feet design
* v6 - 11.5.25: Revert back to one matrix and increase matrix size with more hardware
* v7 - 11.5.25: Revisions of V6 with better and more hardware
* v8 - 11.6.25: KiCad representation of V7
* v9 - 11.12.25: Seperated V8 setup into hierarchical sheeets for modular setup
* v10 - 11.14.25: Moved matrix into hierarchical sheet + more revisions
* v11 - 11.20.25: Refined hierarchical schematics more
* v12 - 11.27.25: More refinement w/ filtering on the ADCs
* v13 - 12.1.25: Added more decoupling and added more protection w/ polyfuses
	* v13 minor 1 - 12.7.25: Added operational-amplifiers as voltage followers
	* v13 minor 2 - 12.26.25: Added reference IC
* v14 - 1.1.26: Combine row and column hierarchical schematics together
	* v14 minor 1 - 1.2.26: Switched row and column terminals to headers
	* v14 minor 2 - 1.9.26: Combine row and column headers into one
	* v14 minor 3 - 1.10.26: Removed external LED in favor of code
* v15 - 1.25.26: Added back the second matrix for pressure, created a logic schematic for pressure too
	* v15 minor 1 - 2.13.26: Change decoupler on ref. IC output from 1uf to 10uf (no recording because I forgot)
	* v15 minor 2 - 2.19.26: Added missing row 12 on the main header
* v16 - 2.22.26: Added RC filters and pull-down resistors between MUX drain pins and OP AMP non-inverting inputs
	* v16 minor 1 - 3.2.26: Fixed reference designator conflicts and updated file names
