local M = {}

local gen = {}

function gen.fn(h, node)
  if node.name then
    h:write("function ")
    h:write(node.name)
  else
    h:write("function")
  end
  h:write("(")
  for i = 1, #node.params do
    h:write(node.params[i].name)
    if i ~= #node.params then
      h:write(",")
    end
  end
  h:write(")")
  M.genBlock(h, node.body)
  h:write("end")
end

function gen.fn_stmt(h, node)
  h:write("local ")
  gen.fn(h, node)
end

function gen.let(h, node)
  h:write("local ")
  for i = 1, #node.names do
    if i > 1 then
      h:write(",")
    end
    h:write(node.names[i])
  end
  h:write("=")
  for i = 1, #node.exprs do
    if i > 1 then
      h:write(",")
    end
    gen[node.exprs[i].ty](h, node.exprs[i])
  end
end

gen["nil"] = function(h, node)
  h:write("nil")
end

function gen.number(h, node)
  h:write(node.value)
end

function gen.bool(h, node)
  if node.value then
    h:write("true")
  else
    h:write("false")
  end
end

function gen.char(h, node)
  local code = node.c:byte()

  h:write(tostring(code))
end

function gen.string(h, node)
  h:write('"')
  h:write(node.value)
  h:write('"')
end

function gen.table(h, node)
  h:write("{")
  for k, v in pairs(node.pairs) do
    h:write("[")
    h:write(string.format("%q", k))
    h:write("]=")
    gen[v.ty](h, v)
    h:write(",")
  end
  h:write("}")
end

function gen.index(h, node)
  gen[node.expr.ty](h, node.expr)
  h:write("[")
  if type(node.key) == "string" then
    h:write(string.format("%q", node.key))
  else
    gen[node.key.ty](h, node.key)
  end
  h:write("]")
end

function gen.assignment(h, node)
  for i = 1, #node.lvalues do
    if i > 1 then
      h:write(",")
    end
    gen[node.lvalues[i].ty](h, node.lvalues[i])
  end
  h:write("=")
  for i = 1, #node.exprs do
    if i > 1 then
      h:write(",")
    end
    gen[node.exprs[i].ty](h, node.exprs[i])
  end
end

function gen.call(h, node)
  gen[node.expr.ty](h, node.expr)
  h:write("(")
  for i = 1, #node.args do
    local arg = node.args[i]
    if i > 1 then
      h:write(",")
    end
    gen[arg.ty](h, arg)
  end
  h:write(")")
end

function gen.ident(h, node)
  h:write(node.name)
end

function gen.unop(h, node)
  if node.op == "!" then
    h:write("not ")
  else
    h:write(node.op)
  end
  gen[node.expr.ty](h, node.expr)
end

function gen.binop(h, node)
  h:write("(")
  gen[node.lhs.ty](h, node.lhs)
  if node.op == "!=" then
    h:write("~=")
  elseif node.op == "&&" then
    h:write(" and ")
  elseif node.op == "||" then
    h:write(" or ")
  else
    h:write(node.op)
  end
  gen[node.rhs.ty](h, node.rhs)
  h:write(")")
end

gen["while"] = function(h, node)
  h:write("while ")
  gen[node.expr.ty](h, node.expr)
  h:write(" do ")
  M.genBlock(h, node.block)
  h:write("end")
end

gen["if"] = function(h, node)
  h:write("if ")
  gen[node.branches[1].cond.ty](h, node.branches[1].cond)
  h:write(" then ")
  M.genBlock(h, node.branches[1].block)
  for i = 2, #node.branches do
    h:write("elseif ")
    gen[node.branches[i].cond.ty](h, node.branches[i].cond)
    h:write(" then ")
    M.genBlock(h, node.branches[i].block)
  end
  if node["else"] then
    h:write("else ")
    M.genBlock(h, node["else"])
  end
  h:write("end")
end

gen["return"] = function(h, node)
  if #node.exprs > 0 then
    h:write("return ")
    for i = 1, #node.exprs do
      if i > 1 then
        h:write(",")
      end
      gen[node.exprs[i].ty](h, node.exprs[i])
    end
  else
    h:write("return")
  end
end

function M.genBlock(h, block)
  for i = 1, #block do
    local node = block[i]

    gen[node.ty](h, node)
    h:write(";")
  end
end

return M
