# CHANGELOG

## Unreleased

## tcc 0.3.0

- feat!: add `--emit link` (new default)
- feat!: `tcc` now outputs to a file by default
- feat: `tcc` now accepts multiple inputs and uses `ll` to link them
- feat: `tcc` links programs with a runtime found in `/lib/tcrt.lua`
- feat: add `-c`, an alias for `--emit lua`
- feat: implement `continue` statements
- feat: implement `run` statements
- feat: improve generated code quality by emitting less string literals

## tcc 0.2.2

- fix: crash when missing the `)` in a function call inside a block

## tcc 0.2.1

- feat: add `for` and `for..in` loop statements
- fix: crash when missing `any` in a function call table argument
- fix: declarations in a `while` may leak into parent scope

## tcc 0.2.0

- feat!: add reserved keyword `in`
- feat: new error message when a reserved keyword is used as an identifier
- feat: support hex literals
- fix: crash when missing `{` after an `if` condition
- fix: crash when missing `fn` or `let` after `pub`
- fix: functions unable to call themselves
- fix: crash when parsing malformed expression `{}`
- fix: crash when parsing parameters without a type
- fix: parenthesised expressions not taking priority

## tcc 0.1.2

- feat: function parameters can now have a type (will be required later)
- feat: break statement
- feat: parentheses support in expressions
- feat: `--version`/`-v` flag to print compiler version

## tcc 0.1.1

- i forgor (bug fixes?)

## tcc 0.1.0

- first version able to compile itself

## tcc 0.0.1

- initial compiler written in lua
