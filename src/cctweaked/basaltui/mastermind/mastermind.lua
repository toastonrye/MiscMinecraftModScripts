--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by toastonrye.
--- DateTime: 8/10/2022 6:13 AM

--[[
===============================================================================================================================================
== mastermind clone ===========================================================================================================================
== project to learn lua and the Basalt UI =====================================================================================================
===============================================================================================================================================
== to do
    1. clean up code, globals, functions (parameter names)
    2. difficulty mode easy, to  stop duplicate colours in the secret code from generating
    3. add more Basalt UI stuff, to demonstrate features
    4. add player wins, gameover logic
    5. new game button should clear gameboard, right now it only generates a new secret code
    6. need to add game instructions, basalt ui tabs???
    7. colour keyboard needs to scroll with main scrollbar
]]--

-- https://basalt.madefor.cc/#/home/installer?id=basic-installer
local filePath = "basalt.lua"
if not(fs.exists(filePath))then
    shell.run("pastebin run ESs1mg7P packed true "..filePath:gsub(".lua", ""))
end
local basalt = require(filePath:gsub(".lua", ""))
-- [PIN COLOUR DATA]-----------------------------------------------------------------------------------------------------------------------

pinsStr = {
    "colours.green",
    "colours.cyan",
    "colours.orange",
    "colors.purple",
    "colours.yellow",
    "colours.pink",
    "colours.red",
    "colours.blue"
}
pins = {
    colours.green,
    colours.cyan,
    colours.orange,
    colors.purple,
    colours.yellow,
    colours.pink,
    colours.red,
    colours.blue
}

-- [GLOBAL VAR]------------------------------------------------------------------------------ Some of these probably shouldn't be global...
_VERSION = 0.2
_USERGUESS = {}     -- user's guess, submitted or cleared by ENTER/X buttons
_SECRETCODE = {}    -- randomly generated 4 peg table
_ROWPOSITION = 1    -- tracks number of guesses, rows
_PEGPOSITION = 1    -- tracks peg position of _USERGUESS (1 through 4)
rScoreFrame, wScoreFrame = {}, {}

-- [FUNCTION fancyButton]------------------------------------------------------------------------------------------------------------------
local function fancyButton(button, override) -- with lua's concept of overloading methods?
    button:onClick(function(self)
        button:setBackground(colours.black)
        button:setForeground(colours.lightGrey)
    end)
    button:onClickUp(function(self)
        button:setBackground(override or colours.grey)
        button:setForeground(colours.black)
    end)
    button:onLoseFocus(function(self)
        button:setBackground(override or colours.grey)
        button:setForeground(colours.black)
    end)
end

-- [FUNCTION generateSecretCode]-----------------------------------------------------------------------------------------------------------
-- basalt question: what would be better to store the colour peg data?
-- the secret code data is stored in panes here, but later the user guesses is stored in 1x1 frames
local function generateSecretCode(secretPane) -- more functions should look like this, less globals?
    local r = {}
    for i=1, 4 do
        table.insert(r, math.random(1,8))
    end
    local randomPegs = {}
    local rOffset = 2
    for k, v in ipairs(r) do
        randomPegs[k] = secretPane:addPane()
                                  :setSize(1,1)
                                  :setValue(pinsStr[v])
                                  :setPosition(rOffset,2)
                                  :setBackground(pins[v])
        rOffset = rOffset + 2
    end
    return randomPegs
end

-- [FUNCTION initGame]---------------------------------------------------------------------------------------------------------------------
-- need to rework so NEW GAME button clears and re-initializes the gameboard
-- this generates frames to be used on the gameboard for storing peg data
local function initGame(rowFrame, maxRows, userFrame) -- pegBoardFrame, 16, userGuessFrame
    local rowTable = {}
    local cellTable = {}
    for i=1, maxRows do
        cellTable[i] = {}
        rowTable[i] = rowFrame:addFrame():setSize(7,2):setPosition(4,0+(i*2))
        for j=1, 4 do  -- generates a grid of 1x1 white frames to be used as peg holes
            cellTable[i][j] = rowFrame:addFrame():setSize(1,1):setPosition(2+(j*2),1+(i*2)):setBackground(colours.white)
        end
        if i%2 == 0 then
            rowTable[i]:setBackground(colours.grey)
        else
            rowTable[i]:setBackground(colours.lightGrey)
        end
    end
    for i=1, 4 do -- Makes 4 white peg holes on the black user input current guess frame
        _USERGUESS[i] = userFrame:addPane()
                                 :setBackground(colours.white)
                                 :setPosition(0+(i*2),2)
                                 :setValue("colours.white")
    end
    for i=1, maxRows do
        rScoreFrame[i] = rowFrame:addFrame():setSize(1,1):setPosition(2,1+(i*2)):setBackground(colours.lightGrey)
        wScoreFrame[i] = rowFrame:addFrame():setSize(1,1):setPosition(12,1+(i*2)):setBackground(colours.lightGrey)
    end
    return rowTable, cellTable
end

-- [FUNCTION sendUserGuess]----------------------------------------------------------------------------------------------------------------
--
local function sendUserGuess(cellTable) -- pegRowFrames
    local scoreTable = {}
    local rCount = 0
    local wCount = 0
    local matches = {}
    for k,v in pairs(_USERGUESS) do -- logic to score the red pegs first, red is an exact match of colour and position
        cellTable[_ROWPOSITION][k]:setBackground(_USERGUESS[k]:getBackground()):setSize(1,1):setPosition(2+(k*2),1+(_ROWPOSITION*2)):setValue(_USERGUESS[k]:getValue())
        if cellTable[_ROWPOSITION][k]:getValue() == _SECRETCODE[k]:getValue() then
            rCount = rCount + 1
            matches[k] = true
        end
    end
    for k,v in pairs(_USERGUESS) do  -- logic to score white, colour match but wrong position.
        for k2,v2 in pairs(_SECRETCODE) do
            if cellTable[_ROWPOSITION][k]:getValue() == _SECRETCODE[k2]:getValue() and matches[k2] ~= true then
                wCount = wCount + 1
                matches[k2] = true
            end
        end
    end
    rScoreFrame[_ROWPOSITION]:addLabel(rCount):setValue(rCount):setBackground(colours.red):setForeground(colours.white)
    wScoreFrame[_ROWPOSITION]:addLabel(wCount):setValue(wCount):setBackground(colours.white):setForeground(colours.black)

    if rCount == 4 then
        basalt.debug("Player WINS!")
    end

    _ROWPOSITION = _ROWPOSITION + 1
    return scoreTable
end

-- [FUNCTION clearUserGuess]----------------------------------------------------------------------------------------------------------------
-- probably should pass variables to function, remove globals
local function clearUserGuess() -- userGuessFrame
    _PEGPOSITION = 1
    for i=1, #_USERGUESS do
        _USERGUESS[i]:setBackground(colours.white)
        _USERGUESS[i]:setValue("")
    end

end

-- [FUNCTION clearPegBoard]----------------------------------------------------------------------------------------------------------------
-- does nothing?
local function clearPegBoard(rowFrames) -- pegRowFrames
    local clearRows = {}
    for i=1, #rowFrames do
        rowFrames[i]:setValue("colours.white"):setBackground(colours.white):setSize(1,1)
    end

end

-- [FRAMES] ===============================================================================================================================
local mainFrame = basalt.createFrame("mainFrame")
                        :show()
                        :setBackground(colours.blue)

local w, h = term.getSize()
local gameFrame = mainFrame.addFrame()
                           :setBackground(colours.lightBlue)
                           :setSize(w-3,h)
                           :setPosition(2,1)

local secretCodeFrame = gameFrame:addFrame()
                                 :setSize(9,3)
                                 :setPosition(16,3)
                                 :setBackground(colours.brown)
                                 :hide()

local userControlsFrame = gameFrame:addFrame()
                                   :setSize(26,9)
                                   :setPosition(3,6)
                                   :setMoveable(true)
                                   :hide()

local userGuessFrame = userControlsFrame:addFrame()
                                        :setSize(9,3)
                                        :setPosition(10,2)
                                        :setBackground(colours.black)

local pegBoardFrame = gameFrame:addFrame("pegBoardFrame")
                               :setSize(13,34)
                               :setPosition(34,2)
                               :setBackground(colours.black)

local pegRowFrames, cellTableFrames = initGame(pegBoardFrame, 16, userGuessFrame) -- guess attempts, hardcoded value of max rows. Difficulty setting?

-- [SCROLLBAR]----------------------------[     ]-----------[     ]-----------[     ]-----------[     ]-----------[     ]------------------
local scrollbar = mainFrame:addScrollbar()
                           :setPosition(w-1,3)
                           :setSize(1,h-3)
                           :setMaxValue(30)
                           :onChange(function(self)
    local y = self:getValue()
    gameFrame:setOffset(0,y-2)
end)

-- [BUTTON NEW GAME]----------------------[     ]-----------[     ]-----------[     ]-----------[     ]-----------[     ]------------------
fancyButton(gameFrame:addButton("getCode")
                     :setPosition(3,3)
                     :setValue("NEW GAME")
                     :onClick(function()
    _SECRETCODE = generateSecretCode(secretCodeFrame)
    clearUserGuess()
    --clearPegBoard(pegRowFrames) -- Can't figure out technique to clear gameboard
    userControlsFrame:show()
end)) -- not overloading this fancyButton function with a colour value, default

-- [BUTTON ENTER]-------------------------[     ]-----------[     ]-----------[     ]-----------[     ]-----------[     ]------------------
fancyButton(userControlsFrame:addButton()
                             :setPosition(2,2)
                             :setSize(7,3)
                             :setValue("ENTER")
                             :setBackground(colours.green)
                             :onClick(function()
    sendUserGuess(cellTableFrames)
    clearUserGuess()
end), colours.green)

-- [BUTTON X]-----------------------------[     ]-----------[     ]-----------[     ]-----------[     ]-----------[     ]------------------
fancyButton(userControlsFrame:addButton()
                             :setPosition(20,2)
                             :setSize(3,3)
                             :setValue("X")
                             :setBackground(colours.red)
                             :onClick(function()
    clearUserGuess()
end), colours.red)

-- [KEYBOARD OF COLOUR]
-- userColourInput is an array of colour buttons, a colour keyboard
-- this should scroll with the scrollbar
local userColourInput = {}
for i=1, #pins do
    userColourInput[i] = fancyButton(userControlsFrame:addButton()
                                                      :setPosition(-1+(i*3),6)
                                                      :setValue(i)
                                                      :setSize(3,3)
                                                      :setBackground(pins[i])
                                                      :onClick(function(self)
        if _PEGPOSITION > 4 then
            _PEGPOSITION = 1
        end
        _USERGUESS[_PEGPOSITION]:setBackground(pins[i]):setValue(pinsStr[i])
        _PEGPOSITION = _PEGPOSITION + 1
    end) , pins[i]) -- overloading fancyButton, restores appropriate button colour
end

-- other stuff, needs to be cleaned up
local versionLabel = gameFrame:addLabel()
                              :setText("v".._VERSION.." QUIT")
                              :setPosition(2,16)
                              :setBackground(colours.red)

versionLabel:onClick(function()
    basalt.autoUpdate(false)
    term.clear()
end)

local testLabel = gameFrame:addLabel()
                           :setText("CHEAT")
                           :setPosition(12,16)
                           :setBackground(colours.red)

testLabel:onClick(function()
    secretCodeFrame:show()
end)
testLabel:onLoseFocus(function()
    secretCodeFrame:hide()
end)

userControlsFrame:onLoseFocus(function(self)
    userControlsFrame:show()
end)

basalt.autoUpdate()
