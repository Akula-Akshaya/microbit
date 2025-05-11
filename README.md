# Tetris-Microbit

A feature-rich implementation of Tetris for the BBC micro:bit platform, featuring multiple game modes, advanced sensor interactions, and multiplayer functionality.

---

## 🚀 Features

### Multiple Game Modes
- **Classic**: Traditional Tetris gameplay  
- **Tilt**: Control pieces by tilting the micro:bit  
- **Battle**: Multiplayer mode—clearing multiple lines sends “garbage” to opponents  
- **Hardcore**: Increased difficulty with faster drop speeds and tilt controls  

### Sensor Integration
- **Accelerometer**: Tilt controls  
- **Temperature sensor**: Activates “Fire Mode” (clears bottom row)  
- **Microphone**: Voice-controlled instant drop  
- **Compass**: Controls gravity direction  
- **Shake gesture**: Scrambles the board  

### Advanced Gameplay Elements
- High score tracking  
- Increasing difficulty levels  
- Visual and sound effects  
- Pause functionality  

---

## 🎮 How to Play

1. **Flash** the `tetris.py` file to your micro:bit.  
2. **Controls**:
   - **Button A**: Rotate piece (or move left in Tilt mode)  
   - **Button B**: Move right  
   - **A + B** together: Instant drop  
   - **Logo touch**: Pause game  
   - **Shake**: Scramble board  
   - **Loud sound**: Instant drop  
   - **Compass north**: Change gravity  
   - **High temperature**: Activate Fire Mode  

3. **Select Game Mode**:  
   At the menu, press **A** or **B** to cycle modes, then **A + B** to start.

---

## 🛠 Installation

1. **Download** `src/tetris.py`  
2. **Connect** your micro:bit to your computer  
3. **Flash** using:
   - [Mu Editor](https://codewith.mu/)  
   - or the official [MicroPython Editor](https://python.microbit.org/)  

---

## 📋 Requirements

- **BBC micro:bit V2** (recommended for full feature set)  
- **BBC micro:bit V1** (supports basic modes only)  

---

## 🤝 Contributors

This project was built by:

-Akshaya
-Alekhya
-Satwik
-Abdul
-Awwab
-Sasi
-Anish

---

## 🙏 Acknowledgements

- Inspired by the classic Tetris game created by Alexey Pajitnov  
- Built using the MicroPython API for BBC micro:bit  
