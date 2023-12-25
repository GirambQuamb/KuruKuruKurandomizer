-----------------------------------
------- CONSTANTS -----------------
-----------------------------------

VERSIONNUMBER = "Version 0.1"

-----------------------------------
------- ADDRESSES -----------------
-----------------------------------

FILENAME_ADD = 0x203BDAE -- Start of GUEST file name
LEVEL_ACCESS_ADD = 0x203BF40 -- Start of level accessibility (goes until + 0x25)

-----------------------------------
------- CHARACTER TABLE -----------
-----------------------------------

CHARACTERTABLE = require("charactertable")

-----------------------------------
------- LEVEL VARIABLES -----------
-----------------------------------

-- List of levels to unlock
lockedLevels = {}
for i=0, 37 do 			-- Just fills a list with 0 to 37. Change 37 to 34 if you don't want the secret levels included                    
	lockedLevels[i] = i+1	-- Ideally this will be changed to use json... allows for a dedicated script to determine level unlock order
end						-- Might make things more balanced...

-- Levels unlocked when the script starts... literally none lol
-- You will want to redo this to use an external file... probably json. Love me some json...
unlockedLevels = {}

-- What level you're on on the map/in game
mapIndex = 1
world = 0
level = 0


-----------------------------------
------- SAVE FILE EDITING ---------
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

	for i=0, #VERSIONNUMBER do
		local s = VERSIONNUMBER:sub(i+1,i+1)
		memory.writebyte(0x0801E8C0+i, CHARACTERTABLE[s])
	end
end

-- File name --

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
		print("Filename too long!")
	end
end

-- Level Accessibility --
-- 1 = Inaccessible, 2 = Accessible, 4 = Completed --
-- Right now it just sets level 0 as the only accessible level --

function initLevelAccess(startingLevel)
	for i=0, 37 do
		if i == startingLevel then
			memory.writebyte(LEVEL_ACCESS_ADD+i, 2)
			unlockedLevels[i+1] = true
		else
			memory.writebyte(LEVEL_ACCESS_ADD+i, 1)
		end
	end
end

function setRandomMakeup()
	-- Unlock all makeup (fun!)
	-- for i=0, 4 do
	-- 	memory.writebyte(0x203bdc0+i,0xff)
	-- end

	-- Set random makeup (Does not set birds, at BDC6 and BDC7)
	memory.writebyte(0x203bdc4, math.random(0x0,0xe)) -- Stick shape
	memory.writebyte(0x203bdc5, math.random(0x0,0x6)) -- Paint
end

-----------------------------------
------- RAM EDITING ---------------
-----------------------------------

-- Sets boundary for player moving right on the map
-- IE: The highest accessible level

function setHighestAccessibleLevel(highestLv)
	memory.writebyte(0x3007e8e,highestLv)
end


-----------------------------------
------- LEVEL RELATED -------------
-----------------------------------

-- Unlocks a level

function unlockLevel()
	if #lockedLevels > 0 then
		local randomIndex = math.random(1,#lockedLevels) -- Choose random index from list of locked levels
		local unlockedLevel = table.remove(lockedLevels,randomIndex)

		unlockedLevels[unlockedLevel] = true -- Insert it into the unlocked levels list

		memory.writebyte(LEVEL_ACCESS_ADD+unlockedLevel-1,2) 
	else
		print("You win!") -- Will have to do something more fun...
	end
end

-----------------------------------
----- INITILIZATION FUNCTIONS -----
-----------------------------------

function firstTimeInit()
	showTitleText() -- Use unused filenames to show text
	setFileName("MARIO") -- Set the file name (TODO: Give the user a chance to set this lol)
	initLevelAccess(0) -- Set all levels to inaccessible, except the input level...
	setRandomMakeup() -- Sets random makeup

	firstLaunch = false
end

-----------------------------------
------- MAIN LOOP -----------------
-----------------------------------

function main()
	while true do
		-- Code here will run once when the script is loaded, then after each emulated frame.

		-- Upon Reset
		if joypad.getimmediate()["Power"] == true then
			print("Reset!")
			-- Could have a function here that does stuff like setup initial save stuff, etc!
		end


		-- Game State
		gameStateA = memory.readbyte(0x3000dca)
		gameStateB = memory.readbyte(0x3000dcb)

		if gameStateA == 1 and gameStateB == 4 and firstLaunch then
			firstTimeInit()
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
			-- Make sure the player can access all levels (Should be 34 when bonus levels are hidden)
			setHighestAccessibleLevel(37)

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
				memory.writebyte(LEVEL_ACCESS_ADD+levelIndex,4)
				unlockLevel()
			end

			-- Player moves left/right
			pressedLeft = memory.readbyte(0x3000dee) == 0x20
			holdingLeft = memory.readbyte(0x3000dec) == 0x20 and memory.readbyte(0x3000df4) == 1

			pressedRight = memory.readbyte(0x3000dee) == 0x10
			holdingRight = memory.readbyte(0x3000dec) == 0x10 and memory.readbyte(0x3000df4) == 1

			if (pressedLeft or holdingLeft) and mapIndex > 1 then
				mapIndex = mapIndex -1
			elseif (pressedRight or holdingRight) and mapIndex < 38 then
				mapIndex = mapIndex +1
			end

			-- Can you access the level you're standing on?
			boolLevelAccessible = unlockedLevels[mapIndex] ~= nil
			
			-- If not, you can't enter
			if boolLevelAccessible == false then
				joypad.set({A = 0})
			end

			memory.writebyte(0x3007e90, mapIndex-1)
		end

		-- Debugging
		if joypad.getimmediate()["L"] == true then
			gui.text(0,0,"Map index: ".. mapIndex .. "  Accessible? " .. tostring(boolLevelAccessible))
		end

		emu.frameadvance();
	end
end

-----------------------------------
------- SCRIPT LOAD ---------------
-----------------------------------

-- Everything before the main loop runs when the script is loaded
-- Would be smart to make certain things load upon starting a fresh file, restarting the gba emulator, etc.

-- This code clears all save data... might be useful if corruption is an issue
-- For now it's commented

-- joypad.set({Power = 1}) -- Reset the console
-- for i=0, 5 do
-- 	emu.frameadvance();
-- 	joypad.set({A=1, B=1, Select=1, Start=1})
-- end
-- emu.frameadvance();
-- joypad.set({Up=1})
-- emu.frameadvance();
-- joypad.set({A=1})
-- emu.frameadvance();

joypad.set({Power = 1}) -- Reset the console
for i=0, 5 do
	emu.frameadvance();
end

-- Is this the first time you're launching?
firstLaunch = true -- Just setting to true for now, this will be based on an external file later

-----------------------------------
------- MAIN FUNCTION -------------
-----------------------------------

main() -- Run the main loop