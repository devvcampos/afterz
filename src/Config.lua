-- Configuracao exclusiva do Aftermath.
return {
    Project = {
        Name = "Aftermath",
        Version = "0.2.0",
    },
    UI = {
        Keybind = "LeftAlt",
        ConfigFolder = "aftermath/Configs",
        AccentColor = Color3.fromRGB(17, 238, 253),
        Size = "Default",
        Watermark = true,
    },
    SensoryESP = {
        Enabled = false,
        -- Revisao conferida da mesma biblioteca remota utilizada pelo Newz.
        URL = "https://raw.githubusercontent.com/rthusrtghdfhtyjkehrfh/sensoryESP/0e161be44ea40bbe215c82051a18258982ac47b9/ESP.lua",
        Boxes = true,
        BoxType = "Corner",
        BoxColor = Color3.fromRGB(17, 238, 253),
        BoxThickness = 1,
        Outlines = true,
        Names = true,
        Distance = true,
        HealthBar = true,
        HealthText = false,
        Skeleton = false,
        Chams = false,
        OffScreenArrows = false,
        TextColor = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        LimitFPS = 60,
    },
}
