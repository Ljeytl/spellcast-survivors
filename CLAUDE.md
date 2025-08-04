# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpellCast Survivors is a vampire survivors-style game built in Godot 4.x where players cast spells by typing their names while fighting waves of enemies. The core mechanic combines strategic positioning with typing skill under pressure.

## Development Commands

This is a Godot project with minimal external dependencies. Development is done through the Godot editor:

- **Open Project**: Open `project.godot` in Godot Editor
- **Run Game**: Press F5 in Godot Editor or use the Play button
- **Export/Build**: Use Project → Export in Godot Editor

Note: This appears to be an early-stage project - the actual game code has not been implemented yet.

## Project Architecture

Based on the design document, the game will follow this structure:

### Core Systems
- **GameManager**: Main game state and flow control (PLAYING, LEVEL_UP, GAME_OVER, PAUSED)
- **SpellSystem**: Handles spell queuing, typing input, and casting mechanics with time dilation
- **Player**: WASD movement, auto-attack (Mana Bolt), and spell casting
- **EnemyManager**: Spawn patterns, difficulty scaling, and enemy behavior
- **UIManager**: HUD elements, level up screen, and game feedback

### Spell System Design
- Number keys (1-6) queue spells
- Players type spell names to cast (e.g., "bolt", "ice blast", "meteor shower")
- Time slows to 20% while typing
- Spells have 8 levels max with damage scaling: `base_damage * (1 + 0.15 * (level - 1))`
- Typing length correlates with spell power (4-13 characters)

### Enemy Scaling
- Health scales every 30 seconds: `base_hp * (1 + 0.1 * floor(time / 30))`
- Speed increases every 60 seconds
- Spawn rate increases every 45 seconds
- XP rewards scale with enemy health: `base_xp * sqrt(health_multiplier)`

### Planned File Structure
```
scenes/
├── Main.tscn
├── Player.tscn
├── Enemy.tscn
└── UI.tscn
scripts/
├── GameManager.gd
├── Player.gd
├── SpellSystem.gd
├── EnemyManager.gd
└── UIManager.gd
```

## Game Design Constraints

- 6 spell types with specific character counts for balance
- Time-based difficulty scaling independent of player level
- XP scaling: Level N requires `100 + (N * 25)` XP
- Enemy types: Chaser, Swarm, Tank, Shooter (introduced progressively)
- Backend API for score tracking (optional for MVP)

## Development Priority

The core typing mechanic is non-negotiable - this differentiates the game from other vampire survivors clones. Focus on:
1. Spell queuing and typing system
2. Time dilation during spell casting
3. Player movement and auto-attack
4. Basic enemy spawning and behavior
5. XP/leveling system

## Current State

This is a fresh Godot project with only the project configuration and design document. No game code has been implemented yet.

## Development Guidelines

- Use Agents when possible to assign tasks
- Use MCP servers when appropriate to access information or test

## Learning Objectives

- Guide User through Godot so that you can code the project