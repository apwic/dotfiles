-- 36 is the default, but you can choose a different size.
-- Uses the same font as window_frame.font
-- config.pane_select_font_size=36,

local module = {}
local wezterm = require("wezterm")

function module.apply_to_config(config, act)
	wezterm.on("update-right-status", function(window, pane)
		window:set_right_status(window:active_workspace())
	end)

	config.keys = {
		-- -- activate pane selection mode with the default alphabet (labels are "a", "s", "d", "f" and so on)
		-- { key = "8", mods = "CTRL", action = act.PaneSelect },
		-- -- activate pane selection mode with numeric labels
		-- {
		-- 	key = "9",
		-- 	mods = "CTRL",
		-- 	action = act.PaneSelect({
		-- 		alphabet = "1234567890",
		-- 	}),
		-- },
		-- -- show the pane selection mode, but have it swap the active and selected panes
		-- {
		-- 	key = "0",
		-- 	mods = "CTRL",
		-- 	action = act.PaneSelect({
		-- 		mode = "SwapWithActive",
		-- 	}),
		-- },
		{
			key = "Enter",
			mods = "SHIFT",
			action = wezterm.action.SendString("\n"),
		},
		-- Switch to the default workspace
		{
			key = "y",
			mods = "CTRL|SHIFT",
			action = act.SwitchToWorkspace({
				name = "default",
			}),
		},
		-- Switch to a AI workspace
		{
			key = "u",
			mods = "CTRL|SHIFT",
			action = act.SwitchToWorkspace({
				name = "AI",
			}),
		},
		-- Switch to a temp workspace
		{
			key = "i",
			mods = "CTRL|SHIFT",
			action = act.SwitchToWorkspace({
				name = "temp",
			}),
		},
		-- Switch to a zai workspace
		{
			key = "o",
			mods = "CTRL|SHIFT",
			action = act.SwitchToWorkspace({
				name = "zai",
			}),
		},

		-- Show the launcher in fuzzy selection mode and have it list all workspaces
		-- and allow activating one.
		{
			key = "9",
			mods = "ALT",
			action = act.ShowLauncherArgs({
				flags = "FUZZY|WORKSPACES",
			}),
		},
		-- Prompt for a name to use for a new workspace and switch to it.
		{
			key = "W",
			mods = "CTRL|SHIFT",
			action = act.PromptInputLine({
				description = wezterm.format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { AnsiColor = "Fuchsia" } },
					{ Text = "Enter name for new workspace" },
				}),
				action = wezterm.action_callback(function(window, pane, line)
					-- line will be `nil` if they hit escape without entering anything
					-- An empty string if they just hit enter
					-- Or the actual line of text they wrote
					if line then
						window:perform_action(
							act.SwitchToWorkspace({
								name = line,
							}),
							pane
						)
					end
				end),
			}),
		},
	}
end

return module
