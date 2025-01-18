# CHANGELOG

## Unreleased

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
