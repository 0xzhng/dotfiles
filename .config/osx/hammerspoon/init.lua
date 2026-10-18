-- ChatGPT Auto-Minimize Feature
-- Watches for ChatGPT launching and minimizes it automatically

-- Flag to track if we just launched ChatGPT ourselves
local justLaunchedChatGPT = false

-- Function to minimize ChatGPT
local function minimizeChatGPT()
    local app = hs.application.get("ChatGPT")
    if app then
        local win = app:mainWindow()
        if win and not win:isMinimized() then
            win:minimize()
            hs.alert.show("ChatGPT minimized")
        end
    end
    justLaunchedChatGPT = false
end

-- Watch for applications launching
local appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
    if appName == "ChatGPT" and eventType == hs.application.watcher.launched then
        -- ChatGPT just launched, wait a moment for window to appear then minimize
        hs.timer.doAfter(1.5, minimizeChatGPT)
    end
end)
appWatcher:start()

-- Also check on Hammerspoon reload (in case ChatGPT is already running)
hs.timer.doAfter(2, function()
    local chatGPT = hs.application.get("ChatGPT")
    if chatGPT then
        local win = chatGPT:mainWindow()
        if win and not win:isMinimized() then
            -- Only minimize if it's a fresh launch (window is frontmost)
            -- Don't minimize if user is actively using it
        end
    end
end)

-- Local, real-time MLX Whisper dictation (physical F5 via Karabiner → F20)
mlxDictation = dofile(hs.configdir .. "/mlx-dictation.lua")
