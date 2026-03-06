local module = {}
local wezterm = require("wezterm")

function module.apply_to_config(config)
	config.color_scheme = "One Dark (Gogh)"
	config.font_size = 13.5
	config.font = wezterm.font("BlexMono Nerd Font")

	config.enable_tab_bar = true
	config.tab_bar_at_bottom = true
	config.hide_tab_bar_if_only_one_tab = false
	config.use_fancy_tab_bar = false
	config.tab_and_split_indices_are_zero_based = false
end

return module
