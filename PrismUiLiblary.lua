-- PrismUI v2.0 - Premium Glassmorphism UI Library
-- Modern, Beautiful, Professional Design

local PrismUI = {}
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Premium Color Schemes
PrismUI.Themes = {
    Dark = {
        Primary = Color3.fromRGB(8, 8, 12),
        Secondary = Color3.fromRGB(18, 18, 24),
        Tertiary = Color3.fromRGB(28, 28, 38),
        Accent = Color3.fromRGB(138, 43, 226), -- Purple accent
        AccentHover = Color3.fromRGB(155, 89, 230),
        Text = Color3.fromRGB(245, 245, 250),
        TextSecondary = Color3.fromRGB(156, 163, 175),
        TextMuted = Color3.fromRGB(107, 114, 128),
        Border = Color3.fromRGB(55, 65, 81),
        BorderLight = Color3.fromRGB(75, 85, 99),
        Success = Color3.fromRGB(16, 185, 129),
        Warning = Color3.fromRGB(245, 158, 11),
        Error = Color3.fromRGB(239, 68, 68),
        Glass = Color3.fromRGB(255, 255, 255)
    },
    Light = {
        Primary = Color3.fromRGB(248, 250, 252),
        Secondary = Color3.fromRGB(255, 255, 255),
        Tertiary = Color3.fromRGB(241, 245, 249),
        Accent = Color3.fromRGB(99, 102, 241),
        AccentHover = Color3.fromRGB(129, 140, 248),
        Text = Color3.fromRGB(15, 23, 42),
        TextSecondary = Color3.fromRGB(51, 65, 85),
        TextMuted = Color3.fromRGB(100, 116, 139),
        Border = Color3.fromRGB(203, 213, 225),
        BorderLight = Color3.fromRGB(226, 232, 240),
        Success = Color3.fromRGB(34, 197, 94),
        Warning = Color3.fromRGB(251, 191, 36),
        Error = Color3.fromRGB(248, 113, 113),
        Glass = Color3.fromRGB(0, 0, 0)
    }
}

PrismUI.CurrentTheme = PrismUI.Themes.Dark

-- Utility Functions
local function CreateTween(obj, props, duration, style, direction)
    duration = duration or 0.4
    style = style or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    return TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
end

local function CreateGlow(obj, intensity)
    intensity = intensity or 20
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://4996891970" -- Soft glow texture
    glow.ImageColor3 = PrismUI.CurrentTheme.Accent
    glow.ImageTransparency = 0.6
    glow.Size = UDim2.new(1, intensity, 1, intensity)
    glow.Position = UDim2.new(0, -intensity/2, 0, -intensity/2)
    glow.ZIndex = obj.ZIndex - 1
    glow.Parent = obj.Parent
    return glow
end

local function CreateShadow(obj, depth, blur)
    depth = depth or 8
    blur = blur or 25
    
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "DropShadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://297694126" -- Shadow texture
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.Size = UDim2.new(1, depth*2, 1, depth*2)
    shadow.Position = UDim2.new(0, -depth, 0, -depth)
    shadow.ZIndex = obj.ZIndex - 2
    shadow.Parent = obj.Parent
    
    -- Animate shadow on hover
    local originalTransparency = shadow.ImageTransparency
    obj.MouseEnter:Connect(function()
        CreateTween(shadow, {ImageTransparency = originalTransparency - 0.2}, 0.3):Play()
    end)
    obj.MouseLeave:Connect(function()
        CreateTween(shadow, {ImageTransparency = originalTransparency}, 0.3):Play()
    end)
    
    return shadow
end

local function CreateGradient(obj, color1, color2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    }
    gradient.Rotation = rotation or 45
    gradient.Parent = obj
    return gradient
end

local function AddGlassEffect(obj)
    -- Glass background
    obj.BackgroundColor3 = PrismUI.CurrentTheme.Glass
    obj.BackgroundTransparency = 0.92
    
    -- Glass border
    local stroke = Instance.new("UIStroke")
    stroke.Color = PrismUI.CurrentTheme.BorderLight
    stroke.Thickness = 1
    stroke.Transparency = 0.6
    stroke.Parent = obj
    
    -- Subtle gradient overlay
    CreateGradient(obj, 
        Color3.fromRGB(255, 255, 255), 
        Color3.fromRGB(200, 200, 255), 
        135
    ).Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.98),
        NumberSequenceKeypoint.new(1, 0.95)
    }
    
    return stroke
end

local function CreateRippleEffect(button)
    button.ClipsDescendants = true
    
    button.MouseButton1Down:Connect(function()
        local ripple = Instance.new("Frame")
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = PrismUI.CurrentTheme.Text
        ripple.BackgroundTransparency = 0.8
        ripple.BorderSizePixel = 0
        ripple.Parent = button
        
        local rippleCorner = Instance.new("UICorner")
        rippleCorner.CornerRadius = UDim.new(1, 0)
        rippleCorner.Parent = ripple
        
        local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        
        CreateTween(ripple, {
            Size = UDim2.new(0, maxSize, 0, maxSize),
            BackgroundTransparency = 1
        }, 0.6, Enum.EasingStyle.Quad):Play()
        
        game:GetService("Debris"):AddItem(ripple, 0.6)
    end)
end

-- Window Class
local Window = {}
Window.__index = Window

function Window:new(title)
    local self = setmetatable({}, Window)
    self.tabs = {}
    self.currentTab = nil
    
    -- Background Blur Effect
    self.blur = Instance.new("BlurEffect")
    self.blur.Size = 15
    self.blur.Parent = Lighting
    
    -- Main GUI with blur backdrop
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "PrismUI_" .. math.random(1000, 9999)
    self.gui.Parent = PlayerGui
    
    -- Backdrop
    self.backdrop = Instance.new("Frame")
    self.backdrop.Name = "Backdrop"
    self.backdrop.Size = UDim2.new(1, 0, 1, 0)
    self.backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self.backdrop.BackgroundTransparency = 0.3
    self.backdrop.BorderSizePixel = 0
    self.backdrop.Parent = self.gui
    
    -- Main Window Frame
    self.window = Instance.new("Frame")
    self.window.Name = "MainWindow"
    self.window.Size = UDim2.new(0, 580, 0, 420)
    self.window.Position = UDim2.new(0.5, -290, 0.5, -210)
    self.window.BorderSizePixel = 0
    self.window.ClipsDescendants = false
    self.window.Parent = self.gui
    
    -- Glass effect for window
    AddGlassEffect(self.window)
    
    -- Window corner radius
    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = UDim.new(0, 20)
    windowCorner.Parent = self.window
    
    -- Drop shadow
    CreateShadow(self.window, 15, 30)
    
    -- Animated glow effect
    local glow = CreateGlow(self.window, 40)
    
    -- Title Bar with gradient
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, 50)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = PrismUI.CurrentTheme.Tertiary
    self.titleBar.BackgroundTransparency = 0.1
    self.titleBar.BorderSizePixel = 0
    self.titleBar.Parent = self.window
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 20)
    titleCorner.Parent = self.titleBar
    
    -- Title gradient
    CreateGradient(self.titleBar, PrismUI.CurrentTheme.Accent, PrismUI.CurrentTheme.AccentHover, 90)
    
    -- Prism Logo/Icon (decorative)
    local logoFrame = Instance.new("Frame")
    logoFrame.Size = UDim2.new(0, 30, 0, 30)
    logoFrame.Position = UDim2.new(0, 15, 0.5, -15)
    logoFrame.BackgroundColor3 = PrismUI.CurrentTheme.Accent
    logoFrame.BorderSizePixel = 0
    logoFrame.Parent = self.titleBar
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 8)
    logoCorner.Parent = logoFrame
    
    CreateGradient(logoFrame, 
        Color3.fromRGB(168, 85, 247), 
        Color3.fromRGB(59, 130, 246), 
        45
    )
    
    -- Logo text
    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.new(1, 0, 1, 0)
    logoText.BackgroundTransparency = 1
    logoText.Text = "P"
    logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
    logoText.TextScaled = true
    logoText.Font = Enum.Font.GothamBold
    logoText.Parent = logoFrame
    
    -- Title Text with better typography
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "Title"
    self.titleLabel.Size = UDim2.new(1, -180, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 55, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = title
    self.titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.titleLabel.TextScaled = true
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Font = Enum.Font.GothamBold
    self.titleLabel.TextSize = 18
    self.titleLabel.Parent = self.titleBar
    
    -- Minimize Button
    self.minimizeBtn = Instance.new("TextButton")
    self.minimizeBtn.Name = "Minimize"
    self.minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
    self.minimizeBtn.Position = UDim2.new(1, -100, 0.5, -17.5)
    self.minimizeBtn.BackgroundColor3 = Color3.fromRGB(251, 191, 36)
    self.minimizeBtn.BackgroundTransparency = 0.2
    self.minimizeBtn.BorderSizePixel = 0
    self.minimizeBtn.Text = "−"
    self.minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.minimizeBtn.TextSize = 18
    self.minimizeBtn.Font = Enum.Font.GothamBold
    self.minimizeBtn.Parent = self.titleBar
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(1, 0)
    minimizeCorner.Parent = self.minimizeBtn
    
    CreateRippleEffect(self.minimizeBtn)
    
    -- Close Button with better styling
    self.closeBtn = Instance.new("TextButton")
    self.closeBtn.Name = "Close"
    self.closeBtn.Size = UDim2.new(0, 35, 0, 35)
    self.closeBtn.Position = UDim2.new(1, -50, 0.5, -17.5)
    self.closeBtn.BackgroundColor3 = Color3.fromRGB(248, 113, 113)
    self.closeBtn.BackgroundTransparency = 0.2
    self.closeBtn.BorderSizePixel = 0
    self.closeBtn.Text = "✕"
    self.closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.closeBtn.TextSize = 14
    self.closeBtn.Font = Enum.Font.GothamBold
    self.closeBtn.Parent = self.titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = self.closeBtn
    
    CreateRippleEffect(self.closeBtn)
    CreateShadow(self.closeBtn, 3, 10)
    
    -- Tab Container with better styling
    self.tabContainer = Instance.new("Frame")
    self.tabContainer.Name = "TabContainer"
    self.tabContainer.Size = UDim2.new(1, 0, 0, 45)
    self.tabContainer.Position = UDim2.new(0, 0, 0, 50)
    self.tabContainer.BackgroundTransparency = 1
    self.tabContainer.Parent = self.window
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = self.tabContainer
    
    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 20)
    tabPadding.PaddingTop = UDim.new(0, 8)
    tabPadding.Parent = self.tabContainer
    
    -- Content Area with glass effect
    self.contentFrame = Instance.new("ScrollingFrame")
    self.contentFrame.Name = "ContentArea"
    self.contentFrame.Size = UDim2.new(1, -30, 1, -110)
    self.contentFrame.Position = UDim2.new(0, 15, 0, 95)
    self.contentFrame.BackgroundTransparency = 1
    self.contentFrame.BorderSizePixel = 0
    self.contentFrame.ScrollBarThickness = 8
    self.contentFrame.ScrollBarImageColor3 = PrismUI.CurrentTheme.Accent
    self.contentFrame.ScrollBarImageTransparency = 0.3
    self.contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    self.contentFrame.Parent = self.window
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 12)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = self.contentFrame
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 5)
    contentPadding.PaddingRight = UDim.new(0, 5)
    contentPadding.PaddingTop = UDim.new(0, 5)
    contentPadding.PaddingBottom = UDim.new(0, 5)
    contentPadding.Parent = self.contentFrame
    
    -- Window functionality
    self:MakeDraggable()
    self:SetupButtons()
    self:AnimateEntrance()
    
    return self
end

function Window:AnimateEntrance()
    -- Start with hidden/scaled down window
    self.window.Size = UDim2.new(0, 0, 0, 0)
    self.window.Rotation = 5
    self.backdrop.BackgroundTransparency = 1
    
    -- Entrance sequence
    CreateTween(self.backdrop, {BackgroundTransparency = 0.3}, 0.4):Play()
    
    wait(0.1)
    
    local entranceTween = CreateTween(self.window, {
        Size = UDim2.new(0, 580, 0, 420),
        Rotation = 0
    }, 0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    entranceTween:Play()
    
    -- Glow pulse effect
    local glow = self.window.Parent:FindFirstChild("Glow")
    if glow then
        spawn(function()
            while self.window.Parent do
                CreateTween(glow, {ImageTransparency = 0.4}, 2, Enum.EasingStyle.Sine):Play()
                wait(2)
                CreateTween(glow, {ImageTransparency = 0.7}, 2, Enum.EasingStyle.Sine):Play()
                wait(2)
            end
        end)
    end
end

function Window:MakeDraggable()
    local dragStart, startPos, dragging = nil, nil, false
    
    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.window.Position
            
            -- Scale down slightly when dragging starts
            CreateTween(self.window, {Size = UDim2.new(0, 570, 0, 410)}, 0.2):Play()
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.window.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            -- Scale back to normal
            CreateTween(self.window, {Size = UDim2.new(0, 580, 0, 420)}, 0.2):Play()
        end
    end)
end

function Window:SetupButtons()
    -- Close button
    self.closeBtn.MouseButton1Click:Connect(function()
        CreateTween(self.window, {
            Size = UDim2.new(0, 0, 0, 0),
            Rotation = -10
        }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
        
        CreateTween(self.backdrop, {BackgroundTransparency = 1}, 0.4):Play()
        
        wait(0.4)
        if self.blur then self.blur:Destroy() end
        self.gui:Destroy()
    end)
    
    -- Minimize button
    self.minimizeBtn.MouseButton1Click:Connect(function()
        local isMinimized = self.window.Size.Y.Offset <= 55
        
        if isMinimized then
            CreateTween(self.window, {Size = UDim2.new(0, 580, 0, 420)}, 0.5, Enum.EasingStyle.Back):Play()
        else
            CreateTween(self.window, {Size = UDim2.new(0, 580, 0, 55)}, 0.5, Enum.EasingStyle.Back):Play()
        end
    end)
    
    -- Button hover effects
    self.closeBtn.MouseEnter:Connect(function()
        CreateTween(self.closeBtn, {Size = UDim2.new(0, 38, 0, 38), BackgroundTransparency = 0}):Play()
    end)
    self.closeBtn.MouseLeave:Connect(function()
        CreateTween(self.closeBtn, {Size = UDim2.new(0, 35, 0, 35), BackgroundTransparency = 0.2}):Play()
    end)
    
    self.minimizeBtn.MouseEnter:Connect(function()
        CreateTween(self.minimizeBtn, {Size = UDim2.new(0, 38, 0, 38), BackgroundTransparency = 0}):Play()
    end)
    self.minimizeBtn.MouseLeave:Connect(function()
        CreateTween(self.minimizeBtn, {Size = UDim2.new(0, 35, 0, 35), BackgroundTransparency = 0.2}):Play()
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
    
    -- Tab Button with modern design
    tab.button = Instance.new("TextButton")
    tab.button.Name = name .. "Tab"
    tab.button.Size = UDim2.new(0, 120, 0, 35)
    tab.button.BackgroundTransparency = 1
    tab.button.BorderSizePixel = 0
    tab.button.Text = name
    tab.button.TextColor3 = PrismUI.CurrentTheme.TextSecondary
    tab.button.TextSize = 14
    tab.button.Font = Enum.Font.GothamSemibold
    tab.button.Parent = self.tabContainer
    
    -- Tab background with glass effect
    local tabBg = Instance.new("Frame")
    tabBg.Name = "Background"
    tabBg.Size = UDim2.new(1, 0, 1, 0)
    tabBg.BackgroundTransparency = 1
    tabBg.BorderSizePixel = 0
    tabBg.Parent = tab.button
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 12)
    tabCorner.Parent = tabBg
    
    -- Tab Content Frame
    tab.frame = Instance.new("Frame")
    tab.frame.Name = name .. "Content"
    tab.frame.Size = UDim2.new(1, 0, 1, 0)
    tab.frame.BackgroundTransparency = 1
    tab.frame.Visible = false
    tab.frame.Parent = self.contentFrame
    
    local tabContentLayout = Instance.new("UIListLayout")
    tabContentLayout.Padding = UDim.new(0, 10)
    tabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabContentLayout.Parent = tab.frame
    
    -- Tab switching with animations
    tab.button.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    -- Tab hover effects
    tab.button.MouseEnter:Connect(function()
        if self.currentTab ~= tab then
            CreateTween(tabBg, {BackgroundTransparency = 0.9}, 0.2):Play()
            CreateTween(tab.button, {TextColor3 = PrismUI.CurrentTheme.Text}, 0.2):Play()
        end
    end)
    
    tab.button.MouseLeave:Connect(function()
        if self.currentTab ~= tab then
            CreateTween(tabBg, {BackgroundTransparency = 1}, 0.2):Play()
            CreateTween(tab.button, {TextColor3 = PrismUI.CurrentTheme.TextSecondary}, 0.2):Play()
        end
    end)
    
    self.tabs[#self.tabs + 1] = tab
    
    -- Auto-select first tab
    if #self.tabs == 1 then
        self:SwitchTab(tab)
    end
    
    return setmetatable(tab, {__index = self:GetElementMethods()})
end

function Window:SwitchTab(targetTab)
    -- Deactivate current tab
    if self.currentTab then
        local currentBg = self.currentTab.button:FindFirstChild("Background")
        CreateTween(currentBg, {BackgroundTransparency = 1}, 0.3):Play()
        CreateTween(self.currentTab.button, {TextColor3 = PrismUI.CurrentTheme.TextSecondary}, 0.3):Play()
        
        -- Fade out animation
        CreateTween(self.currentTab.frame, {BackgroundTransparency = 1}, 0.2):Play()
        wait(0.1)
        self.currentTab.frame.Visible = false
    end
    
    -- Activate new tab
    self.currentTab = targetTab
    local newBg = targetTab.button:FindFirstChild("Background")
    
    AddGlassEffect(newBg)
    CreateTween(newBg, {BackgroundTransparency = 0.85}, 0.3):Play()
    CreateTween(targetTab.button, {TextColor3 = PrismUI.CurrentTheme.Text}, 0.3):Play()
    
    -- Fade in animation
    targetTab.frame.Visible = true
    targetTab.frame.BackgroundTransparency = 1
    CreateTween(targetTab.frame, {BackgroundTransparency = 0}, 0.3):Play()
end

-- Enhanced UI Elements
function Window:GetElementMethods()
    local methods = {}
    
    function methods:Label(text, size)
        local container = Instance.new("Frame")
        container.Name = "LabelContainer"
        container.Size = UDim2.new(1, 0, 0, size or 30)
        container.BackgroundTransparency = 1
        container.Parent = self.frame
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -20, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = PrismUI.CurrentTheme.Text
        label.TextSize = 16
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextWrapped = true
        label.Parent = container
        
        -- Entrance animation
        label.TextTransparency = 1
        CreateTween(label, {TextTransparency = 0}, 0.5):Play()
        
        return container
    end
    
    function methods:Button(text, callback)
        local container = Instance.new("Frame")
        container.Name = "ButtonContainer"
        container.Size = UDim2.new(1, 0, 0, 45)
        container.BackgroundTransparency = 1
        container.Parent = self.frame
        
        local button = Instance.new("TextButton")
        button.Name = "Button"
        button.Size = UDim2.new(1, -10, 1, 0)
        button.Position = UDim2.new(0, 5, 0, 0)
        button.BorderSizePixel = 0
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 15
        button.Font = Enum.Font.GothamSemibold
        button.Parent = container
        
        -- Glass button effect
        AddGlassEffect(button)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = button
        
        -- Gradient background
        CreateGradient(button, PrismUI.CurrentTheme.Accent, PrismUI.CurrentTheme.AccentHover, 45)
        
        -- Button effects
        CreateRippleEffect(button)
        CreateShadow(button, 4, 15)
        
        -- Hover animations
        button.MouseEnter:Connect(function()
            CreateTween(button, {Size = UDim2.new(1, -5, 1, 5)}, 0.2):Play()
        end)
        
        button.MouseLeave:Connect(function()
            CreateTween(button, {Size = UDim2.new(1, -10, 1, 0)}, 0.2):Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            CreateTween(button, {Size = UDim2.new(1, -15, 1, -5)}, 0.1):Play()
            wait(0.1)
            CreateTween(button, {Size = UDim2.new(1, -10, 1, 0)}, 0.1):Play()
            if callback then callback() end
        end)
        
        return container
    end
    
    function methods:Toggle(text, default, callback)
        local container = Instance.new("Frame")
        container.Name = "ToggleContainer"
        container.Size = UDim2.new(1, 0, 0, 50)
        container.BackgroundTransparency = 1
        container.Parent = self.frame
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -10, 1, 0)
        bg.Position = UDim2.new(0, 5, 0, 0)
        bg.BorderSizePixel = 0
        bg.Parent = container
        
        AddGlassEffect(bg)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 15)
        corner.Parent = bg
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -80, 1, 0)
        label.Position = UDim2.new(0, 20, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = PrismUI.CurrentTheme.Text
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = bg
        
        -- Modern toggle switch
        local toggleBg = Instance.new("Frame")
        toggleBg.Name = "ToggleBg"
        toggleBg.Size = UDim2.new(0, 50, 0, 25)
        toggleBg.Position = UDim2.new(1, -65, 0.5, -12.5)
        toggleBg.BackgroundColor3 = default and PrismUI.CurrentTheme.Success or PrismUI.CurrentTheme.Border
        toggleBg.BorderSizePixel = 0
        toggleBg.Parent = bg
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 12.5)
        toggleCorner.Parent = toggleBg
        
        -- Toggle knob with glow
        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.Size = UDim2.new(0, 21, 0, 21)
        knob.Position = default and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = toggleBg
        
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob
        
        CreateShadow(knob, 3, 10)
        
        local state = default
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = bg
        
        button.MouseButton1Click:Connect(function()
            state = not state
            
            local newColor = state and PrismUI.CurrentTheme.Success or PrismUI.CurrentTheme.Border
            local newPos = state and UDim2.new(1, -23, 0.5, -10.5) or UDim2.new(0, 2, 0.5, -10.5)
            
            CreateTween(toggleBg, {BackgroundColor3 = newColor}, 0.3):Play()
            CreateTween(knob, {Position = newPos}, 0.3, Enum.EasingStyle.Back):Play()
            
            if callback then callback(state) end
        end)
        
        return container
    end
    
    function methods:Slider(text, min, max, default, callback)
        local container = Instance.new("Frame")
        container.Name = "SliderContainer"
        container.Size = UDim2.new(1, 0, 0, 65)
        container.BackgroundTransparency = 1
        container.Parent = self.frame
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -10, 1, 0)
        bg.Position = UDim2.new(0, 5, 0, 0)
        bg.BorderSizePixel = 0
        bg.Parent = container
        
        AddGlassEffect(bg)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 15)
        corner.Parent = bg
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Size = UDim2.new(1, -20, 0, 25)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. default
        label.TextColor3 = PrismUI.CurrentTheme.Text
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = bg
        
        -- Value display
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.Size = UDim2.new(0, 50, 0, 25)
        valueLabel.Position = UDim2.new(1, -60, 0, 5)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = PrismUI.CurrentTheme.Accent
        valueLabel.TextSize = 14
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.Parent = bg
        
        -- Slider track
        local track = Instance.new("Frame")
        track.Name = "Track"
        track.Size = UDim2.new(1, -30, 0, 8)
        track.Position = UDim2.new(0, 15, 0, 35)
        track.BackgroundColor3 = PrismUI.CurrentTheme.Border
        track.BorderSizePixel = 0
        track.Parent = bg
        
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(0, 4)
        trackCorner.Parent = track
        
        -- Filled portion
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = PrismUI.CurrentTheme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 4)
        fillCorner.Parent = fill
        
        CreateGradient(fill, PrismUI.CurrentTheme.Accent, PrismUI.CurrentTheme.AccentHover, 45)
        
        -- Slider thumb
        local thumb = Instance.new("Frame")
        thumb.Name = "Thumb"
        thumb.Size = UDim2.new(0, 20, 0, 20)
        thumb.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BorderSizePixel = 0
        thumb.Parent = track
        
        local thumbCorner = Instance.new("UICorner")
        thumbCorner.CornerRadius = UDim.new(1, 0)
        thumbCorner.Parent = thumb
        
        CreateShadow(thumb, 4, 12)
        
        local dragging = false
        local value = default
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = bg
        
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                CreateTween(thumb, {Size = UDim2.new(0, 24, 0, 24)}, 0.2):Play()
            end
        end)
        
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
                CreateTween(thumb, {Size = UDim2.new(0, 20, 0, 20)}, 0.2):Play()
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mouse = UserInputService:GetMouseLocation()
                local relativePos = math.clamp((mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * relativePos)
                
                label.Text = text .. ": " .. value
                valueLabel.Text = tostring(value)
                
                CreateTween(fill, {Size = UDim2.new(relativePos, 0, 1, 0)}, 0.1):Play()
                CreateTween(thumb, {Position = UDim2.new(relativePos, -12, 0.5, -12)}, 0.1):Play()
                
                if callback then callback(value) end
            end
        end)
        
        return container
    end
    
    function methods:Dropdown(text, options, default, callback)
        local container = Instance.new("Frame")
        container.Name = "DropdownContainer"
        container.Size = UDim2.new(1, 0, 0, 45)
        container.BackgroundTransparency = 1
        container.Parent = self.frame
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -10, 1, 0)
        bg.Position = UDim2.new(0, 5, 0, 0)
        bg.BorderSizePixel = 0
        bg.ClipsDescendants = false
        bg.Parent = container
        
        AddGlassEffect(bg)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = bg
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -50, 1, 0)
        label.Position = UDim2.new(0, 15, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = PrismUI.CurrentTheme.TextSecondary
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = bg
        
        local selectedLabel = Instance.new("TextLabel")
        selectedLabel.Size = UDim2.new(1, -80, 1, 0)
        selectedLabel.Position = UDim2.new(0, 15, 0, 0)
        selectedLabel.BackgroundTransparency = 1
        selectedLabel.Text = default
        selectedLabel.TextColor3 = PrismUI.CurrentTheme.Text
        selectedLabel.TextSize = 14
        selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
        selectedLabel.Font = Enum.Font.GothamSemibold
        selectedLabel.Parent = bg
        
        -- Arrow icon
        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 20, 0, 20)
        arrow.Position = UDim2.new(1, -35, 0.5, -10)
        arrow.BackgroundTransparency = 1
        arrow.Text = "▼"
        arrow.TextColor3 = PrismUI.CurrentTheme.Accent
        arrow.TextSize = 12
        arrow.Font = Enum.Font.GothamBold
        arrow.Parent = bg
        
        local expanded = false
        local dropdownList = nil
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = bg
        
        button.MouseButton1Click:Connect(function()
            expanded = not expanded
            
            CreateTween(arrow, {Rotation = expanded and 180 or 0}, 0.3):Play()
            
            if expanded then
                -- Create dropdown list
                dropdownList = Instance.new("Frame")
                dropdownList.Name = "DropdownList"
                dropdownList.Size = UDim2.new(1, 0, 0, #options * 35 + 10)
                dropdownList.Position = UDim2.new(0, 0, 1, 5)
                dropdownList.BorderSizePixel = 0
                dropdownList.ZIndex = 10
                dropdownList.Parent = bg
                
                AddGlassEffect(dropdownList)
                CreateShadow(dropdownList, 8, 20)
                
                local listCorner = Instance.new("UICorner")
                listCorner.CornerRadius = UDim.new(0, 12)
                listCorner.Parent = dropdownList
                
                local listLayout = Instance.new("UIListLayout")
                listLayout.Padding = UDim.new(0, 2)
                listLayout.Parent = dropdownList
                
                local listPadding = Instance.new("UIPadding")
                listPadding.PaddingAll = UDim.new(0, 5)
                listPadding.Parent = dropdownList
                
                -- Animate dropdown appearance
                dropdownList.Size = UDim2.new(1, 0, 0, 0)
                CreateTween(dropdownList, {Size = UDim2.new(1, 0, 0, #options * 35 + 10)}, 0.3, Enum.EasingStyle.Back):Play()
                
                for i, option in ipairs(options) do
                    local optionButton = Instance.new("TextButton")
                    optionButton.Size = UDim2.new(1, 0, 0, 30)
                    optionButton.BackgroundTransparency = 1
                    optionButton.Text = option
                    optionButton.TextColor3 = option == default and PrismUI.CurrentTheme.Accent or PrismUI.CurrentTheme.Text
                    optionButton.TextSize = 13
                    optionButton.Font = Enum.Font.Gotham
                    optionButton.Parent = dropdownList
                    
                    local optionCorner = Instance.new("UICorner")
                    optionCorner.CornerRadius = UDim.new(0, 8)
                    optionCorner.Parent = optionButton
                    
                    optionButton.MouseEnter:Connect(function()
                        CreateTween(optionButton, {BackgroundTransparency = 0.9}, 0.2):Play()
                    end)
                    
                    optionButton.MouseLeave:Connect(function()
                        CreateTween(optionButton, {BackgroundTransparency = 1}, 0.2):Play()
                    end)
                    
                    optionButton.MouseButton1Click:Connect(function()
                        selectedLabel.Text = option
                        expanded = false
                        
                        CreateTween(arrow, {Rotation = 0}, 0.3):Play()
                        CreateTween(dropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2):Play()
                        
                        wait(0.2)
                        if dropdownList then dropdownList:Destroy() end
                        dropdownList = nil
                        
                        if callback then callback(option) end
                    end)
                end
            else
                if dropdownList then
                    CreateTween(dropdownList, {Size = UDim2.new(1, 0, 0, 0)}, 0.2):Play()
                    wait(0.2)
                    dropdownList:Destroy()
                    dropdownList = nil
                end
            end
        end)
        
        return container
    end
    
    function methods:Textbox(text, placeholder, callback)
        local container = Instance.new("Frame")
        container.Name = "TextboxContainer"
        container.Size = UDim2.new(1, 0, 0, 45)
        container.BackgroundTransparency = 1
        container.Parent = self.frame
        
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, -10, 1, 0)
        bg.Position = UDim2.new(0, 5, 0, 0)
        bg.BorderSizePixel = 0
        bg.Parent = container
        
        AddGlassEffect(bg)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = bg
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 15)
        label.Position = UDim2.new(0, 15, 0, 3)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = PrismUI.CurrentTheme.TextSecondary
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.Parent = bg
        
        local textbox = Instance.new("TextBox")
        textbox.Size = UDim2.new(1, -20, 1, -18)
        textbox.Position = UDim2.new(0, 15, 0, 18)
        textbox.BackgroundTransparency = 1
        textbox.Text = ""
        textbox.PlaceholderText = placeholder
        textbox.TextColor3 = PrismUI.CurrentTheme.Text
        textbox.PlaceholderColor3 = PrismUI.CurrentTheme.TextMuted
        textbox.TextSize = 14
        textbox.TextXAlignment = Enum.TextXAlignment.Left
        textbox.Font = Enum.Font.Gotham
        textbox.ClearTextOnFocus = false
        textbox.Parent = bg
        
        -- Focus effects
        textbox.Focused:Connect(function()
            local stroke = bg:FindFirstChild("UIStroke")
            if stroke then
                CreateTween(stroke, {Color = PrismUI.CurrentTheme.Accent, Thickness = 2}, 0.2):Play()
            end
        end)
        
        textbox.FocusLost:Connect(function()
            local stroke = bg:FindFirstChild("UIStroke")
            if stroke then
                CreateTween(stroke, {Color = PrismUI.CurrentTheme.BorderLight, Thickness = 1}, 0.2):Play()
            end
            if callback then callback(textbox.Text) end
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

function PrismUI:Notify(title, message, duration, notificationType)
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "PrismNotification"
    notifGui.Parent = PlayerGui
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 350, 0, 90)
    notification.Position = UDim2.new(1, 20, 1, -110)
    notification.BorderSizePixel = 0
    notification.Parent = notifGui
    
    -- Notification styling based on type
    local bgColor = PrismUI.CurrentTheme.Secondary
    local accentColor = PrismUI.CurrentTheme.Accent
    
    if notificationType == "success" then
        accentColor = PrismUI.CurrentTheme.Success
    elseif notificationType == "warning" then
        accentColor = PrismUI.CurrentTheme.Warning
    elseif notificationType == "error" then
        accentColor = PrismUI.CurrentTheme.Error
    end
    
    AddGlassEffect(notification)
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 15)
    corner.Parent = notification
    
    CreateShadow(notification, 10, 25)
    
    -- Accent bar
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = accentColor
    accentBar.BorderSizePixel = 0
    accentBar.Parent = notification
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 15)
    accentCorner.Parent = accentBar
    
    -- Icon
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 15, 0, 10)
    icon.BackgroundTransparency = 1
    icon.TextColor3 = accentColor
    icon.TextSize = 18
    icon.Font = Enum.Font.GothamBold
    icon.Parent = notification
    
    if notificationType == "success" then
        icon.Text = "✓"
    elseif notificationType == "warning" then
        icon.Text = "⚠"
    elseif notificationType == "error" then
        icon.Text = "✕"
    else
        icon.Text = "ℹ"
    end
    
    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 0, 25)
    titleLabel.Position = UDim2.new(0, 50, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = PrismUI.CurrentTheme.Text
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = notification
    
    -- Message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -60, 0, 45)
    messageLabel.Position = UDim2.new(0, 50, 0, 30)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = PrismUI.CurrentTheme.TextSecondary
    messageLabel.TextSize = 13
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.Parent = notification
    
    -- Slide in animation
    CreateTween(notification, {Position = UDim2.new(1, -370, 1, -110)}, 0.5, Enum.EasingStyle.Back):Play()
    
    -- Progress bar
    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -20, 0, 2)
    progressBg.Position = UDim2.new(0, 10, 1, -8)
    progressBg.BackgroundColor3 = PrismUI.CurrentTheme.Border
    progressBg.BorderSizePixel = 0
    progressBg.Parent = notification
    
    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = accentColor
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressBg
    
    -- Animate progress bar
    CreateTween(progressFill, {Size = UDim2.new(0, 0, 1, 0)}, duration or 5, Enum.EasingStyle.Linear):Play()
    
    -- Auto dismiss
    wait(duration or 5)
    CreateTween(notification, {Position = UDim2.new(1, 20, 1, -110)}, 0.3):Play()
    wait(0.3)
    notifGui:Destroy()
end

return PrismUI
