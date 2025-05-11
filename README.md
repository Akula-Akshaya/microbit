
tertris- microbit

A feature-rich implementation of Tetris for the BBC micro platform, featuring multiple game modes, advanced sensor interactions, and multiplayer functionality.


Features

Multiple Game Modes:

Classic: Traditional Tetris gameplay
Tilt: Control pieces by tilting the micro
Battle: Multiplayer mode where clearing multiple lines sends "garbage" to opponents
Hardcore: Increased difficulty with faster drop speeds and tilt controls


Sensor Integration:

Tilt controls using the accelerometer
Temperature sensor activates "Fire Mode" (clears bottom row)
Microphone enables voice-controlled instant drop
Compass controls gravity direction
Shake gesture scrambles the board


Advanced Gameplay Elements:

High score tracking
Increasing difficulty
Visual and sound effects
Pause functionality



How to Play

Setup: Flash the tetris.py file to your micro.
Controls:

Button A: Rotate piece (or move left in Tilt mode)
Button B: Move right
A+B together: Instant drop
Logo touch: Pause game
Shake: Scramble board
Loud sound: Instant drop
North compass direction: Change gravity
High temperature: Activate Fire Mode


Game Modes: At the menu, press A/B to cycle through modes, and press both buttons to select a mode.

Installation

Download the tetris.py file
Connect your micro to your computer
Flash the file using the Mu Editor or the micro Python Editor

Requirements

BBC micro V2 (recommended for all features)
BBC micro V1 (limited functionality)


Acknowledgements

Inspired by the classic Tetris game created by Alexey Pajitnov
Built using the micro Python API
