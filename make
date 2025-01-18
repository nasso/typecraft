local SRC_DIR = shell.resolve("src")
local TCC0 = "bin/tcc"
local TCC1_DIR = shell.resolve("build/stage1")
local TCC2_DIR = shell.resolve("build/stage2")
local TCC3_DIR = shell.resolve("build/stage3")
local TCC1 = fs.combine(TCC1_DIR, "main")
local TCC2 = fs.combine(TCC2_DIR, "main")
local TCC3 = fs.combine(TCC3_DIR, "main")

local function findSources(dir, sources, prefixLen)
  sources = sources or {}
  prefixLen = prefixLen or #dir + 2
  
  local files = fs.list(dir)

  for i = 1, #files do
    local fullPath = fs.combine(dir, files[i])

    if fs.isDir(fullPath) then
      findSources(fullPath, sources, prefixLen)
    elseif fullPath:match("%.tc$") then
      table.insert(sources, fullPath:sub(prefixLen))
    end
  end

  return sources
end

local function build(tcc, srcDir, outDir)
  print("Compiling with " .. tcc)

  fs.makeDir(outDir)

  local sources = findSources(srcDir)

  for i = 1, #sources do
    local srcPathRel = sources[i]
    local outPathRel = srcPathRel:gsub("%.tc$", ".lua")

    local cmd = {
      "/" .. tcc,
      "/" .. fs.combine(srcDir, srcPathRel),
      "-o",
      "/" .. fs.combine(outDir, outPathRel),
    }

    print(table.concat(cmd, " "))

    local success = shell.execute(table.unpack(cmd))

    if not success then
      error("Compilation failed.", 0)
    end
  end

  term.setTextColor(colors.green)
  print("Compilation success")
  term.setTextColor(colors.white)
end

build(TCC0, SRC_DIR, TCC1_DIR)
build(TCC1, SRC_DIR, TCC2_DIR)
build(TCC2, SRC_DIR, TCC3_DIR)
