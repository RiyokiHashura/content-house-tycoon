# Content House Tycoon - Complete Setup Guide

## 🎯 **System Overview**

Your tycoon uses a **traditional button-based building system** where YOU control all positioning and what gets built. The logic handles the purchasing, dependencies, and integrations automatically.

---

## 🏗️ **Plot Template Structure (What YOU Build in Studio)**

```
PlotTemplate/
├── Base (Your plot baseplate)
├── SpawnLocation (Where players spawn)
├── StreamingPC (Back area - generates passive income)
│   ├── ProximityPrompt ("Start Stream")
│   └── PC_ClientLogic (LocalScript)
├── Buttons/ (Folder - Your purchase buttons)
│   ├── Button_Walls (Part with attributes)
│   ├── Button_Kitchen (Part with attributes)
│   ├── Button_Bedroom (Part with attributes)
│   └── Button_Studio (Part with attributes)
└── Builds/ (Folder - Your build models, initially hidden)
    ├── Build_Walls (Model with attributes)
    ├── Build_Kitchen (Model with attributes)
    ├── Build_Bedroom (Model with attributes)
    └── Build_Studio (Model with attributes)
```

---

## 🔧 **Button Setup (What YOU Configure)**

### **Step 1: Create Button Parts**
- Create a Part in the `Buttons/` folder
- Position it where you want the purchase button
- Name it something descriptive (e.g., "Button_Kitchen")

### **Step 2: Set Button Attributes**
For each button Part, set these **Attributes** in Studio:

```lua
-- Required Attributes:
Price = 500              -- How much it costs
Currency = "Cash"        -- "Cash" or "Subscribers" 
BuildId = "Kitchen"      -- Must match your build model
Dependency = "Walls"     -- What must be bought first (optional)
```

### **Example Button Setup:**
```
Button_Walls:
  - Price: 100
  - Currency: "Cash" 
  - BuildId: "Walls"
  - Dependency: (none)

Button_Kitchen:
  - Price: 500
  - Currency: "Cash"
  - BuildId: "Kitchen" 
  - Dependency: "Walls"

Button_Bedroom:
  - Price: 1000
  - Currency: "Cash"
  - BuildId: "Bedroom"
  - Dependency: "Kitchen"

Button_Studio:
  - Price: 2500
  - Currency: "Cash" 
  - BuildId: "Studio"
  - Dependency: "Bedroom"
```

---

## 🏠 **Build Model Setup (What YOU Create)**

### **Step 1: Create Build Models**
- Create a Model in the `Builds/` folder
- Build your room/furniture/decoration as you want it
- Position it exactly where it should appear when purchased
- Name it descriptively (e.g., "Build_Kitchen")

### **Step 2: Set Build Attributes**
For each build Model, set these **Attributes**:

```lua
-- Required Attributes:
BuildId = "Kitchen"          -- Must match button's BuildId
BuildType = "Room"           -- "Room", "Furniture", "Decoration"
RoomType = "Kitchen"         -- For room builds only (enables streamer hiring)
```

### **Build Type Examples:**
```
Build_Walls:
  - BuildId: "Walls"
  - BuildType: "Structure"

Build_Kitchen:
  - BuildId: "Kitchen" 
  - BuildType: "Room"
  - RoomType: "Kitchen"

Build_Bedroom:
  - BuildId: "Bedroom"
  - BuildType: "Room" 
  - RoomType: "Bedroom"

Build_Studio:
  - BuildId: "Studio"
  - BuildType: "Room"
  - RoomType: "Studio"
```

---

## 💰 **Currency System**

### **Cash Sources:**
- StreamingPC passive income: $10 every 3 seconds
- StreamingPC active income: $30 every 3 seconds (when streaming)
- Cash orbs from streaming: $25-100 per orb
- Streamer NPC income: $5-25 per 30 seconds

### **Subscriber Sources:**
- Subscriber orbs from streaming: 1-50 subs per orb
- Streamer NPC income: 2-10 subs per 30 seconds

---

## 👥 **Streamer NPC System**

### **How It Works:**
1. Player buys a room with `BuildType = "Room"`
2. System automatically creates a "Hire Streamer" spot in that room
3. Player walks near the spot → Streamer shop UI opens
4. Player picks a streamer and pays with subscribers
5. NPC appears and generates passive income

### **Current Streamer Types:**
```
Jake Gaming (Gaming):
  - Cost: 50 subscribers
  - Income: 2 subs/min + $5/min

Zara Moves (Dancing): 
  - Cost: 150 subscribers
  - Income: 5 subs/min + $12/min

Chef Marco (Cooking):
  - Cost: 400 subscribers  
  - Income: 10 subs/min + $25/min
```

---

## 🎮 **Complete Player Flow**

### **Early Game (0-5 minutes):**
1. Player spawns in empty plot
2. StreamingPC generates $10 every 3 seconds (passive income)
3. Player can start streaming for 3x income boost + orbs
4. Buy Walls ($100) → House structure appears
5. Buy Kitchen ($500) → Kitchen room appears with streamer spot

### **Mid Game (5-15 minutes):**
1. Walk to kitchen streamer spot → Hire Jake Gaming (50 subs)
2. Jake generates 2 subs/min + $5/min automatically
3. Save up for Bedroom ($1000) → Bedroom appears with new streamer spot
4. Hire Zara Moves (150 subs) → More passive income

### **Late Game (15+ minutes):**
1. Buy Studio ($2500) → Professional studio appears
2. Hire Chef Marco (400 subs) → Maximum passive income
3. Multiple streamers generating constant income
4. Focus on streaming for active bonuses

---

## 🛠️ **Technical Flow (What The Logic Does)**

### **TycoonBuilder Service:**
1. **Scans** your Buttons/ folder for button parts
2. **Reads** the attributes you set (price, currency, buildId, etc.)
3. **Styles** buttons automatically (green=cash, purple=subs, floating price text)
4. **Detects** when player walks near button
5. **Checks** if player can afford + has dependencies met
6. **Purchases** item and spawns corresponding build model
7. **Integrates** with StreamerService for room builds

### **StreamerService:**
1. **Detects** when room with `BuildType="Room"` is built
2. **Creates** glowing "Hire Streamer" spot in room center
3. **Shows** streamer shop UI when player approaches
4. **Handles** streamer hiring with subscriber payment
5. **Spawns** NPC and tracks passive income generation
6. **Generates** income every 30 seconds with visual popups

### **StreamingService:**
1. **Handles** StreamingPC interactions
2. **Generates** passive income ($10/3sec) and active income ($30/3sec)
3. **Spawns** subscriber and cash orbs during streaming
4. **Shows** floating income text with emojis

---

## 🔍 **Debugging & Testing**

### **Console Commands:**
```lua
-- Debug player data
TycoonBuilder.DEBUG.getPlayerData("PlayerName")
StreamerService.DEBUG.getPlayerData("PlayerName")

-- Force purchase (testing)
TycoonBuilder.DEBUG.forcePurchase("PlayerName", "Kitchen")
StreamerService.DEBUG.forceHireStreamer("PlayerName", "gamer_rookie")
```

### **Common Issues:**
- **Button not working:** Check if Buttons/ folder exists and attributes are set
- **Build not appearing:** Check if Builds/ folder has matching BuildId
- **Streamer spot not appearing:** Check if BuildType="Room" and RoomType is set
- **Dependencies not working:** Check Dependency attribute spelling

---

## 📝 **Quick Setup Checklist**

### **Studio Setup:**
- [ ] Create Buttons/ folder in PlotTemplate
- [ ] Create Builds/ folder in PlotTemplate  
- [ ] Remove old Room1Door, Room2Door, Room3Door parts
- [ ] Position button parts where you want them
- [ ] Set all button attributes (Price, Currency, BuildId, Dependency)
- [ ] Create build models positioned where they should appear
- [ ] Set all build attributes (BuildId, BuildType, RoomType)

### **Testing:**
- [ ] Join game and check console for TycoonBuilder logs
- [ ] Walk near buttons and verify purchase mechanics
- [ ] Test dependency system (can't buy kitchen without walls)
- [ ] Test room building and streamer spot creation
- [ ] Test streamer hiring and income generation

---

## 🚀 **Ready to Build!**

The system is now **completely setup** for your manual control. You just need to:
1. **Position** your buttons and builds where you want them
2. **Set** the attributes with the prices and dependencies you want  
3. **Test** in-game to make sure everything works

The logic handles all the complex stuff - you focus on the creative building! 🎯 