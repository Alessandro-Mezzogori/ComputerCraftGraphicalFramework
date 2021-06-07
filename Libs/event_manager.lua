local event = require "event"

-- event_manager table module
local event_manager = {}

--[[ VARIABLES ]]--

local runningEventLoop = true

-- dummy function 
function unknownEvent() 
  -- do nothing if event want's relevant
end

local unknownEventTable = {unknownEvent}

-- tables that holds the event handlers
local eventHandlerTable = setmetatable({}, {__index = unknownEventTable })

--[[ FUNCTIONS ]]--

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
  local eventNames = {}
  if eventName == nil then
    for evtName, _ in pairs(eventHandlerTable) do 
      table.insert(eventNames, evtName)
    end 
  else
    table.insert(eventNames, eventName)
  end

  for _, evtName in ipairs(eventNames) do
    if eventHandlerTable[evtName] == nil then
      return false
    end

    --loop to search for the eventHandler inside of the associated table
    for _, handler in ipairs(eventHandlerTable[evtName]) do
      -- handler found
      if handler == eventHandler then        
        return true
      end
    end
  end
  return false -- the handler was not found so return false
end

function event_manager.unregisterAllEventHandlers()
  for i, _ in pairs(eventHandlerTable) do eventHandlerTable[i] = nil end
end

-- debug functions
function printEventHandlers()
  for k, v in pairs(eventHandlerTable) do
    print(k .. ":")
    for _, e in ipairs(v) do
      print("   " .. tostring(e))
    end
  end
end

-- event functions 
function event_manager.stopEventLoop(address, char, code, playerName)
  runningEventLoop = false
end

--[[
  starts the pulling loop event
  IMPORTANT:
    notSafe = false or nil (default) : requires that the method event_manager.stopEventLoop has been registered to at least 1 eventName
]]--
function event_manager.startEventLoop(notSafe)
  if (not notSafe) and (not isEventHandlerRegistered(nil, event_manager.stopEventLoop)) then
    print("ERROR: event_manager.stopEventLoop hasn't been registered as an eventHandler...stopping loopEvent start")
    return
  end
  --print("Starting Event Loop")
  -- run loop event    
  runningEventLoop = true
  while runningEventLoop == true do
    handleEvent(event.pull())
  end
end

return event_manager