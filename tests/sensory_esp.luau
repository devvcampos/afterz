-- Run with: luau tests/sensory_esp.luau
-- Tests the adapter lifecycle with a yielding HTTP stub; does not render Roblox UI.
local SensoryESP = require("../src/Integrations/SensoryESP")
local Passed = 0

local function Fixture()
    local F = {
        Queue = {}, Downloads = 0, Compiles = 0, Loads = 0, Unloads = 0,
        Logs = {}, States = {},
        Config = { SensoryESP = {
            Enabled = false, URL = "https://example.test/pinned/ESP.lua",
            Boxes = true, BoxType = "Corner", BoxColor = "cyan", BoxThickness = 1,
            Outlines = true, Names = true, Distance = true, HealthBar = true,
            HealthText = false, Skeleton = false, Chams = false, OffScreenArrows = false,
            TextColor = "white", TextSize = 12, LimitFPS = 60,
        } },
    }
    F.Library = {
        Load = function(_, Config)
            F.Loads += 1
            if F.OnLoad then F.OnLoad() end
            if F.LoadError then error("renderer failed") end
            F.Current = Config
            -- Defaults filled by the real library's DeepMerge.
            F.Current.Outlines.Color = "black"
            F.Current.HealthBar.Gradient = { Enabled = false }
        end,
        GetConfig = function()
            if F.BadConfig then return nil end
            return F.Current
        end,
        Unload = function()
            F.Unloads += 1
            if F.UnloadError then error("unload failed") end
        end,
    }
    F.Runtime = {
        Download = function(URL)
            assert(URL == F.Config.SensoryESP.URL)
            F.Downloads += 1
            if F.OnDownload then F.OnDownload() end
            if F.DownloadError then error("HTTP unavailable") end
            return "library source"
        end,
        Compile = function(Source, Name)
            F.Compiles += 1
            assert(Source == "library source" and Name == "@aftermath/external/sensoryESP")
            if F.CompileError then return nil, "syntax error" end
            return function() return F.Library end
        end,
        Defer = function(Callback) table.insert(F.Queue, Callback) end,
        Warn = function(Message) table.insert(F.Logs, Message) end,
    }
    F.Controller = SensoryESP.Init(F.Config, F.Runtime)
    F.Controller.SetStateChangedCallback(function(State) table.insert(F.States, State) end)
    function F.Run()
        assert(#F.Queue == 1, "expected exactly one worker")
        table.remove(F.Queue, 1)()
    end
    function F.Start()
        assert(F.Controller.SetEnabled(true))
        F.Run()
    end
    return F
end

local function Test(Name, Run)
    Run()
    Passed += 1
    print("PASS " .. Name)
end

Test("disabled by default, no eager network request", function()
    local F = Fixture()
    assert(F.Downloads == 0 and #F.Queue == 0)
    assert(not F.Controller.GetState().Enabled)
end)

Test("one load for repeated enable; player-only API configuration", function()
    local F = Fixture()
    F.Controller.SetEnabled(true)
    F.Controller.SetEnabled(true)
    assert(F.Controller.GetState().Loading)
    F.Run()
    assert(F.Downloads == 1 and F.Loads == 1)
    assert(F.Current.Enabled and F.Current.Players and not F.Current.LocalPlayer)
    assert(next(F.Current.Directories) == nil and not F.Current.Keybind.Enabled)
    assert(type(F.Current.Outlines) == "table" and F.Current.Outlines.Style == "Full")
    assert(F.Current.Chams.Type == "Highlight" and F.Current.Chams.Highlight.FillColor == "cyan")
    assert(F.Current.Distance.Unit == "Studs" and F.Controller.GetState().Enabled)
end)

Test("live updates retain defaults without reload or download", function()
    local F = Fixture()
    F.Start()
    local Current = F.Current
    F.Config.SensoryESP.Boxes = false
    F.Config.SensoryESP.HealthText = true
    F.Config.SensoryESP.Outlines = false
    F.Config.SensoryESP.BoxColor = "red"
    assert(F.Controller.Refresh())
    assert(F.Current == Current and not Current.Boxes and Current.HealthBar.ShowText)
    assert(Current.Outlines.Color == "black" and Current.Outlines.Style == "None")
    assert(Current.HealthBar.Gradient and Current.Skeleton.Color == "red")
    assert(F.Downloads == 1 and F.Loads == 1)
end)

Test("disable unloads and re-enable reuses the downloaded library", function()
    local F = Fixture()
    F.Start()
    F.Controller.SetEnabled(false)
    assert(F.Unloads == 1 and not F.Controller.GetState().Enabled)
    F.Config.SensoryESP.Names = false
    F.Start()
    assert(F.Downloads == 1 and F.Loads == 2 and not F.Current.Names)
    F.Controller.Destroy()
    F.Controller.Destroy()
    assert(F.Unloads == 2 and not F.Controller.SetEnabled(true))
end)

Test("disabled before worker starts never downloads", function()
    local F = Fixture()
    F.Controller.SetEnabled(true)
    F.Controller.SetEnabled(false)
    F.Run()
    assert(F.Downloads == 0 and F.Compiles == 0 and F.Loads == 0)
end)

Test("disable while HTTP is pending never executes downloaded code", function()
    local F = Fixture()
    F.OnDownload = function() coroutine.yield() end
    F.Controller.SetEnabled(true)
    local Worker = coroutine.create(table.remove(F.Queue, 1))
    assert(coroutine.resume(Worker))
    assert(coroutine.status(Worker) == "suspended")
    F.Controller.SetEnabled(false)
    assert(coroutine.resume(Worker))
    assert(F.Compiles == 0 and F.Loads == 0 and not F.Controller.GetState().Enabled)
end)

Test("destroy while HTTP is pending cannot resurrect the ESP", function()
    local F = Fixture()
    F.OnDownload = function() coroutine.yield() end
    F.Controller.SetEnabled(true)
    local Worker = coroutine.create(table.remove(F.Queue, 1))
    assert(coroutine.resume(Worker))
    F.Controller.Destroy()
    local Count = #F.States
    assert(coroutine.resume(Worker))
    assert(F.Compiles == 0 and F.Loads == 0 and #F.States == Count)
    assert(F.Controller.GetState().Destroyed and not F.Controller.GetState().Loading)
end)

Test("rapid on/off/on during HTTP follows latest state and settings", function()
    local F = Fixture()
    F.OnDownload = function()
        F.Controller.SetEnabled(false)
        F.Controller.SetEnabled(true)
        F.Config.SensoryESP.Skeleton = true
    end
    F.Start()
    assert(F.Downloads == 1 and #F.Queue == 0 and F.Current.Skeleton.Enabled)
end)

Test("destroy during library initialization cleans the candidate", function()
    local F = Fixture()
    F.OnLoad = function() F.Controller.Destroy() end
    F.Start()
    assert(F.Unloads == 1 and not F.Controller.GetState().Enabled)
end)

Test("HTTP failure resets toggle, reports error and allows retry", function()
    local F = Fixture()
    F.DownloadError = true
    F.Start()
    local State = F.Controller.GetState()
    assert(State.Error and not State.Enabled and not State.Requested and not State.Loading)
    assert(#F.Logs > 0)
    F.DownloadError = false
    F.Start()
    assert(F.Controller.GetState().Enabled and not F.Controller.GetState().Error)
end)

Test("compile failure remains disabled", function()
    local F = Fixture()
    F.CompileError = true
    F.Start()
    assert(F.Controller.GetState().Error and F.Loads == 0)
end)

Test("incompatible remote API is rejected and cleaned", function()
    local F = Fixture()
    F.Library.GetConfig = nil
    F.Start()
    assert(F.Controller.GetState().Error and F.Loads == 0 and F.Unloads == 1)
end)

Test("renderer initialization failure is reported and cleaned", function()
    local F = Fixture()
    F.LoadError = true
    F.Start()
    assert(F.Controller.GetState().Error and not F.Config.SensoryESP.Enabled and F.Unloads == 1)
end)

Test("bad live config stops the renderer and reports the failure", function()
    local F = Fixture()
    F.Start()
    F.BadConfig = true
    assert(not F.Controller.Refresh())
    assert(F.Controller.GetState().Error and not F.Config.SensoryESP.Enabled and F.Unloads == 1)
end)

Test("unload failure is surfaced", function()
    local F = Fixture()
    F.Start()
    F.UnloadError = true
    assert(not F.Controller.SetEnabled(false))
    assert(F.Controller.GetState().Error)
end)

print(string.format("%d lifecycle tests passed (mock runtime; no Roblox rendering).", Passed))
