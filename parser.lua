local M = {}

local function oneOf(fns)
  local n = #fns

  return function(src)
    for i = 1, n do
      local node, rest = fns[i](src)

      if node then
        return node, rest
      end
    end
  end
end

local function binopParser(next, ...)
  local ops = { ... }
  local pats = {}
  local n = #ops

  for i = 1, #ops do
    local op = ops[i]
    local pat = op:gsub(".", "%%%0")
    table.insert(pats, "^%s*" .. pat .. "()")
  end

  return function(src)
    local node, rest = next(src)
    if not node then return end

    src = rest

    while true do
      local j
      local op

      for i = 1, n do
        j = src:match(pats[i])
        op = ops[i]

        if j then break end
      end
      if not j then break end

      src = src:sub(j)
      local expr, rest = next(src)
      if not expr then return end

      src = rest

      node = {
        ty = "binop",
        op = op,
        lhs = node,
        rhs = expr,
      }
    end

    return node, src
  end
end

-- (<ty> <param>, ...) {
--   <block>
-- }
function M.parseFnBody(src)
  local sParams, bodyStart = src:match(
    "^%s*(%b())%s*{()"
  )
  if not sParams then return end

  sParams = sParams:sub(2, -2)

  local params = {}

  for param in sParams:gmatch("([^,]+),?") do
    local t, n = param:match("(%w+)%s+(%w+)")

    if not t then
      t, n = param:match("(%w+)%s+(%.%.%.)")
    end
    if not t then return end
    
    table.insert(params, {
      typeName = t,
      name = n,
    })
  end

  local body

  src = src:sub(bodyStart)
  body, src = M.parseBlock(src)

  local _, bodyEnd = src:find("^%s*}")
  if not bodyEnd then return end
  src = src:sub(bodyEnd + 1)

  local fn = {}
  fn.ty = "fn"
  fn.params = params
  fn.body = body

  return fn, src
end

-- fn [name](<ty> <param>, ...) {
--   <block>
-- }
function M.parseFnExpr(src)
  local name, j = src:match(
    "^%s*fn%s+(%w+)()"
  )
  if not name then
    j = src:match("^%s*fn()")
    if not j then return end
  end
  src = src:sub(j)

  local node, rest = M.parseFnBody(src)
  if not node then return end

  src = rest  
  node.name = name

  return node, src
end

function M.parseNil(src)
  local j = src:match("^%s*nil()")
  if not j then return end

  src = src:sub(j)

  local node = {}
  node.ty = "nil"

  return node, src
end

function M.parseNumber(src)
  local value, j = src:match("^%s*(%d+)()")
  if not j then return end

  src = src:sub(j)

  local node = {}
  node.ty = "number"
  node.value = value

  return node, src
end

function M.parseBool(src)
  local v, j = src:match("^%s*(true)()")

  if not j then
    v, j = src:match("^%s*(false)()")
  end

  if not j then return end

  src = src:sub(j)

  local node = {}
  node.ty = "bool"
  node.value = v == "true"

  return node, src
end

function M.parseChar(src)
  local start = src:match("^%s*'()")
  if not start then return end
  src = src:sub(start)

  local c = src:sub(1, 1)
  if not c then return end
  if c == "'" then return end
  src = src:sub(2)

  if c == "\\" then
    c = src:sub(1, 1)

    if c == "a" then
      c = "\a"
    elseif c == "b" then
      c = "\b"
    elseif c == "f" then
      c = "\f"
    elseif c == "n" then
      c = "\n"
    elseif c == "r" then
      c = "\r"
    elseif c == "t" then
      c = "\t"
    elseif c == "v" then
      c = "\v"
    elseif c == "\\" then
      c = "\\"
    elseif c == "'" then
      c = "'"
    elseif c == '"' then
      c = '"'
    else
      return
    end

    src = src:sub(2)
  end

  if src:sub(1, 1) ~= "'" then return end
  src = src:sub(2)

  local node = {}
  node.ty = "char"
  node.c = c

  return node, src
end

function M.parseString(src)
  local start = src:match('^%s*"()')
  if not start then return end
  src = src:sub(start)

  local i = 1
  repeat
    local c = src:sub(i, i)

    if c == "\\" then
      i = i + 1
    end

    i = i + 1
  until c == '"'

  local value = src:sub(1, i - 2)

  src = src:sub(i)

  local node = {}
  node.ty = "string"
  node.value = value

  return node, src
end

function M.parseTable(src)
  local tyName, j = src:match("^%s*(%w+)%s*{()")
  if not tyName then return end
  src = src:sub(j)

  local pairs = {}

  while true do
    local key, j = src:match("^%s*(%w+)%s*=()")

    if key then
      src = src:sub(j)
    end

    local expr, rest = M.parseExpr(src)
    if not expr then
      if key then return else break end
    end
    src = rest

    if key then
      pairs[key] = expr
    else
      table.insert(pairs, expr)
    end

    -- try to read a comma
    j = src:match("^%s*,()")
    if not j then break end
    src = src:sub(j)
  end

  j = src:match("^%s*}()")
  if not j then return end
  src = src:sub(j)

  local node = {}
  node.ty = "table"
  node.tyName = tyName
  node.pairs = pairs

  return node, src
end

function M.parseIdent(src)
  local name, j = src:match("^%s*([%w_]+)()")
  if not name then
    name, j = src:match("^%s*(%.%.%.)()")
  end
  if not name then return end

  src = src:sub(j)

  local node = {}
  node.ty = "ident"
  node.name = name

  return node, src
end

function M.parseParens(src)
  local j = src:match("^%s*%(()")
  if not j then return end

  src = src:sub(j)

  local expr, rest = M.parseExpr(src)
  if not expr then return end

  src = rest
  j = src:match("^%s*%)()")
  if not j then return end

  src = src:sub(j)

  return expr, src
end

M.parsePrimary = oneOf {
  M.parseNil,
  M.parseNumber,
  M.parseBool,
  M.parseChar,
  M.parseString,
  M.parseTable,
  M.parseFnExpr,
  M.parseIdent,
  M.parseParens,
}

function M.parseCallArgs(src)
  local j = src:match("^%s*%(()")
  if not j then return end
  src = src:sub(j)

  local args
  args, src = M.parseExprList(src)

  -- read closing paren
  j = src:match("^%s*%)()")
  if not j then return end
  src = src:sub(j)

  return args, src
end

function M.parseIndex(src)
  local expr

  expr, src = M.parsePrimary(src)
  if not expr then return end

  local node = expr

  while true do
    local key, j = src:match("^%s*%.%s*(%w+)()")

    if key then
      src = src:sub(j)
      node = {
        ty = "index",
        expr = node,
        key = key,
      }
    else
      j = src:match("^%s*%[()")
      if j then
        src = src:sub(j)
        key, src = M.parseExpr(src)
        if not key then break end

        j = src:match("^%s*%]()")
        if not j then break end
        src = src:sub(j)

        node = {
          ty = "index",
          expr = node,
          key = key,
        }
      else      
        local args, rest = M.parseCallArgs(src)
        if not args then break end
        src = rest

        node = {
          ty = "call",
          expr = node,
          args = args,
        }
      end
    end
  end

  return node, src
end

function M.parseUnary(src)
  local j, expr

  j = src:match("^%s*%-()")
  if j then
    src = src:sub(j)

    expr, src = M.parseUnary(src)
    if not expr then return end

    local node = {}
    node.ty = "unop"
    node.op = "-"
    node.expr = expr

    return node, src
  end

  j = src:match("^%s*!()")
  if j then
    src = src:sub(j)

    expr, src = M.parseUnary(src)
    if not expr then return end

    local node = {}
    node.ty = "unop"
    node.op = "!"
    node.expr = expr

    return node, src
  end

  j = src:match("^%s*#()")
  if j then
    src = src:sub(j)

    expr, src = M.parseUnary(src)
    if not expr then return end

    local node = {}
    node.ty = "unop"
    node.op = "#"
    node.expr = expr

    return node, src
  end

  return M.parseIndex(src)
end

function M.parseExprList(src, p)
  p = p or M.parseExpr
  local nodes = {}

  while true do
    local node, rest = p(src)
    if not node then break end

    table.insert(nodes, node)
    src = rest

    -- try to read a comma
    j = src:match("^%s*,()")
    if not j then break end
    src = src:sub(j)
  end

  return nodes, src
end

M.parseFactor = binopParser(M.parseUnary, "*", "/")
M.parseTerm = binopParser(M.parseFactor, "+", "-")
M.parseComp = binopParser(M.parseTerm, "==", "!=", ">=", "<=", "<", ">")
M.parseAndOr = binopParser(M.parseComp, "&&", "||")
M.parseExpr = binopParser(M.parseAndOr, "..")

function M.parseNameList(src)
  local names = {}

  while true do
    local name, j = src:match("^%s*(%w+)()")
    if not name then break end
    src = src:sub(j)

    table.insert(names, name)

    -- try to read a comma
    j = src:match("^%s*,()")
    if not j then break end
    src = src:sub(j)
  end

  return names, src
end

function M.parseLet(src)
  local j = src:match("^%s*let%s+()")
  if not j then return end
  src = src:sub(j)

  local names
  names, src = M.parseNameList(src)
  if #names == 0 then return end

  j = src:match("^%s*=()")
  if not j then return end
  src = src:sub(j)

  local exprs
  exprs, src = M.parseExprList(src)
  if #exprs == 0 then return end

  local let = {}
  let.ty = "let"
  let.names = names
  let.exprs = exprs

  return let, src
end

function M.parseLValue(src)
  local expr
  expr, src = M.parseIndex(src)
  if not expr then return end
  if expr.ty == "call" then return end

  return expr, src
end

function M.parseAssignment(src)
  local lvalues
  lvalues, src = M.parseExprList(src, M.parseLValue)
  if #lvalues == 0 then return end

  local j = src:match("^%s*=()")
  if not j then return end
  src = src:sub(j)

  local exprs, rest = M.parseExprList(src)
  if #exprs == 0 then return end

  local node = {}
  node.ty = "assignment"
  node.lvalues = lvalues
  node.exprs = exprs

  return node, rest
end

-- fn <name>(<ty> <param>, ...) {
--   <block>
-- }
function M.parseFnStmt(src)
  local fn
  fn, src = M.parseFnExpr(src)
  if not fn then return end
  if not fn.name then return end

  fn.ty = "fn_stmt"

  return fn, src
end

function M.parseCallStmt(src)
  local node

  node, src = M.parseIndex(src)
  if not node then return end
  if node.ty ~= "call" then return end

  return node, src
end

function M.parseWhile(src)
  local j
  local expr
  local block

  j = src:match("^%s*while()")
  if not j then return end
  src = src:sub(j)

  expr, src = M.parseParens(src)
  if not expr then return end

  j = src:match("^%s*{()")
  if not j then return end
  src = src:sub(j)

  block, src = M.parseBlock(src)

  j = src:match("^%s*}()")
  if not j then return end
  src = src:sub(j)

  local node = {}
  node.ty = "while"
  node.expr = expr
  node.block = block

  return node, src
end

function M.parseIf(src)
  local block
  local expr
  local j

  j = src:match("^%s*if()")
  if not j then return end
  src = src:sub(j)

  expr, src = M.parseParens(src)
  if not expr then return end

  j = src:match("^%s*{()")
  if not j then return end
  src = src:sub(j)

  block, src = M.parseBlock(src)

  j = src:match("^%s*}()")
  if not j then return end
  src = src:sub(j)

  local node = {}
  node.ty = "if"
  node.branches = {
    {
      cond = expr,
      block = block,
    }
  }

  while true do
    j = src:match("^%s*elseif()")
    if not j then break end
    src = src:sub(j)

    expr, src = M.parseParens(src)
    if not expr then return end

    j = src:match("^%s*{()")
    if not j then return end
    src = src:sub(j)

    block, src = M.parseBlock(src)

    j = src:match("^%s*}()")
    if not j then return end
    src = src:sub(j)

    table.insert(node.branches, {
      cond = expr,
      block = block,
    })
  end

  j = src:match("^%s*else()")
  if j then
    src = src:sub(j)

    j = src:match("^%s*{()")
    if not j then return end
    src = src:sub(j)

    block, src = M.parseBlock(src)

    j = src:match("^%s*}()")
    if not j then return end
    src = src:sub(j)

    node["else"] = block
  end

  return node, src
end

function M.parseReturn(src)
  local j = src:match("^%s*return%s+()")
  if not j then return end
  src = src:sub(j)

  local exprs
  exprs, src = M.parseExprList(src)

  local node = {}
  node.ty = "return"
  node.exprs = exprs

  return node, src
end

M.parseStmt = oneOf {
  M.parseLet,
  M.parseFnStmt,
  M.parseWhile,
  M.parseIf,
  M.parseReturn,
  M.parseAssignment,
  M.parseCallStmt,
}

function M.parseBlock(src)
  local ast = {}

  while true do
    local stmt, rest = M.parseStmt(src)
    if not stmt then break end
    src = rest

    table.insert(ast, stmt)

    if stmt.ty == "return" then
      break
    end
  end

  return ast, src
end

return M
