# 🕐 Digital Alarm Clock — 8051 Assembly

<div align="center">

![8051](https://img.shields.io/badge/MCU-AT89S52-blue?style=for-the-badge)
![Language](https://img.shields.io/badge/Language-Assembly-red?style=for-the-badge)
![Crystal](https://img.shields.io/badge/Crystal-12%20MHz-green?style=for-the-badge)
![Assembler](https://img.shields.io/badge/Assembler-ASEM--51-orange?style=for-the-badge)
![Course](https://img.shields.io/badge/Course-EEE%204706-purple?style=for-the-badge)

**A fully functional digital alarm clock built on the AT89S52 microcontroller,
programmed entirely in 8051 Assembly Language.**

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Hardware](#-hardware)
- [Pin Configuration](#-pin-configuration)
- [How It Works](#-how-it-works)
- [Keypad Layout & Usage](#-keypad-layout--usage)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Uploading to Hardware](#-uploading-to-hardware)
- [Simulation in Proteus](#-simulation-in-proteus)
- [Team](#-team)

---

## 🔍 Overview

This project implements a **real-time digital alarm clock** on the **AT89S52 8051 microcontroller** using pure Assembly Language. There is no external RTC (Real-Time Clock) chip, all timekeeping is done purely in software using **Timer 0 interrupts** that fire every 10 milliseconds.

The clock displays the current time on a **16×2 LCD**, supports **three independent alarms**, a **snooze function**, and two extra features: **LED flash synchronised with the buzzer** and a **button-sequence alarm stop** that prevents accidental dismissal.

---

## ✨ Features

### Core Features
| Feature | Description |
|---|---|
| ⏱️ Real-time clock | Displays HH:MM:SS, updated every second via Timer 0 ISR |
| ⏰ 3 Independent Alarms | Set, enable, and trigger three separate alarms |
| 😴 Snooze Function | User-defined snooze duration (1–59 minutes) |
| ⌨️ Keypad Input | Full 4×4 matrix keypad for all user interactions |
| 📺 LCD Display | 16×2 LCD shows time on line 1 and alarm status on line 2 |

### Extra Features
| Feature | Description |
|---|---|
| 💡 LED Flash Sync | Red LED (LED1) flashes in perfect sync with the buzzer during alarms |
| 🔐 Sequence Stop | Must press **1 → 2 → 1** in order to stop the alarm — prevents accidental dismissal |

---

## 🔧 Hardware

| Component | Value / Model | Purpose |
|---|---|---|
| Microcontroller | AT89S52 | Main processor |
| Crystal | 12 MHz | Clock source |
| Capacitors (crystal) | 33 pF × 2 | Crystal stabilisation |
| Reset capacitor | 10 µF electrolytic | Power-on reset |
| Reset resistor | 10 KΩ | Reset pull-up |
| LCD | LM016L (16×2) | Display |
| Contrast pot | 10 KΩ | LCD contrast adjustment |
| Keypad | 4×4 matrix | User input |
| Buzzer | Active buzzer | Alarm sound |
| LED1 | Red LED | Alarm flash indicator |
| LED2 | Green LED | Power / status indicator |
| LED resistors | 330 Ω × 2 | Current limiting |

---

## 📌 Pin Configuration

```
AT89S52
├── P1.0 – P1.7  ──►  LCD Data Bus (D0–D7)
│
├── P2.0 (LCD_RS) ──►  LCD Register Select
├── P2.1 (LCD_RW) ──►  LCD Read/Write
├── P2.2 (LCD_EN) ──►  LCD Enable
├── P2.3 (BUZZER) ──►  Buzzer
├── P2.4 (LED1)   ──►  Red LED  (alarm flash)
├── P2.5 (LED2)   ──►  Green LED (status)
│
├── P3.0 (KR1)   ──►  Keypad Row 1
├── P3.1 (KR2)   ──►  Keypad Row 2
├── P3.2 (KR3)   ──►  Keypad Row 3
├── P3.3 (KR4)   ──►  Keypad Row 4
├── P3.4         ──►  Keypad Column 1
├── P3.5         ──►  Keypad Column 2
├── P3.6         ──►  Keypad Column 3
└── P3.7         ──►  Keypad Column 4
```

> **Note:** EA (Pin 31) must be connected to VCC for internal ROM operation.

---

## ⚙️ How It Works

### Timekeeping — Timer 0 ISR
The clock uses **no external RTC chip**. Instead, Timer 0 is configured in **16-bit mode** and reloaded every **10 ms** using the value `0xD8F0` (calculated for 12 MHz crystal):

```
12 MHz crystal  →  1 machine cycle = 1 µs
10 ms           →  10,000 counts needed
Reload value    =  65536 − 10000 = 55536 = 0xD8F0
```

Every 100 interrupts (100 × 10 ms = 1 second), the ISR increments the seconds counter. Minutes roll over at 60, hours roll over at 24, midnight resets to 00:00:00.

### Main Loop
The main loop runs approximately **10 times per second**:
1. **DISP_TIME** — refreshes the LCD with the current time and alarm status
2. **CHK_ALARMS** — checks snooze and all three alarms against the current time
3. **CHK_KEY_NB** — non-blocking keypad scan for menu navigation
4. **DLY_100MS** — 100 ms delay before next cycle

### Alarm Detection
An alarm fires when **all three conditions** are true simultaneously:
- The alarm is enabled (`A1EN / A2EN / A3EN = 01H`)
- Current `HOUR` and `MINR` match the programmed alarm time
- Current `SEC = 00` (fires only at the exact start of the minute)

### Delay Architecture
Three **separate RAM counter variables** (DC1, DC2, DC3) are used to prevent the classic 8051 nesting bug where an inner delay loop overwrites the outer loop's counter:

```
DC1 (42H)  →  DLY_1MS  (innermost)
DC2 (43H)  →  DLY_5/10/20MS  (middle)
DC3 (44H)  →  DLY_100MS / DLY_1S  (outermost)
```

---

## ⌨️ Keypad Layout & Usage

```
┌─────┬─────┬─────┬─────┐
│  1  │  2  │  3  │  A  │
├─────┼─────┼─────┼─────┤
│  4  │  5  │  6  │  B  │
├─────┼─────┼─────┼─────┤
│  7  │  8  │  9  │  C  │
├─────┼─────┼─────┼─────┤
│  *  │  0  │  #  │  D  │
└─────┴─────┴─────┴─────┘
```

| Key | Function |
|---|---|
| `1` | Set current time |
| `2` | Set Alarm 1 |
| `3` | Set Alarm 2 |
| `4` | Set Alarm 3 |
| `0`–`9` | Enter digits for time / alarm / snooze |
| `A` | Snooze (press during alarm, then enter minutes) |
| `D` | Force stop alarm permanently |
| `1` → `2` → `1` | Sequence stop — stops alarm after correct sequence |

### LCD Display Format
```
Line 1:  Time:HH:MM:SS
Line 2:  A:1--
         │ ││└─ Alarm 3: '-' = off, '3' = armed
         │ │└── Alarm 2: '-' = off, '2' = armed
         │ └─── Alarm 1: '-' = off, '1' = armed
         └────── Always shows 'A:'
```

---

## 📁 Project Structure

```
📦 Digital-Alarm-Clock-8051
├── 📄 DigitalClkAlarm_v6.asm       # Main source code (Active-HIGH buzzer)
├── 📄 DigitalClkAlarm_v6_AH.asm    # Active-HIGH buzzer variant
├── 📄 DigitalClkAlarm_v6.hex       # Compiled HEX file (ready to upload)
├── 📄 README.md                    # This file
└── 📁 Proteus/
    └── 📄 AlarmClock.pdsprj        # Proteus simulation schematic
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Purpose | Download |
|---|---|---|
| MIDE-51 / ASEM-51 | Assembler and IDE | [mide51.org](http://www.mide51.org) |
| Proteus 8+ | Circuit simulation | [labcenter.com](https://www.labcenter.com) |
| AVRDUDE | HEX file uploader | Included with WinAVR |
| USBasp programmer | Hardware programming | Common lab programmer |
| Zadig | USBasp driver (Windows) | [zadig.akeo.ie](https://zadig.akeo.ie) |

### Assembling the Code

1. Open `DigitalClkAlarm_v6.asm` in **MIDE-51**
2. Press **F9** (or Build → Compile)
3. The `.hex` file is generated in the same folder
4. Check the output window — should show **0 errors, 0 warnings**

---

## 📤 Uploading to Hardware

### Wiring the USBasp to AT89S52

| USBasp Pin | AT89S52 Pin | Signal |
|---|---|---|
| MOSI | Pin 6 (P1.5) | Data to MCU |
| MISO | Pin 7 (P1.6) | Data from MCU |
| SCK | Pin 8 (P1.7) | Clock |
| RESET | Pin 9 (RST) | Reset |
| VCC | Pin 40 | Power |
| GND | Pin 20 | Ground |

> ⚠️ **Important:** Disconnect P1 wires from the LCD before programming.
> P1.5, P1.6, P1.7 are shared with the LCD data bus and will cause write failures if the LCD is connected during upload.

### Upload Command

```bash
avrdude -c usbasp -p at89s52 -B 8 -U flash:w:DigitalClkAlarm_v6.hex:i
```

### Expected Output

```
avrdude: AVR device initialized and ready to accept instructions
avrdude: Device signature = 0x1e5206
avrdude: writing flash (XXXX bytes):
Writing | ################################################## | 100%
avrdude: XXXX bytes of flash written
avrdude: verifying flash memory against DigitalClkAlarm_v6.hex:
avrdude: XXXX bytes of flash verified
```

### Troubleshooting Upload Issues

| Error | Cause | Fix |
|---|---|---|
| `target doesn't answer` | RST circuit issue or wrong wiring | Check RST pin connections |
| `***failed` on every write | LCD connected during programming | Disconnect P1 from LCD |
| `***failed` on every write | Dual power sources conflicting | Power MCU from USBasp only during upload |
| `cannot find USBasp` | Driver not installed | Use Zadig to install libusb-win32 |
| Garbled LCD after upload | Wrong crystal frequency in code | Confirm 12 MHz crystal and correct reload value `0xD8F0` |

---

## 🖥️ Simulation in Proteus

1. Open `AlarmClock.pdsprj` in Proteus
2. Double-click the **AT89C52** component → set **Clock Frequency** to `11059200` Hz (11.0592 MHz) if simulating, or `12000000` for the hardware version
3. Load the HEX file in the MCU properties
4. Connect LCD **VEE (Pin 3)** to GND for full contrast in simulation
5. Press **Play ▶** to run

> 💡 **Tip:** In Proteus simulation use 11.0592 MHz and reload value `0xDC00`. On real hardware with 12 MHz crystal use reload value `0xD8F0` as in v6.

---

## 👥 Team

**Course:** EEE 4706
**Team:** C2 Group 1

| Member | Student ID |
|---|---|
| Member 1 | 210021326 |
| Member 2 | 210021333 |
| Member 3 | 210021340 |
| Member 4 | 210021347 |
| Member 5 | 210021354 |

---

## 📝 License

This project was developed as part of a university course assignment.
Feel free to use it as a reference for learning 8051 Assembly programming.

---

<div align="center">

**Built with ❤️ in Assembly Language**

*No RTOS. No HAL. No libraries. Just pure 8051 registers and raw hardware control.*

</div>
