-- Test different path formats
local path = "build/Release/xbrzscale.exe"
print("Testing path: " .. path)

-- Test 1: With backslashes
local path1 = string.gsub(path, "/", "\\")
local cmd1 = '"' .. path1 .. '" 2>&1'
print("\nCommand 1: " .. cmd1)
local h1 = io.popen(cmd1)
if h1 then
  local r1 = h1:read("*a")
  h1:close()
  print("Result 1: " .. (r1 and r1:sub(1, 100) or "nil"))
end

-- Test 2: With ./ prefix and backslashes
local path2 = ".\\build\\Release\\xbrzscale.exe"
local cmd2 = '"' .. path2 .. '" 2>&1'
print("\nCommand 2: " .. cmd2)
local h2 = io.popen(cmd2)
if h2 then
  local r2 = h2:read("*a")
  h2:close()
  print("Result 2: " .. (r2 and r2:sub(1, 100) or "nil"))
end
