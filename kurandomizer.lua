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
------- SAVE FILE EDITING ---------
-----------------------------------

-- 0203BFA2 -> File 1 name
-- 0203C196 -> File 2 name
-- 0203C38A -> File 3 name
-- 0203C57E -> File 4 name

-- Show some text using the unused filenames
-- TODO: Change "Delete saved data" to something
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

function setLevelsInaccessible()
	memory.writebyte(LEVEL_ACCESS_ADD,2)
	for i=1, 37 do
		memory.writebyte(LEVEL_ACCESS_ADD+i, 1)
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
------- RANDOMIZER LOGIC ----------
-----------------------------------

-- List of levels to unlock

lockedLevels = {}
for i=1, 5 do 			-- Just fills a list with 1 to 37. Change 37 to 34 if you don't want the secret levels included                    
	lockedLevels[i] = i+1	-- Ideally this will be changed to use json... allows for a dedicated script to determine level unlock order
end						-- Might make things more balanced...

print(lockedLevels)

-- Levels unlocked when the script starts
-- You will want to redo this to use an external file... probably json. Love me some json...

unlockedLevels = {0}

-- Unlocks a level

function unlockLevel()
	if #lockedLevels > 0 then
		local randomIndex = math.random(1,#lockedLevels) -- Choose random index from list of locked levels
		local unlockedLevel = table.remove(lockedLevels,randomIndex)
		
		unlockedLevels[unlockedLevel] = 0 -- Insert it into the unlocked levels list
		table.sort(unlockedLevels) -- Sort the table too so the map movement isn't weird

		memory.writebyte(LEVEL_ACCESS_ADD+unlockedLevel-1,2) 
	else
		print("You win!") -- Will have to do something more fun...
	end
end

function getLevelIndex()
	if world == 0 then
		return level
	elseif world > 0 then
		return 4 + world*3 + level
	end
end



mapIndex = 1
world = 0
level = 0

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

		setHighestAccessibleLevel(37)

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
			-- Test
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

			gui.text(0,0,"Map index: ".. mapIndex .. "  Accessible? " .. tostring(boolLevelAccessible))
			
			-- If not, you can't enter
			if boolLevelAccessible == false then
				joypad.set({A = 0})
			end

			memory.writebyte(0x3007e90, mapIndex-1)

			-- Debugging
			if joypad.getimmediate()["L"] == true then
				print(unlockedLevels)
			end
		end

		emu.frameadvance();
	end
end

-----------------------------------
------- SCRIPT LOAD ---------------
-----------------------------------

-- Everything before the main loop runs when the script is loaded
-- Would be smart to make certain things load upon starting a fresh file, restarting the gba emulator, etc.

joypad.set({Power = 1}) -- Reset the console
for i=0, 5 do
	emu.frameadvance();
end

showTitleText() -- Use unused filenames to show text
setFileName("MARIO") -- Set the file name (TODO: Give the user a chance to set this lol)
setLevelsInaccessible() -- Set all levels to inaccessible, except the first training level
setRandomMakeup() -- Sets random makeup

-----------------------------------
------- MAIN FUNCTION -------------
-----------------------------------

main() -- Run the main loop