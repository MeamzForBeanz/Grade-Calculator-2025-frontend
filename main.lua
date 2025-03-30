_G.lg = love.graphics
_G.lm = love.mouse

local urutora = require("urutora")
local grade_calculator = require("grade_calculator")

local u
require("images")
require("fonts")

local bgColor = { 0.2, 0.1, 0.3 }
for _, bg in ipairs(bgs) do
    bg:setFilter("nearest", "nearest")
end
bgIndex = 1
bgRotation = 0

local function initCanvasStuff()
    w, h = 320, 180 -- Canvas size
    canvas = lg.newCanvas(w, h)
    canvas:setFilter("nearest", "nearest")
    canvasX, canvasY = 0, 0
    sx = lg.getWidth() / canvas:getWidth()
    sy = lg.getHeight() / canvas:getHeight()
end

local function doResizeStuff(w, h)
    sx = math.floor(w / canvas:getWidth())
    sx = sx < 1 and 1 or sx
    sy = sx
    if (canvas:getHeight() * sy) > h then
        sy = math.floor(h / canvas:getHeight())
        sy = sy < 1 and 1 or sy
        sx = sy
    end
    canvasX = w / 2 - (canvas:getWidth() / 2) * sx
    canvasY = h / 2 - (canvas:getHeight() / 2) * sy
    u.setDimensions(canvasX, canvasY, sx, sy)
end

local function initStuff()
    u = urutora:new()
    initCanvasStuff()
    u.setDefaultFont(proggyTiny)
    doResizeStuff(lg.getDimensions())
    transparentCursorImg = love.image.newImageData(1, 1)
    lm.setCursor(lm.newCursor(transparentCursorImg))
end

-- Function to create a shallow copy of the inputs table
local function copyInputs(inputs)
    local copy = {}
    for k, v in pairs(inputs) do
        copy[k] = v
    end
    return copy
end

local function back()
    if currentStep > 1 then
        -- Go back one step within the current phase
        currentStep = currentStep - 1
        state = "displaying_text"
        currentTypingText = nil
    elseif #stepHistory > 0 then
        -- Restore the previous phase from the stack
        local prevState = table.remove(stepHistory)
        dialogueSteps = prevState.dialogueSteps
        currentStep = prevState.currentStep
        inputs = prevState.inputs
        state = "displaying_text"
        currentTypingText = nil
    end
    -- If currentStep == 1 and no history, do nothing (user is at the start)
end

-- Reusable function to create a typing text object
function createTypingText(text, x, y, font, typingSpeed, fadeDuration, maxWidth)
    return {
        text = text,
        x = x,
        y = y,
        font = font,
        typingSpeed = typingSpeed,
        fadeDuration = fadeDuration,
        currentIndex = 1,
        charTimes = {},
        timer = 0,
        isFinished = false,
        maxWidth = maxWidth or (w - 20), -- Default to canvas width minus padding
        update = function(self, dt)
            if not self.isFinished then
                self.timer = self.timer + dt
                while self.timer >= self.typingSpeed and self.currentIndex <= #self.text do
                    self.charTimes[self.currentIndex] = love.timer.getTime()
                    self.currentIndex = self.currentIndex + 1
                    self.timer = self.timer - self.typingSpeed
                end
                if self.currentIndex > #self.text then
                    self.isFinished = true
                end
            end
        end,
        draw = function(self)
            local currentX = self.x
            local currentY = self.y
            local line = ""
            local lines = {}
            local word = ""

            -- Split text into lines based on maxWidth
            for i = 1, #self.text do
                local char = self.text:sub(i, i)
                if char == " " then
                    if self.font:getWidth(line .. word) > self.maxWidth then
                        table.insert(lines, line)
                        line = word .. " "
                    else
                        line = line .. word .. " "
                    end
                    word = ""
                else
                    word = word .. char
                end
            end
            -- Handle the last word
            if word ~= "" then
                if self.font:getWidth(line .. word) > self.maxWidth then
                    table.insert(lines, line)
                    line = word
                else
                    line = line .. word
                end
            end
            if line ~= "" then
                table.insert(lines, line)
            end

            -- Draw each line with the typing effect
            local linesSoFar = {}
            for lineIndex, lineText in ipairs(lines) do
                currentX = self.x
                for charIndex = 1, #lineText do
                    local globalIndex = 0
                    for i = 1, lineIndex - 1 do
                        globalIndex = globalIndex + #lines[i] -- Add length of previous lines
                    end
                    globalIndex = globalIndex + charIndex -- Add position in current line
                    if globalIndex <= self.currentIndex then
                        local timeSinceAdded = love.timer.getTime() - (self.charTimes[globalIndex] or 0)
                        local alpha = math.min(timeSinceAdded / self.fadeDuration, 1)
                        lg.setColor(1, 1, 1, alpha)
                        local char = lineText:sub(charIndex, charIndex)
                        lg.print(char, currentX, currentY)
                        currentX = currentX + self.font:getWidth(char)
                    end
                end
                currentY = currentY + self.font:getHeight() + 2 -- Move to next line with spacing
                table.insert(linesSoFar, lineText)
            end
            lg.setColor(1, 1, 1, 1) -- Reset color
        end
    }
end

-- Generate dialogue steps based on calculator choice
local function generateDialogueSteps(choice)
    local steps = {}
    if choice == "1" then
        steps = {
            { type = "display", text = "Unweighted Calculator Selected" },
            { type = "input", prompt = "Enter total course points: ", storeIn = "totalPoints" },
            { type = "input", prompt = "Enter minimum points for A: ", storeIn = "minA" },
            { type = "input", prompt = "Enter minimum points for B: ", storeIn = "minB" },
            { type = "input", prompt = "Enter minimum points for C: ", storeIn = "minC" },
            { type = "input", prompt = "Enter minimum points for D: ", storeIn = "minD" },
            { type = "input", prompt = "Enter number of assignments: ", storeIn = "numAssignments" },
        }
    elseif choice == "2" then
        steps = {
            { type = "display", text = "Weighted Calculator Selected" },
            { type = "input", prompt = "Enter number of categories: ", storeIn = "numCategories" },
        }
    else
        steps = {
            { type = "display", text = "Invalid choice. Please click back and enter 1 or 2." }
        }
    end
    return steps
end


-- Generate assignment input steps
local function generateAssignmentSteps(numAssignments)
    local steps = {}
    for i = 1, numAssignments do
        table.insert(steps, { type = "input", prompt = "Enter assignment " .. i .. " name: ", storeIn = "assignmentName" .. i })
        table.insert(steps, { type = "input", prompt = "Enter points possible for assignment " .. i .. ": ", storeIn = "pointsPossible" .. i })
        table.insert(steps, { type = "input", prompt = "Enter points earned for assignment " .. i .. ": ", storeIn = "pointsEarned" .. i })
        table.insert(steps, { type = "input", prompt = "Is assignment " .. i .. " a bonus? (1 for Yes, 0 for No): ", storeIn = "isBonus" .. i })
    end
    return steps
end

local function next()
    if textInput.text == "" then
        local randomIndex = love.math.random(1, #errorMessages)
        errorLabel.text = errorMessages[randomIndex]
        errorLabel.visible = true
    else
        local step = dialogueSteps[currentStep]
        inputs[step.storeIn] = textInput.text
        textInput.visible = false
        errorLabel.visible = false

        if step.storeIn == "choice" then
            -- Save current state before generating new steps
            table.insert(stepHistory, {dialogueSteps = dialogueSteps, currentStep = currentStep, inputs = copyInputs(inputs)})
            dialogueSteps = generateDialogueSteps(inputs.choice)
            currentStep = 1
            if #dialogueSteps == 0 then
                print("Error: Invalid choice or no steps generated.")
                state = "finished"
                return
            end
            state = "displaying_text"
            currentTypingText = nil
        elseif step.storeIn == "numAssignments" then
            local num = tonumber(inputs.numAssignments)
            if num and num > 0 then
                -- Save current state before generating assignment steps
                table.insert(stepHistory, {dialogueSteps = dialogueSteps, currentStep = currentStep, inputs = copyInputs(inputs)})
                inputs.numAssignments = num
                dialogueSteps = generateAssignmentSteps(inputs.numAssignments)
                currentStep = 1
                if #dialogueSteps == 0 then
                    print("Error: No assignments to input.")
                    state = "finished"
                    return
                end
                state = "displaying_text"
                currentTypingText = nil
            else
                print("Error: Invalid number of assignments.")
                errorLabel.text = "Please enter a positive number."
                errorLabel.visible = true
                return
            end
        else
            currentStep = currentStep + 1
            if currentStep > #dialogueSteps then
                if inputs.choice == "1" then
                    local assignments = {}
                    for i = 1, inputs.numAssignments do
                        table.insert(assignments, {
                            inputs["assignmentName" .. i],
                            tonumber(inputs["pointsPossible" .. i]),
                            tonumber(inputs["pointsEarned" .. i]),
                            inputs["isBonus" .. i] == 1
                        })
                    end
                    resultText = grade_calculator.run_calculator(
                        1,
                        tonumber(inputs.totalPoints),
                        tonumber(inputs.minA),
                        tonumber(inputs.minB),
                        tonumber(inputs.minC),
                        tonumber(inputs.minD),
                        assignments
                    )
                elseif inputs.choice == "2" then
                    resultText = "Weighted calculator not yet implemented."
                end
                state = "finished"
            else
                state = "displaying_text"
                currentTypingText = nil
            end
        end
    end
end

function love.load()
    initStuff()

    Dialogue = {
        "Welcome to Hayden Phillip's Grade Calculator for COSC 1436",
        "Choose calculator type (1 for Unweighted, 2 for Weighted): ",
    }

    -- Initial dialogue steps
    dialogueSteps = {
        { type = "display", text = Dialogue[1] },
        { type = "input", prompt = Dialogue[2], storeIn = "choice" },
    }

    -- Initialize state
    currentStep = 1
    inputs = {}
    currentTypingText = nil
    state = "displaying_text"
    typingSpeed = 0.05
    fadeDuration = 0.5
    resultText = nil
    stepHistory = {}  -- Stack to track step history

    -- UI components
    textInput = u.text({ x = (w - 300) / 2, y = h / 2 - 15, w = 300, h = 30, text = "", visible = false, tag = "inputText" })
        :setStyle({ font = robotoBold })
    u:add(textInput)
    textInput.visible=false

    -- Add back button at bottom left
    backButton = u.button({ text = 'Back', x = 10, y = 150, w = 50, h = 20 })
    u:add(backButton)
    backButton:action(function(evt) back() end)

    errorLabel = { text = "", visible = false, y = h / 2 + 20 }
    errorMessages = { "Please enter a value.", "Input cannot be empty.", "You must provide a value." }
end

function love.update(dt)
    u:update(dt)
    bgRotation = bgRotation + dt * 5
    if bgRotation >= 360 then
        bgRotation = 0
    end

    if state == "displaying_text" then
        if not currentTypingText then
            local step = dialogueSteps[currentStep]
            local text = step.type == "display" and step.text or step.prompt
            local x = 10
            currentTypingText = createTypingText(text, x, h / 2 - 50, robotoBold, typingSpeed, fadeDuration, w - 20)
        end
        currentTypingText:update(dt)
        if currentTypingText.isFinished then
            if dialogueSteps[currentStep].type == "display" then
                state = "waiting_for_proceed"
            elseif dialogueSteps[currentStep].type == "input" then
                state = "waiting_for_input"
                textInput.visible = true
                textInput.text = inputs[dialogueSteps[currentStep].storeIn] or ""
                errorLabel.visible = false
            end
        end
    end
end

local function drawBg()
    local bg = bgs[bgIndex]
    lg.draw(
        bg,
        w / 2,
        h / 2,
        math.rad(bgRotation),
        w / bg:getWidth() * 3,
        h / bg:getHeight() * 3,
        bg:getWidth() / 2,
        bg:getHeight() / 2
    )
end

function drawCursor()
    if lm.isDown(1) then
        lg.setColor(1, 0, 0)
    end
    local x, y = u.utils:getMouse()
    lg.draw(arrow, math.floor(x), math.floor(y))
    lg.setColor(1, 1, 1)
end

function love.draw()
    lg.setCanvas({ canvas, stencil = true })
    lg.clear(bgColor)
    lg.setColor(1, 1, 1)
    drawBg()

    if currentTypingText then
        currentTypingText:draw()
    end

    u:draw() -- Always draw Urutora elements (back button and text input when visible)

    if state == "waiting_for_input" and errorLabel.visible then
        local textWidth = robotoBold:getWidth(errorLabel.text)
        local x = (w - textWidth) / 2
        lg.setColor(1, 0, 0)
        lg.print(errorLabel.text, x, errorLabel.y)
        lg.setColor(1, 1, 1)
    end

    if resultText then
        lg.print(resultText, 10, 10)
    end

    drawCursor()
    lg.setCanvas()
    lg.draw(canvas, math.floor(canvasX), math.floor(canvasY), 0, sx, sy)
end

function love.resize(w, h)
    doResizeStuff(w, h)
end

function love.mousemoved(x, y, dx, dy)
    u:moved(x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    u:released(x, y)
end

function love.textinput(text)
    u:textinput(text)
end

function love.wheelmoved(x, y)
    u:wheelmoved(x, y)
end

function love.keypressed(k, scancode, isrepeat)
    u:keypressed(k, scancode, isrepeat)
    if k == "escape" then
        love.event.quit()
    end
    if state == "waiting_for_proceed" and (k == "space" or k == "return") then
        currentStep = currentStep + 1
        if currentStep > #dialogueSteps then
            state = "finished"
        else
            state = "displaying_text"
            currentTypingText = nil
        end
    elseif state == "waiting_for_input" and k == "return" then
        if textInput.text == "" then
            local randomIndex = love.math.random(1, #errorMessages)
            errorLabel.text = errorMessages[randomIndex]
            errorLabel.visible = true
        else next() end
    end
end

function love.mousepressed(x, y, button)
    u:pressed(x, y, button)
    if state == "waiting_for_proceed" then
        currentStep = currentStep + 1
        if currentStep > #dialogueSteps then
            state = "finished"
        else
            state = "displaying_text"
            currentTypingText = nil
        end
    elseif state == "waiting_for_input" then
        local mx, my = u.utils:getMouse()
        if not (mx >= textInput.x and mx <= textInput.x + textInput.w and my >= textInput.y and my <= textInput.y + textInput.h) then
            textInput.visible = false
            errorLabel.visible = false
            state = "displaying_text"
            currentTypingText = nil
        end
    end
end


