-- Adaptador da API sensoryESP: Load(config), GetConfig() e Unload().
-- A biblioteca enumera Players:GetPlayers() e acompanha Player.Character.
local SensoryESP = {}

local function Merge(Target, Source)
    for Key, Value in pairs(Source) do
        if type(Value) == "table" then
            if type(Target[Key]) ~= "table" then
                Target[Key] = {}
            end
            Merge(Target[Key], Value)
        else
            Target[Key] = Value
        end
    end
end

function SensoryESP.BuildConfig(Settings)
    return {
        Enabled = true,
        Players = true,
        LocalPlayer = false,
        Directories = {},
        Keybind = { Enabled = false },
        LimitFPS = Settings.LimitFPS,
        DynamicBoxes = true,
        DynamicBoxesCheap = true,
        Boxes = Settings.Boxes,
        BoxType = Settings.BoxType,
        BoxColor = Settings.BoxColor,
        BoxThickness = Settings.BoxThickness,
        Outlines = { Style = Settings.Outlines and "Full" or "None" },
        Names = Settings.Names,
        TextColor = Settings.TextColor,
        TextSize = Settings.TextSize,
        TextOutline = Settings.Outlines,
        -- Studs evita presumir uma escala de metros especifica do jogo.
        Distance = { Enabled = Settings.Distance, Unit = "Studs", Ending = " studs" },
        HealthBar = { Enabled = Settings.HealthBar, ShowText = Settings.HealthText },
        Skeleton = { Enabled = Settings.Skeleton, Color = Settings.BoxColor },
        Chams = {
            Enabled = Settings.Chams,
            Type = "Highlight",
            Highlight = {
                FillColor = Settings.BoxColor,
                FillTransparency = 0.65,
                OutlineColor = Settings.BoxColor,
                OutlineTransparency = 0,
                VisibleCheck = false,
            },
        },
        OffScreenArrows = { Enabled = Settings.OffScreenArrows, Color = Settings.BoxColor },
    }
end

function SensoryESP.Init(Config, Dependencies)
    Dependencies = Dependencies or {}
    local Settings = Config.SensoryESP
    local Download = Dependencies.Download or function(URL)
        return game:HttpGet(URL)
    end
    local Compile = Dependencies.Compile or loadstring
    local Defer = Dependencies.Defer or task.defer
    local Log = Dependencies.Warn or warn
    local Library
    local Active = false
    local Loading = false
    local Destroyed = false
    local LastError
    local StateChanged
    local Controller = {}

    function Controller.GetState()
        return {
            Enabled = Active,
            Requested = Settings.Enabled == true,
            Loading = Loading,
            Error = LastError,
            Destroyed = Destroyed,
        }
    end

    local function Notify()
        if not Destroyed and StateChanged then
            local OK, Message = pcall(StateChanged, Controller.GetState())
            if not OK then
                Log("[Aftermath/UI] " .. tostring(Message))
            end
        end
    end

    local function Unload(Candidate)
        if type(Candidate) == "table" and type(Candidate.Unload) == "function" then
            local OK, Message = pcall(Candidate.Unload, Candidate)
            if not OK then
                Log("[Aftermath/sensoryESP] Falha no encerramento: " .. tostring(Message))
                return false, tostring(Message)
            end
        end
        return true
    end

    local function Fail(Message)
        Active = false
        Settings.Enabled = false
        LastError = tostring(Message)
        Log("[Aftermath/sensoryESP] " .. LastError)
        Notify()
        return false, LastError
    end

    function Controller.Refresh()
        if Destroyed then
            return false, "Integracao encerrada"
        end
        if not Active then
            -- As preferencias serao aplicadas quando o carregamento terminar.
            return true, "Preferencias preparadas"
        end
        local OK, Message = pcall(function()
            local Current = Library:GetConfig()
            assert(type(Current) == "table", "GetConfig nao retornou uma tabela")
            -- GetConfig devolve a configuracao usada pelo renderizador em tempo real.
            Merge(Current, SensoryESP.BuildConfig(Settings))
            Current.Directories = {}
        end)
        if not OK then
            Unload(Library)
            Library = nil
            return Fail(Message)
        end
        LastError = nil
        Notify()
        return true, "Preferencias aplicadas"
    end

    function Controller.SetEnabled(Value)
        if Destroyed then
            return false, "Integracao encerrada"
        end
        Settings.Enabled = Value == true
        LastError = nil
        if not Settings.Enabled then
            local OK, Message = true, nil
            if Active then
                OK, Message = Unload(Library)
            end
            Active = false
            if not OK then
                Library = nil
                return Fail(Message)
            end
            Notify()
            return true
        end
        if Active then
            return Controller.Refresh()
        end
        if Loading then
            Notify()
            return true
        end

        Loading = true
        Notify()
        Defer(function()
            local Candidate = Library
            local function Wanted()
                return not Destroyed and Settings.Enabled == true
            end
            local OK, Message = xpcall(function()
                if not Wanted() then
                    return
                end
                if not Candidate then
                    assert(type(Compile) == "function", "loadstring indisponivel no executor")
                    local Source = Download(Settings.URL)
                    -- Um download pendente nao pode reabrir um painel encerrado.
                    if not Wanted() then
                        return
                    end
                    assert(type(Source) == "string" and #Source > 0, "Resposta vazia da biblioteca")
                    local Chunk, CompileError = Compile(Source, "@aftermath/external/sensoryESP")
                    assert(type(Chunk) == "function", tostring(CompileError))
                    Candidate = Chunk()
                    assert(type(Candidate) == "table", "sensoryESP nao retornou uma tabela")
                    for _, Method in ipairs({ "Load", "GetConfig", "Unload" }) do
                        assert(type(Candidate[Method]) == "function", "sensoryESP sem metodo " .. Method)
                    end
                end
                if not Wanted() then
                    return
                end
                Candidate:Load(SensoryESP.BuildConfig(Settings))
                if Wanted() then
                    Library = Candidate
                    Active = true
                end
            end, function(Error)
                return tostring(Error)
            end)

            Loading = false
            if not Active then
                Unload(Candidate)
                Library = nil
            end
            if not OK and not Destroyed and Settings.Enabled then
                Fail(Message)
            else
                Notify()
            end
        end)
        return true
    end

    function Controller.SetStateChangedCallback(Callback)
        assert(Callback == nil or type(Callback) == "function", "Callback invalido")
        StateChanged = Callback
        Notify()
    end

    function Controller.Destroy()
        if Destroyed then
            return
        end
        Destroyed = true
        Settings.Enabled = false
        StateChanged = nil
        if Active then
            Unload(Library)
        end
        Active = false
        Library = nil
    end

    return Controller
end

return SensoryESP
