_G.lg = love.graphics
_G.lm = love.mouse

local urutora = require("urutora")
local grade_calculator = require("grade_calculator")
local styleManager = require("styleManager")

local u
require("images")
require("fonts")

local bgColor = { 0.2, 0.1, 0.3 }
local currentChoiceButtons = {}

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

local function updateResultLabel()
    local text = resultLabel.text or ""
    -- split into lines
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        lines[#lines+1] = line
    end

    -- measure
    local font = currentStyle.font
    local maxW = 0
    for _, line in ipairs(lines) do
        maxW = math.max( maxW, font:getWidth(line) )
    end
    local lineH = font:getHeight()
    local totalH = #lines * lineH + (#lines-1)*2  -- 2px spacing

    -- apply to label
    resultLabel.w = maxW
    resultLabel.h = totalH
    resultLabel.x = (w - maxW) / 2
    resultLabel.y = (h - totalH) / 2
end


-- removes any on‑screen choice buttons
local function clearChoiceButtons()
	for _, btn in ipairs(currentChoiceButtons) do
		u:remove(btn)
	end
	currentChoiceButtons = {}
end

local function back()
	clearChoiceButtons()
	if currentStep > 1 then
		currentStep = currentStep - 1
		state = "displaying_text"
		currentTypingText = nil
	elseif #stepHistory > 0 then
		local prevState = table.remove(stepHistory)
		dialogueSteps = prevState.dialogueSteps
		currentStep = prevState.currentStep
		inputs = prevState.inputs
		state = "displaying_text"
		currentTypingText = nil
	end
end

-- Reusable function to create a typing text object
function createTypingText(text, x, y, font, color, typingSpeed, fadeDuration, maxWidth)
	font = font or proggyTiny -- Default font if not provided
	color = color or { 1, 1, 1, 1 } -- Default to white if not provided
	return {
		text = text,
		x = x,
		y = y,
		font = font,
		color = color,
		typingSpeed = typingSpeed,
		fadeDuration = fadeDuration,
		currentIndex = 1,
		charTimes = {},
		timer = 0,
		isFinished = false,
		maxWidth = maxWidth or (w - 20),
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
			lg.setFont(self.font)
			local currentX = self.x
			local currentY = self.y
			local line = ""
			local lines = {}
			local word = ""
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
			for lineIndex, lineText in ipairs(lines) do
				currentX = self.x
				for charIndex = 1, #lineText do
					local globalIndex = 0
					for i = 1, lineIndex - 1 do
						globalIndex = globalIndex + #lines[i]
					end
					globalIndex = globalIndex + charIndex
					if globalIndex <= self.currentIndex then
						local timeSinceAdded = love.timer.getTime() - (self.charTimes[globalIndex] or 0)
						local alpha = math.min(timeSinceAdded / self.fadeDuration, 1)
						local r, g, b = unpack(self.color)
						lg.setColor(r, g, b, alpha)
						local char = lineText:sub(charIndex, charIndex)
						lg.print(char, currentX, currentY)
						currentX = currentX + self.font:getWidth(char)
					end
				end
				currentY = currentY + self.font:getHeight() + 2
			end
			lg.setColor(1, 1, 1, 1) -- Reset color
		end,
	}
end

local function generateCategorySteps(numCategories)
	local steps = {}
	for i = 1, numCategories do
		table.insert(steps, {
			type = "input",
			prompt = "Enter name for category " .. i .. ": ",
			storeIn = "categoryName" .. i,
		})
		table.insert(steps, {
			type = "input",
			prompt = "Enter weight for category " .. i .. " (e.g. 0.25): ",
			storeIn = "categoryWeight" .. i,
		})
	end
	-- Then ask how many assignments to enter
	table.insert(steps, {
		type = "input",
		prompt = "Enter number of assignments: ",
		storeIn = "numAssignments",
	})
	return steps
end

-- After you know how many assignments, collect for each:
-- { name, category, possible, earned, bonus }
local function generateWeightedAssignmentSteps(numAssignments)
	local steps = {}
	for i = 1, numAssignments do
		table.insert(steps, {
			type = "input",
			prompt = "Assignment " .. i .. " name: ",
			storeIn = "assignmentName" .. i,
		})
		table.insert(steps, {
			type = "multi-choice",
			prompt = "Select category for assignment " .. i .. ": ",
			storeIn = "assignmentCategory" .. i,
			choices = (function()
				local cs = {}
				for j = 1, tonumber(inputs.numCategories) do
					table.insert(cs, inputs["categoryName" .. j])
				end
				return cs
			end)(),
		})
		table.insert(steps, {
			type = "input",
			prompt = "Points possible for assignment " .. i .. ": ",
			storeIn = "pointsPossible" .. i,
		})
		table.insert(steps, {
			type = "input",
			prompt = "Points earned for assignment " .. i .. ": ",
			storeIn = "pointsEarned" .. i,
		})
		table.insert(steps, {
			type = "multi-choice",
			prompt = "Is assignment " .. i .. " a bonus?",
			storeIn = "isBonus" .. i,
			choices = { "Yes", "No" },
		})
	end
	return steps
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
	end
	return steps
end

local function next()
	clearChoiceButtons()
	local step = dialogueSteps[currentStep]

	-- Handle text‐entry steps
	if step.type == "input" then
		if textInput.text == "" then
			local randomIndex = love.math.random(1, #errorMessages)
			errorLabel.text = errorMessages[randomIndex]
			errorLabel.visible = true
			return
		end
		inputs[step.storeIn] = textInput.text
		textInput.visible = false
		errorLabel.visible = false

	-- Handle button‐choice steps
	elseif step.type == "multi-choice" then
		-- first choice (weighted/unweighted) reloads dialog
		if step.storeIn == "choice" then
			table.insert(stepHistory, {
				dialogueSteps = dialogueSteps,
				currentStep = currentStep,
				inputs = copyInputs(inputs),
			})
			dialogueSteps = generateDialogueSteps(inputs.choice)
			currentStep = 1
			state = "displaying_text"
			currentTypingText = nil
			return
		end

		clearChoiceButtons()
		currentStep = currentStep + 1

		if currentStep > #dialogueSteps then
			-- C++ time!
            backButton.visible = false
			-- Unweighted calculation
			if inputs.choice == "1" then
				local assignments = {}
				for i = 1, inputs.numAssignments do
					assignments[i] = {
						inputs["assignmentName" .. i],
						tonumber(inputs["pointsPossible" .. i]),
						tonumber(inputs["pointsEarned" .. i]),
						inputs["isBonus" .. i] == "1" and 1 or 0,
					}
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
			else
				-- weighted calculation
				local category_weights = {}
				for i = 1, tonumber(inputs.numCategories) do
					category_weights[inputs["categoryName" .. i]] = tonumber(inputs["categoryWeight" .. i])
				end

				-- build assignments array of subtables
				local assignments = {}
				for i = 1, inputs.numAssignments do
					assignments[i] = {
						inputs["assignmentName" .. i],
						inputs["assignmentCategory" .. i],
						tonumber(inputs["pointsPossible" .. i]),
						tonumber(inputs["pointsEarned" .. i]),
						inputs["isBonus" .. i] == "Yes" and true or false,
					}
				end
				-- Run the C++ binding
				resultText = grade_calculator.run_calculator(2, category_weights, assignments)
			end
            resultLabel.text = resultText
            resultLabel.visible = true
            updateResultLabel()
            state = "finished"
            return
        
		end

		state = "displaying_text"
		currentTypingText = nil
		return
	end
	if step.storeIn == "numCategories" then
		local n = tonumber(inputs.numCategories)
		if not n or n < 1 then
			errorLabel.text = "Please enter a positive number."
			errorLabel.visible = true
			return
		end
		table.insert(stepHistory, {
			dialogueSteps = dialogueSteps,
			currentStep = currentStep,
			inputs = copyInputs(inputs),
		})
		inputs.numCategories = n
		dialogueSteps = generateCategorySteps(n)
		currentStep = 1
		state = "displaying_text"
		currentTypingText = nil
		return
	end
	if step.storeIn == "numAssignments" then
		local m = tonumber(inputs.numAssignments)
		if not m or m < 1 then
			errorLabel.text = "Please enter a positive number."
			errorLabel.visible = true
			return
		end
		table.insert(stepHistory, {
			dialogueSteps = dialogueSteps,
			currentStep = currentStep,
			inputs = copyInputs(inputs),
		})
		inputs.numAssignments = m
		if inputs.choice == "1" then
			dialogueSteps = generateAssignmentSteps(m)
		else
			dialogueSteps = generateWeightedAssignmentSteps(m)
		end
		currentStep = 1
		state = "displaying_text"
		currentTypingText = nil
		return
	end

	currentStep = currentStep + 1
	if currentStep > #dialogueSteps then
		print("Inputs: ", inputs)
		if inputs.choice == "1" then
			-- build an array of assignment tables
			local assignments = {}
			for i = 1, inputs.numAssignments do
				assignments[i] = {
					inputs["assignmentName" .. i],
					tonumber(inputs["pointsPossible" .. i]),
					tonumber(inputs["pointsEarned" .. i]),
					inputs["isBonus" .. i] == "1" and 1 or 0,
				}
			end

			-- pass the assignments table as argument #7
			resultText = grade_calculator.run_calculator(
				1,
				tonumber(inputs.totalPoints),
				tonumber(inputs.minA),
				tonumber(inputs.minB),
				tonumber(inputs.minC),
				tonumber(inputs.minD),
				assignments
			)
			resultLabel.text = resultText
			resultLabel.visible = true
		elseif inputs.choice == "2" then
			local category_weights = {}
			for i = 1, tonumber(inputs.numCategories) do
				category_weights[inputs["categoryName" .. i]] = tonumber(inputs["categoryWeight" .. i])
			end

			local assignments = {}
			for i = 1, inputs.numAssignments do
				assignments[i] = {
					inputs["assignmentName" .. i],
					inputs["assignmentCategory" .. i],
					tonumber(inputs["pointsPossible" .. i]),
					tonumber(inputs["pointsEarned" .. i]),
					inputs["isBonus" .. i] == "Yes" and true or false,
				}
			end

			-- invoke the C++ binding
			resultText = grade_calculator.run_calculator(2, category_weights, assignments)
		end

		state = "finished"
	else
		state = "displaying_text"
		currentTypingText = nil
	end
end

function generateChoiceButtons()
	local btns = {}
	local step = dialogueSteps[currentStep]
	local choices = step.choices or {}
	local btnW, btnH, spacing = 150, 30, 10
	local totalW = #choices * btnW + (#choices - 1) * spacing
	local startX = (w - totalW) / 2
	local y = h / 2 + 20

    for i, txt in ipairs(choices) do
        local btn = u.button({
          text = txt,
          x    = startX + (i - 1) * (btnW + spacing),
          y    = y,
          w    = btnW,
          h    = btnH,
        })
        btn:setStyle(currentStyle)    -- ← use full style
        btn:action(function(evt)
          inputs[step.storeIn] = tostring(i)
          next()
        end)
        u:add(btn)
        table.insert(btns, btn)
      end
      

	return btns
end

-- Generate assignment input steps
function generateAssignmentSteps(numAssignments)
	local steps = {}
	for i = 1, numAssignments do
		table.insert(
			steps,
			{ type = "input", prompt = "Enter assignment " .. i .. " name: ", storeIn = "assignmentName" .. i }
		)
		table.insert(steps, {
			type = "input",
			prompt = "Enter points possible for assignment " .. i .. ": ",
			storeIn = "pointsPossible" .. i,
		})
		table.insert(steps, {
			type = "input",
			prompt = "Enter points earned for assignment " .. i .. ": ",
			storeIn = "pointsEarned" .. i,
		})
		table.insert(steps, {
			type = "multi-choice",
			prompt = "Is assignment " .. i .. " a bonus?",
			storeIn = "isBonus" .. i,
			choices = { "Yes", "No" },
		})
	end
	return steps
end

function love.load()
	initStuff()

	-- Create UI elements and add them directly to the Urutora instance 'u'
	textInput = u.text({ x = (w - 300) / 2, y = h / 2 - 15, w = 300, h = 30, text = "", tag = "inputText" })
	u:add(textInput)
	textInput.visible = false

	resultLabel = u.label({ text = "", x = 10, y = 10, w = w - 20, h = 20, visible = false })
	u:add(resultLabel)

	-- Add style selector button
	backButton = u.button({ text = "Back", x = 10, y = 150, w = 50, h = 20 })
	u:add(backButton)

	backButton:action(function(evt)
		back()
	end)
	-- Create error label
	errorLabel = u.label({ text = "", visible = false, y = h / 2 + 20, x = w / 2 })

	u:add(errorLabel)

	-- Initialize style
	errorLabel:setStyle({ fgColor = { 1, 0, 0 } })

	currentStyleIndex = 2 -- Start with oliveStyle (assuming index 2)
	styleManager.handleStyleChanges(u, { index = currentStyleIndex })


	currentStyle = styleManager.styles[currentStyleIndex]
	bgColor = currentStyle.bgColor
    u:setStyle(currentStyle, u.utils.nodeTypes.BUTTON)

	Dialogue = {
		"Welcome to Hayden Phillips' Grade Calculator for COSC 1436",
		"Is your grade weighted or unweighted?",
	}

	dialogueSteps = {
		{ type = "display", text = Dialogue[1] },
		{
			type = "multi-choice",
			prompt = Dialogue[2],
			storeIn = "choice",
			choices = { "(Unweighted)", "(Weighted)" },
		},
	}

	currentStep = 1
	inputs = {}
	currentTypingText = nil
	state = "displaying_text"
	typingSpeed = 0.05
	fadeDuration = 0.5
	stepHistory = {}

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
			currentTypingText = createTypingText(
				text,
				x,
				h / 2 - 50,
				currentStyle.font,
				currentStyle.fgColor,
				typingSpeed,
				fadeDuration,
				w - 20
			)
		end
		currentTypingText:update(dt)
		if currentTypingText.isFinished then
			if dialogueSteps[currentStep].type == "multi-choice" then
				state = "waiting_for_choice"
				if #currentChoiceButtons == 0 then
					currentChoiceButtons = generateChoiceButtons()
				end
			end
			if dialogueSteps[currentStep].type == "display" then
				state = "waiting_for_proceed"
			end
			if dialogueSteps[currentStep].type == "input" then
				state = "waiting_for_input"
				textInput.visible = true
				textInput.text = inputs[dialogueSteps[currentStep].storeIn] or ""
				errorLabel.visible = false
			end
		end
	end
end

local function drawBg()
	lg.setColor(currentStyle.bgColor)
	lg.rectangle("fill", 0, 0, w, h)
	local bg = bgs[bgIndex]
	lg.setColor(1, 1, 1)
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
	drawBg()
	if currentTypingText then
		currentTypingText:draw()
	end
	u:draw()
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
			print(errorLabel.text)
			local randomIndex = love.math.random(1, #errorMessages)
			errorLabel.text = errorMessages[randomIndex]
			errorLabel.visible = true
		else
			next()
		end
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
		if
			not (
				mx >= textInput.x
				and mx <= textInput.x + textInput.w
				and my >= textInput.y
				and my <= textInput.y + textInput.h
			)
		then
			textInput.visible = false
			errorLabel.visible = false
			state = "displaying_text"
			currentTypingText = nil
		end
	end
end
