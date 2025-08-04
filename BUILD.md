# Building SpellCast Survivors

## Prerequisites
- Godot 4.x Engine

## Export Instructions

### Method 1: Using Godot Editor
1. Open the project in Godot Editor
2. Go to **Project → Export**
3. Select either "Windows Desktop" or "macOS" preset
4. Click **Export Project**
5. Save as `SpellCast Survivors.exe` (Windows) or `SpellCast Survivors.dmg` (macOS)

### Method 2: Command Line Export
```bash
# Export Windows build
godot --headless --export-release "Windows Desktop" "SpellCast Survivors.exe"

# Export macOS build  
godot --headless --export-release "macOS" "SpellCast Survivors.dmg"
```

## Platform-Specific Notes

### Windows (.exe)
- Creates a single executable file
- May require Visual C++ Redistributable on target machines
- Compatible with Windows 10/11

### macOS (.dmg)
- Creates a disk image containing the .app bundle
- Universal binary (supports Intel and Apple Silicon)
- Compatible with macOS 10.12+
- May show security warnings on first run (right-click → Open to bypass)

## Distribution
Ready-to-run executable files that can be shared directly with users.