local SRC_DIR = shell.resolve("src")
local TCC0 = "/projects/tcc/tcc"
local TCC1_DIR = shell.resolve("target/stage1")
local TCC2_DIR = shell.resolve("target/stage2")
local TCC3_DIR = shell.resolve("target/stage3")
local TCC1 = fs.combine(TCC1_DIR, "main")
local TCC2 = fs.combine(TCC2_DIR, "main")
local TCC3 = fs.combine(TCC3_DIR, "main")

function sh(...)
  print(...)
  if not shell.execute(...) then
    error("Build failed.", 0)
  end
end

sh("craft", "--name", "stage1", "tcc", ...)
sh(
  "craft",
  "--name", "stage2",
  "--tcc", "target/stage1",
  "--ll", "target/stage1",
  "tcc",
  ...
)
sh(
  "craft",
  "--name", "stage3",
  "--tcc", "target/stage2",
  "--ll", "target/stage2",
  "tcc",
  ...
)
sh("diff", "target/stage2", "target/stage3")
sh(
  "craft",
  "--tcc", "target/stage2",
  "--ll", "/bin/ll",
  "runtime",
  ...
)
