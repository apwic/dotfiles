local options = require("options")
local keymaps = require("keymaps")
local wezterm = require("wezterm")
local config = wezterm.config_builder()

options.apply_to_config(config)
keymaps.apply_to_config(config, wezterm.action)
return config
