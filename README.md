# lionstride-inventeam-2026

## Branch for the debugger UI/website

[![HTML5](https://img.shields.io/badge/html5-%23E34F26.svg?style=for-the-badge&logo=html5&logoColor=white)](https://github.com/3pnguyen/lionstride-inventeam-2026/blob/website-source/README.md) <!-- - --> [![CSS3](https://img.shields.io/badge/css3-%231572B6.svg?style=for-the-badge&logo=css3&logoColor=white)](https://github.com/3pnguyen/lionstride-inventeam-2026/blob/website-source/README.md) <!-- - --> [![JavaScript](https://img.shields.io/badge/javascript-%23323330.svg?style=for-the-badge&logo=javascript&logoColor=%23F7DF1E)](https://github.com/3pnguyen/lionstride-inventeam-2026/blob/website-source/README.md) <!-- - --> [![Github Pages](https://img.shields.io/badge/github%20pages-121013?style=for-the-badge&logo=github&logoColor=white)](https://github.com/3pnguyen/lionstride-inventeam-2026/blob/website-source/README.md)

<!-- Badeges from https://gprm.itsvg.in and https://github.com/Ileriayo/markdown-badges  -->

<div align="center">
    <table>
        <tr>
            <td><img src="https://github.com/3pnguyen/lionstride-inventeam-2026/blob/main/display-images/website-empty.png" width="450" /></td>
            <td><img src="https://github.com/3pnguyen/lionstride-inventeam-2026/blob/main/display-images/website-empty-dark.png" width="450" /></td>
        </tr>
        <tr>
            <td><img src="https://github.com/3pnguyen/lionstride-inventeam-2026/blob/main/display-images/websirte-in-use-dark.png" width="450" /></td>
            <td><img src="https://github.com/3pnguyen/lionstride-inventeam-2026/blob/main/display-images/website-in-use.png" width="450" /></td>
        </tr>
    </table>
</div>

(Images of update 4.5.2026)

## Purpose

This code is almost like the website version of the app, but this frontend code is used for getting raw output and debugging the ESP32s and circuits. It communicates to the ESP32 via serial communication and runs the exact same commands as you would in the serial monitor withtin PlatformIO. Using PlatformIO is more complicated for everyone one to use, so the debugger UI should make it easier on our teamates to use. [You can click here to enter it.](https://3pnguyen.github.io/lionstride-inventeam-2026/)

## Changelog for code

* 2.28.2026- started and finished first version of the UI (in 7 hours)
* 3.8.2026 - made website fully scalable for size
* 3.10.2026 - Applied Khang's code to await for ESP32 to start properly
* 4.5.2026 - Quality of life updates
    * Made improvements to the Javascript by seperating main.js into seperate files (making the website something I actually want to code)
    * Now hosts this website through GitHub Pages
    * Settings panel w/ dark mode & ability to test both the prototype board and PCB board
* 4.18.2026 - Following the introduction of another configuration to test, configurations are now stored in a JSON file. The settings section now uses a drop-down menu 
