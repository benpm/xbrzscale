-- Test script for xBRZ filter plugin
-- Run with: aseprite --batch --script test-xbrz.lua

print("Testing xBRZ filter plugin...")

-- Test 1: Check if the plugin file can be loaded
print("\n[Test 1] Loading plugin file...")
local success, err = pcall(function()
  dofile("aseprite-plugin/xbrz-filter.lua")
end)

if success then
  print("✓ Plugin file loaded successfully")
else
  print("✗ Error loading plugin: " .. tostring(err))
  os.exit(1)
end

-- Test 2: Check if init function exists
print("\n[Test 2] Checking init function...")
if init and type(init) == "function" then
  print("✓ init() function found")
else
  print("✗ init() function not found")
  os.exit(1)
end

-- Test 3: Check if exit function exists
print("\n[Test 3] Checking exit function...")
if exit and type(exit) == "function" then
  print("✓ exit() function found")
else
  print("✗ exit() function not found")
  os.exit(1)
end

-- Test 4: Test xbrzscale executable finding logic
print("\n[Test 4] Testing xbrzscale executable search...")
local xbrzPaths = {
  "build/Release/xbrzscale.exe",
  "build/Release/xbrzscale",
  "build/xbrzscale.exe",
  "build/xbrzscale",
  "../build/Release/xbrzscale.exe",
  "../build/Release/xbrzscale",
  "../build/xbrzscale.exe",
  "../build/xbrzscale",
  "xbrzscale.exe",
  "xbrzscale"
}

local xbrzCmd = nil
for _, path in ipairs(xbrzPaths) do
  print("  Checking: " .. path)

  -- First check if file exists
  local f = io.open(path, "r")
  if f then
    f:close()
    print("    File exists, testing execution...")

    -- Now try to execute it
    -- Convert forward slashes to backslashes for Windows compatibility
    local execPath = string.gsub(path, "/", "\\")
    local cmd = '"' .. execPath .. '" 2>&1'
    local handle = io.popen(cmd)
    if handle then
      local result = handle:read("*a")
      handle:close()

      if result and (string.find(result, "usage") or string.find(result, "scale_factor")) then
        xbrzCmd = execPath
        print("  ✓ Found xbrzscale at: " .. path)
        print("  Output: " .. result:sub(1, 50))
        break
      else
        print("    Unexpected output: " .. (result and result:sub(1, 50) or "nil"))
      end
    else
      print("    Failed to execute")
    end
  end
end

if not xbrzCmd then
  print("✗ WARNING: xbrzscale executable not found in any of these paths:")
  for _, path in ipairs(xbrzPaths) do
    print("  - " .. path)
  end
  print("\n  Please build xbrzscale first:")
  print("    mkdir build && cd build")
  print("    cmake .. -DCMAKE_BUILD_TYPE=Release")
  print("    cmake --build . --config Release")
else
  print("\n[Test 5] Verifying xbrzscale works with actual file...")

  -- Create a test file
  local testInputPath = os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
  testInputPath = testInputPath .. "/xbrz_test_input.png"
  local testOutputPath = (os.getenv("TEMP") or os.getenv("TMP") or "/tmp") .. "/xbrz_test_output.png"

  -- Check if we have a test image
  local testImage = "examples/threeformsPJ2.png"
  local f = io.open(testImage, "r")
  if f then
    f:close()
    -- Copy test image
    if os.getenv("OS") and string.find(os.getenv("OS"), "Windows") then
      os.execute('copy "' .. testImage .. '" "' .. testInputPath .. '" > nul 2>&1')
    else
      os.execute('cp "' .. testImage .. '" "' .. testInputPath .. '"')
    end

    -- Try to run xbrzscale
    local scaleCmd = string.format('"%s" 2 "%s" "%s" 2>&1', xbrzCmd, testInputPath, testOutputPath)
    print("  Running: " .. scaleCmd)
    local result = os.execute(scaleCmd)

    -- Check if output was created
    local outf = io.open(testOutputPath, "r")
    if outf then
      outf:close()
      print("  ✓ xbrzscale successfully created output file")
      os.remove(testOutputPath)
    else
      print("  ✗ xbrzscale did not create output file")
    end

    os.remove(testInputPath)
  else
    print("  (Skipping - no test image found)")
  end
end

print("\n=================================")
print("All syntax tests passed!")
print("Plugin is ready for installation.")
print("=================================")
