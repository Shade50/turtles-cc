-- Auto-update (GitHub public) + versioning
local BASE = "https://raw.githubusercontent.com/Shade50/turtles-cc/main/"
local FILES = { "main.lua" }   -- ajoute d'autres fichiers si besoin
local VERSION_URL = BASE .. "version.txt"
local LOCAL_VERSION_FILE = ".version"

local function getUrl(url)
  local h, err = http.get(url)
  if not h then return nil, err end
  local data = h.readAll()
  h.close()
  return data
end

local function writeFile(path, data)
  local f = fs.open(path, "w")
  f.write(data)
  f.close()
end

local function readFile(path)
  if not fs.exists(path) then return nil end
  local f = fs.open(path, "r")
  local data = f.readAll()
  f.close()
  return data
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Force update if a "force" file exists (you can create it with: echo > force)
local FORCE = fs.exists("force")

local remoteV, err = getUrl(VERSION_URL)
if not remoteV then
  print("Can't reach version.txt:", err)
  print("Running existing code...")
else
  remoteV = trim(remoteV)
  local localV = trim(readFile(LOCAL_VERSION_FILE) or "0.0.0")

  if FORCE or remoteV ~= localV then
    print("Updating... local=" .. localV .. " remote=" .. remoteV)
    for _, name in ipairs(FILES) do
      local data, derr = getUrl(BASE .. name)
      if not data then
        print("Failed:", name, derr)
      else
        writeFile(name, data)
        print("Updated:", name)
      end
    end
    writeFile(LOCAL_VERSION_FILE, remoteV)

    if FORCE then
      fs.delete("force")
      print("Force flag cleared.")
    end
  else
    print("Up to date:", localV)
  end
end

if fs.exists("main.lua") then
  shell.run("main.lua")
else
  print("main.lua missing.")
end