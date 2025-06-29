# Content House Tycoon
## Roblox Tycoon Game - Professional Architecture

### 🎯 Project Overview
A simulation game where players start as solo content creators and build media empires. Combines passive income mechanics with active skill-based gameplay.

### 🏗️ Architecture Philosophy
- **Modular Design**: Each system is isolated and communicates through well-defined interfaces
- **Event-Driven**: Loose coupling between systems using RemoteEvents and BindableEvents
- **Data Integrity**: Single source of truth for all game state
- **Scalable**: Built to handle multiple content types and expansion features

### 📁 Project Structure
```
src/
├── server/           # ServerScriptService modules
│   ├── init.server.luau
│   ├── managers/     # Core game systems
│   └── services/     # Utility services
├── client/           # StarterPlayerScripts
│   ├── init.client.luau
│   ├── controllers/  # Client-side logic
│   └── ui/          # Interface management
└── shared/          # ReplicatedStorage modules
    ├── config/      # Game configuration
    ├── events/      # RemoteEvents/BindableEvents
    └── types/       # Type definitions
```

### 🚀 Development Status
- [ ] Core Architecture Setup
- [ ] Player Data Management
- [ ] Plot System
- [ ] Hype Stream Loop
- [ ] Upgrade System
- [ ] UI Implementation

### 🔧 Setup Instructions
1. Ensure Rojo is installed and configured
2. Run `rojo serve` to sync with Roblox Studio
3. Build and test incrementally

### 📋 Current Sprint Goals
**MVP Phase 1**: Get basic streaming loop working
1. Player spawns on assigned plot
2. Can interact with StreamingPC to start stream
3. HypeOrbs spawn and move to collection point
4. Cash is awarded for collection
5. Basic upgrade system functional

### 🤝 Collaboration Protocol
- All changes go through this repository
- Test each feature before moving to next
- Document any Studio-specific setup requirements
- Maintain clean, readable code with proper error handling