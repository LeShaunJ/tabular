# Changelog

## 0.2.1

- **ci**: include `codacy` quality scans
- **refactor**(test): swap for readability
- **chore**(quality): correct `Naming/BlockParameterName`
- **chore**(quality): correct `Lint/Formatting`
- **chore**(quality): correct `Naming/BlockParameterName`
- **chore**(quality): correct `Performance/MinMaxAfterMap`
- **chore**(quality): correct `Lint/MissingBlockArgument`
- **chore**(quality): ignore `Lint/UselessAssign` for `ECR` variables

## 0.2.0

- **docs**: update and tweak
- **ci**: include tags in tests
- **feat**: provide `relayer` & `installer` completer method definers
- **feat**: support `#relay` functionality to hand over full completion back to the shell
- **feat**(habit): expose `@words` in receiver context
- **feat**: provide `macro define` to create a `form` as a... function ([0 ]_[0 ])
- **feat**(habit): support variadic `aliases`
- **fix**(directable): make public
- **fix**(install?): use correct `prompt` reference
- **refactor**(habit)!: privatize `alias Replier`
- **refactor**(habit): use `macro` for context building
- **refactor**(habit): internal naming and private functionality, explicit typing
- **refactor**: extend `self` instead of `self.*` in module
- **refactor**: change `args` to `words`
- **style**: reformat comments; fix typos; remove useless log messages

## 0.1.0

- **build**: mimic functionality of [`go-cobra`](https://github.com/spf13/cobra) completions
- **include**: basic documentation
- **todo**: add tests
- **todo**: support `powershell` (?)
