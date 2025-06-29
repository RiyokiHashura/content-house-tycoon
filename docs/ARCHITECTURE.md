# Technical Architecture - Content House Tycoon

## 🎯 Core Systems Overview

### Data Flow Architecture
```
Player Joins → DataService → PlotManager → StreamController → UI Controller
     ↓              ↓            ↓              ↓              ↓
Save/Load      Plot Assignment  Hype Stream    Orb Generation  Interface
```

## 📦 Module Specifications

### Server-Side Modules (`src/server/`)

#### 1. GameController (init.server.luau)
**Responsibility**: Central orchestration and system initialization
- Initializes all managers in correct order
- Handles player join/leave events
- Coordinates cross-system communication

#### 2. DataService (services/DataService.luau)
**Responsibility**: All player data persistence
```lua
-- Interface
DataService:LoadPlayerData(player: Player) -> PlayerData
DataService:SavePlayerData(player: Player) -> void
DataService:SetupPlayerStats(player: Player) -> void
```

#### 3. PlotManager (managers/PlotManager.luau)
**Responsibility**: Plot assignment and management
```lua
-- Interface
PlotManager:AssignPlot(player: Player, savedData: PlayerData?) -> Plot
PlotManager:GetPlayerPlot(player: Player) -> Plot?
PlotManager:FreePlot(player: Player) -> void
```

#### 4. StreamController (managers/StreamController.luau)
**Responsibility**: Core gameplay loop execution
```lua
-- Interface
StreamController:StartStream(player: Player) -> boolean
StreamController:HandleOrbCollection(player: Player, orb: Part) -> void
```

### Client-Side Modules (`src/client/`)

#### 1. InteractionController (controllers/InteractionController.luau)
**Responsibility**: Handle all 3D world interactions
- ProximityPrompt connections
- Plot discovery and validation
- RemoteEvent firing

#### 2. UIController (ui/UIController.luau)
**Responsibility**: All interface management
- Upgrade menu logic
- Stat display updates
- Screen navigation

### Shared Modules (`src/shared/`)

#### 1. GameConfig (config/GameConfig.luau)
**Responsibility**: Single source of truth for all game balance
```lua
return {
    Stream = {
        BaseDuration = 30,
        BaseOrbValue = 10,
        ActiveMultiplier = 3,
        OrbSpawnInterval = 2
    },
    Upgrades = {
        PC = {
            {Level = 1, Cost = 0, Duration = 30, OrbValue = 10},
            {Level = 2, Cost = 500, Duration = 25, OrbValue = 15},
            {Level = 3, Cost = 2000, Duration = 20, OrbValue = 20}
        }
    }
}
```

#### 2. RemoteEvents (events/RemoteEvents.luau)
**Responsibility**: Centralized event management
```lua
return {
    ToggleStream = Instance.new("RemoteEvent"),
    PurchaseUpgrade = Instance.new("RemoteEvent"),
    CollectOrb = Instance.new("RemoteEvent")
}
```

## 🔄 Core Gameplay Flow

### Stream Initiation Sequence
1. **Client**: Player approaches StreamingPC
2. **Client**: ProximityPrompt appears "Start Stream"
3. **Client**: Player presses E, fires `ToggleStream` RemoteEvent
4. **Server**: Validates request (plot ownership, cooldown)
5. **Server**: Sets PC.IsStreaming = true
6. **Server**: Begins orb generation loop

### Orb Generation & Collection
1. **Server**: Spawns HypeOrb at PC position every `OrbSpawnInterval`
2. **Server**: Applies BodyPosition to move orb toward MonetizationServer
3. **Client**: Detects orb proximity to player (magnetism effect)
4. **Client**: If player intercepts, fires `CollectOrb` RemoteEvent
5. **Server**: Awards cash based on collection method (passive vs active)

### Data Persistence Strategy
- **Save Triggers**: Player leaving, periodic auto-save (5 minutes)
- **Save Data**: Cash, Subscribers, PC_Level, Plot ownership
- **Load Strategy**: Immediate on join, fallback to defaults if no data

## 🛠️ Error Handling & Validation

### Server Validation Rules
- All RemoteEvent handlers validate player ownership
- Plot assignments check availability before assignment
- Upgrade purchases verify sufficient funds
- Stream requests check cooldowns and equipment state

### Client Resilience
- UI updates listen to server stat changes, not local predictions
- Plot discovery retries until successful
- RemoteEvent calls include timeout handling

## 📈 Performance Considerations

### Server Optimization
- Single coroutine per active stream (not per orb)
- Orb cleanup after 30 seconds if uncollected
- Plot data cached in memory, not re-queried

### Network Efficiency
- Batch orb spawning when possible
- Minimal RemoteEvent payloads
- UI updates only on actual value changes

## 🧪 Testing Strategy

### Unit Testing
- Each manager can be tested in isolation
- Mock dependencies for reliable testing
- Validate all edge cases (no plots available, invalid upgrades)

### Integration Testing
- Full player join/leave cycle
- Complete stream loop execution
- Data persistence round-trip

## 🚀 Deployment Protocol

### Pre-Deploy Checklist
- [ ] All managers initialize without errors
- [ ] Basic stream loop functional
- [ ] Data saves/loads correctly
- [ ] UI responds to server updates
- [ ] No memory leaks in extended play

This architecture prioritizes maintainability, testability, and scalability while keeping the initial MVP simple and focused. 