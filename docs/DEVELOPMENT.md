# Development Guide - Content House Tycoon

## 🚀 Current Status: Phase 1 - Architecture Setup

### What We've Built So Far
- ✅ **Project Structure**: Clean Rojo-based architecture
- ✅ **Configuration System**: Centralized game balance in `GameConfig.luau`
- ✅ **Event System**: Organized RemoteEvents and BindableEvents
- ✅ **Data Management**: Robust save/load with retry logic
- ✅ **Plot System**: Player assignment and ownership tracking
- ✅ **Basic Controllers**: Server and client initialization

### Next Steps - MVP Phase 1
1. **Create Plot Template** (Studio Work Required)
2. **Implement Stream Controller** (Core Gameplay)
3. **Create HypeOrb System** (Resource Generation)
4. **Basic UI Implementation** (Player Interface)
5. **Testing & Refinement**

## 🛠️ Development Workflow

### Rojo Sync Process
1. Make code changes in VS Code
2. Rojo automatically syncs to Studio
3. Test in Studio play mode
4. Create any required Studio assets (parts, GUIs, etc.)
5. Commit changes to Git

### Testing Protocol
- **Unit Testing**: Each manager can be tested independently
- **Integration Testing**: Full player join → plot assignment → basic interaction
- **Performance Testing**: Multiple players, extended play sessions

## 📋 Studio Setup Requirements

### Assets Needed in ReplicatedStorage
- `PlotTemplate` (Model)
  - Must have `PrimaryPart` set
  - Contains `SpawnLocation` (SpawnLocation part)
  - Contains `StreamingPC` (Part with ProximityPrompt)
- `HypeOrb` (Part template for resources)

### Workspace Setup
- Place `PlotSpawn` parts where you want plots to appear
- Each `PlotSpawn` will be replaced with a `PlotTemplate` clone

## 🔧 Architecture Decisions

### Why This Structure?
- **Modularity**: Each system can be developed/tested independently
- **Scalability**: Easy to add new content types and features
- **Maintainability**: Clear separation of concerns
- **Performance**: Efficient data flow and minimal network traffic

### Key Design Patterns
- **Dependency Injection**: Managers don't directly reference each other
- **Event-Driven**: Loose coupling through RemoteEvents/BindableEvents
- **Single Source of Truth**: All configuration in `GameConfig`
- **Defensive Programming**: Extensive error handling and validation

## 🐛 Known Issues & Solutions

### Current Linter Warnings
The TypeScript linter is complaining about the shared module requires. This is expected during development and will resolve once the full structure is synced to Studio.

### Performance Considerations
- Plot limit set to 50 (configurable in `GameConfig`)
- Auto-save every 5 minutes to prevent data loss
- Orb cleanup after 30 seconds to prevent memory leaks

## 📊 Metrics & Monitoring

### Server Logs
All major systems log their operations:
- `[DataService]`: Player data operations
- `[PlotManager]`: Plot assignments and releases
- `[GameController]`: Overall system status

### Performance Metrics
- Player count vs plot availability
- Data save/load success rates
- Stream session durations

## 🚦 Phase 1 Success Criteria

### MVP Definition
A player can:
1. Join the game and get assigned a plot
2. Approach their StreamingPC and see a ProximityPrompt
3. Start a stream and see HypeOrbs spawn
4. Collect orbs 
5. Have their progress saved when they leave

### Technical Requirements
- No server errors during normal operation
- Data persistence works reliably
- Plot assignment handles edge cases
- Clean player join/leave cycle

## 🔄 Next Development Sprint

### Priority 1: Core Gameplay Loop
1. **StreamController.luau** - Implement the hype stream logic
2. **HypeOrb mechanics** - Spawning, movement, collection
3. **Basic UI** - Display cash/subscribers

### Priority 2: Polish & Testing
1. Error handling and edge cases
2. Performance optimization
3. User experience improvements

This architecture is built to scale. Once the core loop works, adding new content types, upgrade paths, and features will be straightforward due to the modular design. 