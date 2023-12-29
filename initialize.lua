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
    accessible = false,
    bonusID = nil
    },

    {  -- Level 2
    accessible = false,
    bonusID = nil
    },

    { -- Level 3
    accessible = false,
    bonusID = nil
    },

    { -- Level 4
    accessible = false,
    bonusID = nil
    },

    { -- Level 5
    accessible = false,
    bonusID = nil
    },

    { -- Level 6
    accessible = false,
    bonusID = 11
    },

    { -- Level 7
    accessible = false,
    bonusID = 21
    },

    { -- Level 8
    accessible = false,
    bonusID = 1
    },

    { -- Level 9
    accessible = false,
    bonusID = 12
    },

    { -- Level 10
    accessible = false,
    bonusID = 22
    },

    { -- Level 11
    accessible = false,
    bonusID = 2
    },

    { -- Level 12
    accessible = false,
    bonusID = 13
    },

    { -- Level 13
    accessible = false,
    bonusID = 23
    },

    { -- Level 14
    accessible = false,
    bonusID = 3
    },

    { -- Level 15
    accessible = false,
    bonusID = 14
    },

    { -- Level 16
    accessible = false,
    bonusID = 24
    },

    { -- Level 17
    accessible = false,
    bonusID = 4
    },

    { -- Level 18
    accessible = false,
    bonusID = 15
    },

    { -- Level 19
    accessible = false,
    bonusID = 25
    },

    { -- Level 20
    accessible = false,
    bonusID = 5
    },

    { -- Level 21
    accessible = false,
    bonusID = 16
    },

    { -- Level 22
    accessible = false,
    bonusID = 26
    },

    { -- Level 23
    accessible = false,
    bonusID = 6
    },

    { -- Level 24
    accessible = false,
    bonusID = 27
    },

    { -- Level 25
    accessible = false,
    bonusID = 28
    },

    { -- Level 26
    accessible = false,
    bonusID = 7
    },

    { -- Level 27
    accessible = false,
    bonusID = 29
    },

    { -- Level 28
    accessible = false,
    bonusID = 30
    },

    { -- Level 29
    accessible = false,
    bonusID = 9
    },

    { -- Level 30
    accessible = false,
    bonusID = 31
    },

    { -- Level 31
    accessible = false,
    bonusID = 32
    },

    { -- Level 32
    accessible = false,
    bonusID = 9
    },

    { -- Level 33
    accessible = false,
    bonusID = 33
    },

    { -- Level 34
    accessible = false,
    bonusID = 34
    },

    { -- Level 35
    accessible = false,
    bonusID = 10
    },

    { -- Level 36
    accessible = false,
    bonusID = nil
    },

    { -- Level 37
    accessible = false,
    bonusID = nil
    },

    {-- Level 38
    accessible = false,
    bonusID = nil
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

function initialize.init()
    -- Deep copy the randomized levels again
    randomizedLevels = deepcopy(defaultLevels)

    -- Shuffle bonuses if set to do so
    if SHUFFLE_BONUSES then shuffleBonuses() end

    file = io.open("random.json", "w")
    file:write(json.encode(randomizedLevels))
    file:close()
end

return initialize