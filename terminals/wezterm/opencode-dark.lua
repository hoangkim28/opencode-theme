-- OpenCode Dark — wezterm color scheme
-- Usage: load in wezterm.lua with:
--   local scheme = dofile(os.getenv("HOME") .. "/.config/wezterm/opencode-dark.lua")
--   config.colors = scheme.colors

local colors = {
    foreground = "#CFCECD",
    background = "#211E1E",
    cursor_bg = "#FAB283",
    cursor_fg = "#211E1E",
    cursor_border = "#FAB283",
    selection_fg = "#211E1E",
    selection_bg = "#FAB283",
    scrollbar_thumb = "#4B4646",
    split = "#4B4646",
    ansi = {
        "#2A2626", "#E06C75", "#7FD88F", "#E5C07B",
        "#5C9CF5", "#9D7CD8", "#56B6C2", "#CFCECD",
    },
    brights = {
        "#656363", "#FF8A93", "#9BE8A7", "#F2D291",
        "#7FB0FF", "#BDA0E8", "#74CBD4", "#E9E8E7",
    },
    indexed = {},
    compose_cursor = "#E9E8E7",
    copy_mode_active_highlight_bg = { Color = "#FAB283" },
    copy_mode_active_highlight_fg = { Color = "#211E1E" },
    copy_mode_inactive_highlight_bg = { Color = "#D98A5E" },
    copy_mode_inactive_highlight_fg = { Color = "#211E1E" },
    quick_select_label_bg = { Color = "#9D7CD8" },
    quick_select_label_fg = { Color = "#211E1E" },
    quick_select_match_bg = { Color = "#FAB283" },
    quick_select_match_fg = { Color = "#211E1E" },
}

return { colors = colors }
