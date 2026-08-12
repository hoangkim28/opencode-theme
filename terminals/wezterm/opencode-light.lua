-- OpenCode Light — wezterm color scheme
-- Usage: load in wezterm.lua with:
--   local scheme = dofile(os.getenv("HOME") .. "/.config/wezterm/opencode-light.lua")
--   config.colors = scheme.colors

local colors = {
    foreground = "#211E1E",
    background = "#F1ECEC",
    cursor_bg = "#D68C27",
    cursor_fg = "#F1ECEC",
    cursor_border = "#D68C27",
    selection_fg = "#F1ECEC",
    selection_bg = "#D68C27",
    scrollbar_thumb = "#B7B1B1",
    split = "#B7B1B1",
    ansi = {
        "#4B4646", "#D1383D", "#3D9A57", "#B0851F",
        "#3B7DD8", "#9D7CD8", "#318795", "#211E1E",
    },
    brights = {
        "#8A8585", "#E84A50", "#4FB86C", "#D08F2A",
        "#2968C3", "#B08DE8", "#3D9FB0", "#1A1A1A",
    },
    indexed = {},
    compose_cursor = "#211E1E",
    copy_mode_active_highlight_bg = { Color = "#D68C27" },
    copy_mode_active_highlight_fg = { Color = "#F1ECEC" },
    copy_mode_inactive_highlight_bg = { Color = "#B06F1E" },
    copy_mode_inactive_highlight_fg = { Color = "#F1ECEC" },
    quick_select_label_bg = { Color = "#9D7CD8" },
    quick_select_label_fg = { Color = "#F1ECEC" },
    quick_select_match_bg = { Color = "#D68C27" },
    quick_select_match_fg = { Color = "#F1ECEC" },
}

return { colors = colors }
