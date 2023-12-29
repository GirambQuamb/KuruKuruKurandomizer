-----------------------------------
------- CONSTANTS -----------------
-----------------------------------

VERSION = "Prerelease"

-----------------------------------
------- ADDRESSES -----------------
-----------------------------------

FILENAME_ADD = 0x203BDAE -- Start of GUEST file name
LEVEL_ACCESS_ADD = 0x203BF40 -- Start of level accessibility (goes until + 0x25)

-----------------------------------
------- REQUIREMENTS --------------
-----------------------------------

CHARACTERTABLE = require "charactertable"
SETTINGS = require "settings" -- Randomizer settings
json = require "json" -- json functions
initialize = require "initialize" -- Functions to initialize a new run

-----------------------------------
----------- VARIABLES -------------
-----------------------------------

gameStateA = 0 -- Are these necessary?
gameStateB = 0

-----------------------------------
------- SAVE FILE RELATED ---------
-----------------------------------

-- 0203BFA2 -> File 1 name
-- 0203C196 -> File 2 name
-- 0203C38A -> File 3 name
-- 0203C57E -> File 4 name

-- 0801E8C0 -> "Delete Saved Data" text overwriting

-- Show some text using the file select screen
function showTitleText()
	local topTitle = "Kuru Kuru"
	local middleTitle = "Kururin"
	local bottomTitle = "Randomizer"

	memory.writebyte(0x203BFA2, 0x20)
	for i=0, #topTitle do
		local s = topTitle:sub(i+1,i+1)
		memory.writebyte(0x0203BFA2+i, CHARACTERTABLE[s])
	end

	for i=0, #middleTitle do
		local s = middleTitle:sub(i+1,i+1)
		memory.writebyte(0x0203C196+i, CHARACTERTABLE[s])
	end

	for i=0, #bottomTitle do
		local s = bottomTitle:sub(i+1,i+1)
		memory.writebyte(0x0203C38A+i, CHARACTERTABLE[s])
	end

	memory.writebyte(0x0203C57E, 0x20)

	for i=0, #VERSION do
		local s = VERSION:sub(i+1,i+1)
		memory.writebyte(0x0801E8C0+i, CHARACTERTABLE[s])
	end
end

-- Set filename
function setFileName(filename)
	if #filename < 10 then
		for i = 0, 10 do
			local s = filename:sub(i+1,i+1)
			if i > #filename-1 then
				memory.writebyte(FILENAME_ADD+i, 0)
			else
				if CHARACTERTABLE[s] then
					memory.writebyte(FILENAME_ADD+i, CHARACTERTABLE[s])
				else
					memory.writebyte(FILENAME_ADD+i, CHARACTERTABLE["?"])
				end
			end
		end
	else
		print("Filename too long! Setting to \"GUEST\"")
		setFileName("GUEST")
	end
end

function setRandomMakeup()
	local stick = math.random(0x0,0xe)
	local paint = math.random(0x0,0x6)

	-- Set random makeup (Does not set birds, at BDC6 and BDC7)
	memory.writebyte(0x203bdc4, stick) -- Stick shape
	memory.writebyte(0x203bdc5, paint) -- Paint
end

-- Save which bonuses are unlocked, which makeup is worn, and which levels have the "I missed something" text
function copySaveData(addr)
	-- Only copy to a file if you're past the title screen
	-- This prevents overwriting makeup when resetting
	if memory.readbyte(0x3000dca) > 1 then
		-- Relevant save data array
		local mem = memory.read_bytes_as_array(0x203BDC0, 0x200)

		local sav = io.open("random.dat", "w")
		sav:write(json.encode(mem))
		sav:close()

		-- Debugging
		-- print("Save data copied to random.dat")
		-- if addr then
		-- 	print("Address: " .. string.format("%x", addr))
		-- else
		-- 	print("Called manually :)")
		-- end
	end
end

function writeSaveData(data)
	memory.write_bytes_as_array(0x203BDC0, data)
end


-- If the save file is written to, run the appropriate funciton
for i = 0x203BDA0, 0x203BFA0 do
	event.on_bus_write(copySaveData, i)
end

-----------------------------------
------- LEVEL RELATED -------------
-----------------------------------

-- Unlocks a given level
function unlockLevel(level)
	randomizedLevels[level]["accessible"] = true
	memory.writebyte(LEVEL_ACCESS_ADD+level-1,2)
	
	local randomizedJSON = io.open("random.json","w")
	randomizedJSON:write(json.encode(randomizedLevels))
    randomizedJSON:close()
end

-- Randomly chooses an appropriate level to unlock
function chooseUnlockedLevel()
	-- Number of levels in the randomized list to choose from
	local numPossibleLevels = 0

	-- Lowest/highest level the randomizer is willing to choose from
	local lowestPossibleLevel = 1
	local highestPossibleLevel = 38

	-- List of locked level indexes
	local lockedLevels = {}

	-- Base length of list on settings
	if tonumber(LEVEL_ORDER) ~= nil then
		numPossibleLevels = tonumber(LEVEL_ORDER)
	elseif LEVEL_ORDER == "unshuffled" then
		numPossibleLevels = 1
	elseif LEVEL_ORDER == "random" then
		numPossibleLevels = #randomizedLevels
	elseif LEVEL_ORDER == "close" then
		numPossibleLevels = 6
	else -- or throw a pretend error
		print("Error with \"LEVEL_ORDER\" setting.\nCheck settings.lua and enter a valid option!")
		return
	end

	-- Base valid level choices based on settings
	if not INCLUDE_TRAINING_LEVELS then lowestPossibleLevel = 6 end
	if not INCLUDE_BONUS_LEVELS then highestPossibleLevel = 35 end

	-- Iterate through the list of randomized levels
	for key, value in ipairs(randomizedLevels) do
		-- Only check valid levels
		if key >= lowestPossibleLevel and key <= highestPossibleLevel then
			-- Add it to our lockedLevels table if it's locked
			if value["accessible"] == false then
				table.insert(lockedLevels, key) -- This is the index in randomizedLevels that we will use to unlock
			end
		end
		-- Break out of the loop if we've hit our max length
		if #lockedLevels == numPossibleLevels then break end
	end

	-- Only unlock a level if there's a level to unlock
	if #lockedLevels > 0 then
		r = math.random(#lockedLevels)
		unlockLevel(lockedLevels[r])
	end
end

-- Sets boundary for player moving right on the map
-- IE: The highest accessible level
function setHighestAccessibleLevel()
	if INCLUDE_BONUS_LEVELS then
		memory.writebyte(0x3007e8e,37)
	else
		memory.writebyte(0x3007e8e,34)
	end
end

-- Sets all levels to inaccessible
function initLevelAccess()
	for i=0, 37 do
		memory.writebyte(LEVEL_ACCESS_ADD+i, 1)
	end
end

-----------------------------------
---- INITILIZATION FUNCTIONS ------
-----------------------------------

-- Delete all saved data
function deleteSavedData()
	joypad.set({Power = 1})
	for i=0, 5 do
		emu.frameadvance();
		joypad.set({A=1, B=1, Select=1, Start=1})
	end
	emu.frameadvance();
	joypad.set({Up=1})
	for i=0, 6 do
		emu.frameadvance();
	end
	joypad.set({A=1})
	for i=0, 60 do
		emu.frameadvance();
	end
end

-- Setup level access, json file, etc.
function setupFile()
	showTitleText() -- Use unused filenames to show text
	setFileName(FILE_NAME) -- Set the file name

	-- Set all levels to inaccessible in-game
	initLevelAccess() -- Set all levels to inaccessible, except the input level...

	-- Hide bonus levels if they are excluded
	if not INCLUDE_BONUS_LEVELS then memory.writebyte(0x800D218, 0x9) end

	-- If there is a random.dat file, load the data from it
	local saveFile = io.open("random.dat","r")
	if saveFile ~= nil then
		local m = json.decode(saveFile:read())
		writeSaveData(m)
		saveFile:close()
	-- Otherwise randomize the makeup if that setting is enabled
	elseif RANDOMIZE_MAKEUP then 
		copySaveData()
		setRandomMakeup() 
	end


	------------------------------
	---- Check if JSON exists ----
	------------------------------
	local randomizedJSON = io.open("random.json","r")

	-- If it doesn't, make it
	if randomizedJSON == nil then
		initialize.init() -- Start from scratch and make one
		chooseUnlockedLevel() -- Choose the starting level
	-- Otherwise, use it
	else
		randomizedLevels = json.decode(randomizedJSON:read())
		randomizedJSON:close()
		-- for i=1, #randomizedLevels do
		-- 	if randomizedLevels[i]["accessible"] == true then
		-- 		-- unlockLevel(randomizedLevels[i]["index"])
		-- 		unlockLevel(i)
		-- 	end
		-- end
	end
end

-----------------------------------
------- MAIN LOOP -----------------
-----------------------------------

function main()
	-- Whether we've done the initial setup
	initialized = false

	-- What level you're on on the map/in game
	if INCLUDE_TRAINING_LEVELS then 
		mapIndex = 1 
		firstLevel = 1
	else 
		mapIndex = 6 
		firstLevel = 6
	end

	-- World and level
	world = 0
	level = 0

	-- Frame timer
	frameTimer = -1

	while true do
		-- Code here will run once when the script is loaded, then after each emulated frame.

		-- Upon Reset
		if joypad.getimmediate()["Power"] == true then
			copySaveData()
			deleteSavedData()
			main()
		end

		-- Game State
		gameStateA = memory.readbyte(0x3000dca)
		gameStateB = memory.readbyte(0x3000dcb)

		-- Second "PRESS START" screen
		if gameStateA == 1 and gameStateB == 4 then
			-- Initialize values
			-- Loading from json or first-time init is decided in this function
			if not initialized then 
				setupFile()
				initialized = true
			end
		end

		-- SAVE SELECT STATE
		if gameStateA == 2 and gameStateB == 1 then
			memory.writebyte(0x3007ea5,5)
			joypad.set({Up = 0, Down = 0})
		end

		-- SELECT A MODE STATE
		if gameStateA == 3 and gameStateB == 0 then
			
		end

		-- MAP STATE (From level)
		-- If the player is one the map (Also if the player is on the results screen)
		if gameStateA == 3 and (gameStateB == 2 or gameStateB == 4) then
			-- Make sure the player can access all levels
			setHighestAccessibleLevel()

			-- Skips post=level cutscenes
			if memory.read_u32_le(0x3007EE0) == 0x80083B9 then
				memory.writebyte(0x3007EE1, 0x82)
			end

			-- Addresses related to world/level
			world = memory.readbyte(0x3004420)
			level = memory.readbyte(0x3004421)

			-- Setting our levelIndex based on that
			if world == 0 then
				levelIndex = level
			else
				levelIndex = 2 + world*3 + level
			end
			
			-- Have you just completed this level? (It will only ever be 0x3 immediately upon clearing it)
			if memory.readbyte(LEVEL_ACCESS_ADD+levelIndex) == 0x3 then
				memory.writebyte(LEVEL_ACCESS_ADD+levelIndex,4) -- Set the level to a star on the map
				chooseUnlockedLevel()

				-- Set a timer for 5 frames
				frameTimer = emu.framecount()+5
			end

			-- After that 5 frames, write save data to random.dat
			-- This is stupid and I hate it, but it solves a minor problem with save data
			if frameTimer == emu.framecount() then
				copySaveData()
			end

			-- Player moves left/right
			pressedLeft = memory.readbyte(0x3000dee) == 0x20
			holdingLeft = memory.readbyte(0x3000dec) == 0x20 and memory.readbyte(0x3000df4) == 1

			pressedRight = memory.readbyte(0x3000dee) == 0x10
			holdingRight = memory.readbyte(0x3000dec) == 0x10 and memory.readbyte(0x3000df4) == 1

			if (pressedLeft or holdingLeft) and mapIndex > firstLevel then
				mapIndex = mapIndex -1
			elseif (pressedRight or holdingRight) and mapIndex <= memory.readbyte(0x3007e8e) then
				mapIndex = mapIndex +1
			end

			-- Can you access the level you're standing on?
			boolLevelAccessible = randomizedLevels[mapIndex]["accessible"]

			memory.writebyte(0x3007e90, mapIndex-1)

			-- If you're at the first possible level, disable the left button
			if mapIndex == firstLevel then 
				-- Also disable A button if you're on an inaccessible level
				if boolLevelAccessible == false then
					joypad.set({Left = 0, A = 0}) 
				else
					joypad.set({Left = 0}) 
				end
			end
		end

		-- Debugging
		if joypad.getimmediate()["L"] == true then
			gui.text(0,0,"Map index: ".. mapIndex .. "  Accessible? " .. tostring(boolLevelAccessible))
		end

		emu.frameadvance()
	end
end

-----------------------------------
------- SCRIPT LOAD ---------------
-----------------------------------

-- Everything before the main loop runs when the script is loaded

deleteSavedData() -- Clear saved data
main() -- Run the main loop