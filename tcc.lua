local version = "0.0.1"
local parser = require "parser"
local codegen = require "codegen"

local StringWriter = {}
StringWriter.__index = StringWriter

function StringWriter.new()
  local sw = {}
  sw.parts = {}
  return setmetatable(sw, StringWriter)
end

function StringWriter:write(s)
  table.insert(self.parts, s)
end

function StringWriter:flush() end
function StringWriter:close() end

function StringWriter:__tostring()
  return table.concat(self.parts, "")
end

local args = { ... }
local sourcePath = nil
local outputPath = nil
local src = nil

local i = 1
while i <= #args do
  local arg = args[i]

  if arg == "-o" then
    i = i + 1
    outputPath = shell.resolve(args[i])
  elseif not sourcePath then
    sourcePath = arg
    if arg ~= "-" then
      sourcePath = shell.resolve(sourcePath)
    end
  else
    print("Unexpected argument: " .. arg)
    return
  end
  i = i + 1
end

if not sourcePath then
  local replEnv = {}
  local running = true

  function replEnv.exit()
    running = false
  end

  term.setTextColor(colors.cyan)
  print("TypeCraft " .. version)
  print("Call exit() to exit.")
  while running do
    term.setTextColor(colors.blue)
    term.write("tc> ")
    term.setTextColor(colors.white)

    local src = read()
    local ast, rest = parser.parseBlock("return " .. src)

    if not ast or rest:match("%S") then
      ast, rest = parser.parseBlock(src)
    end

    if not ast or rest:match("%S") then
      print("didn't parse: " .. rest)
    else
      local h = StringWriter.new()
      codegen.genBlock(h, ast)
      local src = tostring(h)
      local fn = load(src, "repl", "t", replEnv)
      local values = { fn() }

      for i = 1, #values do
        print(textutils.serialize(values[i]))
      end
    end
  end
  return
end

local outputHandle = io.stdout

if outputPath then
  outputHandle = io.open(outputPath, "w")
end

if sourcePath == "-" then
  src = {}

  parallel.waitForAny(
    function()
      while true do
        table.insert(src, read())
      end
    end,
    function()
      local ctrl = false

      while true do
        local e, k, held = os.pullEvent("key")
        local down = e == "key"
        local up = e == "key_up"

        if (down or up) and not held then
          if k == keys.leftCtrl then
            ctrl = down
          elseif k == keys.rightCtrl then
            ctrl = down
          elseif ctrl and k == keys.d then
            return
          end
        end
      end
    end
  )

  src = table.concat(src, "\n")
else
  local srcHandle = io.open(sourcePath, "r")

  if not srcHandle then
    print("No such file: /" .. sourcePath)
    return
  end

  src = srcHandle:read("a")
  srcHandle:close()
end

local ast, rest = parser.parseBlock(src)

if rest:match("%S") then
  error("Couldn't parse:\n" .. rest:sub(1, 40), 0)
end

codegen.genBlock(outputHandle, ast)

outputHandle:flush()
outputHandle:close()
