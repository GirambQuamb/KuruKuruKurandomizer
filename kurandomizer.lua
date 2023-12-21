-----------------------------------
------- ADDRESSES -----------------
-----------------------------------

FILENAME_ADD = 0x203BDAE -- Start of GUEST file name
LEVEL_ACCESS_ADD = 0x203BF40 -- Start of level accessibility (goes until + 0x25)

-- Unlock all makeup (fun!)
-- for i=0, 4 do
-- 	memory.writebyte(0x203bdc0+i,0xff)
-- end

-- Set random makeup (more fun!)
memory.writebyte(0x203bdc4, math.random(0x0,0xe)) -- Stick shape
memory.writebyte(0x203bdc5, math.random(0x0,0x6)) -- Paint
-- memory.write_u16_le(0x203bdc6, 0) -- No birbs >:(
-- memory.write_u16_le(0x203bdc6, math.random(0,1024)) -- Birbs

CHARACTERTABLE = {
	[" "] = 0x20,
	["!"] = 0x21,
	["\""] = 0x22,
	["#"] = 0x23,
	["$"] = 0x24,
	["%"] = 0x25,
	["&"] = 0x26,
	["'"] = 0x27,
	["("] = 0x28,
	[")"] = 0x29,
	["+"] = 0x2b,
	[","] = 0x2c,
	["-"] = 0x2d,
	["."] = 0x2e,
	["/"] = 0x2f,
	["0"] = 0x30,
	["1"] = 0x31,
	["2"] = 0x32,
	["3"] = 0x33,
	["4"] = 0x34,
	["5"] = 0x35,
	["6"] = 0x36,
	["7"] = 0x37,
	["8"] = 0x38,
	["9"] = 0x39,
	[":"] = 0x3a,
	[";"] = 0x3b,
	["<"] = 0x3c,
	["="] = 0x3d,
	[">"] = 0x3e,
	["?"] = 0x3f,
	["@"] = 0x40,
	["A"] = 0x41,
	["B"] = 0x42,
	["C"] = 0x43,
	["D"] = 0x44,
	["E"] = 0x45,
	["F"] = 0x46,
	["G"] = 0x47,
	["H"] = 0x48,
	["I"] = 0x49,
	["J"] = 0x4a,
	["K"] = 0x4b,
	["L"] = 0x4c,
	["M"] = 0x4d,
	["N"] = 0x4e,
	["O"] = 0x4f,
	["P"] = 0x50,
	["Q"] = 0x51,
	["R"] = 0x52,
	["S"] = 0x53,
	["T"] = 0x54,
	["U"] = 0x55,
	["V"] = 0x56,
	["W"] = 0x57,
	["X"] = 0x58,
	["Y"] = 0x59,
	["Z"] = 0x5a,
	["["] = 0x5b,
	["¥"] = 0x5c,
	["]"] = 0x5d,
	["^"] = 0x5e,
	["_"] = 0x5f,
	["`"] = 0x60,
	["a"] = 0x61,
	["b"] = 0x62,
	["c"] = 0x63,
	["d"] = 0x64,
	["e"] = 0x65,
	["f"] = 0x66,
	["g"] = 0x67,
	["h"] = 0x68,
	["i"] = 0x69,
	["j"] = 0x6a,
	["k"] = 0x6b,
	["l"] = 0x6c,
	["m"] = 0x6d,
	["n"] = 0x6e,
	["o"] = 0x6f,
	["p"] = 0x70,
	["q"] = 0x71,
	["r"] = 0x72,
	["s"] = 0x73,
	["t"] = 0x74,
	["u"] = 0x75,
	["v"] = 0x76,
	["w"] = 0x77,
	["x"] = 0x78,
	["y"] = 0x79,
	["z"] = 0x7a,
	["{"] = 0x7b,
	["|"] = 0x7c,
	["}"] = 0x7d,
	["~"] = 0x7e,
	["•"] = 0x7f
}

-----------------------------------
------- SAVE FILE EDITING ---------
-----------------------------------

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

-----------------------------------
------- RAM EDITING ---------------
-----------------------------------

-- Sets boundary for player moving right on the map
-- IE: The highest accessible level

function setHighestAccessibleLevel()
	highestAccessibleLevel = memory.readbyte(0x3007e8e)
	-- HIGHEST COMPLETABLE LEVEL
	-- If levels have a completion of "1" they are inaccessible
	-- Highest accessible level is the highest level index with no "1"
	for i=0, 37 do
		if memory.readbyte(LEVEL_ACCESS_ADD+i) > 1 then
			highestAccessibleLevel = i
		end
	end
	memory.writebyte(0x3007e8e,highestAccessibleLevel)
end


-----------------------------------
------- RANDOMIZER LOGIC ----------
-----------------------------------

-- List of levels to unlock

lockedLevels = {}
for i=1, 37 do 			-- Just fills a list with 1 to 37. Change 37 to 34 if you don't want the secret levels included                    
	lockedLevels[i] = i	-- Ideally this will be changed to use json... allows for a dedicated script to determine level unlock order
end						-- Might make things more balanced...

-- Levels unlocked when the script starts
-- You will want to redo this to use an external file... probably json. Love me some json...

unlockedLevels = {0}

-- Unlocks a level

function unlockLevel()
	if #lockedLevels > 0 then
		local randomIndex = math.random(1,#lockedLevels) -- Choose random index from list of locked levels
		local unlockedLevel = table.remove(lockedLevels,randomIndex) -- Remove that random level

		table.insert(unlockedLevels, unlockedLevel) -- Insert it into the unlocked levels list
		table.sort(unlockedLevels) -- Sort the table too so the map movement isn't weird

		-- set the map index to the level you were just on
		for i=1, #unlockedLevels do
			if mapLevel == unlockedLevels[i] then
				mapIndex = i
				break
			end
		end
		-- Make the level accessible in-game
		memory.writebyte(LEVEL_ACCESS_ADD+unlockedLevel,2) 
	else
		print("You win!")
		gui.text(0,0,"You Win!")
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
mapLevel = 0
world = 0
level = 0

-----------------------------------
------- MAIN LOOP -----------------
-----------------------------------

function main()
	while true do
		-- Code here will run once when the script is loaded, then after each emulated frame.

		-- Game State
		gameStateA = memory.readbyte(0x3000dca)
		gameStateB = memory.readbyte(0x3000dcb)

		setHighestAccessibleLevel()

		-- SAVE SELECT STATE
		if gameStateA == 2 and gameStateB == 1 then
			memory.writebyte(0x3007ea5,5)
			joypad.set({Up = 0, Down = 0})
		end

		-- SELECT A MODE STATE
		if gameStateA == 3 and gameStateB == 0 then
			
		end

		-- MAP STATE (From level)
		-- If the player is one the map
		if gameStateA == 3 and (gameStateB == 2 or gameStateB == 4) then
			-- Map
			world = memory.readbyte(0x3004420)
			level = memory.readbyte(0x3004421)

			-- Set level index based on smarter shit
			if world == 0 then
				levelIndex = level
			else
				levelIndex = 2 + world*3 + level
			end
			
			-- Have you just completed this level?
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
				mapLevel = unlockedLevels[mapIndex]
			elseif (pressedRight or holdingRight) and mapIndex < #unlockedLevels then
				mapIndex = mapIndex +1
				mapLevel = unlockedLevels[mapIndex]
			end
			-- gui.text(0,0,"Map index: ".. mapIndex .. "  Map Level: " .. unlockedLevels[mapIndex])
			memory.writebyte(0x3007e90, mapLevel)
		end

		emu.frameadvance();
	end
end

-- Set the file name
setFileName("Aidan")

-- Set all levels to inaccessible, except the first training level
setLevelsInaccessible()

-- Run the main loop
main()