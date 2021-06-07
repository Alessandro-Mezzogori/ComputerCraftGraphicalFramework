local event = require "event"

-- event_manager table module
event_manager = {}

runningEventLoop = true
char_space = string.byte(" ")

function unknownEvent() 
  -- do nothing if event want's relevant
end

local unknownEventTable = {unknownEvent}

-- tables that holds the event handlers
eventHandlerTable = setmetatable({}, {__index = unknownEventTable })

-- function to separate eventID from the other parameters
function handleEvent(eventID, ...)
  if(eventID and eventHandlerTable[eventID] ~= nil) then
    for _, f in ipairs(eventHandlerTable[eventID]) do
      f(...)
    end
  end
end

-- register event logic

--[[
  register a specific event to an handler that will be called in the eventLoop (if in foreground)
  or by the os itself if in background
  IMPORTANT:
    background event handlers MUST be cleaned up using "unregisterAllEventHandlers(true)" to not have unexpected behaviour
]]--
function event_manager.registerEventHandler(eventName, eventHandler)
  if eventHandlerTable[eventName] == nil then
    eventHandlerTable[eventName] = {eventHandler}
    
    --print("Registerd eventHandler: " .. tostring(eventHandler) .. " to event " .. eventName)
  else
    table.insert(eventHandlerTable[eventName], eventHandler)
    --print("Added eventHandler " .. tostring(eventHandler) .. " to event " .. eventName)
  end
end

function event_manager.unregisterEventHandler(eventName, eventHandler)
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

function isEventHandlerRegistered(eventName, eventHandler)
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

function event_manager.unregisterAllEventHandlers()
  for i, _ in pairs(eventHandlerTable) do eventHandlerTable[i] = nil end
end

-- debug functions
function printEventHandlers()
  print("eventHandlerTable: ")
  for k, v in pairs(eventHandlerTable) do
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

function event_manager.startEventLoop()
  local stopEventName = "key_up"
  local stopEventHandler = stopEventLoop
  
  -- add a way to stop the loop event 
  if isEventHandlerRegistered(stopEventName, stopEventHandler) == false then
    event_manager.registerEventHandler("key_up", stopEventLoop) -- stop event isn't registered so register it
  end
  
  --print("Starting Event Loop")
  -- run loop event    
  runningEventLoop = true
  while runningEventLoop == true do
    handleEvent(event.pull())
  end
end

-- clean up any eventHandler from previous calls
event_manager.unregisterAllEventHandlers()
event_manager.unregisterAllEventHandlers(true)

return event_manager