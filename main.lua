-- ===== SIMPLE VOLUME MINER =====
-- Mines L x W x H and dumps in chest BELOW start when full

local L = 20
local W = 20
local H = 3

local x,y,z,dir = 0,0,0,0 -- 0=F,1=R,2=B,3=L

local function face(t)
  while dir ~= t do
    turtle.turnRight()
    dir = (dir + 1) % 4
  end
end

local function digF() while turtle.detect() do turtle.dig() sleep(0.02) end end
local function digU() while turtle.detectUp() do turtle.digUp() sleep(0.02) end end
local function digD() while turtle.detectDown() do turtle.digDown() sleep(0.02) end end

rednet.open("right") -- adapte si le modem est ailleurs

local STOP = false

local function listen()
  while true do
    local _, msg = rednet.receive()
    if msg == "STOP" then
      print("Order: STOP")
      STOP = true
    elseif msg == "HOME" then
      print("Order: GO HOME")
      goHome()
    end
  end
end

parallel.waitForAny(listen, function()
  -- TON SCRIPT DE MINAGE ICI
  -- Dans ta boucle principale, ajoute juste :
  -- if STOP then goHome(); return end
end)

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
  z=z-1
end

local function down()
  digD()
  while not turtle.down() do turtle.attackDown() sleep(0.02) digD() end
  z=z+1
end

local function invFull()
  for i=1,16 do
    if turtle.getItemCount(i)==0 then return false end
  end
  return true
end

local function dumpBehind()
  turtle.turnLeft()
  turtle.turnLeft() -- demi-tour

  for i=1,16 do
    turtle.select(i)
    turtle.drop()
  end

  turtle.turnLeft()
  turtle.turnLeft() -- se remet face avant
  turtle.select(1)
end

local function goHome()
  while z < 0 do down() end

  if y>0 then face(3)
  elseif y<0 then face(1) end
  while y~=0 do fwd() end

  if x>0 then face(2)
  elseif x<0 then face(0) end
  while x~=0 do fwd() end

  face(0)
end

local function goTo(tx,ty,tz,td)
  while z>tz do up() end
  while z<tz do down() end

  if y<ty then face(1)
  elseif y>ty then face(3) end
  while y~=ty do fwd() end

  if x<tx then face(0)
  elseif x>tx then face(2) end
  while x~=tx do fwd() end

  face(td)
end

local function dumpAndReturn()
  local sx,sy,sz,sd = x,y,z,dir
  goHome()
  dumpBehind()
  goTo(sx,sy,sz,sd)
end

local function mineLayer()
  for row=1,W do
    for step=1,L-1 do
      if invFull() then dumpAndReturn() end
      fwd()
    end

    if row<W then
      if row%2==1 then
        face(1) fwd() face(2)
      else
        face(1) fwd() face(0)
      end
    end
  end
end

print("Mining "..L.."x"..W.."x"..H)

digF()

for layer=1,H do
  mineLayer()
  goHome()
  if layer<H then up() digF() end
end

goHome()
dumpBehind()

print("Done.")