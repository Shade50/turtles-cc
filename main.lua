-- Volume Miner: dig a box L x W x H (length x width x height)
-- Pattern: serpentine rows, layer by layer, going down.
-- Simple & reliable.

-- ====== SETTINGS ======
local L = 20   -- length (forward)
local W = 20   -- width  (to the right)
local H = 5   -- height (downwards)
local RETURN_HOME = true

-- Inventory handling:
local DROP_TO_CHEST_BELOW = true  -- put chest below start and set true
local DROP_TO_CHEST_BEHIND = false  -- put chest behind start and set true (default)

-- ====== HELPERS ======
local function turnRight() turtle.turnRight() end
local function turnLeft() turtle.turnLeft() end

local function digForward()
  while turtle.detect() do turtle.dig(); sleep(0.05) end
end
local function digUp()
  while turtle.detectUp() do turtle.digUp(); sleep(0.05) end
end
local function digDown()
  while turtle.detectDown() do turtle.digDown(); sleep(0.05) end
end

local function forward()
  digForward()
  while not turtle.forward() do
    turtle.attack()
    sleep(0.05)
    digForward()
  end
end

local function up()
  digUp()
  while not turtle.up() do
    turtle.attackUp()
    sleep(0.05)
    digUp()
  end
end

local function down()
  digDown()
  while not turtle.down() do
    turtle.attackDown()
    sleep(0.05)
    digDown()
  end
end

local function invFull()
  for i=1,16 do if turtle.getItemCount(i) == 0 then return false end end
  return true
end

local function dumpAtHome()
  if not (DROP_TO_CHEST_BELOW or DROP_TO_CHEST_BEHIND) then return end

  for i=1,16 do
    turtle.select(i)
    if turtle.getItemCount(i) > 0 then
      if DROP_TO_CHEST_BELOW then turtle.dropDown() end
      if DROP_TO_CHEST_BEHIND then
        -- drop behind: turn around, drop, turn back
        turtle.turnLeft(); turtle.turnLeft()
        turtle.drop()
        turtle.turnLeft(); turtle.turnLeft()
      end
    end
  end
  turtle.select(1)
end

local function estimateFuelNeeded()
  -- Rough estimate:
  -- Each block moved costs 1 fuel.
  -- Movement inside volume:
  -- For each layer: (L-1)*W moves forward + (W-1) moves sideways between rows
  -- Plus moving down between layers: (H-1)
  -- Plus some turns (no fuel)
  local movesPerLayer = (L - 1) * W + (W - 1)
  local moves = movesPerLayer * H + (H - 1)

  if RETURN_HOME then
    -- returning roughly: go back to start (L-1 forward/back per row not needed; we return by navigation)
    -- Safe overestimate: add same amount again
    moves = moves * 2
  end
  -- Add safety margin
  return math.floor(moves * 1.2 + 50)
end

local function ensureFuel(minFuel)
  if turtle.getFuelLevel() == "unlimited" then return true end
  while turtle.getFuelLevel() < minFuel do
    local refueled = false
    for i=1,16 do
      if turtle.getItemCount(i) > 0 then
        turtle.select(i)
        if turtle.refuel(1) then
          refueled = true
          break
        end
      end
    end
    turtle.select(1)
    if not refueled then
      print("Fuel too low. Need at least: "..minFuel.." fuel.")
      print("Put fuel in inventory then run again.")
      return false
    end
  end
  return true
end

-- Track position to return home
local x, y, z = 0, 0, 0         -- x forward, y right, z down
local dir = 0                  -- 0=forward,1=right,2=back,3=left

local function face(target)
  while dir ~= target do
    turnRight()
    dir = (dir + 1) % 4
  end
end

local function moveForwardTrack()
  forward()
  if dir == 0 then x = x + 1
  elseif dir == 1 then y = y + 1
  elseif dir == 2 then x = x - 1
  else y = y - 1 end
end

local function moveDownTrack()
  down()
  z = z + 1
end

local function goHome()
  -- Return to (0,0,0) and face forward (dir=0)
  -- First go up (reverse down)
  while z > 0 do
    -- going up
    up()
    z = z - 1
  end
  -- Go to y=0
  if y > 0 then face(3) else face(1) end
  while y ~= 0 do
    moveForwardTrack()
  end
  -- Go to x=0
  if x > 0 then face(2) else face(0) end
  while x ~= 0 do
    moveForwardTrack()
  end
  face(0)
end

-- ====== MINING LOGIC ======
local function mineLayer()
  -- Mine a W x L area (serpentine)
  for row = 1, W do
    -- Move along length
    for step = 1, L - 1 do
      if invFull() and RETURN_HOME == false then
        -- in simple mode, stop if full and no return strategy
        print("Inventory full. Stopping.")
        return false
      end
      moveForwardTrack()
    end

    -- Go to next row (except last)
    if row < W then
      if row % 2 == 1 then
        face(1)              -- right
        moveForwardTrack()
        face(2)              -- back
      else
        face(1)
        moveForwardTrack()
        face(0)              -- forward
      end
    end
  end

  -- After layer ends, we may be at far corner facing either 0 or 2.
  return true
end

local function resetToLayerStart()
  -- After finishing a layer, we want to end up at the "start corner" (x=0,y=0) of next layer.
  -- The serpentine ends at y=W-1, and x either 0 or L-1 depending on W parity.
  -- We'll just goHome on same z-level then continue down.
  goHome()
end

-- ====== RUN ======
print(("Volume miner %dx%dx%d"):format(L,W,H))
local need = estimateFuelNeeded()
print("Estimated fuel needed:", need)

if not ensureFuel(need) then return end

-- Ensure starting block is clear to move into volume
digForward()

for layer = 1, H do
  print("Layer", layer, "of", H)

  local ok = mineLayer()
  if not ok then break end

  -- Return to layer start corner to keep it simple & safe
  resetToLayerStart()

  -- Go down for next layer (except last)
  if layer < H then
    moveDownTrack()
    -- clear the space for next layer entrance
    digForward()
  end

  -- Optional: if inventory full, return home, dump, and go back down (not implemented to keep simple)
end

if RETURN_HOME then
  print("Returning home...")
  goHome()
  print("Dumping...")
  dumpAtHome()
end

print("Done.")