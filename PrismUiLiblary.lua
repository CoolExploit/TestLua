-- Lightweight Roblox UI Library (~190 lines)
local UILib = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Theme configuration
local Themes = {
    Light = {bg = Color3.fromRGB(240,240,240), accent = Color3.fromRGB(0,120,215), text = Color3.fromRGB(0,0,0), secondary = Color3.fromRGB(220,220,220)},
    Dark = {bg = Color3.fromRGB(45,45,45), accent = Color3.fromRGB(100,150,255), text = Color3.fromRGB(255,255,255), secondary = Color3.fromRGB(65,65,65)}
}
local currentTheme = Themes.Dark

-- Utility functions
local function tween(obj, props, duration)
    TweenService:Create(obj, TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad), props):Play()
end

local function createElement(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

-- Main UI Library
function UILib:Window(title)
    local window = {}
    
    -- Create main GUI
    local screenGui = createElement("ScreenGui", {Name = "UILib", ResetOnSpawn = false}, PlayerGui)
    local main = createElement("Frame", {
        Size = UDim2.new(0, 500, 0, 400), Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = currentTheme.bg, BorderSizePixel = 0
    }, screenGui)
    
    createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, main)
    
    -- Title bar
    local titleBar = createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = currentTheme.accent, BorderSizePixel = 0
    }, main)
    createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, titleBar)
    
    local titleText = createElement("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        Text = title, TextColor3 = Color3.new(1,1,1), BackgroundTransparency = 1,
        Font = Enum.Font.SourceSansBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left
    }, titleBar)
    
    -- Close button
    local closeBtn = createElement("TextButton", {
        Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -30, 0, 0),
        Text = "×", TextColor3 = Color3.new(1,1,1), BackgroundTransparency = 1,
        Font = Enum.Font.SourceSansBold, TextSize = 18
    }, titleBar)
    closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)
    
    -- Tab system
    local tabBar = createElement("Frame", {
        Size = UDim2.new(1, 0, 0, 35), Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = currentTheme.secondary, BorderSizePixel = 0
    }, main)
    
    local tabContainer = createElement("Frame", {
        Size = UDim2.new(1, 0, 1, -65), Position = UDim2.new(0, 0, 0, 65),
        BackgroundTransparency = 1
    }, main)
    
    -- Make draggable
    local dragging = false
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local startPos = input.Position
            local startGuiPos = main.Position
            
            local connection
            connection = UserInputService.InputChanged:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                    local delta = input2.Position - startPos
                    main.Position = UDim2.new(startGuiPos.X.Scale, startGuiPos.X.Offset + delta.X, startGuiPos.Y.Scale, startGuiPos.Y.Offset + delta.Y)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input2)
                if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    window.tabs = {}
    window.activeTab = nil
    
    function window:Tab(name)
        local tab = {}
        local tabBtn = createElement("TextButton", {
            Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(0, #self.tabs * 100, 0, 0),
            Text = name, TextColor3 = currentTheme.text, BackgroundColor3 = currentTheme.secondary,
            BorderSizePixel = 0, Font = Enum.Font.SourceSans, TextSize = 14
        }, tabBar)
        
        local content = createElement("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            ScrollBarThickness = 6, CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false
        }, tabContainer)
        createElement("UIListLayout", {Padding = UDim.new(0, 5)}, content)
        
        tabBtn.MouseButton1Click:Connect(function()
            if window.activeTab then window.activeTab.Visible = false end
            content.Visible = true
            window.activeTab = content
        end)
        
        if not window.activeTab then
            content.Visible = true
            window.activeTab = content
        end
        
        -- Tab element functions
        function tab:Button(text, callback)
            local btn = createElement("TextButton", {
                Size = UDim2.new(1, -20, 0, 30), Text = text,
                BackgroundColor3 = currentTheme.accent, TextColor3 = Color3.new(1,1,1),
                BorderSizePixel = 0, Font = Enum.Font.SourceSans, TextSize = 14
            }, content)
            createElement("UICorner", {CornerRadius = UDim.new(0, 4)}, btn)
            btn.MouseButton1Click:Connect(callback or function() end)
            content.CanvasSize = UDim2.new(0, 0, 0, content.UIListLayout.AbsoluteContentSize.Y)
        end
        
        function tab:Toggle(text, default, callback)
            local frame = createElement("Frame", {Size = UDim2.new(1, -20, 0, 30), BackgroundTransparency = 1}, content)
            local label = createElement("TextLabel", {
                Size = UDim2.new(1, -50, 1, 0), Text = text, TextColor3 = currentTheme.text,
                BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
            }, frame)
            local toggle = createElement("TextButton", {
                Size = UDim2.new(0, 40, 0, 20), Position = UDim2.new(1, -40, 0.5, -10),
                BackgroundColor3 = default and currentTheme.accent or currentTheme.secondary,
                Text = "", BorderSizePixel = 0
            }, frame)
            createElement("UICorner", {CornerRadius = UDim.new(0, 10)}, toggle)
            
            local state = default
            toggle.MouseButton1Click:Connect(function()
                state = not state
                tween(toggle, {BackgroundColor3 = state and currentTheme.accent or currentTheme.secondary})
                if callback then callback(state) end
            end)
            content.CanvasSize = UDim2.new(0, 0, 0, content.UIListLayout.AbsoluteContentSize.Y)
        end
        
        function tab:Slider(text, min, max, default, callback)
            local frame = createElement("Frame", {Size = UDim2.new(1, -20, 0, 50), BackgroundTransparency = 1}, content)
            local label = createElement("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20), Text = text .. ": " .. default,
                TextColor3 = currentTheme.text, BackgroundTransparency = 1,
                Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
            }, frame)
            local sliderBg = createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 25),
                BackgroundColor3 = currentTheme.secondary, BorderSizePixel = 0
            }, frame)
            createElement("UICorner", {CornerRadius = UDim.new(0, 10)}, sliderBg)
            local sliderFill = createElement("Frame", {
                Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
                BackgroundColor3 = currentTheme.accent, BorderSizePixel = 0
            }, sliderBg)
            createElement("UICorner", {CornerRadius = UDim.new(0, 10)}, sliderFill)
            
            local value = default
            sliderBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local connection
                    connection = UserInputService.InputChanged:Connect(function(input2)
                        if input2.UserInputType == Enum.UserInputType.MouseMovement then
                            local percent = math.clamp((input2.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                            value = math.floor(min + (max - min) * percent)
                            sliderFill.Size = UDim2.new(percent, 0, 1, 0)
                            label.Text = text .. ": " .. value
                            if callback then callback(value) end
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input2)
                        if input2.UserInputType == Enum.UserInputType.MouseButton1 then
                            connection:Disconnect()
                        end
                    end)
                end
            end)
            content.CanvasSize = UDim2.new(0, 0, 0, content.UIListLayout.AbsoluteContentSize.Y)
        end
        
        function tab:Dropdown(text, options, default, callback)
            local frame = createElement("Frame", {Size = UDim2.new(1, -20, 0, 30), BackgroundTransparency = 1}, content)
            local dropdown = createElement("TextButton", {
                Size = UDim2.new(1, 0, 1, 0), Text = text .. ": " .. default,
                BackgroundColor3 = currentTheme.secondary, TextColor3 = currentTheme.text,
                BorderSizePixel = 0, Font = Enum.Font.SourceSans, TextSize = 14
            }, frame)
            createElement("UICorner", {CornerRadius = UDim.new(0, 4)}, dropdown)
            
            local expanded = false
            dropdown.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    for i, option in ipairs(options) do
                        local optBtn = createElement("TextButton", {
                            Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 1, (i-1) * 25),
                            Text = option, BackgroundColor3 = currentTheme.bg, TextColor3 = currentTheme.text,
                            BorderSizePixel = 0, Font = Enum.Font.SourceSans, TextSize = 12, ZIndex = 10
                        }, dropdown)
                        createElement("UICorner", {CornerRadius = UDim.new(0, 4)}, optBtn)
                        optBtn.MouseButton1Click:Connect(function()
                            dropdown.Text = text .. ": " .. option
                            if callback then callback(option) end
                            for _, child in pairs(dropdown:GetChildren()) do
                                if child:IsA("TextButton") and child ~= dropdown then child:Destroy() end
                            end
                            expanded = false
                        end)
                    end
                else
                    for _, child in pairs(dropdown:GetChildren()) do
                        if child:IsA("TextButton") and child ~= dropdown then child:Destroy() end
                    end
                end
            end)
            content.CanvasSize = UDim2.new(0, 0, 0, content.UIListLayout.AbsoluteContentSize.Y)
        end
        
        function tab:Textbox(text, placeholder, callback)
            local textbox = createElement("TextBox", {
                Size = UDim2.new(1, -20, 0, 30), PlaceholderText = placeholder,
                BackgroundColor3 = currentTheme.secondary, TextColor3 = currentTheme.text,
                BorderSizePixel = 0, Font = Enum.Font.SourceSans, TextSize = 14
            }, content)
            createElement("UICorner", {CornerRadius = UDim.new(0, 4)}, textbox)
            textbox.FocusLost:Connect(function() if callback then callback(textbox.Text) end end)
            content.CanvasSize = UDim2.new(0, 0, 0, content.UIListLayout.AbsoluteContentSize.Y)
        end
        
        function tab:Keybind(text, key, callback)
            local frame = createElement("Frame", {Size = UDim2.new(1, -20, 0, 30), BackgroundTransparency = 1}, content)
            local label = createElement("TextLabel", {
                Size = UDim2.new(1, -60, 1, 0), Text = text, TextColor3 = currentTheme.text,
                BackgroundTransparency = 1, Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left
            }, frame)
            local keyLabel = createElement("TextLabel", {
                Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(1, -50, 0, 0),
                Text = key.Name, TextColor3 = currentTheme.text, BackgroundColor3 = currentTheme.secondary,
                BorderSizePixel = 0, Font = Enum.Font.SourceSans, TextSize = 12
            }, frame)
            createElement("UICorner", {CornerRadius = UDim.new(0, 4)}, keyLabel)
            
            UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == key then if callback then callback() end end
            end)
            content.CanvasSize = UDim2.new(0, 0, 0, content.UIListLayout.AbsoluteContentSize.Y)
        end
        
        table.insert(window.tabs, tab)
        return tab
    end
    
    return window
end

function UILib:Notify(title, text, duration)
    local notif = createElement("Frame", {
        Size = UDim2.new(0, 300, 0, 80), Position = UDim2.new(1, -320, 0, 20),
        BackgroundColor3 = currentTheme.bg, BorderSizePixel = 0
    }, PlayerGui)
    createElement("UICorner", {CornerRadius = UDim.new(0, 8)}, notif)
    
    createElement("TextLabel", {
        Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 5),
        Text = title, TextColor3 = currentTheme.text, BackgroundTransparency = 1,
        Font = Enum.Font.SourceSansBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left
    }, notif)
    
    createElement("TextLabel", {
        Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0, 35),
        Text = text, TextColor3 = currentTheme.text, BackgroundTransparency = 1,
        Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true
    }, notif)
    
    tween(notif, {Position = UDim2.new(1, -320, 0, 20)}, 0.3)
    wait(duration or 3)
    tween(notif, {Position = UDim2.new(1, 0, 0, 20)}, 0.3)
    wait(0.3)
    notif:Destroy()
end

function UILib:Theme(themeName)
    if Themes[themeName] then
        currentTheme = Themes[themeName]
    end
end

return UILib
