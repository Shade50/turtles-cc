-- Mine corridor simple: dig forward forever
-- Options: place a chest behind turtle to dump when full.

local USE_CHEST_BEHIND = true
local KEEP_FUEL_MIN = 200   -- refuel if fuel below this
local REFUEL_EACH = 1       -- how many items to consume per refuel attempt

local function invFull()
  for i=1,16 do
    if turtle.getItemCount(i) == 0 then return false end
  end
  return true
end

local function dumpToChestBehind()
  if not USE_CHEST_BEHIND then return end
  for i=1,16 do
    turtle.select(i)
    if turtle.getItemCount(i) > 0 then
      turtle.dropDown() -- change to drop() if your chest is behind/ front
    end
  end
  turtle.select(1)
end

local function ensureFuel()
  if turtle.getFuelLevel() == "unlimited" then return true end
  if turtle.getFuelLevel() >= KEEP_FUEL_MIN then return true end

  -- Try to refuel from inventory
  for i=1,16 do
    if turtle.getItemCount(i) > 0 then
      turtle.select(i)
      if turtle.refuel(REFUEL_EACH) then
        turtle.select(1)
        return true
      end
    end
  end

  turtle.select(1)
  print("No fuel items found. Add fuel and run again.")
  return false
end

local function digForward()
  while turtle.detect() do
    turtle.dig()
    sleep(0.1)
  end
end

local function moveForward()
  while not turtle.forward() do
    -- if blocked by entity
    digForward()
    turtle.attack()
    sleep(0.1)
  end
end

print("Mining corridor started. Ctrl+T to stop.")
turtle.select(1)

while true do
  if not ensureFuel() then break end

  -- If inventory full: dump
  if invFull() then
    print("Inventory full -> dumping...")
    dumpToChestBehind()
    if invFull() then
      print("Still full (no chest or chest full). Stopping.")
      break
    end
  end

  -- Mine one block forward and move
  digForward()
  moveForward()

  -- Optional: clear ceiling and floor (uncomment if you want 1x3 tunnel)
  -- if turtle.detectUp() then turtle.digUp() end
  -- if turtle.detectDown() then turtle.digDown() end
end

print("Mining stopped.")