_G.lg = love.graphics
_G.lm = love.mouse

local urutora = require('urutora')
local u
require 'images'
require 'fonts'

local bgColor = { 0.2, 0.1, 0.3 }
for _, bg in ipairs(bgs) do bg:setFilter('nearest', 'nearest') end 
bgIndex = 1
bgRotation = 0

local function initCanvasStuff()
  w, h = 320, 180  -- Canvas size
  canvas = lg.newCanvas(w, h)
  canvas:setFilter('nearest', 'nearest')
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

function love.load()
  initStuff()

  -- State management
  state = "initial_text"
  fullInitialText = "Please enter your name:"
  currentInitialIndex = 1
  initialCharTimes = {}
  timer = 0
  typingSpeed = 0.05
  fadeDuration = 0.5
  fullFinalText = ""
  currentFinalIndex = 1
  finalCharTimes = {}
  errorMessages = { "Please enter a name.", "Name cannot be empty.", "You must provide a name." }

  -- UI components
  textInput = u.text({ x = (w - 300) / 2, y = h / 2 - 15, w = 300, h = 30, text = '', visible = false, tag = 'inputText' }):setStyle({ font = robotoBold })
  u:add(textInput)
  errorLabel = { text = '', visible = false, y = h / 2 + 20 }
end

function love.update(dt)
  u:update(dt)
  bgRotation = bgRotation + dt * 5
  if bgRotation >= 360 then bgRotation = 0 end

  if state == "initial_text" then
    timer = timer + dt
    while timer >= typingSpeed and currentInitialIndex <= #fullInitialText do
      initialCharTimes[currentInitialIndex] = love.timer.getTime()
      currentInitialIndex = currentInitialIndex + 1
      timer = timer - typingSpeed
    end
    if currentInitialIndex > #fullInitialText then
      state = "input"
      textInput.visible = true
    end
  elseif state == "final_text" then
    timer = timer + dt
    while timer >= typingSpeed and currentFinalIndex <= #fullFinalText do
      finalCharTimes[currentFinalIndex] = love.timer.getTime()
      currentFinalIndex = currentFinalIndex + 1
      timer = timer - typingSpeed
    end
  end
end

local function drawBg()
  local bg = bgs[bgIndex]
  lg.draw(bg,
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
  if lm.isDown(1) then lg.setColor(1, 0, 0) end
  local x, y = u.utils:getMouse()
  lg.draw(arrow, math.floor(x), math.floor(y))
  lg.setColor(1, 1, 1)
end

function love.draw()
  lg.setCanvas({ canvas, stencil = true })
  lg.clear(bgColor)
  lg.setColor(1, 1, 1)
  drawBg()
  
  lg.setFont(robotoBold)
  if state == "initial_text" then
    local textWidth = robotoBold:getWidth(fullInitialText)
    local x = (w - textWidth) / 2
    local y = h / 2 - 50
    for i = 1, #fullInitialText do
      if i < currentInitialIndex then
        local timeSinceAdded = love.timer.getTime() - initialCharTimes[i]
        local alpha = math.min(timeSinceAdded / fadeDuration, 1)
        lg.setColor(1, 1, 1, alpha)
        local char = fullInitialText:sub(i,i)
        lg.print(char, x, y)
        x = x + robotoBold:getWidth(char)
      end
    end
  elseif state == "final_text" then
    local textWidth = robotoBold:getWidth(fullFinalText)
    local x = (w - textWidth) / 2
    local y = h / 2 + 50
    for i = 1, #fullFinalText do
      if i < currentFinalIndex then
        local timeSinceAdded = love.timer.getTime() - finalCharTimes[i]
        local alpha = math.min(timeSinceAdded / fadeDuration, 1)
        lg.setColor(1, 1, 1, alpha)
        local char = fullFinalText:sub(i,i)
        lg.print(char, x, y)
        x = x + robotoBold:getWidth(char)
      end
    end
  end
  lg.setColor(1, 1, 1, 1)

  u:draw()  -- Draws the textbox when visible
  if errorLabel.visible then
    local textWidth = robotoBold:getWidth(errorLabel.text)
    local x = (w - textWidth) / 2
    lg.setColor(1, 0, 0)
    lg.print(errorLabel.text, x, errorLabel.y)
    lg.setColor(1, 1, 1)
  end
  drawCursor()
  lg.setCanvas()
  lg.draw(canvas, math.floor(canvasX), math.floor(canvasY), 0, sx, sy)
end

function love.mousepressed(x, y, button)
  u:pressed(x, y, button)
  if state == "input" then
    local mx, my = u.utils:getMouse()
    if not (mx >= textInput.x and mx <= textInput.x + textInput.w and my >= textInput.y and my <= textInput.y + textInput.h) then
      textInput.visible = false
      errorLabel.visible = false
      state = "initial_text"
      currentInitialIndex = 1
      initialCharTimes = {}
      timer = 0
    end
  end
end

function love.mousemoved(x, y, dx, dy) u:moved(x, y, dx, dy) end
function love.mousereleased(x, y, button) u:released(x, y) end
function love.textinput(text) u:textinput(text) end
function love.wheelmoved(x, y) u:wheelmoved(x, y) end

function love.keypressed(k, scancode, isrepeat)
  u:keypressed(k, scancode, isrepeat)
  if k == 'escape' then love.event.quit() end
  if state == "input" and k == "return" then
    if textInput.text == "" then
      local randomIndex = love.math.random(1, #errorMessages)
      errorLabel.text = errorMessages[randomIndex]
      errorLabel.visible = true
    else
      fullFinalText = "Hello, " .. textInput.text .. "!"
      currentFinalIndex = 1
      finalCharTimes = {}
      timer = 0
      state = "final_text"
      textInput.visible = false
      errorLabel.visible = false
    end
  end
end

function love.resize(w, h)
  doResizeStuff(w, h)
end