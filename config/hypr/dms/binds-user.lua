-- Optional per-user keybind overrides (managed by DMS). Loaded after default binds.

-- === Power actions with DMS-styled confirmation (confirmPowerActions plugin) ===
-- binds.lua's default SUPER+SHIFT+E just exits Hyprland with no confirmation;
-- swap it for the confirm dialog, and add reboot/poweroff/suspend equivalents
-- that have no default binding at all.
hl.unbind("SUPER + SHIFT + E")
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("dms ipc call confirmPowerActions logout"))
hl.bind("SUPER + CTRL + X", hl.dsp.exec_cmd("dms ipc call confirmPowerActions reboot"))
hl.bind("SUPER + SHIFT + X", hl.dsp.exec_cmd("dms ipc call confirmPowerActions poweroff"))
hl.bind("SUPER + ALT + X", hl.dsp.exec_cmd("dms ipc call confirmPowerActions suspend"))

-- === App launchers ===
-- binds.lua's default SUPER+O opens the Hyprland overview; reclaim it for
-- Obsidian (overview is still reachable via SUPER+TAB).
hl.unbind("SUPER + O")
hl.bind("SUPER + O", hl.dsp.exec_cmd("flatpak run md.obsidian.Obsidian"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("brave-browser"))
hl.bind("SUPER + D", hl.dsp.exec_cmd("discord"))
hl.bind("SUPER + S", hl.dsp.exec_cmd("steam"))

-- === Screenshots (original key scheme; binds.lua's Print-based ones still work too) ===
hl.bind("ALT + S", hl.dsp.exec_cmd("dms screenshot"))
hl.bind("CTRL + SHIFT + S", hl.dsp.exec_cmd("dms screenshot full"))
hl.bind("SHIFT + ALT + S", hl.dsp.exec_cmd("dms screenshot window"))

-- === Restored from pre-migration config (dropped during the .conf -> .lua conversion) ===
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("dms restart"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("dms ipc call control-center toggle"))
