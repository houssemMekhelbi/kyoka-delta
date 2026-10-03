-- Kyoka delta look and feel: cold, off-axis, fractured mirror, violet aura on void.
-- Loaded after futuwwa.lua so these values win; behaviour and binds stay there.
--
-- Corners are sharp (rounding 0): a mirror shard has no radius. The off-axis
-- reading comes from the border gradient at 300° and the shadow thrown down
-- and to the right; focus carries a violet glow (the aura).

local C = {
    void       = "08070D",
    panel      = "100E19",
    raised     = "1B1729",
    violet     = "4A30A6",
    violet_lit = "8B6CF0",
    indigo_lit = "6F8CF5",
    pewter     = "9A92C4",
    ice        = "8FE3F2",
    frost      = "ECEAF5",
}

hl.config({
    general = {
        gaps_in     = 4,   -- 8px between windows
        gaps_out    = 14,
        border_size = 2,
        col = {
            active_border   = {
                colors = { "rgb(" .. C.ice .. ")", "rgb(" .. C.violet_lit .. ")", "rgb(" .. C.violet .. ")" },
                angle  = 300,
            },
            inactive_border = "rgba(" .. C.violet_lit .. "33)",
        },
    },

    decoration = {
        rounding       = 0,

        active_opacity   = 0.88,
        inactive_opacity = 0.72,

        blur = {
            enabled           = true,
            size              = 7,
            passes            = 3,
            vibrancy          = 0.28,
            noise             = 0.015,
            new_optimizations = true,
            popups            = true,
        },

        -- The aura: a violet halo around the focused window only.
        glow = {
            enabled        = true,
            range          = 22,
            render_power   = 3,
            color          = "rgba(" .. C.violet_lit .. "59)",
            color_inactive = "rgba(00000000)",
        },

        -- Off-axis drop: thrown down and to the right, violet-black.
        shadow = {
            enabled        = true,
            range          = 30,
            render_power   = 3,
            offset         = { 8, 12 },
            color          = "rgba(0A0616C8)",
            color_inactive = "rgba(05040A90)",
        },
    },

    group = {
        col = {
            border_active   = "rgb(" .. C.ice .. ")",
            border_inactive = "rgba(" .. C.violet_lit .. "33)",
        },
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = "rgb(" .. C.void .. ")",
    },
})

-- Launcher bind points at the Kyoka launcher; futuwwa.lua binds the Girih one.
hl.unbind("SUPER + D")
hl.bind("SUPER + D",
    hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/kyoka-launcher"),
    { description = "Application launcher" })

-- Terminals draw their own 84% glass so text stays fully opaque.
hl.window_rule({
    name    = "kyoka-terminal-opaque",
    match   = { class = "^(foot|footclient|Alacritty|com.mitchellh.ghostty)$" },
    opacity = "1.0 override 1.0 override",
})

-- Glass for layer surfaces: waybar panels, alert banners, launcher, notifications.
-- ignore_alpha keeps the fully transparent gaps between panels unblurred.
hl.layer_rule({
    name         = "kyoka-bar-glass",
    match        = { namespace = "^hattin-" },
    blur         = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    name         = "kyoka-launcher-glass",
    match        = { namespace = "^launcher$" },
    blur         = true,
    ignore_alpha = 0.1,
})

hl.layer_rule({
    name         = "kyoka-notify-glass",
    match        = { namespace = "^swaync" },
    blur         = true,
    ignore_alpha = 0.1,
})

-- Launcher: floating foot + fzf (~/.local/bin/kyoka-launcher).
hl.window_rule({
    name     = "kyoka-launcher",
    match    = { class = "^kyoka-launcher$" },
    float    = true,
    size     = "780 470",
    center   = true,
    pin      = true,
    opacity  = "1.0 override 1.0 override",
})

-- Taskwarrior popups from the waybar "yawm" module (~/.local/bin/kyoka-yawm):
-- task list on click, one-line quick add on right-click.
hl.window_rule({
    name     = "kyoka-yawm",
    match    = { class = "^kyoka-yawm$" },
    float    = true,
    size     = "820 600",
    center   = true,
    pin      = true,
    opacity  = "1.0 override 1.0 override",
})

hl.window_rule({
    name     = "kyoka-yawm-add",
    match    = { class = "^kyoka-yawm-add$" },
    float    = true,
    size     = "720 240",
    center   = true,
    pin      = true,
    opacity  = "1.0 override 1.0 override",
})

local kyoka_popups = { "kyoka-launcher", "kyoka-yawm", "kyoka-yawm-add" }

-- Close every popup window except those of class `keep`.
-- hl.get_windows matches `class` exactly (no regex), so pass the plain name.
function kyoka_close_popups(keep)
    for _, class in ipairs(kyoka_popups) do
        if class ~= keep then
            for _, w in ipairs(hl.get_windows({ class = class })) do
                hl.dispatch(hl.dsp.window.close({ window = "address:" .. w.address }))
            end
        end
    end
end

function kyoka_close_launcher()
    kyoka_close_popups()
end

-- Close popups as soon as focus moves elsewhere.
hl.on("window.active", function(win)
    kyoka_close_popups(win and win.class)
end)
