-- Auto-updater (GitHub Raw)
local BASE = "https://raw.githubusercontent.com/Shade50/turtles-cc/main/"
local FILES = { "main.lua" }

local function download(url, path)
  local res = http.get(url, nil, true) -- true = binary mode safe
  if not res then
    return false, "http.get failed: " .. url
  end
  local data = res.readAll()
  res.close()

  local f = fs.open(path, "w")
  f.write(data)
  f.close()
  return true
end

for _, name in ipairs(FILES) do
  local ok, err = download(BASE .. name, name)
  if not ok then
    print("Update failed for " .. name)
    print(err)
    print("Running existing version if present...")
  else
    print("Updated: " .. name)
  end
end

if fs.exists("main.lua") then
  shell.run("main.lua")
else
  print("main.lua not found.")
end