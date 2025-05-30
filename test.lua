------------------------------------------
-- WindrunnerRotations - Test Runner
-- Author: VortexQ8
------------------------------------------

-- Create minimal WoW API functions for testing
CreateFrame = function() return { RegisterEvent = function() end, SetScript = function() end } end
GetSpellInfo = function() return "Spell" end
UnitBuff = function() return nil end
InCombatLockdown = function() return false end
CombatLogGetCurrentEventInfo = function() return nil end
C_Timer = { After = function(delay, callback) end }

-- Load our addon
local addon = dofile("Init.lua")

-- Define a function to execute Lua files with proper context
function dofileWithContext(filename, context)
    -- Read the file content
    local f = io.open(filename, "r")
    if not f then
        print("Error: could not open file " .. filename)
        return nil
    end
    
    local content = f:read("*all")
    f:close()
    
    -- Create a special environment for the module
    local env = {}
    -- Copy the global environment
    for k, v in pairs(_G) do
        env[k] = v
    end
    
    -- Set up the context variables
    env.API = context.API
    
    if context.Core then
        env.ConfigRegistry = context.Core.ConfigRegistry
        env.AAC = context.Core.AdvancedAbilityControl
    end
    
    if filename:find("Classes/Warlock") and context.Classes and context.Classes.Warlock then
        env.Warlock = context.Classes.Warlock
    elseif filename:find("Classes/Mage") and context.Classes and context.Classes.Mage then
        env.Mage = context.Classes.Mage
    end
    
    -- Execute file directly in this environment
    local chunk, err = loadfile(filename)
    if not chunk then
        print("Error loading " .. filename .. ": " .. err)
        return nil
    end
    
    -- Set the environment for the chunk
    setfenv(chunk, env)
    
    -- Execute and return the result
    local result = chunk()
    return result
end

-- Prepare context
local moduleContext = {
    API = addon.API,
    Classes = addon.Classes,
    Core = addon.Core
}

-- Load base class modules
print("Loading base class modules...")
local warlockModule = dofileWithContext("Classes/Warlock/Warlock.lua", moduleContext)
local mageModule = dofileWithContext("Classes/Mage/Mage.lua", moduleContext)

-- Set them on the addon object
addon.Classes.Warlock = warlockModule
addon.Classes.Mage = mageModule

-- Prepare context for spec modules
local warlockSpecContext = {
    API = addon.API,
    Classes = {
        Warlock = warlockModule
    },
    Core = addon.Core
}

local mageSpecContext = {
    API = addon.API,
    Classes = {
        Mage = mageModule
    },
    Core = addon.Core
}

-- Load specialization modules
print("Loading specialization modules...")
addon.Classes.Warlock.Affliction = dofileWithContext("Classes/Warlock/Affliction.lua", warlockSpecContext) or {}
addon.Classes.Mage.Frost = dofileWithContext("Classes/Mage/Frost.lua", mageSpecContext) or {}

print("\n===================================")
print("Testing Affliction Warlock module")
print("===================================\n")

-- Check if the Affliction Warlock module exists and test it
if addon.Classes.Warlock.Affliction then
    local module = addon.Classes.Warlock.Affliction
    
    -- Override GetActiveSpecID to return Affliction Spec ID (265)
    addon.API.GetActiveSpecID = function() return 265 end
    
    -- Test the module
    print("Initializing Affliction Warlock module...")
    if type(module.Initialize) == "function" then
        module:Initialize()
        
        print("\nRunning Affliction Warlock rotation...")
        if type(module.RunRotation) == "function" then
            -- Create some test conditions
            addon.API.GetPlayerPower = function() return 5 end -- Full soul shards
            addon.API.GetNearbyEnemiesCount = function() return 1 end -- Single target scenario
            addon.API.GetActiveSpecID = function() return 265 end -- Affliction Spec ID
            
            -- Run the rotation
            module:RunRotation()
        else
            print("RunRotation method not found")
        end
    else
        print("Initialize method not found")
    end
else
    print("Affliction Warlock module not found")
end

print("\n===================================")
print("Testing Frost Mage module")
print("===================================\n")

-- Check if the Frost Mage module exists and test it
if addon.Classes.Mage.Frost then
    local module = addon.Classes.Mage.Frost
    
    -- Override GetActiveSpecID to return Frost Spec ID (64)
    addon.API.GetActiveSpecID = function() return 64 end
    
    -- Test the module
    print("Initializing Frost Mage module...")
    if type(module.Initialize) == "function" then
        module:Initialize()
        
        print("\nRunning Frost Mage rotation...")
        if type(module.RunRotation) == "function" then
            -- Create some test conditions
            addon.API.GetNearbyEnemiesCount = function() return 1 end -- Single target scenario
            addon.API.GetActiveSpecID = function() return 64 end -- Frost Spec ID
            
            -- Run the rotation
            module:RunRotation()
        else
            print("RunRotation method not found")
        end
    else
        print("Initialize method not found")
    end
else
    print("Frost Mage module not found")
end

print("\n===================================")
print("Test complete")
print("===================================\n")