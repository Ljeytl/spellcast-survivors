# Building SpellCast Survivors

## Prerequisites
- Godot 4.x Engine

## Export Instructions

### Method 1: Using Godot Editor
1. Open the project in Godot Editor
2. Go to **Project → Export**
3. Select the desired platform preset
4. Click **Export Project**
5. Choose destination in `builds/` folder

### Method 2: Command Line Export
```bash
# Export Windows build
godot --headless --export-release "Windows Desktop" builds/windows/SpellCast-Survivors.exe

# Export macOS build  
godot --headless --export-release "macOS" builds/macos/SpellCast-Survivors.app

# Export Web build
godot --headless --export-release "Web" builds/web/index.html
```

## Platform-Specific Notes

### Windows
- Creates a single `.exe` file
- May require Visual C++ Redistributable on target machines

### macOS
- Creates an `.app` bundle
- May require code signing for distribution

### Web
- Creates HTML5 files playable in browsers
- Requires a web server to run locally (can't open `index.html` directly)
- To test locally: `python -m http.server 8000` in the builds/web directory

## Distribution
- Windows: Distribute the entire `builds/windows/` folder
- macOS: Distribute the `.app` bundle
- Web: Upload `builds/web/` contents to a web server