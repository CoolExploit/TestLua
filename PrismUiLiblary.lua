-- PrismUI - Professional Roblox UI Library
-- Version 1.0 | Glassmorphism Design | 350 Lines Optimized

local PrismUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Theme System
PrismUI.Themes = {
    Dark = {
        Primary = Color3.fromRGB(15, 15, 20),
        Secondary = Color3.fromRGB(25, 25, 35),
        Accent = Color3.fromRGB(100, 150, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Border = Color3.fromRGB(50, 50, 70),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60)
    },
    Light = {
        Primary = Color3.fromRGB(240, 240, 245),
        Secondary = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(59, 130, 246),
        Text = Color3.fromRGB(30, 30, 30),
        TextSecondary = Color3.fromRGB(100, 100, 100),
        Border = Color3.fromRGB(200, 200, 220),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(245, 158, 11),
        Error = Color3.fromRGB(239, 68, 68)
    }
}

PrismUI.CurrentTheme = PrismUI.Themes.Dark

-- Utility Functions
local function CreateTween(obj, props, duration, style)
    duration = duration or 0.3
    style = style or Enum.EasingStyle.Quart
    return TweenService:Create(obj, TweenInfo.new(duration, style, Enum.EasingDirection.Out), props)
end

local function AddShadow(obj)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.ZIndex = obj.ZIndex - 1
    shadow.Parent = obj.Parent
    return shadow
end

local function CreateBlur(parent)
    local blur = Instance.new("BlurEffect")
    blur.Size = 10
    blur.Parent = game.Lighting
    return blur
end

-- Window Class
local Window = {}
Window.__index = Window

function Window:new(title)
    local self = setmetatable({}, Window)
    self.tabs = {}
    self.currentTab = nil
    
    -- Main GUI
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "PrismUI"
    self.gui.Parent = PlayerGui
    
    -- Main Window
    self.window = Instance.new("Frame")
    self.window.Name = "Window"
    self.window.Size = UDim2.new(0, 500, 0, 400)
    self.window.Position = UDim2.new(0.5, -250, 0.5, -200)
    self.window.BackgroundColor3 = PrismUI.CurrentTheme.Primary
    self.window.BackgroundTransparency = 0.1
    self.window.BorderSizePixel = 0
    self.window.Parent = self.gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = self.window
    
    AddShadow(self.window)
    
    -- Title Bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, 40)
    self.titleBar.BackgroundColor3 = PrismUI.CurrentTheme.Secondary
    self.titleBar.BackgroundTransparency = 0.2
    self.titleBar.BorderSizePixel = 0
    self.titleBar.Parent = self.window
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = self.titleBar
    
    -- Title Text
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "Title"
    self.titleLabel.Size = UDim2.new(1, -100, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 15, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = title
    self.titleLabel.TextColor3 = PrismUI.CurrentTheme.Text
    self.titleLabel.TextScaled = true
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Font = Enum.Font.GothamBold
    self.titleLabel.Parent = self.titleBar
    
    -- Close Button
    self.closeBtn = Instance.new("TextButton")
    self.closeBtn.Name = "Close"
    self.closeBtn.Size = UDim2.new(0, 30, 0, 30)
    self.closeBtn.Position = UDim2.new(1, -35, 0, 5)
    self.closeBtn.BackgroundColor3 = PrismUI.CurrentTheme.Error
    self.closeBtn.BackgroundTransparency = 0.3
    self.closeBtn.BorderSizePixel = 0
    self.closeBtn.Text = "×"
    self.closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.closeBtn.TextScaled = true
    self.closeBtn.Font = Enum.Font.GothamBold
    self.closeBtn.Parent = self.titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = self.closeBtn
    
    -- Tab Container
    self.tabContainer = Instance.new("Frame")
    self.tabContainer.Name = "TabContainer"
    self.tabContainer.Size = UDim2.new(1, 0, 0, 35)
    self.tabContainer.Position = UDim2.new(0, 0, 0, 40)
    self.tabContainer.BackgroundTransparency = 1
    self.tabContainer.Parent = self.window
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = self.tabContainer
    
    -- Content Frame
    self.contentFrame = Instance.new("ScrollingFrame")
    self.contentFrame.Name = "Content"
    self.contentFrame.Size = UDim2.new(1, -20, 1, -85)
    self.contentFrame.Position = UDim2.new(0, 10, 0, 75)
    self.contentFrame.BackgroundTransparency = 1
    self.contentFrame.BorderSizePixel = 0
    self.contentFrame.ScrollBarThickness = 6
    self.contentFrame.ScrollBarImageColor3 = PrismUI.CurrentTheme.Accent
    self.contentFrame.Parent = self.window
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = self.contentFrame
    
    -- Make window draggable
    self:MakeDraggable()
    
    -- Close functionality
    self.closeBtn.MouseButton1Click:Connect(function()
        CreateTween(self.window, {Size = UDim2.new(0, 0, 0, 0)}, 0.3):Play()
        wait(0.3)
        self.gui:Destroy()
    end)
    
    -- Entrance animation
    self.window.Size = UDim2.new(0, 0, 0, 0)
    CreateTween(self.window, {Size = UDim2.new(0, 500, 0, 400)}, 0.5, Enum.EasingStyle.Back):Play()
    
    return self
end

function Window:MakeDraggable()
    local dragStart, startPos
    local dragging = false
    
    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.window.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

function Window:Tab(name)
    local tab = {
        name = name,
        window = self,
        frame = nil,
        button = nil,
        elements = {}
    }
    
    -- Tab Button
    tab.button = Instance.new("TextButton")
    tab.button.Name = name
    tab.button.Size = UDim2.new(0, 100, 1, 0)
    tab.button.BackgroundColor3 = PrismUI.CurrentTheme.Secondary
    tab.button.BackgroundTransparency = 0.5
    tab.button.BorderSizePixel = 0
    tab.button.Text = name
    tab.button.TextColor3 = PrismUI.CurrentTheme.TextSecondary
    tab.button.TextScaled = true
    tab.button.Font = Enum.Font.Gotham
    tab.button.Parent = self.tabContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tab.button
    
    -- Tab Content
    tab.frame = Instance.new("Frame")
    tab.frame.Name = name .. "Content"
    tab.frame.Size = UDim2.new(1, 0, 1, 0)
    tab.frame.BackgroundTransparency = 1
    tab.frame.Visible = false
    tab.frame.Parent = self.contentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = tab.frame
    
    -- Tab switching
    tab.button.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    -- Hover effects
    tab.button.MouseEnter:Connect(function()
        CreateTween(tab.button, {BackgroundTransparency = 0.3}):Play()
    end)
    
    tab.button.MouseLeave:Connect(function()
        if self.currentTab ~= tab then
            CreateTween(tab.button, {BackgroundTransparency = 0.5}):Play()
        end
    end)
    
    self.tabs[#self.tabs + 1] = tab
    
    if not self.currentTab then
        self:SwitchTab(tab)
    end
    
    return setmetatable(tab, {__index = self:GetElementMethods()})
end

function Window:SwitchTab(targetTab)
    if self.currentTab then
        self.currentTab.frame.Visible = false
        CreateTween(self.currentTab.button, {BackgroundTransparency = 0.5}):Play()
    end
    
    self.currentTab = targetTab
    targetTab.frame.Visible = true
    CreateTween(targetTab.button, {BackgroundTransparency = 0.2, TextColor3 = PrismUI.CurrentTheme.Text}):Play()
end

-- UI Elements Methods
function Window:GetElementMethods()
    local methods = {}
    
    function methods:Label(text, size)
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, 0, 0, size or 25)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = PrismUI.CurrentTheme.Text
        label.TextScaled = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = self.frame
        
        CreateTween(label, {TextTransparency = 0}, 0.3):Play()
        return label
    end
    
    function methods:Button(text, callback)
        local button = Instance.new("TextButton")
        button.Name = "Button"
        button.Size = UDim2.new(1, 0, 0, 35)
        button.BackgroundColor3 = PrismUI.CurrentTheme.Accent
        button.BackgroundTransparency = 0.2
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.Parent = self.frame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button
        
        -- Animations
        button.MouseEnter:Connect(function()
            CreateTween(button, {Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 0}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            CreateTween(button, {Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 0.2}):Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            CreateTween(button, {Size = UDim2.new(1, 0, 0, 32)}):Play()
            wait(0.1)
            CreateTween(button, {Size = UDim2.new(1, 0, 0, 35)}):Play()
            if callback then callback() end
        end)
        
        return button
    end
    
    function methods:Toggle(text, default, callback)
        local container = Instance.new("Frame")
        container.Name = "Toggle"
        container.Size = UDim2.new(1, 0, 0, 35)
        container.BackgroundColor3 = PrismUI.CurrentTheme.Secondary
        container.BackgroundTransparency = 0.3
        container.BorderSizePixel = 0
        container.Parent = self.frame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = container
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = PrismUI.CurrentTheme.Text
        label.TextScaled = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = container
        
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(0, 40, 0, 20)
        toggleFrame.Position = UDim2.new(1, -50, 0.5, -10)
        toggleFrame.BackgroundColor3 = default and PrismUI.CurrentTheme.Accent or PrismUI.CurrentTheme.Border
        toggleFrame.BorderSizePixel = 0
        toggleFrame.Parent = container
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 10)
        toggleCorner.Parent = toggleFrame
        
        local toggleButton = Instance.new("Frame")
        toggleButton.Size = UDim2.new(0, 16, 0, 16)
        toggleButton.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.BorderSizePixel = 0
        toggleButton.Parent = toggleFrame
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = toggleButton
        
        local state = default
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = container
        
        button.MouseButton1Click:Connect(function()
            state = not state
            CreateTween(toggleFrame, {BackgroundColor3 = state and PrismUI.CurrentTheme.Accent or PrismUI.CurrentTheme.Border}):Play()
            CreateTween(toggleButton, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
            if callback then callback(state) end
        end)
        
        return container
    end
    
    function methods:Slider(text, min, max, default, callback)
        local container = Instance.new("Frame")
        container.Name = "Slider"
        container.Size = UDim2.new(1, 0, 0, 50)
        container.BackgroundColor3 = PrismUI.CurrentTheme.Secondary
        container.BackgroundTransparency = 0.3
        container.BorderSizePixel = 0
        container.Parent = self.frame
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = container
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. default
        label.TextColor3 = PrismUI.CurrentTheme.Text
        label.TextScaled = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = container
        
        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(1, -20, 0, 6)
        sliderFrame.Position = UDim2.new(0, 10, 0, 30)
        sliderFrame.BackgroundColor3 = PrismUI.CurrentTheme.Border
        sliderFrame.BorderSizePixel = 0
        sliderFrame.Parent = container
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 3)
        sliderCorner.Parent = sliderFrame
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = PrismUI.CurrentTheme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = sliderFrame
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = fill
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = container
        
        local dragging = false
        local value = default
        
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mouse = UserInputService:GetMouseLocation()
                local relativePos = math.clamp((mouse.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * relativePos)
                
                label.Text = text .. ": " .. value
                CreateTween(fill, {Size = UDim2.new(relativePos, 0, 1, 0)}):Play()
                
                if callback then callback(value) end
            end
        end)
        
        return container
    end
    
    return methods
end

-- Main PrismUI Functions
function PrismUI:Window(title)
    return Window:new(title)
end

function PrismUI:Theme(themeName)
    if self.Themes[themeName] then
        self.CurrentTheme = self.Themes[themeName]
    end
end

function PrismUI:Notify(title, message, duration, type)
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(1, -20, 1, -100)
    notification.BackgroundColor3 = type == "success" and self.CurrentTheme.Success or 
                                   type == "warning" and self.CurrentTheme.Warning or
                                   type == "error" and self.CurrentTheme.Error or
                                   self.CurrentTheme.Secondary
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "PrismNotification"
    gui.Parent = PlayerGui
    notification.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = notification
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -20, 0, 40)
    messageLabel.Position = UDim2.new(0, 10, 0, 30)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    messageLabel.TextScaled = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    -- Slide in animation
    CreateTween(notification, {Position = UDim2.new(1, -320, 1, -100)}, 0.4, Enum.EasingStyle.Back):Play()
    
    -- Auto dismiss
    wait(duration or 5)
    CreateTween(notification, {Position = UDim2.new(1, -20, 1, -100)}, 0.3):Play()
    wait(0.3)
    gui:Destroy()
end

return PrismUI
