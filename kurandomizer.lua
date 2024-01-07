-----------------------------------
------- CONSTANTS -----------------
-----------------------------------

VERSION = "Version 1.0"

-----------------------------------
------- ADDRESSES -----------------
-----------------------------------

-- Probably could've had more here...
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
gameStateB = 0 -- Not sure, but I'm scared to delete them now

-----------------------------------
------- SAVE FILE RELATED ---------
-----------------------------------

-- Show some text using the file select screen
function showTitleText()
	local topTitle = "Kuru Kuru"
	local middleTitle = "Kururin"
	local bottomTitle = "Randomizer"

	-- Loop through relevant strings and place them character by character
	-- There's probably a better way to do this but whatever
	--memory.writebyte(0x203BFA2, 0x20)
	for i=0, #topTitle do
		local s = topTitle:sub(i+1,i+1)
		memory.writebyte(0x203BFA2+i, CHARACTERTABLE[s]) -- File 1 name
	end

	for i=0, #middleTitle do
		local s = middleTitle:sub(i+1,i+1)
		memory.writebyte(0x0203C196+i, CHARACTERTABLE[s]) -- File 2 name
	end

	for i=0, #bottomTitle do
		local s = bottomTitle:sub(i+1,i+1)
		memory.writebyte(0x0203C38A+i, CHARACTERTABLE[s]) -- File 3 name
	end

	memory.writebyte(0x0203C57E, 0x20) --  File 4 name

	for i=0, #VERSION do
		local s = VERSION:sub(i+1,i+1)
		memory.writebyte(0x0801E8C0+i, CHARACTERTABLE[s]) -- "Delete Saved Data" text
	end
end

-- Sets filename
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

-- Set random makeup (Does not set birds, at BDC6 and BDC7)
function setRandomMakeup()
	local stick = math.random(0x0,0xe)
	local paint = math.random(0x0,0x6)
	memory.writebyte(0x203bdc4, stick) -- Stick shape
	memory.writebyte(0x203bdc5, paint) -- Paint
end

-- Save which bonuses are unlocked, which makeup is worn, and which levels have the "I missed something" text
-- Level completion times, level accessibility/completion, and probably more
function copySaveData(addr)
	-- Only copy to a file if you're past the title screen, or have called this function manually
	if memory.readbyte(0x3000dca) > 1 or addr == nil then
		-- Relevant save data array
		local mem = memory.read_bytes_as_array(0x203BDC0, 0x200)

		local sav = io.open("random.dat", "w")
		sav:write(json.encode(mem))
		sav:close()
	end
end

-- Writes from random.dat to the game's RAM
function writeSaveData(data)
	memory.write_bytes_as_array(0x203BDC0, data)
end

-- Whenever this section of RAM is written to, we'll run the copy function
for i = 0x203BDA0, 0x203BFA0 do
	event.on_bus_write(copySaveData, i)
end

-----------------------------------
------- LEVEL RELATED -------------
-----------------------------------

-- Unlocks a given level
function unlockLevel(level)
	-- Set the level as accessible
	randomizedLevels[level]["accessible"] = true
	memory.writebyte(LEVEL_ACCESS_ADD+level-1,2)
	
	-- Update random.json
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
	else -- or throw a warning and default to "close"
		print("Error with \"LEVEL_ORDER\" setting.\nDefaulting to \"close\"!")
		numPossibleLevels = 6
		return
	end

	-- Base valid level choices on settings
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
	-- Determined solely by whether bonus levels are included
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

-- Change the bonus for each level
function setLevelBonus()
	local bonusID = randomizedLevels[mapIndex]["bonusID"]
	local IDString

	-- If this level has a bonus in it
	if bonusID then
		-- Add a leading zero to single-digit IDs
		if bonusID < 10 then
			IDString = "0"..tostring(bonusID)
		else
			IDString = tostring(bonusID)
		end

		-- Grab each digit and add 224 to it (0xE?)
		memory.writebyte(0x2000000+0x4, 224 + tonumber(string.sub(IDString,1,1)))
		memory.writebyte(0x2000000+0x6, 224 + tonumber(string.sub(IDString,2,2)))
	end
end

-----------------------------------
---- INITILIZATION FUNCTIONS ------
-----------------------------------

-- This function resets the game while holding the button combo to delete saved data
-- It automatically deletes all saved data, which is no problem if you have the json and dat files
-- Also gives me an excuse to make a custom title screen :D
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

-- Setup level access, json/dat files, etc.
function setupFile()
	showTitleText() -- Use unused filenames to show text
	setFileName(FILE_NAME) -- Set the file name

	-- Set all levels to inaccessible in-game
	initLevelAccess()

	-- Hide bonus levels if they are excluded
	if not INCLUDE_BONUS_LEVELS then memory.writebyte(0x800D218, 0x9) end

	-- Check if dat file exists
	local saveFile = io.open("random.dat","r")

	-- If it does, load data from it
	if saveFile ~= nil then
		local m = json.decode(saveFile:read())
		writeSaveData(m)
		saveFile:close()
	-- If it doesn't, make one
	else
		copySaveData()
		-- And randomize makeup if needed
		if RANDOMIZE_MAKEUP then 
			setRandomMakeup() 
		end
	end

	-- Check if JSON exists 
	local randomizedJSON = io.open("random.json","r")

	-- If it doesn't, make it
	if randomizedJSON == nil then
		initialize.init() -- Start from scratch and make one
		chooseUnlockedLevel() -- Choose the starting level
	-- Otherwise, load data from it
	else
		randomizedLevels = json.decode(randomizedJSON:read())
		randomizedJSON:close()
	end
end

-----------------------------------
------- WINNING -------------------
-----------------------------------

-- This function should return true if the player has won, false otherwise
function checkWin()
	-- All bonuses
	if WIN_CONDITION == "bonuses" then
		return checkBonusWin()

	-- All available levels
	elseif WIN_CONDITION == "levels" then
		return checkLevelsWin()

	-- All available levels and all bonuses
	elseif WIN_CONDITION == "all" then
		return checkBonusWin() and checkLevelsWin()

	--All birds
	else
		return checkBirdWin()
	end

	return false -- We should never get here but I'm known to write bad code
end

-- Check if the player has all makeup/birds
function checkBonusWin()
	-- Read all the collected bonuses as one whole thing
	if memory.read_u32_le(0x203BDC0) == 0xFFFFFFFF then
		return true
	end

	return false
end

-- Check if the player has completed every level they can
function checkLevelsWin()
	local levelStart = 1
	local levelEnd = 38

	if not INCLUDE_BONUS_LEVELS then
		levelEnd = 35
	end

	if not INCLUDE_TRAINING_LEVELS then
		levelStart = 6
	end

	for i = levelStart-1, levelEnd-1 do
		if memory.readbyte(LEVEL_ACCESS_ADD+i) < 4 then
			return false
		end
	end

	return true
end

-- Check if the player has all birds
function checkBirdWin()
	-- Least two bytes of this address are the last two birds
	local lastTwoBirds = bit.check(memory.readbyte(0x203BDC1), 0) and bit.check(memory.readbyte(0x203BDC1), 1)
	
	-- If you have those, and the 8 others, you win!
	if memory.readbyte(0x203BDC0) == 0xFF and lastTwoBirds then
		return true
	end

	return false
end

-- This function should only be called on the results screen of a level
-- Sets various memory addresses to transition to the "Congratulations" screen when the player proceeds
function win()
	aPressed = false -- Has the player pressed A to see the congrats screen?

	-- 8 frames of this to make sure it works
	for i=1, 8 do
		joypad.set({A = 0, Start = 0})
		memory.writebyte(0x3000DCA, 4)
		memory.writebyte(0x3007EE0, 0xB9)
		memory.writebyte(0x3007EE1, 0x84)
		emu.frameadvance()
	end
	while true do
		-- If the player has seen the congrats screen, don't let em continue after the credits
		if aPressed then
			joypad.set({A = 0, Start = 0})
		end
		if joypad.getimmediate()["A"] then
			aPressed = true
		end

		emu.frameadvance()
	end
end

-----------------------------------
------- MAIN LOOP -----------------
-----------------------------------

function main()
	-- Whether we've done the initial setup
	initialized = false

	-- What level you start on
	if INCLUDE_TRAINING_LEVELS then 
		mapIndex = 1 
		firstLevel = 1
	else 
		mapIndex = 6 
		firstLevel = 6 -- This variable sets whether you can go left past level 6 into the training room
	end

	-- World and level
	world = 0
	level = 0

	-- Frame timer, dumb solution for one function
	frameTimer = -1

	-- Loop! Loop! Loop!
	while true do
		-- Upon Reset, ensure there's no "save damaged" screen by restarting the whole thing
		if joypad.getimmediate()["Power"] == true then
			copySaveData()
			deleteSavedData()
			main()
		end

		-- Game state addresses
		gameStateA = memory.readbyte(0x3000dca)
		gameStateB = memory.readbyte(0x3000dcb)

		-- Second "PRESS START" state
		if gameStateA == 1 and gameStateB == 4 then
			-- Initialize randomizer-related things
			if not initialized then 
				setupFile()
				initialized = true
			end
		end

		-- SAVE SELECT STATE
		if gameStateA == 2 and gameStateB == 1 then
			memory.writebyte(0x3007ea5,5)  -- Set the cursor to the correct file
			joypad.set({Up = 0, Down = 0}) -- Keep it there
		end

		-- MAP STATE/RESULTS SCREEN
		if gameStateA == 3 and (gameStateB == 2 or gameStateB == 4) then
			-- Make sure the player can access all levels
			setHighestAccessibleLevel()

			-- Skips post-level cutscenes
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
				-- While you're here, you should win the game if you've completed the randomizer goal
				if checkWin() then win() end
			end

			-- Player moves left/right
			pressedLeft = memory.readbyte(0x3000dee) == 0x20
			holdingLeft = memory.readbyte(0x3000dec) == 0x20 and memory.readbyte(0x3000df4) == 1

			pressedRight = memory.readbyte(0x3000dee) == 0x10
			holdingRight = memory.readbyte(0x3000dec) == 0x10 and memory.readbyte(0x3000df4) == 1

			-- Keep track of the map index...
			-- Starting to think this might be unnessesary, but it's scary to change code this far in LOL
			if (pressedLeft or holdingLeft) and mapIndex > firstLevel then
				mapIndex = mapIndex -1
			elseif (pressedRight or holdingRight) and mapIndex <= memory.readbyte(0x3007e8e) then
				mapIndex = mapIndex +1
			end

			-- Can you access the level you're standing on?
			boolLevelAccessible = randomizedLevels[mapIndex]["accessible"]

			-- Setting the level we're standing on to our map index???
			-- This should maybe be the other way around, since I already have a levelIndex variable
			memory.writebyte(0x3007e90, mapIndex-1)

			-- If you're at the first possible level, disable the left button
			if mapIndex == firstLevel then 
				-- Also disable A button if you're on an inaccessible level
				if boolLevelAccessible == false then
					joypad.set({Left = 0, A = 0}) 
				else
					joypad.set({Left = 0}) 
				end
			elseif boolLevelAccessible == false then
				joypad.set({A = 0}) 
			end
		end

		-- IN-LEVEL STATE
		if gameStateA == 3 and gameStateB == 3 then
			-- Set the bonus :)
			if memory.readbyte(0x2000004) == 0xE9 then -- All levels will default to E
				setLevelBonus()
			end
		end

		-- Debugging
		-- if joypad.getimmediate()["L"] == true then
		-- 	gui.text(0,0,"Map index: ".. mapIndex .. "  Accessible? " .. tostring(boolLevelAccessible))
		-- end

		emu.frameadvance()
	end
end

-----------------------------------
------- SCRIPT LOAD ---------------
-----------------------------------

deleteSavedData() -- Clear saved data
main() -- Run the main loop