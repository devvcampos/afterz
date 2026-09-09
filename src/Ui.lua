-- Painel independente, montado com a biblioteca visual usada pelo Newz.
-- Controles visuais e integracao opcional sensoryESP.
local UI = {}

function UI.Init(Config, Library, OnClose, ESP)
    local Player = game:GetService("Players").LocalPlayer
    assert(Player, "UI precisa ser inicializada no cliente")
    assert(type(Library.CreateWindow) == "function", "Biblioteca de interface invalida")

    Library.UnloadEnabled = true
    Library.AccentColor = Config.UI.AccentColor

    local Window = Library:CreateWindow({
        Name = Config.Project.Name,
        Content = "Painel  /  v" .. Config.Project.Version,
        Size = Library.Scales[Config.UI.Size] or Library.Scales.Default,
        ConfigFolder = Config.UI.ConfigFolder,
        Enable3DRenderer = false,
        Keybind = Config.UI.Keybind,
    })
    Window:SetAccount({ Username = Player.DisplayName, Expires = "DEV" })

    local Watermark = Window:Watermark()
    Watermark:AddBlock("eye", Config.Project.Name)
    Watermark:AddBlock("user", Player.Name)
    Watermark:SetRender(Config.UI.Watermark)

    local Tabs = {}
    Tabs.Home = Window:AddTab({ Name = "Início", Icon = "eye", Type = "Double" })
    local Welcome = Tabs.Home:AddSection({ Name = "Aftermath", Position = "left" })
    Welcome:AddLabel("Bem-vindo, " .. Player.DisplayName, true)
    Welcome:AddLabel("Seu novo painel está pronto.", true)
    Welcome:AddLabel("Versão " .. Config.Project.Version, true)

    local Navigation = Tabs.Home:AddSection({ Name = "Painel", Position = "right" })
    local KeyHint = Navigation:AddLabel("Abrir / ocultar: " .. Config.UI.Keybind, true)
    Navigation:AddLabel("Arraste o cabeçalho para mover.", true)
    Navigation:AddLabel("Personalize em Configurações.", true)

    Tabs.Game = Window:AddTab({ Name = "Jogo", Icon = "crosshairs", Type = "Double" })
    local ESPSettings = Config.SensoryESP
    local GameSection = Tabs.Game:AddSection({ Name = "sensoryESP", Position = "left" })
    local ESPStatus = GameSection:AddLabel("ESP: desligado", true)
    GameSection:AddLabel("Origem: Players / Character", true)
    local Syncing = false
    local EnabledToggle = GameSection:AddLabel("Ativar ESP"):AddToggle({
        Flag = "aftermath_esp_enabled",
        Default = ESPSettings.Enabled,
        Callback = function(Value)
            if not Syncing then
                ESP.SetEnabled(Value)
            end
        end,
    })
    ESP.SetStateChangedCallback(function(State)
        if State.Error then
            ESPStatus:SetText("ESP: erro (detalhes no F9)")
        elseif State.Loading and State.Requested then
            ESPStatus:SetText("ESP: carregando...")
        elseif State.Enabled then
            ESPStatus:SetText("ESP: ativo")
        else
            ESPStatus:SetText("ESP: desligado")
        end
        if EnabledToggle:GetValue() ~= State.Requested then
            Syncing = true
            EnabledToggle:SetValue(State.Requested)
            Syncing = false
        end
    end)

    local function AddESPToggle(Section, Name, Key)
        Section:AddLabel(Name):AddToggle({
            Flag = "aftermath_esp_" .. Key,
            Default = ESPSettings[Key],
            Callback = function(Value)
                ESPSettings[Key] = Value
                ESP.Refresh()
            end,
        })
    end
    AddESPToggle(GameSection, "Caixas", "Boxes")
    AddESPToggle(GameSection, "Nomes", "Names")
    AddESPToggle(GameSection, "Distância (studs)", "Distance")
    AddESPToggle(GameSection, "Barra de vida", "HealthBar")
    AddESPToggle(GameSection, "Valor da vida", "HealthText")
    AddESPToggle(GameSection, "Esqueleto", "Skeleton")
    AddESPToggle(GameSection, "Destaque (chams)", "Chams")
    AddESPToggle(GameSection, "Setas fora da tela", "OffScreenArrows")

    local Appearance = Tabs.Game:AddSection({ Name = "Aparência", Position = "right" })
    AddESPToggle(Appearance, "Contornos", "Outlines")
    Appearance:AddLabel("Estilo da caixa"):AddDropdown({
        Flag = "aftermath_esp_box_type",
        Default = ESPSettings.BoxType,
        Values = { "Normal", "Corner", "Circle" },
        Multi = false,
        Callback = function(Value)
            ESPSettings.BoxType = Value
            ESP.Refresh()
        end,
    })
    local function AddESPColor(Name, Key)
        Appearance:AddLabel(Name):AddColorPicker({
            Flag = "aftermath_esp_" .. Key,
            Default = ESPSettings[Key],
            Callback = function(Value)
                ESPSettings[Key] = Value
                ESP.Refresh()
            end,
        })
    end
    AddESPColor("Cor do ESP", "BoxColor")
    AddESPColor("Cor dos nomes", "TextColor")
    local function AddESPSlider(Name, Key, Min, Max)
        Appearance:AddLabel(Name):AddSlider({
            Flag = "aftermath_esp_" .. Key,
            Default = ESPSettings[Key],
            Min = Min,
            Max = Max,
            Rounding = 0,
            Callback = function(Value)
                ESPSettings[Key] = Value
                ESP.Refresh()
            end,
        })
    end
    AddESPSlider("Espessura", "BoxThickness", 1, 3)
    AddESPSlider("Tamanho do nome", "TextSize", 10, 20)
    AddESPSlider("FPS do ESP", "LimitFPS", 15, 120)
    Appearance:AddLabel("Seu personagem é ignorado.", true)

    Tabs.Settings = Window:AddTab({ Name = "Configurações", Icon = "gear", Type = "Double" })
    local Interface = Tabs.Settings:AddSection({ Name = "Interface", Position = "left" })
    Interface:AddLabel("Marca d'água"):AddToggle({
        Flag = "aftermath_ui_watermark",
        Default = Config.UI.Watermark,
        Callback = function(Value)
            Config.UI.Watermark = Value
            Watermark:SetRender(Value)
        end,
    })
    Interface:AddLabel("Tecla do menu"):AddKeybind({
        Flag = "aftermath_ui_menu_key",
        Default = Config.UI.Keybind,
        Callback = function(Value)
            Config.UI.Keybind = Value
            Window.Keybind = Value
            KeyHint:SetText("Abrir / ocultar: " .. tostring(Value))
        end,
    })
    Interface:AddLabel("Tamanho"):AddDropdown({
        Flag = "aftermath_ui_size",
        Default = Config.UI.Size,
        Values = { "Small", "Default", "Large" },
        Multi = false,
        Callback = function(Value)
            if Library.Scales[Value] then
                Config.UI.Size = Value
                Window:SetSize(Library.Scales[Value])
            end
        end,
    })

    local Session = Tabs.Settings:AddSection({ Name = "Sessão", Position = "right" })
    Session:AddLabel("Salve suas preferências no topo.", true)
    Session:AddButton({
        Name = "Ocultar painel",
        Callback = function()
            Window:ToggleInterface()
        end,
    })
    Session:AddButton({
        Name = "Encerrar painel",
        Callback = OnClose,
    })

    local Controller = { Window = Window, Tabs = Tabs }
    local Destroyed = false
    function Controller.Destroy()
        if Destroyed then
            return
        end
        Destroyed = true
        ESP.SetStateChangedCallback(nil)
        Library:Unload()
    end
    return Controller
end

return UI
