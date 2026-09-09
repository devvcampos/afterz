local Main = {}

-- LoadLibrary is lazy: dispose the previous panel before creating its replacement.
function Main.Start(Config, UI, LoadLibrary, SensoryESP)
    local Environment = (getgenv and getgenv()) or _G
    local Previous = Environment.AFTERMATH_PANEL
    if type(Previous) == "table" and type(Previous.Destroy) == "function" then
        Previous.Destroy()
    end

    local Controller
    local Library
    local ESP
    local Destroyed = false
    local App = { Config = Config }
    function App.Destroy()
        if Destroyed then
            return
        end
        Destroyed = true
        if ESP then
            ESP.Destroy()
        end
        if Controller then
            Controller.Destroy()
        elseif Library then
            Library:Unload()
        end
        if Environment.AFTERMATH_PANEL == App then
            Environment.AFTERMATH_PANEL = nil
        end
    end

    local Success, Result = xpcall(function()
        assert(game:GetService("Players").LocalPlayer, "Aftermath precisa rodar no cliente Roblox")
        Library = LoadLibrary()
        ESP = SensoryESP.Init(Config)
        Controller = UI.Init(Config, Library, App.Destroy, ESP)
        App.Window = Controller.Window
        App.Library = Library
        App.Tabs = Controller.Tabs
        App.ESP = ESP
        if Config.SensoryESP.Enabled then
            ESP.SetEnabled(true)
        end
        return App
    end, function(Message)
        return debug.traceback(tostring(Message), 2)
    end)

    if not Success then
        App.Destroy()
        error("Falha ao abrir Aftermath:\n" .. tostring(Result), 0)
    end

    Environment.AFTERMATH_PANEL = App
    return App
end

return Main
