# Tetris+ for Micro:bit

A feature-rich implementation of Tetris for the BBC micro:bit platform, featuring multiple game modes, advanced sensor interactions, and multiplayer functionality.

## 🚀 Features

### Multiple Game Modes
* **Classic**: Traditional Tetris gameplay with button controls
* **Tilt**: Control pieces by tilting the micro:bit using accelerometer input
* **Battle**: Multiplayer mode where clearing multiple lines sends "garbage" to opponents
* **Hardcore**: Increased difficulty with faster drop speeds and tilt controls

### Sensor Integration
* **Accelerometer**: Tilt controls for piece movement
* **Temperature sensor**: Activates "Fire Mode" (clears bottom row) when above 30°C
* **Microphone**: Loud sound triggers instant piece drop
* **Compass**: Controls gravity direction when pointed north (350-10°)
* **Shake gesture**: Scrambles the board randomly
* **Touch logo**: Pauses the game

### Advanced Gameplay Elements
* High score tracking with filesystem storage
* Increasing difficulty levels (speed increases over time)
* Visual and sound effects for game events
* Pause functionality
* Radio communication for multiplayer battles

## 🎮 How to Play

1. **Flash** the `tetris.py` file to your micro:bit.
2. **Select Game Mode**: At the menu, press **A** or **B** to cycle through modes, then **A + B** to start.

### Game Mode Details

#### CLASSIC Mode
* Traditional Tetris gameplay
* **Button A**: Rotate piece
* **Button B**: Move right
* **A + B** together: Instant drop
* Clear lines to score points
* Speed increases as you progress

#### TILT Mode
* Tilting controls replace button movements
* Tilt left/right to move the piece horizontally
* **Button A**: Rotate piece
* **A + B** together: Instant drop
* Uses the accelerometer for a more immersive experience

#### BATTLE Mode
* Multiplayer competition via radio communication
* When you clear 2+ lines at once, sends "garbage lines" to opponents
* Receive garbage lines from opponents
* Last player standing wins
* Radio messages handle synchronization between devices

#### HARDCORE Mode
* Significantly faster piece dropping
* Uses tilt controls like TILT mode
* Higher scoring potential
* Less forgiving gameplay
* All sensor interactions are more sensitive

### Controls (All Modes)
* **Button A**: Rotate piece / scroll menu backward
* **Button B**: Move right / scroll menu forward
* **A + B** together: Instant drop / select menu option
* **Logo touch**: Pause game
* **Shake**: Scramble board randomly
* **Loud sound**: Trigger instant drop
* **Compass north**: Change gravity direction
* **High temperature** (>30°C): Activate Fire Mode (clears bottom row)

## Special Features

### Fire Mode
* Triggered when temperature exceeds 30°C
* Temporarily clears the bottom row
* Has a 10-second cooldown between activations

### Gravity Rotation
* Activated when compass points north (350-10°)
* Changes the direction of falling pieces
* Adds an extra challenge to gameplay

### Scramble Feature
* Triggered by shake gesture
* Randomizes current block positions
* Can help or hinder depending on the situation!

## Visual & Audio Feedback
* LED icons (DIAMOND, TRIANGLE, SKULL, etc.) for game events
* Display shows falling blocks and grid state in real-time
* Sound effects for line clears and game events

## 🛠 Installation

1. **Download** `src/tetris.py`
2. **Connect** your micro:bit to your computer
3. **Flash** using:
   * Mu Editor
   * or the official MicroPython Editor

## Technical Implementation

The game uses a class-based structure with:
* **TetrisGame** class: Main game logic, grid management, and game states
* **main()** function: Game loop running at 50ms intervals, handling all updates
* **Error handling**: Scrolls "ERROR" message if something goes wrong

## 📋 Requirements

* **BBC micro:bit V2** (recommended for full feature set including microphone and touch logo)
* **BBC micro:bit V1** (supports basic modes with limited sensor functionality)

## 🤝 Contributors

This project was built by:
-Akshaya -Alekhya -Satwik -Abdul -Awwab -Sasi -Anish

## 🙏 Acknowledgements

* Inspired by the classic Tetris game created by Alexey Pajitnov
* Built using the MicroPython API for BBC micro:bit
