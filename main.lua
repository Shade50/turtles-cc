-- ===== SIMPLE VOLUME MINER + REMOTE CONTROL (HOME/STOP) =====
-- Mines L x W x H (UP) and dumps in chest BEHIND start when full.
-- Commands from PC: "HOME" or "STOP"
print("MAIN START")
sleep(1)
print("MODEM LEFT: ", peripheral.getType("left"))
sleep(1)
local L, W, H = 20, 20, 3

-- Tracking (x forward, y right, z up is NEGATIVE here)
local x, y, z, dir = 0, 0, 0, 0 -- dir: 0=F,1=R,2=B,3=L

-- Rednet
rednet.open("left") -- modem on left (turtle)

local STOP = false
local DO_HOME = false

local function face(t)
  while dir ~= t do
    turtle.turnRight()
    dir = (dir + 1) % 4
  end
end

local function digF() while turtle.detect() do turtle.dig() sleep(0.02) end end
local function digU() while turtle.detectUp() do turtle.digUp() sleep(0.02) end end
local function digD() while turtle.detectDown() do turtle.digDown() sleep(0.02) end end

local function fwd()
  digF()
  while not turtle.forward() do turtle.attack() sleep(0.02) digF() end
  if dir==0 then x=x+1
  elseif dir==1 then y=y+1
  elseif dir==2 then x=x-1
  else y=y-1 end
end

local function up()
  digU()
  while not turtle.up() do turtle.attackUp() sleep(0.02) digU() end
  z = z - 1 -- up = negative z (important)
end

local function down()
  digD()
  while not turtle.down() do turtle.attackDown() sleep(0.02) digD() end
  z = z + 1
end

local function invFull()
  for i=1,16 do
    if turtle.getItemCount(i)==0 then return false end
  end
  return true
end

local function dumpBehind()
  turtle.turnLeft(); turtle.turnLeft()
  for i=1,16 do
    turtle.select(i)
    turtle.drop()
  end
  turtle.turnLeft(); turtle.turnLeft()
  turtle.select(1)
end

local function goHome()
  -- since up makes z negative, home is z=0 => while z<0 go DOWN
  while z > 0 do up() end

  if y>0 then face(3) elseif y<0 then face(1) end
  while y~=0 do fwd() end

  if x>0 then face(2) elseif x<0 then face(0) end
  while x~=0 do fwd() end

  face(0)
end

local function goTo(tx,ty,tz,td)
  while z > tz do up() end
  while z < tz do down() end

  if y<ty then face(1) elseif y>ty then face(3) end
  while y~=ty do fwd() end

  if x<tx then face(0) elseif x>tx then face(2) end
  while x~=tx do fwd() end

  face(td)
end

local function dumpAndReturn()
  local sx,sy,sz,sd = x,y,z,dir
  goHome()
  dumpBehind()
  goTo(sx,sy,sz,sd)
end

-- Listener runs forever in parallel
local function listen()
  while true do
    local _, msg = rednet.receive()
    if msg == "STOP" then
      STOP = true
      print("Order: STOP")
    elseif msg == "HOME" then
      DO_HOME = true
      print("Order: HOME")
    end
  end
end

local function mineLayer()
  for row=1,W do
    for step=1,L-1 do
      if STOP then return false end
      if DO_HOME then
        DO_HOME = false
        goHome()
        dumpBehind()
      end
      if invFull() then dumpAndReturn() end
      fwd()
    end

    if row < W then
      if row % 2 == 1 then
        face(1); fwd(); face(2)
      else
        face(1); fwd(); face(0)
      end
    end
  end
  return true
end

local function mine()
  print("Mining "..L.."x"..W.."x"..H.." (down)")
  digF()

  for layer=1,H do
    if STOP then break end

    local ok = mineLayer()
    goStartSameDepth()
    if not ok then break end

    if layer < H then down(); digF() end
  end

  goHome()
  dumpBehind()
  print(STOP and "Stopped." or "Done.")
end

local function goStartSameDepth()
  -- revient à x=0,y=0 SANS changer z
  if y>0 then face(3) elseif y<0 then face(1) end
  while y~=0 do fwd() end

  if x>0 then face(2) elseif x<0 then face(0) end
  while x~=0 do fwd() end

  face(0)
end

-- Run both: mining + listening
parallel.waitForAny(listen, mine)