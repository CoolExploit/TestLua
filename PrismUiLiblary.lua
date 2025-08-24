-- Enhanced Roblox UI Library with Smooth Animations & Modern Design
local UILib = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Enhanced Theme System
local Themes = {
    Dark = {
        bg = Color3.fromRGB(25, 25, 30),
        surface = Color3.fromRGB(35, 35, 42),
        accent = Color3.fromRGB(88, 101, 242),
        accentHover = Color3.fromRGB(71, 82, 196),
        text = Color3.fromRGB(255, 255, 255),
        textDim = Color3.fromRGB(180, 180, 180),
        border = Color3.fromRGB(50, 50, 60),
        success = Color3.fromRGB(87, 242, 135),
        warning = Color3.fromRGB(255, 202, 40)
    },
    Light = {
        bg = Color3.fromRGB(248, 249, 250),
        surface = Color3.fromRGB(255, 255, 255),
        accent = Color3.fromRGB(99, 102, 241),
        accentHover = Color3.fromRGB(79, 70, 229),
        text = Color3.fromRGB(17, 24, 39),
        textDim = Color3.fromRGB(107, 114, 128),
        border = Color3.fromRGB(229, 231, 235),
        success = Color3.fromRGB(34, 197, 94),
        warning = Color3.fromRGB(245, 158, 11)
    }
}
local currentTheme = Themes.Dark

-- Animation Presets
local Animations = {
    fast = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    smooth = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    bounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    elastic = TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
}

-- Enhanced Utility Functions
local function tween(obj, props, animType, callback)
    local tweenInfo = animType or Animations.smooth
    local tweenObj = TweenService:Create(obj, tweenInfo, props)
    if callback then tweenObj.Completed:Connect(callback) end
    tweenObj:Play()
    return tweenObj
end

local function createElement(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function addHoverEffect(obj, hoverColor, originalColor)
    obj.MouseEnter:Connect(function()
        tween(obj, {BackgroundColor3 = hoverColor}, Animations.fast)
    end)
    obj.MouseLeave:Connect(function()
        tween(obj, {BackgroundColor3 = originalColor}, Animations.fast)
    end)
end

local function addRippleEffect(obj)
    obj.MouseButton1Down:Connect(function()
        tween(obj, {Size = obj.Size - UDim2.new(0, 4, 0, 2)}, Animations.fast)
    end)
    obj.MouseButton1Up:Connect(function()
        tween(obj, {Size = obj.Size + UDim2.new(0, 4, 0, 2)}, Animations.bounce)
    end)
end

-- Enhanced Window System
function UILib:Window(title, config)
    local window = {}
    config = config or {}
    
    -- Create main GUI with backdrop
    local screenGui = createElement("ScreenGui", {
        Name = "UILib_" .. title,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, PlayerGui)
    
    -- Backdrop blur effect
    local backdrop = createElement("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0
    }, screenGui)
    
    -- Main window with shadow
    local shadow = createElement("Frame", {
        Size = UDim2.new(0, 506, 0, 406),
        Position = UDim2.new(0.5, -253, 0.5, -203),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0
    }, screenGui)
    createElement("UICorner", {CornerRadius = UDim.new(0, 12)}, shadow)
    
    local main = createElement("Frame", {
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = currentTheme.bg,
        BorderColor3 = currentTheme.border,
        BorderSizePixel = 1
    }, screenGui)
    createElement("UICorner", {CornerRadius = UDim.new(0, 12)}, main)
    
    -- Animated entrance
    main.Size = UDim2.new(0, 0, 0, 0)
    tween(main, {Size = UDim2.new(0, 500, 0, 400)}, Animations.elastic)
    
    -- Enhanced title bar with gradient
    local titleBar = createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = currentTheme.accent,
        BorderSizePixel = 0
    }, main)
    createElement("UICorner", {CornerRadius = UDim.new(0, 12)}, titleBar)
    createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -20),
        BackgroundColor3 = currentTheme.accent,
        BorderSizePixel = 0
    }, titleBar)
    
    -- Title with icon
    local titleContainer = createElement("Frame", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1
    }, titleBar)
    
    local titleText = createElement("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        Text = "  " .. title,
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    }, titleContainer)
    
    -- Enhanced close button
    local closeBtn = createElement("TextButton", {
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -40, 0.5, -17.5),
        Text = "✕",
        TextColor3 = Color3.new(1, 1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 59, 48),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 14
    }, titleBar)
    createElement("UICorner", {CornerRadius = UDim.new(0, 6)}, closeBtn)
    
    addHoverEffect(closeBtn, Color3.fromRGB(255, 69, 58), Color3.fromRGB(255, 59, 48))
    addRippleEffect(closeBtn)
    
    closeBtn.MouseButton1Click:Connect(function()
        tween(main, {Size = UDim2.new(0, 0, 0, 0)}, Animations.smooth, function()
            screenGui:Destroy()
        end)
    end)
    
    -- Enhanced tab system
    local tabBar = createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = currentTheme.surface,
        BorderSizePixel = 0
    }, main)
    
    local tabContainer = createElement("Frame", {
        Size = UDim2.new(1, 0, 1, -85),
        Position = UDim2.new(0, 0, 0, 85),
        BackgroundTransparency = 1
    }, main)
    
    -- Enhanced dragging system
    local dragging = false
    local dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    window.tabs = {}
    window.activeTab = nil
    
    function window:Tab(name)
        local tab = {}
        local tabIndex = #self.tabs + 1
        
        -- Enhanced tab button
        local tabBtn = createElement("TextButton", {
            Size = UDim2.new(0, 120, 1, -10),
            Position = UDim2.new(0, (tabIndex - 1) * 125 + 10, 0, 5),
            Text = name,
            TextColor3 = currentTheme.textDim,
            BackgroundColor3 = currentTheme.border,
            BorderSizePixel = 0,
            Font = Enum.Font.Gotham,
            TextSize = 13
        }, tabBar)
        createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, tabBtn)
        
        local tabIndicator = createElement("Frame", {
            Size = UDim2.new(0, 0, 0, 3),
            Position = UDim2.new(0, 0, 1, -3),
            BackgroundColor3 = currentTheme.accent,
            BorderSizePixel = 0
        }, tabBtn)
        createElement("UICorner", {CornerRadius = UDim.new(0, 2)}, tabIndicator)
        
        -- Tab content with scrolling
        local content = createElement("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, -10),
            Position = UDim2.new(0, 10, 0, 5),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = currentTheme.accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false
        }, tabContainer)
        
        local layout = createElement("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, content)
        
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
        end)
        
        -- Tab switching with animation
        tabBtn.MouseButton1Click:Connect(function()
            -- Deactivate current tab
            if window.activeTab then
                local oldTab = window.activeTab
                tween(oldTab, {Position = UDim2.new(-1, 0, 0, 0)}, Animations.fast, function()
                    oldTab.Visible = false
                    oldTab.Position = UDim2.new(0, 10, 0, 5)
                end)
                
                -- Reset old tab button
                for _, tabData in pairs(window.tabs) do
                    if tabData.content == oldTab then
                        tween(tabData.button, {TextColor3 = currentTheme.textDim, BackgroundColor3 = currentTheme.border})
                        tween(tabData.indicator, {Size = UDim2.new(0, 0, 0, 3)})
                        break
                    end
                end
            end
            
            -- Activate new tab
            content.Position = UDim2.new(1, 0, 0, 5)
            content.Visible = true
            tween(content, {Position = UDim2.new(0, 10, 0, 5)}, Animations.smooth)
            tween(tabBtn, {TextColor3 = currentTheme.text, BackgroundColor3 = currentTheme.surface})
            tween(tabIndicator, {Size = UDim2.new(1, 0, 0, 3)})
            
            window.activeTab = content
        end)
        
        -- Auto-activate first tab
        if tabIndex == 1 then
            content.Visible = true
            tabBtn.TextColor3 = currentTheme.text
            tabBtn.BackgroundColor3 = currentTheme.surface
            tabIndicator.Size = UDim2.new(1, 0, 0, 3)
            window.activeTab = content
        end
        
        -- Enhanced UI Elements
        function tab:Button(text, callback)
            local btn = createElement("TextButton", {
                Size = UDim2.new(1, 0, 0, 35),
                Text = text,
                BackgroundColor3 = currentTheme.accent,
                TextColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                LayoutOrder = #content:GetChildren()
            }, content)
            createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, btn)
            
            addHoverEffect(btn, currentTheme.accentHover, currentTheme.accent)
            addRippleEffect(btn)
            
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end
        
        function tab:Toggle(text, default, callback)
            local frame = createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 40),
                BackgroundColor3 = currentTheme.surface,
                BorderSizePixel = 0,
                LayoutOrder = #content:GetChildren()
            }, content)
            createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, frame)
            
            local label = createElement("TextLabel", {
                Size = UDim2.new(1, -70, 1, 0),
                Position = UDim2.new(0, 15, 0, 0),
                Text = text,
                TextColor3 = currentTheme.text,
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)
            
            local toggleBg = createElement("Frame", {
                Size = UDim2.new(0, 50, 0, 25),
                Position = UDim2.new(1, -60, 0.5, -12.5),
                BackgroundColor3 = default and currentTheme.success or currentTheme.border,
                BorderSizePixel = 0
            }, frame)
            createElement("UICorner", {CornerRadius = UDim.new(0, 15)}, toggleBg)
            
            local toggleKnob = createElement("Frame", {
                Size = UDim2.new(0, 21, 0, 21),
                Position = default and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0
            }, toggleBg)
            createElement("UICorner", {CornerRadius = UDim.new(0, 12)}, toggleKnob)
            
            local state = default
            local button = createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = ""
            }, toggleBg)
            
            button.MouseButton1Click:Connect(function()
                state = not state
                tween(toggleBg, {BackgroundColor3 = state and currentTheme.success or currentTheme.border})
                tween(toggleKnob, {Position = state and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)}, Animations.bounce)
                if callback then callback(state) end
            end)
        end
        
        function tab:Slider(text, min, max, default, callback)
            local frame = createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 60),
                BackgroundColor3 = currentTheme.surface,
                BorderSizePixel = 0,
                LayoutOrder = #content:GetChildren()
            }, content)
            createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, frame)
            
            local label = createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 25),
                Position = UDim2.new(0, 15, 0, 5),
                Text = text .. ": " .. default,
                TextColor3 = currentTheme.text,
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            }, frame)
            
            local sliderBg = createElement("Frame", {
                Size = UDim2.new(1, -30, 0, 6),
                Position = UDim2.new(0, 15, 0, 40),
                BackgroundColor3 = currentTheme.border,
                BorderSizePixel = 0
            }, frame)
            createElement("UICorner", {CornerRadius = UDim.new(0, 3)}, sliderBg)
            
            local sliderFill = createElement("Frame", {
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = currentTheme.accent,
                BorderSizePixel = 0
            }, sliderBg)
            createElement("UICorner", {CornerRadius = UDim.new(0, 3)}, sliderFill)
            
            local sliderKnob = createElement("Frame", {
                Size = UDim2.new(0, 16, 0, 16),
                Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderColor3 = currentTheme.accent,
                BorderSizePixel = 2
            }, sliderBg)
            createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, sliderKnob)
            
            local value = default
            local dragging = false
            
            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    tween(sliderKnob, {Size = UDim2.new(0, 20, 0, 20)}, Animations.fast)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local percent = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                    value = math.floor(min + (max - min) * percent)
                    
                    tween(sliderFill, {Size = UDim2.new(percent, 0, 1, 0)}, Animations.fast)
                    tween(sliderKnob, {Position = UDim2.new(percent, -10, 0.5, -10)}, Animations.fast)
                    label.Text = text .. ": " .. value
                    
                    if callback then callback(value) end
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
                    dragging = false
                    tween(sliderKnob, {Size = UDim2.new(0, 16, 0, 16)}, Animations.bounce)
                end
            end)
        end
        
        table.insert(window.tabs, {content = content, button = tabBtn, indicator = tabIndicator})
        return tab
    end
    
    return window
end

-- Enhanced Notification System
function UILib:Notify(title, message, duration, notifType)
    local typeColors = {
        info = currentTheme.accent,
        success = currentTheme.success,
        warning = currentTheme.warning,
        error = Color3.fromRGB(239, 68, 68)
    }
    
    local notif = createElement("Frame", {
        Size = UDim2.new(0, 0, 0, 80),
        Position = UDim2.new(1, 0, 0, 100 + (#PlayerGui:GetChildren() * 90)),
        BackgroundColor3 = currentTheme.surface,
        BorderColor3 = typeColors[notifType or "info"],
        BorderSizePixel = 2
    }, PlayerGui)
    createElement("UICorner", {CornerRadius = UDim.new(0, 10)}, notif)
    
    -- Slide in animation
    tween(notif, {Size = UDim2.new(0, 320, 0, 80), Position = UDim2.new(1, -340, 0, 100 + (#PlayerGui:GetChildren() * 90))}, Animations.bounce)
    
    -- Content
    createElement("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 15, 0, 10),
        Text = title,
        TextColor3 = currentTheme.text,
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    }, notif)
    
    createElement("TextLabel", {
        Size = UDim2.new(1, -20, 0, 35),
        Position = UDim2.new(0, 15, 0, 35),
        Text = message,
        TextColor3 = currentTheme.textDim,
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    }, notif)
    
    -- Auto dismiss
    wait(duration or 4)
    tween(notif, {Position = UDim2.new(1, 0, 0, notif.Position.Y.Offset)}, Animations.smooth, function()
        notif:Destroy()
    end)
end

function UILib:Theme(themeName)
    if Themes[themeName] then
        currentTheme = Themes[themeName]
    end
end

return UILib
