-- OpenCode Light — wezterm color scheme
-- Usage: load in wezterm.lua with:
--   local scheme = dofile(os.getenv("HOME") .. "/.config/wezterm/opencode-light.lua")
--   config.colors = scheme.colors

local colors = {
    foreground = "#211E1E",
    background = "#F1ECEC",
    cursor_bg = "#D68C27",
    cursor_fg = "#211E1E",
    cursor_border = "#D68C27",
    selection_fg = "#211E1E",
    selection_bg = "#D68C27",
    scrollbar_thumb = "#B7B1B1",
    split = "#B7B1B1",
    ansi = {
        "#4B4646", "#B52A30", "#257A3E", "#7A5B00",
        "#2968C3", "#7651B5", "#1E6E79", "#211E1E",
    },
    brights = {
        "#6B6666", "#B52A30", "#257A3E", "#7A5B00",
        "#2968C3", "#7651B5", "#1E6E79", "#1A1A1A",
    },
    indexed = {},
    compose_cursor = "#211E1E",
    copy_mode_active_highlight_bg = { Color = "#D68C27" },
    copy_mode_active_highlight_fg = { Color = "#211E1E" },
    copy_mode_inactive_highlight_bg = { Color = "#8A5200" },
    copy_mode_inactive_highlight_fg = { Color = "#F1ECEC" },
    quick_select_label_bg = { Color = "#7651B5" },
    quick_select_label_fg = { Color = "#F1ECEC" },
    quick_select_match_bg = { Color = "#D68C27" },
    quick_select_match_fg = { Color = "#211E1E" },
}

return { colors = colors }
