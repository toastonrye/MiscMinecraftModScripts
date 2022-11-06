-- -------------------------------------------------------------------------------------------------------------------
local filePath = "basalt.lua"
if not(fs.exists(filePath))then
    shell.run("wget run https://basalt.madefor.cc/install.lua packed basalt.lua master")
end
-- -------------------------------------------------------------------------------------------------------------------
local basalt = require("basalt")

local me = peripheral.find("meBridge")
if not me then error("meBridge not found") end

local ae2RawData = {} -- meBridge peripheral, isItemCraftable table variable. Bug: Only returns if item amount >=1 ?
local ae2ParsedData = {}

local w, h = term.getSize()
local mainF = basalt.createFrame():show():setBackground(colours.purple)
local pollF = mainF.addFrame():setSize(w-2,h):setPosition(2,5):setBackground(colours.yellow)
local pollingProgress = mainF:addProgressbar():setPosition(1,4):setBackground(colours.white):setProgress(10)
-- -------------------------------------------------------------------------------------------------------------------
local function fancyButton(self, event, button, x, y)
    self:onClick(function()
        self:setBackground(colours.black)
        self:setForeground(colours.lightGrey)
    end)
    self:onClickUp(function()
        self:setBackground(colours.grey)
        self:setForeground(colours.black)
    end)
    self:onLoseFocus(function()
        self:setBackground(colours.grey)
        self:setForeground(colours.black)
    end)
end
-- -------------------------------------------------------------------------------------------------------------------
local function scanCraftableItems(setpoints)
	local parsed = {}
	
	redstone.setOutput("back", true)
	os.sleep(1)
	
	local raw = me.listCraftableItems()
	local spFound
	
	for k, v in pairs(raw) do
		if setpoints ~= nil then
			for k2, v2 in pairs(setpoints) do
				if v.name == v2.name then
					spFound = v2.setpoint
					basalt.debug("here")
				end
			end
		end
		table.insert(parsed, {name = v.name, amount = v.amount, setpoint = spFound or 1})
	end
	
	redstone.setOutput("back", false)
	
	basalt.debug("Redstone Off")
	basalt.debug(parsed)
	
	return parsed
end

local function saveMe(p)
	for k, v in pairs(p) do
		--p[k].setpoint = 32
	end
	

	local f = fs.open("meBridge.txt", "w")
	f.write(textutils.serialize(p))
	f.close()
	basalt.debug("Saved!")
end

-- appendME() should be the main saving function??                        -- NEW PLAN program will read whats visible and add setpoints.
local function appendMe(p)
	local f = fs.open("meBridge.txt", "r")
	local d = f.readAll()
	f.close()
	local load = textutils.unserialize(d)
	
	local m = false
	if load == nil then -- if meBridge empty/non-existent, set it to recent polling data
		load = p
	else -- if file not empty, try to append missing keys
		for k, v in pairs(p) do
			for k2, v2 in pairs(load) do
				if v.name == v2.name and not m then
					--basalt.debug(v.name .. " = " .. load[k].name)
					m = true
				end
				if not m then
					table.insert(load, v) -- THE PROBLEM??
					basalt.debug("Adding " .. v.name .. " | " .. v.amount .. " | " .. v.setpoint)
				end
				m = false
			end
		end
	end
	
	local f = fs.open("meBridge.txt", "w") -- do not append, values inserted into "load"
	f.write(textutils.serialize(load))
	--f.write(load)
	f.close()
	basalt.debug("Appended!")
end

local function loadSetpoints()
	local f = fs.open("meBridge.txt", "r")
	if f ~= nil then -- if meBridge.txt exists, load it
		local data = f.readAll()
		f.close()
		local p = textutils.unserialize(data)
		return p
	end
end

local function init()
	local setpoints = loadSetpoints()
	local parsed = scanCraftableItems(setpoints)
	
	local f = fs.open("meBridge.txt", "w")
	f.write(textutils.serialize(parsed))
	f.close()
	basalt.debug("Saved!")
	
	--[[local f = fs.open("meBridge.txt", "r")
	if f ~= nil then -- if meBridge.txt exists, load it
		local d = f.readAll()
		f.close()
		local p = textutils.unserialize(d)
	else -- if meBridge.txt does not exist, make empty file
		local f = fs.open("meBridge.txt", "w")
		f.write()
		f.close()
	end
	
	if p == nil then
		basalt.debug("p read from polling")
		p = scanCraftableItems()
	else
		basalt.debug("p loaded from file")
	end
	return p
	--]]
end


local buttonRescan = mainF:addButton():onClick(basalt.schedule(function() ae2RawData = scanCraftableItems() end)):setSize(10,3):setPosition(1,1):setValue("Rescan")
fancyButton(buttonRescan)

local buttonAppend = mainF:addButton():onClick(function() appendMe(ae2RawData) end):setSize(10,3):setPosition(36,1):setValue("Append")
fancyButton(buttonAppend)

--local buttonSave = mainF:addButton():onClick(function() saveMe(ae2RawData) end):setSize(10,3):setPosition(12,1):setValue("Save")
--fancyButton(buttonSave)

local function myMain()
	while true do
		os.sleep(1)
	end
end

ae2RawData = init() -- try to read meBridge.txt if it exists, if not call scanCraftableItems() function
-- -------------------------------------------------------------------------------------------------------------------
--basalt.debug("Hi")
parallel.waitForAll(basalt.autoUpdate, myMain)
