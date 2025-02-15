-- 36 is the default, but you can choose a different size.
-- Uses the same font as window_frame.font
-- config.pane_select_font_size=36,

local module = {}

function module.apply_to_config(config, act)
	config.keys = {
		-- activate pane selection mode with the default alphabet (labels are "a", "s", "d", "f" and so on)
		{ key = "8", mods = "CTRL", action = act.PaneSelect },
		-- activate pane selection mode with numeric labels
		{
			key = "9",
			mods = "CTRL",
			action = act.PaneSelect({
				alphabet = "1234567890",
			}),
		},
		-- show the pane selection mode, but have it swap the active and selected panes
		{
			key = "0",
			mods = "CTRL",
			action = act.PaneSelect({
				mode = "SwapWithActive",
			}),
		},
	}
end

return module
