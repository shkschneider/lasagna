# Lasagna - Stack the Layers!

A simple lasagna stacking game built with Lua and the LÖVE framework.

## About

Stack layers of lasagna ingredients (pasta, sauce, cheese, and meat) to build the tallest lasagna you can! Each successfully placed layer adds to your score, but be careful - you only have 3 lives, and the ingredients get smaller with each layer.

## How to Play

- **SPACE**: Drop the current ingredient
- **ESC**: Return to menu / Quit game

Your goal is to stack as many layers as possible without running out of lives. The ingredient moves back and forth across the screen - press SPACE when it's aligned with the previous layer!

## Requirements

- [LÖVE (Love2D)](https://love2d.org/) version 11.3 or higher

## Installation

1. Install LÖVE from https://love2d.org/
2. Clone this repository:
   ```bash
   git clone https://github.com/shkschneider/lasagna.git
   cd lasagna
   ```

## Running the Game

### Linux/macOS
```bash
love .
```

### Windows
Drag the game folder onto the `love.exe` executable, or run:
```bash
love.exe .
```

### Alternative Method
You can also package the game into a `.love` file:
```bash
zip -r lasagna.love .
love lasagna.love
```

## Game Features

- Simple, addictive gameplay
- Increasing difficulty as you stack more layers
- Four different ingredient types with unique colors
- Score tracking and lives system
- Clean, minimalist graphics

## Files

- `main.lua` - Main game logic and rendering
- `conf.lua` - LÖVE configuration (window settings, etc.)

## License

This project is open source and available for anyone to use and modify.
