# Agent Guidelines for Neovim Configuration

## Commands
- **Lint**: `stylua --check .` (format check)
- **Format**: `stylua .` (auto-format Lua files)
- **Test**: This is a Neovim config - no unit tests, verify by starting `nvim`
- **Dependency management**: Use `:Lazy` in Neovim to manage plugins

## Code Style Guidelines
- **Indentation**: 2 spaces (configured in .stylua.toml)
- **Line width**: 160 characters max
- **Quotes**: Prefer single quotes, auto-selected by stylua
- **Function calls**: No parentheses when possible (`require 'module'` not `require('module')`)
- **Comments**: Use `--` for line comments, `--[[]]` for block comments
- **Tables**: Trailing commas allowed, use consistent formatting
- **Plugin configuration**: Use `opts = {}` for simple setup, `config = function()` for complex setup

## Structure & Imports
- Main config in `init.lua` (single file approach)
- Custom plugins in `lua/custom/plugins/`
- Use `require('module')` for imports
- Plugin specs in lazy.nvim format with dependencies clearly listed

## Naming Conventions
- Files: snake_case (e.g., `custom_plugin.lua`)
- Variables: snake_case
- Functions: snake_case
- Constants: UPPER_SNAKE_CASE
- Keymaps: Use descriptive desc fields for which-key integration

## Error Handling
- Use `pcall()` for potentially failing operations
- Check for plugin availability before configuration
- Use conditional loading with `cond` in plugin specs