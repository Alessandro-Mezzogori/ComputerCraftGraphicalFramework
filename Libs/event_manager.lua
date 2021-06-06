local event = require "event"

-- event_manager table module
eventManagerTable = {}

runningEventLoop = true
char_space = string.byte(" ")

function unknownEvent() 
  -- do nothing if event want's relevant
end

local unknownEventTable = {unknownEvent}

-- tables that holds the event handlers
foregroundEventHandlers = setmetatable({}, {__index = unknownEventTable })
backgroundEventHandlers = setmetatable({}, {__index = unknownEventTable })

-- function to separate eventID from the other parameters
function handleEvent(eventID, ...)
  if(eventID and foregroundEventHandlers[eventID] ~= nil) then
    for _, f in ipairs(foregroundEventHandlers[eventID]) do
      f(...)
    end
  end
end

function handleBackgroundEvents(eventID, ...)
 if(eventID and backgroundEventHandlers[eventID] ~= nil) then
    for _, f in ipairs(backgroundEventHandlers[eventID]) do
      f(...)
    end
  end
end

-- register event logic
function registerEventHandlerHelper(eventName, eventHandler, eventHandlerTable)
  if eventHandlerTable[eventName] == nil then
    event.listen(eventName, handleEvent) -- binds the handleEvent to the eventName
    eventHandlerTable[eventName] = {eventHandler}
    
    --print("Registerd eventHandler: " .. tostring(eventHandler) .. " to event " .. eventName)
  else
    table.insert(eventHandlerTable[eventName], eventHandler)
    --print("Added eventHandler " .. tostring(eventHandler) .. " to event " .. eventName)
  end
end

--[[
  register a specific event to an handler that will be called in the eventLoop (if in foreground)
  or by the os itself if in background
  IMPORTANT:
    background event handlers MUST be cleaned up using "unregisterAllEventHandlers(true)" to not have unexpected behaviour
]]--
function eventManagerTable.registerEventHandler(eventName, eventHandler, inBackground)
  local eventHandlerTable = foregroundEventHandlers
  if( inBackground == true ) then
    eventHandlerTable = backgroundEventHandlers
    event.listen(eventName, handleBackgroundEvents)
  end

  registerEventHandlerHelper(eventName, eventHandler, eventHandlerTable)
end

function eventManagerTable.unregisterEventHandler(eventName, eventHandler, inBackground)
  local eventHandlerTable = foregroundEventHandlers
  if(inBackground == true) then eventHandlerTable = backgroundEventHandlers end
  -- if there are no eventhandlers for an event name print info message and return
  if eventHandlerTable[eventName] == nil then
    --print("No eventHandler registered with " .. eventName)
    return
  end
  
  -- find the key of the eventHandler inside the table 
  local eventIndex = 0
  for _, handler in ipairs(eventHandlerTable[eventName]) do
    if handler == eventHandler then
      eventIndex = _
      break    
    end
  end

  -- remove element at found index
  if eventIndex ~= 0 then
    table.remove(eventHandlerTable[eventName], eventIndex)
    --print("Unregistered handler " .. tostring(eventHandler) .. " from event " .. eventName)
    return
  end

  --print(tostring(eventHandler) .. " was not found in the events associated with " .. eventName)
end

function isEventHandlerRegistered(eventName, eventHandler, inBackground)
  local eventHandlerTable = foregroundEventHandlers
  if(inBackground == true) then eventHandlerTable = backgroundEventHandlers end

  -- if there's no association there's not eventHandler neither  
  if eventHandlerTable[eventName] == nil then
    return false
  end

  --loop to search for the eventHandler inside of the associated table
  for _, handler in ipairs(eventHandlerTable[eventName]) do
    -- handler found
    if handler == eventHandler then        
      return true
    end
  end
  return false -- the handler was not found so return false
end

function eventManagerTable.unregisterAllEventHandlers(inBackground)
  local eventHandlerTable = foregroundEventHandlers
  if (inBackground == true) then eventHandlerTable = backgroundEventHandlers end

  for i, _ in pairs(eventHandlerTable) do eventHandlerTable[i] = nil end
end

-- debug functions
function printEventHandlers()
  print("ForegroundEventHandlers: ")
  for k, v in pairs(foregroundEventHandlers) do
    print(k .. ":")
    for _, e in ipairs(v) do
      print(e)
    end
  end

  print("BackgroundEventHandlers: ")
  for k, v in pairs(backgroundEventHandlers) do
    print(k .. ":")
    for _, e in ipairs(v) do
      print(e)
    end
  end
end

-- event functions 
function stopEventLoop(address, char, code, playerName)
  if( char == char_space ) then
    runningEventLoop = false
  end
end

function eventManagerTable.startEventLoop()
  local stopEventName = "key_up"
  local stopEventHandler = stopEventLoop
  
  -- add a way to stop the loop event 
  if isEventHandlerRegistered(stopEventName, stopEventHandler) == false then
    registerEventHandler("key_up", stopEventLoop) -- stop event isn't registered so register it
  end
  
  --print("Starting Event Loop")
  -- run loop event    
  runningEventLoop = true
  while runningEventLoop == true do
    handleEvent(event.pull())
  end
end

-- clean up any eventHandler from previous calls
unregisterAllEventHandlers()
unregisterAllEventHandlers(true)

return eventManagerTable