-- Requirements
SETTINGS = require "settings"
json = require "json"

-- Shuffle a table
local function shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

-- Clone a table
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Default table of levels, with properties for whether they are accessible/completed, and the bonus they hold
defaultLevels = {
    { -- Level 1
    index = 1,
    accessible = false,
    completed = false,
    bonusID = nil,
    bonusCollected = nil
    },

    {  -- Level 2
    index = 2,
    accessible = false,
    completed = false,
    bonusID = nil,
    bonusCollected = nil
    },

    { -- Level 3
    index = 3,
    accessible = false,
    completed = false,
    bonusID = nil,
    bonusCollected = nil
    },

    { -- Level 4
    index = 4,
    accessible = false,
    completed = false,
    bonusID = nil,
    bonusCollected = nil
    },

    { -- Level 5
    index = 5,
    accessible = false,
    completed = false,
    bonusID = nil,
    bonusCollected = nil
    },

    { -- Level 6
    index = 6,
    accessible = false,
    completed = false,
    bonusID = 11,
    bonusCollected = false
    },

    { -- Level 7
    index = 7,
    accessible = false,
    completed = false,
    bonusID = 21,
    bonusCollected = false
    },

    { -- Level 8
    index = 8,
    accessible = false,
    completed = false,
    bonusID = 1,
    bonusCollected = false
    },

    { -- Level 9
    index = 9,
    accessible = false,
    completed = false,
    bonusID = 12,
    bonusCollected = false
    },

    { -- Level 10
    index = 10,
    accessible = false,
    completed = false,
    bonusID = 22,
    bonusCollected = false
    },

    { -- Level 11
    index = 11,
    accessible = false,
    completed = false,
    bonusID = 2,
    bonusCollected = false
    },

    { -- Level 12
    index = 12,
    accessible = false,
    completed = false,
    bonusID = 13,
    bonusCollected = false
    },

    { -- Level 13
    index = 13,
    accessible = false,
    completed = false,
    bonusID = 23,
    bonusCollected = false
    },

    { -- Level 14
    index = 14,
    accessible = false,
    completed = false,
    bonusID = 3,
    bonusCollected = false
    },

    { -- Level 15
    index = 15,
    accessible = false,
    completed = false,
    bonusID = 14,
    bonusCollected = false
    },

    { -- Level 16
    index = 16,
    accessible = false,
    completed = false,
    bonusID = 24,
    bonusCollected = false
    },

    { -- Level 17
    index = 17,
    accessible = false,
    completed = false,
    bonusID = 4,
    bonusCollected = false
    },

    { -- Level 18
    index = 18,
    accessible = false,
    completed = false,
    bonusID = 15,
    bonusCollected = false
    },

    { -- Level 19
    index = 19,
    accessible = false,
    completed = false,
    bonusID = 25,
    bonusCollected = false
    },

    { -- Level 20
    index = 20,
    accessible = false,
    completed = false,
    bonusID = 5,
    bonusCollected = false
    },

    { -- Level 21
    index = 21,
    accessible = false,
    completed = false,
    bonusID = 16,
    bonusCollected = false
    },

    { -- Level 22
    index = 22,
    accessible = false,
    completed = false,
    bonusID = 26,
    bonusCollected = false
    },

    { -- Level 23
    index = 23,
    accessible = false,
    completed = false,
    bonusID = 6,
    bonusCollected = false
    },

    { -- Level 24
    index = 24,
    accessible = false,
    completed = false,
    bonusID = 27,
    bonusCollected = false
    },

    { -- Level 25
    index = 25,
    accessible = false,
    completed = false,
    bonusID = 28,
    bonusCollected = false
    },

    { -- Level 26
    index = 26,
    accessible = false,
    completed = false,
    bonusID = 7,
    bonusCollected = false
    },

    { -- Level 27
    index = 27,
    accessible = false,
    completed = false,
    bonusID = 29,
    bonusCollected = false
    },

    { -- Level 28
    index = 28,
    accessible = false,
    completed = false,
    bonusID = 30,
    bonusCollected = false
    },

    { -- Level 29
    index = 29,
    accessible = false,
    completed = false,
    bonusID = 9,
    bonusCollected = false
    },

    { -- Level 30
    index = 30,
    accessible = false,
    completed = false,
    bonusID = 31,
    bonusCollected = false
    },

    { -- Level 31
    index = 31,
    accessible = false,
    completed = false,
    bonusID = 32,
    bonusCollected = false
    },

    { -- Level 32
    index = 32,
    accessible = false,
    completed = false,
    bonusID = 9,
    bonusCollected = false
    },

    { -- Level 33
    index = 33,
    accessible = false,
    completed = false,
    bonusID = 33,
    bonusCollected = false
    },

    { -- Level 34
    index = 34,
    accessible = false,
    completed = false,
    bonusID = 34,
    bonusCollected = false
    },

    { -- Level 35
    index = 35,
    accessible = false,
    completed = false,
    bonusID = 10,
    bonusCollected = false
    },

    { -- Level 36
    index = 36,
    accessible = false,
    completed = false,
    bonusID = nil,
    bonusCollected = nil
    },

    { -- Level 37
    index = 37,
    accessible = false,
    completed = false,
    bonusID = nil,
    bonusCollected = nil
    },

    {-- Level 38
    index = 38,
    accessible = false,
    completed = false,
    bonusID = nil,
    bonusCollected = nil
    }
}

-- Copy of default table, to be modified with above functions and put into a json
randomizedLevels = deepcopy(defaultLevels)

local initialize = {}

-- Shuffle bonuses amongst levels that can hold them
local function shuffleBonuses()
    local bonusIDTable = {}
    for i = 1, #defaultLevels do
        table.insert(bonusIDTable, defaultLevels[i]["bonusID"])
    end

    shuffle(bonusIDTable)

    for i = 1, #defaultLevels do
        randomizedLevels[i]["bonusID"] = bonusIDTable[i-5]
    end
end

-- local function removeBonusLevels()
--     for i = 36, 38 do
--         randomizedLevels[i] = {"NOT IN GAME"}
--     end
-- end

-- local function removeTrainingLevels()
--     for i = 1, 5 do
--         randomizedLevels[i] = {"NOT IN GAME"}
--     end
-- end

function initialize.init()
    -- Deep copy the randomized levels again
    randomizedLevels = deepcopy(defaultLevels)

    -- Shuffle bonuses if set to do so
    if SHUFFLE_BONUSES then shuffleBonuses() end

    -- -- Remove bonus levels if set to exclude
    -- if not INCLUDE_BONUS_LEVELS then removeBonusLevels() end

    -- -- Remove training levels if set to exclude
    -- if not INCLUDE_TRAINING_LEVELS then removeTrainingLevels() end

    file = io.open("random.json", "w")
    file:write(json.encode(randomizedLevels))
    file:close()
end

return initialize