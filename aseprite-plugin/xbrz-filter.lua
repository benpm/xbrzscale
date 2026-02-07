-- xBRZ Filter Plugin for Aseprite
-- Applies high-quality pixel art scaling using the xBRZ algorithm

local function applyXbrzFilter(scaleFactor)
  local sprite = app.activeSprite
  if not sprite then
    app.alert("No active sprite")
    return
  end

  local cel = app.activeCel
  if not cel then
    app.alert("No active cel")
    return
  end

  -- Get the image from the active cel
  local image = cel.image
  if not image then
    app.alert("No image in active cel")
    return
  end

  app.transaction(function()
    -- Create temporary file paths
    local tempDir = os.getenv("TEMP") or os.getenv("TMP") or "/tmp"
    local inputPath = tempDir .. "/xbrz_input_" .. os.time() .. ".png"
    local outputPath = tempDir .. "/xbrz_output_" .. os.time() .. ".png"

    -- Save the current image to a temporary file
    image:saveAs(inputPath)

    -- Find xbrzscale executable
    -- Look in common locations
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
    -- First try to find the file
    for _, path in ipairs(xbrzPaths) do
      local f = io.open(path, "r")
      if f then
        f:close()
        -- Verify it's the right executable by running it
        -- Convert forward slashes to backslashes for Windows compatibility
        local execPath = string.gsub(path, "/", "\\")
        local testCmd = '"' .. execPath .. '" 2>&1'
        local handle = io.popen(testCmd)
        if handle then
          local result = handle:read("*a")
          handle:close()
          if result and (string.find(result, "usage") or string.find(result, "scale_factor")) then
            xbrzCmd = execPath
            break
          end
        end
      end
    end

    if not xbrzCmd then
      app.alert("xbrzscale executable not found. Please build xbrzscale first and ensure it's in the PATH or in the same directory as this plugin.")
      -- Clean up temp file
      os.remove(inputPath)
      return
    end

    -- Run xbrzscale
    local cmd = string.format('"%s" %d "%s" "%s"', xbrzCmd, scaleFactor, inputPath, outputPath)
    local success = os.execute(cmd)

    if not success or success ~= 0 then
      app.alert("xBRZ filter failed to execute")
      os.remove(inputPath)
      os.remove(outputPath)
      return
    end

    -- Load the scaled image
    local scaledImage = Image{ fromFile=outputPath }
    if not scaledImage then
      app.alert("Failed to load scaled image")
      os.remove(inputPath)
      os.remove(outputPath)
      return
    end

    -- Create a new sprite with the scaled image
    local newSprite = Sprite(scaledImage.width, scaledImage.height, sprite.colorMode)
    newSprite:setPalette(sprite.palettes[1])

    -- Copy the scaled image to the first cel
    local newLayer = newSprite.layers[1]
    local newCel = newSprite:newCel(newLayer, 1, scaledImage, Point(0, 0))

    -- Set the new sprite as active
    app.activeSprite = newSprite

    -- Clean up temporary files
    os.remove(inputPath)
    os.remove(outputPath)

    app.alert("xBRZ " .. scaleFactor .. "x filter applied successfully!")
  end)
end

function init(plugin)
  -- Register xBRZ 2x filter command
  plugin:newCommand{
    id="XbrzFilter2x",
    title="xBRZ 2x",
    group="sprite_size",
    onclick=function()
      applyXbrzFilter(2)
    end,
    onenabled=function()
      return app.activeSprite ~= nil and app.activeCel ~= nil
    end
  }

  -- Register xBRZ 3x filter command
  plugin:newCommand{
    id="XbrzFilter3x",
    title="xBRZ 3x",
    group="sprite_size",
    onclick=function()
      applyXbrzFilter(3)
    end,
    onenabled=function()
      return app.activeSprite ~= nil and app.activeCel ~= nil
    end
  }

  -- Register xBRZ 4x filter command
  plugin:newCommand{
    id="XbrzFilter4x",
    title="xBRZ 4x",
    group="sprite_size",
    onclick=function()
      applyXbrzFilter(4)
    end,
    onenabled=function()
      return app.activeSprite ~= nil and app.activeCel ~= nil
    end
  }

  -- Register xBRZ 5x filter command
  plugin:newCommand{
    id="XbrzFilter5x",
    title="xBRZ 5x",
    group="sprite_size",
    onclick=function()
      applyXbrzFilter(5)
    end,
    onenabled=function()
      return app.activeSprite ~= nil and app.activeCel ~= nil
    end
  }

  -- Register xBRZ 6x filter command
  plugin:newCommand{
    id="XbrzFilter6x",
    title="xBRZ 6x",
    group="sprite_size",
    onclick=function()
      applyXbrzFilter(6)
    end,
    onenabled=function()
      return app.activeSprite ~= nil and app.activeCel ~= nil
    end
  }
end

function exit(plugin)
  -- Cleanup when plugin is unloaded
end
