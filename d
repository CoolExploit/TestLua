-- --==================================================================
-- --     Remote Explorer  v3.1  - Stable Edition                     --
-- --     Full spy . Script gen . Blacklist . Freq . Mobile OK        --
-- --     Made by PabloScripter AKA Mr Root on TikTok                 --
-- --==================================================================
-- Last updated: v3.1 - full audit pass
--   Fixed: RenderStepped CPU waste, spyPaused scope, NameTag filter,
--          mobile drag, double-prune, BLNotice nil ref, auto-detect
--          toast spam, hook GetFullName pcall, interval lock on mobile,
--          minimize restoring wrong H, resize disabled on mobile.

-- ====================================================================
--  SERVICES  (all pcall-guarded to survive stripped environments)
-- ====================================================================
local function getS(name)
    local ok, s = pcall(game.GetService, game, name)
    return ok and s or nil
end

local Players     = getS("Players")
local TweenSvc    = getS("TweenService")
local UIS         = getS("UserInputService")
local RunSvc      = getS("RunService")
local HttpSvc     = getS("HttpService")
local CoreGui     = getS("CoreGui")
local LocalPlayer = Players and Players.LocalPlayer

if not (Players and TweenSvc and UIS and CoreGui) then
    warn("[RemoteExplorer] Critical services missing - aborting.")
    return
end

-- ====================================================================
--  CONFIG
-- ====================================================================
local CFG = {
    MAX_SPY_UI     = 250,   -- max visible spy rows (oldest destroyed)
    MAX_SPY_LOG    = 600,   -- max spy log table entries
    MAX_REMOTE_LOG = 400,   -- max remoteLog entries
    FIRE_CD        = 0.32,  -- fire debounce (seconds)
    SCAN_YIELD     = 20,    -- yield every N descendants while scanning
    TOAST_TIME     = 2.5,   -- seconds toast stays on screen
    FREQ_WINDOW    = 5,     -- rolling window for calls/sec
    AUTO_DETECT_S  = 10,    -- seconds between new-remote checks
    ARG_HIST_MAX   = 20,    -- max saved arg strings per remote
}

-- ====================================================================
--  SAFE CAPABILITY PROBES  (each wrapped so nothing can crash here)
-- ====================================================================
local function probe(fn)
    local ok, v = pcall(fn)
    return ok and v or false
end

local C = {}
C.isMobile     = probe(function() return UIS.TouchEnabled end)
C.pcall        = type(pcall) == "function"
C.http         = probe(function() HttpSvc:JSONEncode({}) return true end)
C.getgenv      = probe(function() return type(getgenv) == "function" end)
C.gethidprop   = probe(function() return type(gethiddenproperty) == "function" end)
C.firetouch    = probe(function() return type(firetouchinterest) == "function" end)
C.getrawmeta   = probe(function() return type(getrawmetatable) == "function" end)
C.hookmethod   = probe(function() return type(hookmetamethod) == "function" end)
C.getnamecall  = probe(function() return type(getnamecallmethod) == "function" end)
C.newcclosure  = probe(function() return type(newcclosure) == "function" end)
C.syn          = probe(function() return type(syn) == "table" end)
C.protect_gui  = probe(function() return C.syn and type(syn.protect_gui) == "function" end)
C.readfile     = probe(function() return type(readfile) == "function" end)
C.writefile    = probe(function() return type(writefile) == "function" end)
C.setclip      = probe(function() return type(setclipboard) == "function" end)
C.decompile    = probe(function() return type(decompile) == "function" end)
C.getscripts   = probe(function() return type(getloadedmodules)=="function" or type(getscripts)=="function" end)
C.clipboard    = C.setclip or probe(function()
    return UIS.CanSetClipboard and UIS:CanSetClipboard() == true
end)

-- ====================================================================
--  MODE DETECTION
-- ====================================================================
local function capScore()
    local s = 0
    if C.pcall       then s=s+1 end
    if C.http        then s=s+1 end
    if C.getgenv     then s=s+2 end
    if C.gethidprop  then s=s+2 end
    if C.firetouch   then s=s+2 end
    if C.getrawmeta  then s=s+2 end
    if C.hookmethod  then s=s+4 end
    if C.getnamecall then s=s+4 end
    if C.newcclosure then s=s+4 end
    if C.protect_gui then s=s+2 end
    return s
end
local function detectMode()
    local s = capScore()
    if s >= 18 then return "Ultra"
    elseif s >= 10 then return "Medium"
    elseif s >= 4  then return "Normal"
    else return "Low" end
end

local MODES = {"Low","Normal","Medium","Ultra"}
local MINFO = {
    Low    = {col=Color3.fromRGB(210,65,65),  icon="[!]", desc="Basic executor.\nScan + fire only."},
    Normal = {col=Color3.fromRGB(215,125,35), icon="[.]", desc="Standard executor.\nMost features enabled."},
    Medium = {col=Color3.fromRGB(200,190,0),  icon="[+]", desc="Good executor.\nSpy in partial mode."},
    Ultra  = {col=Color3.fromRGB(55,220,105), icon="[*]", desc="Full executor.\nAll features unlocked."},
}
local MFEAT = {
    Low    = {scan=true,fire=true,spy=false,autogen=false,clip=false,repeat_f=false,export=false,blacklist=false,scriptgen=false,freq=false},
    Normal = {scan=true,fire=true,spy=false,autogen=true, clip=true, repeat_f=true, export=true, blacklist=true, scriptgen=true, freq=false},
    Medium = {scan=true,fire=true,spy=true, autogen=true, clip=true, repeat_f=true, export=true, blacklist=true, scriptgen=true, freq=true},
    Ultra  = {scan=true,fire=true,spy=true, autogen=true, clip=true, repeat_f=true, export=true, blacklist=true, scriptgen=true, freq=true},
}

local detectedMode = detectMode()
local chosenMode   = detectedMode  -- may be overridden in splash

-- ====================================================================
--  SHARED STATE  (global so re-runs don't lose spy history)
-- ====================================================================
remoteLog   = remoteLog or {}
local spyLog      = {}
local favorites   = {}
local callCounts  = {}
local callTimes   = {}
local argHistory  = {}
local blacklist   = {}
local whitelist   = {}
local whitelistOn = false

-- ====================================================================
--  UTILITY
-- ====================================================================
local function safeRun(fn, ...)
    local ok, e = pcall(fn, ...)
    if not ok then warn("[RemoteExplorer] " .. tostring(e)) end
    return ok
end

-- Prune a table to max entries from the front
local function pruneTable(t, max)
    while #t > max do table.remove(t, 1) end
end

local function copyClip(txt)
    if C.setclip then
        local ok = pcall(setclipboard, txt)
        if ok then return true end
    end
    local ok2 = pcall(function()
        if UIS.CanSetClipboard and UIS:CanSetClipboard() then
            UIS:SetClipboard(txt)
        end
    end)
    return ok2
end

local function instPath(inst)
    local ok, full = pcall(function() return inst:GetFullName() end)
    if ok then return full end
    -- fallback: walk manually
    local p, par = inst.Name, inst.Parent
    while par and par ~= game do p = par.Name .. "." .. p; par = par.Parent end
    return p
end

-- Argument formatting
local function fmtArg(arg)
    local t = typeof(arg)
    if     t == "string"   then return '"' .. tostring(arg) .. '"', t
    elseif t == "number"   then return tostring(arg), t
    elseif t == "boolean"  then return tostring(arg), t
    elseif t == "nil"      then return "nil", "nil"
    elseif t == "Vector3"  then return ("Vector3.new(%.3f,%.3f,%.3f)"):format(arg.X,arg.Y,arg.Z), t
    elseif t == "CFrame"   then return ("CFrame.new(%.3f,%.3f,%.3f)"):format(arg.Position.X,arg.Position.Y,arg.Position.Z), t
    elseif t == "table"    then return "{table}", t
    elseif t == "Instance" then
        local ok2, name = pcall(function() return arg:GetFullName() end)
        return ok2 and name or tostring(arg), t
    else return "<" .. tostring(arg) .. ">", "other" end
end

local function fmtArgs(args)
    local parts = {}
    for _, a in ipairs(args) do
        local s = fmtArg(a)
        table.insert(parts, s)
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function parseArgs(str)
    local args = {}
    str = str:match("^%s*{%s*(.-)%s*}%s*$") or str
    local depth, cur = 0, ""
    local function push(s)
        local a = s:match("^%s*(.-)%s*$")
        if not a or a == "" then return end
        if     a:match('^".*"$') or a:match("^'.*'$") then table.insert(args, a:sub(2,-2))
        elseif tonumber(a)   then table.insert(args, tonumber(a))
        elseif a == "true"   then table.insert(args, true)
        elseif a == "false"  then table.insert(args, false)
        elseif a == "nil"    then table.insert(args, nil)
        else                      table.insert(args, a) end
    end
    for ch in str:gmatch(".") do
        if     ch == "{"            then depth = depth + 1; cur = cur .. ch
        elseif ch == "}"            then depth = depth - 1; if depth >= 0 then cur = cur .. ch end
        elseif ch == "," and depth == 0 then push(cur); cur = ""
        else cur = cur .. ch end
    end
    push(cur)
    return args
end

-- ====================================================================
--  SMART ARG SYSTEM  - 3-source accurate auto-generation
--  Returns: args (table), sourceLabel (string), confidence (string)
--  confidence: "live" | "log" | "script" | "pattern"
--  ("unknown" color kept as internal fallback only)
-- ====================================================================

-- Source 1: scan loaded game scripts for literal FireServer/InvokeServer calls
-- Returns a list of {args, scriptName} matches for a given remote name
local function scanScriptsForArgs(remoteName, method)
    local results = {}
    if not C.getscripts then return results end

    -- gather all loaded script sources
    local scripts = {}
    pcall(function()
        if type(getloadedmodules) == "function" then
            for _, s in ipairs(getloadedmodules()) do table.insert(scripts, s) end
        end
    end)
    pcall(function()
        if type(getscripts) == "function" then
            for _, s in ipairs(getscripts()) do table.insert(scripts, s) end
        end
    end)

    -- patterns to search: RemoteName:FireServer(...)  or  RemoteName:InvokeServer(...)
    local mth = method or "FireServer"
    local searchPatterns = {
        remoteName .. ":" .. mth .. "%s*%((.-)%)",
        '"' .. remoteName .. '"[^:]*:' .. mth .. "%s*%((.-)%)",
    }

    for _, scr in ipairs(scripts) do
        local src, sName = "", "?"
        pcall(function() src = decompile and decompile(scr) or "" end)
        pcall(function() sName = scr.Name or "?" end)
        if type(src) == "string" and #src > 0 then
            for _, pat in ipairs(searchPatterns) do
                for rawArgs in src:gmatch(pat) do
                    rawArgs = rawArgs:match("^%s*(.-)%s*$")
                    if rawArgs and rawArgs ~= "" then
                        -- parse the literal args from source
                        local parsed = {}
                        pcall(function() parsed = parseArgs("{" .. rawArgs .. "}") end)
                        if #parsed > 0 then
                            table.insert(results, {args=parsed, script=sName, raw=rawArgs})
                        end
                    end
                end
            end
        end
    end
    return results
end

-- Human-readable arg type description for the source label
local function describeArgs(args)
    if #args == 0 then return "no arguments" end
    local parts = {}
    for _, a in ipairs(args) do
        local t = typeof(a)
        if t == "string" then
            table.insert(parts, '"' .. tostring(a):sub(1,18) .. (tostring(a):len()>18 and ".." or "") .. '"')
        elseif t == "number" or t == "boolean" then
            table.insert(parts, tostring(a))
        elseif t == "nil" then
            table.insert(parts, "nil")
        elseif t == "Instance" then
            local ok2, n2 = pcall(function() return a.Name end)
            table.insert(parts, ok2 and n2 or "Instance")
        else
            table.insert(parts, t)
        end
    end
    return table.concat(parts, ", ")
end

-- Name-pattern fallback (improved with more patterns + better descriptions)
local function patternArgs(remote)
    local n   = remote.Name:lower()
    local cam = workspace.CurrentCamera
    local pos = cam and cam.CFrame.Position or Vector3.new()
    local function tgt()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then return p.Character end
        end; return "Target"
    end

    -- Each entry: {pattern, args, description}
    local PATTERNS = {
        -- Movement
        {{"teleport","warp","^tp$","setpos"},            {pos},                    "Vector3 position"},
        {{"move","position","setcframe"},                 {pos},                    "Vector3 position"},
        -- Economy
        {{"buy","purchase","shop","store","order"},       {"item_id", 1},           "itemId, quantity"},
        {{"sell"},                                        {"item_id", 1},           "itemId, quantity"},
        {{"craft","forge","make"},                        {"item_id", 1},           "itemId, amount"},
        {{"upgrade","evolve","enhance"},                  {"item_id"},              "itemId"},
        {{"trade"},                                       {"item_id", 1},           "itemId, amount"},
        -- Combat
        {{"damage","hurt","injure"},                      {tgt(), 10},              "target, damage"},
        {{"hit","strike","punch"},                        {tgt(), 10},              "target, damage"},
        {{"attack","fight"},                              {tgt(), 10},              "target, damage"},
        {{"kill","destroy","eliminate"},                  {tgt()},                  "target"},
        {{"heal","revive","regen"},                       {LocalPlayer and LocalPlayer.Character or "Player"}, "target"},
        -- Inventory
        {{"equip","wear","hold"},                         {"DefaultTool"},          "toolName"},
        {{"unequip","drop","remove"},                     {"DefaultTool"},          "toolName"},
        {{"select","choose"},                             {"DefaultTool"},          "itemName"},
        {{"collect","grab","pickup","loot","get"},        {"ItemName"},             "itemName"},
        -- Interaction
        {{"interact","use","activate"},                   {"Part"},                 "partName"},
        {{"open"},                                        {"DoorName"},             "objectName"},
        {{"close"},                                       {"DoorName"},             "objectName"},
        {{"sit"},                                         {"SeatName"},             "seatName"},
        -- Boolean toggles
        {{"toggle","switch","flip"},                      {true},                   "boolean"},
        {{"enable","on","start","begin"},                 {true},                   "boolean (true)"},
        {{"disable","off","stop","end"},                  {false},                  "boolean (false)"},
        -- Chat
        {{"chat","message","send","say","talk"},          {"Hello"},                "message string"},
        -- Player actions
        {{"sprint","run","dash"},                         {true},                   "boolean"},
        {{"walk","slow"},                                 {false},                  "boolean"},
        {{"jump"},                                        {},                       "(no args)"},
        {{"respawn","reset","die"},                       {},                       "(no args)"},
        {{"vote"},                                        {"option1"},              "option string"},
        -- Admin
        {{"kick"},                                        {"Reason"},               "reason string"},
        {{"ban"},                                         {"Reason", 3600},         "reason, duration"},
        {{"mute"},                                        {LocalPlayer and LocalPlayer.Name or "Player"}, "playerName"},
        -- Data
        {{"get","fetch","load","request"},                {"key"},                  "key string"},
        {{"set","save","store","update"},                 {"key", "value"},         "key, value"},
        {{"delete","remove","clear"},                     {"key"},                  "key string"},
    }

    for _, entry in ipairs(PATTERNS) do
        local pats, args, desc = entry[1], entry[2], entry[3]
        for _, pat in ipairs(pats) do
            if n:find(pat) then
                return args, desc
            end
        end
    end

    -- Total unknown
    local isEvent = remote:IsA("RemoteEvent")
    return isEvent and {} or {}, nil
end

-- MAIN: smartArgs - tries all 3 sources in order
-- Returns: args, sourceLabel, confidence
local function smartArgs(remote)
    local key    = instPath(remote)
    local rName  = remote.Name
    local method = remote:IsA("RemoteEvent") and "FireServer" or "InvokeServer"

    -- ?? Source 1: Spy log (most accurate - real intercepted calls) ??
    -- Search newest first, prefer spy log over remoteLog
    local bestSpy, bestSpyAge = nil, math.huge
    for i = #spyLog, 1, -1 do
        local e = spyLog[i]
        if e.remote == remote and #e.args > 0 then
            local age = #spyLog - i  -- 0 = most recent
            if age < bestSpyAge then
                bestSpy = e; bestSpyAge = age
            end
        end
    end
    if bestSpy then
        local ago = bestSpyAge == 0 and "most recent" or (bestSpyAge .. " call(s) ago")
        return bestSpy.args,
            "[OK] Live spy  .  " .. ago .. "  .  " .. #bestSpy.args .. " arg(s)",
            "live"
    end

    -- ?? Source 2: remoteLog (manually fired calls) ??
    for i = #remoteLog, 1, -1 do
        local e = remoteLog[i]
        if e.remote == remote and #e.args > 0 then
            return e.args,
                "[OK] From fired log  .  " .. #e.args .. " arg(s)",
                "log"
        end
    end

    -- ?? Source 3: Script scanner (decompiled source) ??
    local scriptResults = scanScriptsForArgs(rName, method)
    if #scriptResults > 0 then
        -- Pick the result with the most arguments (most informative)
        local best = scriptResults[1]
        for _, r in ipairs(scriptResults) do
            if #r.args > #best.args then best = r end
        end
        return best.args,
            "~ Script scan  .  " .. best.script .. "  .  raw: " .. best.raw:sub(1, 38),
            "script"
    end

    -- ?? Source 4: Name-pattern fallback ??
    local patArgs, patDesc = patternArgs(remote)
    if patDesc then
        return patArgs,
            "[!] Pattern guess  .  " .. rName .. " -> " .. patDesc,
            "pattern"
    end

    -- ?? Total unknown - best guess based on remote type ??
    local isEvent = remote:IsA("RemoteEvent")
    local fallback = isEvent and {"arg1", 1, true} or {"getData", "param1"}
    return fallback,
        "[!] Pattern guess  .  " .. rName .. " -> " .. (isEvent and "generic event args" or "generic function args"),
        "pattern"
end

-- Script generator (SimpleSpy style output)
local function genScript(remote, args, method)
    local path  = instPath(remote)
    local mth   = method or (remote:IsA("RemoteEvent") and "FireServer" or "InvokeServer")
    local inner = fmtArgs(args):sub(2, -2)
    local lines = {
        "-- Generated by Remote Explorer v3.1",
        "-- Remote: " .. path,
        "-- Method: " .. mth,
        "-- Time:   " .. os.date(),
        "",
        'local remote = game:GetService("ReplicatedStorage")'
            .. ':FindFirstChild("' .. remote.Name .. '", true)',
        "if not remote then",
        '    warn("Remote not found: ' .. remote.Name .. '")',
        "    return",
        "end",
        "",
    }
    if remote:IsA("RemoteEvent") then
        table.insert(lines, "remote:FireServer(" .. inner .. ")")
    else
        table.insert(lines, 'local result = remote:InvokeServer(' .. inner .. ")")
        table.insert(lines, 'print("[RemoteExplorer] Result:", result)')
    end
    return table.concat(lines, "\n")
end

-- Call frequency tracking
local function recordCall(key)
    callTimes[key] = callTimes[key] or {}
    table.insert(callTimes[key], os.clock())
    -- prune entries older than window + 1s buffer
    local cutoff = os.clock() - CFG.FREQ_WINDOW - 1
    while callTimes[key][1] and callTimes[key][1] < cutoff do
        table.remove(callTimes[key], 1)
    end
end

local function getFreq(key)
    if not callTimes[key] or #callTimes[key] == 0 then return 0 end
    local now, count = os.clock(), 0
    local cutoff = now - CFG.FREQ_WINDOW
    for _, t in ipairs(callTimes[key]) do
        if t >= cutoff then count = count + 1 end
    end
    return count / CFG.FREQ_WINDOW
end

-- ====================================================================
--  CAPABILITY DISPLAY TABLE  (splash use)
-- ====================================================================
local CAP_ROWS = {
    {"pcall / HttpService",        C.pcall and C.http},
    {"getgenv / getenv",           C.getgenv},
    {"gethiddenproperty",          C.gethidprop},
    {"getrawmetatable",            C.getrawmeta},
    {"hookmetamethod",             C.hookmethod},
    {"getnamecallmethod",          C.getnamecall},
    {"newcclosure",                C.newcclosure},
    {"syn / protect_gui",          C.protect_gui},
    {"clipboard access",           C.clipboard},
    {"readfile / writefile",       C.readfile and C.writefile},
    {"decompile",                  C.decompile},
    {"getscripts / getloadedmodules", C.getscripts},
}
local SCAN_STEPS = {
    {frac=0.08, txt="Checking basic Lua globals..."},
    {frac=0.18, txt="Testing pcall / HttpService..."},
    {frac=0.30, txt="Probing executor extensions..."},
    {frac=0.44, txt="Checking getgenv / metamethods..."},
    {frac=0.58, txt="Testing hookmetamethod..."},
    {frac=0.70, txt="Testing getnamecallmethod..."},
    {frac=0.80, txt="Verifying newcclosure..."},
    {frac=0.88, txt="Checking clipboard / file I/O..."},
    {frac=0.95, txt="Testing decompile / getscripts..."},
    {frac=1.00, txt="Finalizing mode assignment..."},
}

-- ====================================================================
--  MOBILE DRAG HELPER
--  Makes any Frame draggable via touch (since .Draggable is PC-only)
-- ====================================================================
local function makeDraggable(frame)
    -- PC: use built-in
    pcall(function() frame.Draggable = true end)

    if not C.isMobile then return end

    -- Touch fallback
    local dragging = false
    local startTouchPos, startFramePos

    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startTouchPos = inp.Position
            startFramePos = frame.Position
        end
    end)
    frame.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.Touch then
            local delta = inp.Position - startTouchPos
            frame.Position = UDim2.new(
                startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
                startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ====================================================================
--  TWEEN HELPER  (silent, never crashes)
-- ====================================================================
local function tw(obj, info, props)
    pcall(function()
        TweenSvc:Create(obj, info, props):Play()
    end)
end
local function twFast(obj, props)
    tw(obj, TweenInfo.new(0.22, Enum.EasingStyle.Quad), props)
end

-- ====================================================================
--  SPLASH / PRE-LOADER
-- ====================================================================
local SplashGui = Instance.new("ScreenGui")
SplashGui.Name = "REXSplash"
SplashGui.ResetOnSpawn = false
SplashGui.DisplayOrder = 9999
if C.protect_gui then pcall(syn.protect_gui, SplashGui) end
SplashGui.Parent = CoreGui

local sOverlay = Instance.new("Frame", SplashGui)
sOverlay.Size = UDim2.new(1,0,1,0)
sOverlay.BackgroundColor3 = Color3.fromRGB(0,0,0)
sOverlay.BackgroundTransparency = 0.45
sOverlay.BorderSizePixel = 0

-- Card dimensions adapt to mobile
local CARD_W = C.isMobile and 300 or 420
local CARD_H = C.isMobile and 330 or 420

local sCard = Instance.new("Frame", SplashGui)
sCard.Size = UDim2.new(0, CARD_W, 0, CARD_H)
sCard.AnchorPoint = Vector2.new(0.5, 0.5)
sCard.Position = UDim2.new(0.5, 0, 0.5, 0)
sCard.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
sCard.BorderSizePixel = 0
sCard.BackgroundTransparency = 1
Instance.new("UICorner", sCard).CornerRadius = UDim.new(0, 16)
local sCardStroke = nil
pcall(function() sCardStroke = Instance.new("UIStroke", sCard) end)
pcall(function() sCardStroke.Color = Color3.fromRGB(155, 18, 18) end)
pcall(function() sCardStroke.Thickness = 1.5 end)

-- Helper: text label on card
local function sLbl(txt, y, h, sz, bold, col, center)
    local l = Instance.new("TextLabel", sCard)
    l.Size = UDim2.new(1, -24, 0, h)
    l.Position = UDim2.new(0, 12, 0, y)
    l.BackgroundTransparency = 1
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = sz or 12
    l.TextColor3 = col or Color3.fromRGB(200, 60, 60)
    l.Text = txt
    l.TextXAlignment = center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    l.TextTransparency = 1
    l.TextWrapped = true
    return l
end

local sTitleLbl = sLbl("Remote Explorer  v3.1", 12, 28, C.isMobile and 18 or 22, true,
    Color3.fromRGB(255, 42, 42), true)
local sSubLbl   = sLbl("Initializing...", 46, 16, 12, false, Color3.fromRGB(185, 95, 95))

-- Capability list (compact on mobile)
local CAP_ROW_H = C.isMobile and 8 or 9
local sCF = Instance.new("Frame", sCard)
sCF.Size = UDim2.new(1, -24, 0, #CAP_ROWS * (CAP_ROW_H + 1))
sCF.Position = UDim2.new(0, 12, 0, 68)
sCF.BackgroundTransparency = 1
sCF.ClipsDescendants = true
Instance.new("UIListLayout", sCF).Padding = UDim.new(0, 1)

local sCapLabels = {}
for _, row in ipairs(CAP_ROWS) do
    local l = Instance.new("TextLabel", sCF)
    l.Size = UDim2.new(1, 0, 0, CAP_ROW_H)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextSize = CAP_ROW_H
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(125, 55, 55)
    l.Text = "  ?  " .. row[1]
    l.TextTransparency = 1
    table.insert(sCapLabels, {lbl = l, ok = row[2]})
end

-- Progress bar
local BAR_Y = 68 + #CAP_ROWS * (CAP_ROW_H + 1) + 8
local sBarBG = Instance.new("Frame", sCard)
sBarBG.Size = UDim2.new(0.88, 0, 0, 7)
sBarBG.Position = UDim2.new(0.06, 0, 0, BAR_Y)
sBarBG.BackgroundColor3 = Color3.fromRGB(42, 0, 0)
sBarBG.BorderSizePixel = 0
Instance.new("UICorner", sBarBG).CornerRadius = UDim.new(1, 0)
local sBar = Instance.new("Frame", sBarBG)
sBar.Size = UDim2.new(0, 0, 1, 0)
sBar.BackgroundColor3 = Color3.fromRGB(205, 32, 32)
sBar.BorderSizePixel = 0
Instance.new("UICorner", sBar).CornerRadius = UDim.new(1, 0)

-- Mode display box
local MODE_BOX_Y = BAR_Y + 14
local sModeBox = Instance.new("Frame", sCard)
sModeBox.Size = UDim2.new(0.88, 0, 0, 76)
sModeBox.Position = UDim2.new(0.06, 0, 0, MODE_BOX_Y)
sModeBox.BackgroundColor3 = Color3.fromRGB(26, 0, 0)
sModeBox.BorderSizePixel = 0
sModeBox.Visible = false
Instance.new("UICorner", sModeBox).CornerRadius = UDim.new(0, 10)
local sModeStroke = nil
pcall(function() sModeStroke = Instance.new("UIStroke", sModeBox) end); sModeStroke.Thickness = 1

local sModeIcon = Instance.new("TextLabel", sModeBox)
sModeIcon.Size = UDim2.new(0, 42, 1, 0)
sModeIcon.BackgroundTransparency = 1
sModeIcon.Font = Enum.Font.GothamBold
sModeIcon.TextSize = 26

local sModeNameLbl = Instance.new("TextLabel", sModeBox)
sModeNameLbl.Size = UDim2.new(1, -50, 0, 26)
sModeNameLbl.Position = UDim2.new(0, 48, 0, 6)
sModeNameLbl.BackgroundTransparency = 1
sModeNameLbl.Font = Enum.Font.GothamBold
sModeNameLbl.TextSize = 18
sModeNameLbl.TextXAlignment = Enum.TextXAlignment.Left

local sModeDescLbl = Instance.new("TextLabel", sModeBox)
sModeDescLbl.Size = UDim2.new(1, -50, 0, 36)
sModeDescLbl.Position = UDim2.new(0, 48, 0, 32)
sModeDescLbl.BackgroundTransparency = 1
sModeDescLbl.Font = Enum.Font.Gotham
sModeDescLbl.TextSize = 10
sModeDescLbl.TextXAlignment = Enum.TextXAlignment.Left
sModeDescLbl.TextYAlignment = Enum.TextYAlignment.Top
sModeDescLbl.TextWrapped = true
sModeDescLbl.TextColor3 = Color3.fromRGB(185, 125, 125)

-- Override row
local OV_Y = MODE_BOX_Y + 80
local sOvLbl = sLbl("Override mode:", OV_Y, 16, 11, false, Color3.fromRGB(165, 68, 68))
sOvLbl.Visible = false

local sMBFrame = Instance.new("Frame", sCard)
sMBFrame.Size = UDim2.new(0.88, 0, 0, 28)
sMBFrame.Position = UDim2.new(0.06, 0, 0, OV_Y + 18)
sMBFrame.BackgroundTransparency = 1
sMBFrame.Visible = false
local sMBLayout = Instance.new("UIListLayout", sMBFrame)
sMBLayout.FillDirection = Enum.FillDirection.Horizontal
sMBLayout.Padding = UDim.new(0, 5)

local sModeButtons = {}
for _, m in ipairs(MODES) do
    local b = Instance.new("TextButton", sMBFrame)
    b.Size = UDim2.new(0, C.isMobile and 60 or 68, 1, 0)
    b.Text = m; b.Font = Enum.Font.GothamBold; b.TextSize = 12
    b.BackgroundColor3 = Color3.fromRGB(48, 0, 0)
    b.TextColor3 = Color3.fromRGB(195, 65, 65)
    b.BorderSizePixel = 0; b.TextTransparency = 1
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    sModeButtons[m] = b
end

local CONFIRM_Y = OV_Y + 18 + 32
local sConfirm = Instance.new("TextButton", sCard)
sConfirm.Size = UDim2.new(0.88, 0, 0, 34)
sConfirm.Position = UDim2.new(0.06, 0, 0, CONFIRM_Y)
sConfirm.BackgroundColor3 = Color3.fromRGB(140, 10, 10)
sConfirm.TextColor3 = Color3.fromRGB(255, 255, 255)
sConfirm.Font = Enum.Font.GothamBold; sConfirm.TextSize = 15
sConfirm.Text = "Launch Remote Explorer"
sConfirm.BorderSizePixel = 0; sConfirm.Visible = false; sConfirm.TextTransparency = 1
Instance.new("UICorner", sConfirm).CornerRadius = UDim.new(0, 8)

-- Fit card height to content
sCard.Size = UDim2.new(0, CARD_W, 0, math.max(CARD_H, CONFIRM_Y + 44))

local function refreshSplashMode(mode)
    local info = MINFO[mode]
    sModeNameLbl.Text = mode:upper(); sModeNameLbl.TextColor3 = info.col
    sModeIcon.Text = info.icon; sModeIcon.TextColor3 = info.col
    sModeDescLbl.Text = info.desc
    pcall(function() sCardStroke.Color = info.col end)
    for mname, btn in pairs(sModeButtons) do
        btn.BackgroundColor3 = (mname == mode) and Color3.fromRGB(108, 0, 0) or Color3.fromRGB(48, 0, 0)
        btn.TextColor3 = (mname == mode) and Color3.fromRGB(255, 195, 195) or Color3.fromRGB(195, 65, 65)
    end
end

for mname, btn in pairs(sModeButtons) do
    btn.MouseButton1Click:Connect(function()
        chosenMode = mname
        refreshSplashMode(mname)
    end)
end

local function tweenBarTo(frac, dur)
    local t = TweenSvc:Create(sBar, TweenInfo.new(dur, Enum.EasingStyle.Quad), {Size = UDim2.new(frac, 0, 1, 0)})
    t:Play(); t.Completed:Wait()
end

-- ?? Animate splash ????????????????????????????????????????????????
task.spawn(function()
    sCard.BackgroundTransparency = 1
    tw(sCard, TweenInfo.new(0.42, Enum.EasingStyle.Quint), {BackgroundTransparency = 0})
    task.wait(0.26)
    tw(sTitleLbl, TweenInfo.new(0.28), {TextTransparency = 0})
    task.wait(0.1)
    tw(sSubLbl, TweenInfo.new(0.26), {TextTransparency = 0})
    task.wait(0.18)

    -- Reveal cap rows one by one, matching scan steps
    for i, entry in ipairs(sCapLabels) do
        local step = SCAN_STEPS[math.min(i, #SCAN_STEPS)]
        sSubLbl.Text = step.txt
        tweenBarTo(step.frac, 0.22)
        tw(entry.lbl, TweenInfo.new(0.16), {TextTransparency = 0})
        entry.lbl.TextColor3 = entry.ok
            and Color3.fromRGB(50, 205, 90)
            or  Color3.fromRGB(158, 48, 48)
        entry.lbl.Text = (entry.ok and "  [OK]  " or "  [X]  ") .. CAP_ROWS[i][1]
        task.wait(0.065)
    end
    tweenBarTo(1, 0.26); task.wait(0.16)
    sSubLbl.Text = "Analysis complete!"

    -- Show mode box
    sModeBox.Visible = true; sModeBox.BackgroundTransparency = 1
    refreshSplashMode(detectedMode)
    tw(sModeBox, TweenInfo.new(0.3), {BackgroundTransparency = 0})
    for _, d in ipairs(sModeBox:GetDescendants()) do
        pcall(function() d.TextTransparency = 1 end)
    end
    task.wait(0.08)
    for _, d in ipairs(sModeBox:GetDescendants()) do
        pcall(function() tw(d, TweenInfo.new(0.26), {TextTransparency = 0}) end)
    end
    task.wait(0.32)

    -- Override row
    sOvLbl.Visible = true; sMBFrame.Visible = true
    tw(sOvLbl, TweenInfo.new(0.26), {TextTransparency = 0})
    for _, b in pairs(sModeButtons) do
        tw(b, TweenInfo.new(0.2), {TextTransparency = 0, BackgroundTransparency = 0})
    end
    task.wait(0.1)
    sConfirm.Visible = true
    tw(sConfirm, TweenInfo.new(0.26), {TextTransparency = 0, BackgroundTransparency = 0})

    -- Hover for PC
    if not C.isMobile then
        sConfirm.MouseEnter:Connect(function()
            twFast(sConfirm, {BackgroundColor3 = Color3.fromRGB(195, 22, 22)})
        end)
        sConfirm.MouseLeave:Connect(function()
            twFast(sConfirm, {BackgroundColor3 = Color3.fromRGB(140, 10, 10)})
        end)
    end
end)

-- ====================================================================
--  MAIN GUI  (built on confirm)
-- ====================================================================
local launched = false
sConfirm.MouseButton1Click:Connect(function()
    if launched then return end
    launched = true

    tw(sCard,    TweenInfo.new(0.35), {BackgroundTransparency = 1})
    tw(sOverlay, TweenInfo.new(0.35), {BackgroundTransparency = 1})
    task.wait(0.4)
    SplashGui:Destroy()

    local feat = MFEAT[chosenMode]

    -- ?? ScreenGui ?????????????????????????????????????????????????
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RemoteExplorerV31"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 100
    if C.protect_gui then pcall(syn.protect_gui, ScreenGui) end
    ScreenGui.Parent = CoreGui

    -- ?? TOAST ?????????????????????????????????????????????????????
    local toastQueue = {}; local toastRunning = false
    local TOAST_COLORS = {
        ok   = Color3.fromRGB(32, 148, 70),
        err  = Color3.fromRGB(170, 32, 32),
        warn = Color3.fromRGB(178, 138, 0),
        info = Color3.fromRGB(58, 58, 138),
    }
    local function toast(txt, kind)
        table.insert(toastQueue, {txt = txt, kind = kind or "info"})
        if toastRunning then return end
        toastRunning = true
        task.spawn(function()
            while #toastQueue > 0 do
                local t = table.remove(toastQueue, 1)
                local col = TOAST_COLORS[t.kind] or TOAST_COLORS.info
                local tf = Instance.new("Frame", ScreenGui)
                tf.Size = UDim2.new(0, 280, 0, 36)
                tf.AnchorPoint = Vector2.new(0.5, 0)
                tf.Position = UDim2.new(0.5, 0, 1, 10)
                tf.BackgroundColor3 = col; tf.BorderSizePixel = 0; tf.BackgroundTransparency = 0.06
                Instance.new("UICorner", tf).CornerRadius = UDim.new(0, 8)
                local tl = Instance.new("TextLabel", tf)
                tl.Size = UDim2.new(1, -10, 1, 0); tl.Position = UDim2.new(0, 5, 0, 0)
                tl.BackgroundTransparency = 1; tl.Font = Enum.Font.GothamBold; tl.TextSize = 12
                tl.TextColor3 = Color3.fromRGB(255,255,255); tl.Text = t.txt; tl.TextWrapped = true
                tw(tf, TweenInfo.new(0.26, Enum.EasingStyle.Back), {Position = UDim2.new(0.5, 0, 1, -52)})
                task.wait(CFG.TOAST_TIME)
                tw(tf, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 1, 10), BackgroundTransparency = 1})
                tw(tl, TweenInfo.new(0.2), {TextTransparency = 1})
                task.wait(0.26); pcall(function() tf:Destroy() end); task.wait(0.04)
            end
            toastRunning = false
        end)
    end

    -- ?? DIMENSIONS (mobile-aware) ??????????????????????????????????
    local W  = C.isMobile and 300 or 540
    local H  = C.isMobile and 370 or 455
    local TW_TAB = C.isMobile and 56 or 76  -- tab button width

    -- ?? MAIN FRAME ????????????????????????????????????????????????
    local MF = Instance.new("Frame", ScreenGui)
    MF.Size = UDim2.new(0, W, 0, H)
    MF.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    MF.BackgroundColor3 = Color3.fromRGB(15, 0, 0)
    MF.BorderSizePixel = 0
    MF.Active = true
    MF.ClipsDescendants = true
    Instance.new("UICorner", MF).CornerRadius = UDim.new(0, 12)
    local mfStroke = nil
    pcall(function() mfStroke = Instance.new("UIStroke", MF) end)
    pcall(function() mfStroke.Color = MINFO[chosenMode].col; mfStroke.Thickness = 1.2 end)
    MF.BackgroundTransparency = 1
    tw(MF, TweenInfo.new(0.42, Enum.EasingStyle.Quint), {BackgroundTransparency = 0})

    makeDraggable(MF)

    -- ?? RESIZE HANDLE (PC only - pointless on mobile) ?????????????
    local resizeHandle = nil
    if not C.isMobile then
        resizeHandle = Instance.new("TextButton", ScreenGui)
        resizeHandle.Size = UDim2.new(0, 16, 0, 16)
        resizeHandle.BackgroundColor3 = Color3.fromRGB(75, 0, 0)
        resizeHandle.Text = ">>"; resizeHandle.Font = Enum.Font.GothamBold
        resizeHandle.TextSize = 10; resizeHandle.TextColor3 = Color3.fromRGB(195, 75, 75)
        resizeHandle.BorderSizePixel = 0; resizeHandle.Active = true
        Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 4)

        local function updateHandle()
            if not resizeHandle or not resizeHandle.Parent then return end
            local p = MF.AbsolutePosition; local s = MF.AbsoluteSize
            resizeHandle.Position = UDim2.new(0, p.X + s.X - 8, 0, p.Y + s.Y - 8)
        end
        updateHandle()

        local resizing, rsStart, rsOrigSz = false, nil, nil
        resizeHandle.MouseButton1Down:Connect(function()
            resizing = true
            rsStart  = UIS:GetMouseLocation()
            rsOrigSz = MF.AbsoluteSize
        end)
        UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
        -- Only update handle on mouse move, NOT every RenderStep
        UIS.InputChanged:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseMovement then
                updateHandle()
                if resizing then
                    local d = UIS:GetMouseLocation() - rsStart
                    MF.Size = UDim2.new(0, math.max(340, rsOrigSz.X + d.X),
                                        0, math.max(260, rsOrigSz.Y + d.Y))
                    H = MF.AbsoluteSize.Y  -- update H reference after resize
                end
            end
        end)
    end

    -- ?? STYLE HELPER ??????????????????????????????????????????????
    local function styleB(b, locked)
        b.BorderSizePixel = 0; b.Font = Enum.Font.GothamBold; b.TextSize = 13
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        if locked then
            b.BackgroundColor3 = Color3.fromRGB(30, 5, 5)
            b.TextColor3 = Color3.fromRGB(80, 30, 30)
        else
            b.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
            b.TextColor3 = Color3.fromRGB(255, 36, 36)
            if not C.isMobile then
                b.MouseEnter:Connect(function() twFast(b, {BackgroundColor3 = Color3.fromRGB(76, 0, 0)}) end)
                b.MouseLeave:Connect(function() twFast(b, {BackgroundColor3 = Color3.fromRGB(50, 0, 0)}) end)
            end
        end
    end

    -- ?? TOP BAR ???????????????????????????????????????????????????
    local TopBar = Instance.new("Frame", MF)
    TopBar.Size = UDim2.new(1, 0, 0, 30)
    TopBar.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
    TopBar.BorderSizePixel = 0
    Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)

    local TitleL = Instance.new("TextLabel", TopBar)
    TitleL.Size = UDim2.new(1, -175, 1, 0); TitleL.Position = UDim2.new(0, 10, 0, 0)
    TitleL.BackgroundTransparency = 1; TitleL.Text = "Remote Explorer"
    TitleL.TextColor3 = Color3.fromRGB(255, 40, 40)
    TitleL.Font = Enum.Font.GothamBold; TitleL.TextSize = 15
    TitleL.TextXAlignment = Enum.TextXAlignment.Left

    local Badge = Instance.new("TextLabel", TopBar)
    Badge.Size = UDim2.new(0, 60, 0, 18); Badge.Position = UDim2.new(0, 150, 0, 6)
    Badge.BackgroundColor3 = MINFO[chosenMode].col; Badge.BackgroundTransparency = 0.35
    Badge.Text = MINFO[chosenMode].icon .. " " .. chosenMode
    Badge.Font = Enum.Font.GothamBold; Badge.TextSize = 10
    Badge.TextColor3 = Color3.fromRGB(255, 255, 255); Badge.BorderSizePixel = 0
    Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 4)

    -- Badge pulse (task-based, no RenderStepped)
    task.spawn(function()
        while Badge and Badge.Parent do
            tw(Badge, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundTransparency = 0.70})
            task.wait(1.1)
            if not (Badge and Badge.Parent) then break end
            tw(Badge, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundTransparency = 0.16})
            task.wait(1.1)
        end
    end)

    local CloseB = Instance.new("TextButton", TopBar)
    CloseB.Size = UDim2.new(0, 28, 1, 0); CloseB.Position = UDim2.new(1, -28, 0, 0)
    CloseB.Text = "X"; styleB(CloseB)
    CloseB.MouseButton1Click:Connect(function()
        if resizeHandle then pcall(function() resizeHandle:Destroy() end) end
        ScreenGui:Destroy()
    end)

    local MinB = Instance.new("TextButton", TopBar)
    MinB.Size = UDim2.new(0, 28, 1, 0); MinB.Position = UDim2.new(1, -58, 0, 0)
    MinB.Text = "-"; styleB(MinB)
    local minimized = false
    local currentH = H  -- track real height across resizes
    MinB.MouseButton1Click:Connect(function()
        minimized = not minimized
        currentH = MF.AbsoluteSize.Y  -- capture current height before minimizing
        local sz = minimized
            and UDim2.new(0, MF.AbsoluteSize.X, 0, 30)
            or  UDim2.new(0, MF.AbsoluteSize.X, 0, currentH)
        tw(MF, TweenInfo.new(0.28, Enum.EasingStyle.Quint), {Size = sz})
        for _, c in ipairs(MF:GetChildren()) do
            if c ~= TopBar then c.Visible = not minimized end
        end
        if resizeHandle then resizeHandle.Visible = not minimized end
    end)

    -- ?? SEARCH / SPY FILTER BOXES ?????????????????????????????????
    local function mkTextBox(placeholder, tcol, pcol)
        local b = Instance.new("TextBox", MF)
        b.Size = UDim2.new(1, -20, 0, 24); b.Position = UDim2.new(0, 10, 0, 34)
        b.BackgroundColor3 = Color3.fromRGB(24, 0, 0)
        b.TextColor3 = tcol; b.PlaceholderText = placeholder; b.PlaceholderColor3 = pcol
        b.Text = ""; b.Font = Enum.Font.Gotham; b.TextSize = 12
        b.ClearTextOnFocus = false; b.BorderSizePixel = 0
        b.TextXAlignment = Enum.TextXAlignment.Left; b.Visible = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 6)
        return b
    end
    local SearchBox = mkTextBox("  [?]  Search remotes...",
        Color3.fromRGB(255, 98, 98), Color3.fromRGB(100, 35, 35))
    local SpyFilter = mkTextBox("  [?]  Filter spy by name...",
        Color3.fromRGB(255, 148, 75), Color3.fromRGB(100, 52, 25))

    -- ?? TABS ??????????????????????????????????????????????????????
    local TAB_Y = 62
    local function mkTab(txt, x, locked)
        local b = Instance.new("TextButton", MF)
        b.Size = UDim2.new(0, TW_TAB, 0, 24); b.Position = UDim2.new(0, x, 0, TAB_Y)
        b.Text = txt; styleB(b, locked); b.TextSize = C.isMobile and 10 or 11
        return b
    end
    local GAP = TW_TAB + 3
    local LearnTab  = mkTab("Learn",      8)
    local RemoteTab = mkTab("Remotes",    8 + GAP)
    local FavTab    = mkTab("[*] Favs",     8 + GAP*2)
    local SpyTab    = mkTab(feat.spy and "Spy" or "[L] Spy",        8 + GAP*3, not feat.spy)
    local BlackTab  = mkTab(feat.blacklist and "[B] BL" or "[L] BL", 8 + GAP*4, not feat.blacklist)

    -- Spy count badge
    local SpyBadge = Instance.new("TextLabel", MF)
    SpyBadge.Size = UDim2.new(0, 18, 0, 12)
    SpyBadge.Position = UDim2.new(0, 8 + GAP*3 + TW_TAB - 14, 0, TAB_Y - 5)
    SpyBadge.BackgroundColor3 = Color3.fromRGB(195, 25, 25); SpyBadge.Text = "0"
    SpyBadge.Font = Enum.Font.GothamBold; SpyBadge.TextSize = 8
    SpyBadge.TextColor3 = Color3.fromRGB(255,255,255); SpyBadge.BorderSizePixel = 0
    SpyBadge.Visible = false
    Instance.new("UICorner", SpyBadge).CornerRadius = UDim.new(1, 0)

    local spyCount = 0
    local function bumpSpy()
        spyCount = spyCount + 1
        SpyBadge.Text = spyCount > 99 and "99+" or tostring(spyCount)
        SpyBadge.Visible = true
    end

    -- ?? PANEL FACTORY ?????????????????????????????????????????????
    local PY = TAB_Y + 28

    local function mkScrollPanel(bottomPad)
        local f = Instance.new("ScrollingFrame", MF)
        f.Position = UDim2.new(0, 10, 0, PY)
        f.Size = UDim2.new(1, -20, 1, -(PY + 26 + (bottomPad or 0)))
        f.BackgroundColor3 = Color3.fromRGB(11, 0, 0)
        f.BorderSizePixel = 0; f.CanvasSize = UDim2.new(0,0,0,0)
        f.ScrollBarThickness = 3; f.ScrollBarImageColor3 = Color3.fromRGB(145, 25, 25)
        pcall(function() f.AutomaticCanvasSize = Enum.AutomaticSize.Y end); f.Visible = false
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        local ll = Instance.new("UIListLayout", f); ll.Padding = UDim.new(0, 3)
        Instance.new("UIPadding", f).PaddingTop = UDim.new(0, 4)
        return f
    end
    local function mkFramePanel()
        local f = Instance.new("Frame", MF)
        f.Position = UDim2.new(0, 10, 0, PY)
        f.Size = UDim2.new(1, -20, 1, -(PY + 26))
        f.BackgroundColor3 = Color3.fromRGB(11, 0, 0)
        f.BorderSizePixel = 0; f.Visible = false
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
        return f
    end

    local LearnPanel  = mkFramePanel(); LearnPanel.Visible = true
    local RemoteList  = mkScrollPanel()
    local FavList     = mkScrollPanel()
    local SpyPanel    = mkScrollPanel(22)  -- room for export btn
    local BlackPanel  = mkScrollPanel()

    -- Learn text
    local LearnLbl = Instance.new("TextLabel", LearnPanel)
    LearnLbl.Size = UDim2.new(1,-12,1,-8); LearnLbl.Position = UDim2.new(0,6,0,4)
    LearnLbl.BackgroundTransparency = 1; LearnLbl.TextColor3 = Color3.fromRGB(220, 62, 62)
    LearnLbl.TextXAlignment = Enum.TextXAlignment.Left
    LearnLbl.TextYAlignment = Enum.TextYAlignment.Top
    LearnLbl.Font = Enum.Font.Gotham; LearnLbl.TextSize = 12
    LearnLbl.TextWrapped = true
    LearnLbl.Text = table.concat({
        "\nRemote Explorer v3.1  -  " .. chosenMode .. " Mode\n",
        "?? Tabs ??",
        "Remotes : Scan + fire/call remotes",
        "[*] Favs  : Bookmarked remotes",
        "Spy     : Live hook spy (like SimpleSpy)",
        "[B] BL   : Blacklist / whitelist management\n",
        "?? Popup features ??",
        "Auto Args  : Smart argument generation",
        "Arg history: ? > browse last 20 arg sets",
        "Repeat fire: fire on a timed interval",
        "Script gen : copy full ready-to-use Lua script",
        "Call freq  : calls/sec rolling meter\n",
        "?? Spy features ??",
        "Full __namecall hook (FireServer / InvokeServer)",
        "Return value capture for RemoteFunctions",
        "Arg type tags per entry",
        "Copy individual spy entry as script",
        "Blacklist remotes from spy",
        "Pause / resume capture",
        "Filter by name, export full log\n",
        "?? Mode: " .. chosenMode .. " ??",
        MINFO[chosenMode].desc,
        "\nMade by PabloScripter AKA Mr Root on TikTok",
    }, "\n")

    -- Fav empty notice
    local FavEmpty = Instance.new("TextLabel", FavList)
    FavEmpty.Size = UDim2.new(1,-8,0,38); FavEmpty.BackgroundTransparency = 1
    FavEmpty.Font = Enum.Font.Gotham; FavEmpty.TextSize = 12
    FavEmpty.TextColor3 = Color3.fromRGB(100, 36, 36); FavEmpty.TextWrapped = true
    FavEmpty.Text = "No favorites yet.\nStar a remote in the Remotes tab."

    -- Spy notice
    local SpyNotice = Instance.new("TextLabel", SpyPanel)
    SpyNotice.Size = UDim2.new(1,-8,0,48); SpyNotice.BackgroundTransparency = 1
    SpyNotice.Font = Enum.Font.Gotham; SpyNotice.TextSize = 11
    SpyNotice.TextColor3 = Color3.fromRGB(120, 46, 46); SpyNotice.TextWrapped = true
    SpyNotice.TextXAlignment = Enum.TextXAlignment.Left
    SpyNotice.Text = not feat.spy
        and "[L] Spy requires Medium or Ultra mode.\n    Needs hookmetamethod + getnamecallmethod."
        or  "Spy active. Green = FireServer  .  Orange = InvokeServer  .  Red = ReturnValue"

    -- BL notice (keep reference so refreshBL can skip it)
    local BLNotice = Instance.new("TextLabel", BlackPanel)
    BLNotice.Name = "BLNotice"
    BLNotice.Size = UDim2.new(1,-8,0,36); BLNotice.BackgroundTransparency = 1
    BLNotice.Font = Enum.Font.Gotham; BLNotice.TextSize = 11
    BLNotice.TextColor3 = Color3.fromRGB(120, 46, 46); BLNotice.TextWrapped = true
    BLNotice.TextXAlignment = Enum.TextXAlignment.Left
    BLNotice.Text = not feat.blacklist
        and "[L] Blacklist requires Normal+ mode."
        or  "Blacklisted remotes are hidden from spy.\nWhitelist mode: spy shows ONLY listed remotes."

    -- ?? SPY TOOLBAR BUTTONS ???????????????????????????????????????
    local SpyPauseBtn = Instance.new("TextButton", MF)
    SpyPauseBtn.Size = UDim2.new(0, 72, 0, 20); SpyPauseBtn.Position = UDim2.new(1, -82, 0, PY+3)
    SpyPauseBtn.Text = "[P] Pause"; styleB(SpyPauseBtn); SpyPauseBtn.TextSize = 10; SpyPauseBtn.Visible = false

    local SpyClearBtn = Instance.new("TextButton", MF)
    SpyClearBtn.Size = UDim2.new(0, 58, 0, 20); SpyClearBtn.Position = UDim2.new(1, -82, 0, PY+26)
    SpyClearBtn.Text = "Clear"; styleB(SpyClearBtn); SpyClearBtn.TextSize = 10; SpyClearBtn.Visible = false

    local ExportBtn = Instance.new("TextButton", MF)
    ExportBtn.Size = UDim2.new(0, 100, 0, 20)
    ExportBtn.Position = UDim2.new(0, 10, 1, -24)
    ExportBtn.Text = feat.export and "[C] Export Log" or "[L] Export"
    styleB(ExportBtn, not feat.export); ExportBtn.TextSize = 10; ExportBtn.Visible = false

    -- BL whitelist toggle
    local WLToggle = Instance.new("TextButton", MF)
    WLToggle.Size = UDim2.new(0, 118, 0, 22); WLToggle.Position = UDim2.new(0, 10, 1, -27)
    WLToggle.Text = "Whitelist: OFF"; styleB(WLToggle, not feat.blacklist)
    WLToggle.TextSize = 10; WLToggle.Visible = false

    -- ?? STATUS BAR ????????????????????????????????????????????????
    local StatusLbl = Instance.new("TextLabel", MF)
    StatusLbl.Size = UDim2.new(1, -20, 0, 20); StatusLbl.Position = UDim2.new(0, 10, 1, -24)
    StatusLbl.BackgroundTransparency = 1; StatusLbl.TextColor3 = Color3.fromRGB(150, 45, 45)
    StatusLbl.Text = "Mode: " .. chosenMode .. "  |  Ready"
    StatusLbl.Font = Enum.Font.Gotham; StatusLbl.TextSize = 10
    StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- ================================================================
    --  POPUP
    -- ================================================================
    local Popup = Instance.new("Frame", ScreenGui)
    Popup.Size = UDim2.new(0, C.isMobile and 290 or 318, 0, 348)
    Popup.AnchorPoint = Vector2.new(0.5, 0.5)
    Popup.Position = UDim2.new(0.5, 0, 0.5, 0)
    Popup.BackgroundColor3 = Color3.fromRGB(17, 0, 0)
    Popup.Visible = false; Popup.Active = true; Popup.BorderSizePixel = 0
    Instance.new("UICorner", Popup).CornerRadius = UDim.new(0, 10)
    local popStroke = nil
    pcall(function() popStroke = Instance.new("UIStroke", Popup) end)
    pcall(function() popStroke.Color = Color3.fromRGB(130, 16, 16); popStroke.Thickness = 1 end)
    makeDraggable(Popup)

    -- Popup element helpers
    local PW = Popup.Size.X.Offset
    local function pBtn(txt, x, y, w, h, locked)
        local b = Instance.new("TextButton", Popup)
        b.Size = UDim2.new(0, w, 0, h); b.Position = UDim2.new(0, x, 0, y)
        b.Text = txt; styleB(b, locked); b.TextSize = 11; return b
    end
    local function pLbl(txt, x, y, w, h, sz, bold, col)
        local l = Instance.new("TextLabel", Popup)
        l.Size = UDim2.new(0, w, 0, h); l.Position = UDim2.new(0, x, 0, y)
        l.BackgroundTransparency = 1; l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
        l.TextSize = sz or 11; l.TextColor3 = col or Color3.fromRGB(195, 75, 75)
        l.Text = txt; l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextWrapped = true; return l
    end

    -- Close
    local pClose = pBtn("X", PW-30, 2, 28, 28, false); pClose.TextSize = 11
    pClose.MouseButton1Click:Connect(function() Popup.Visible = false end)

    -- Title + type
    local pTitle   = pLbl("Remote Name", 10, 3, PW-44, 28, 15, true, Color3.fromRGB(255, 46, 46))
    local pTypeLbl = pLbl("", 10, 30, PW-20, 14, 10, false, Color3.fromRGB(160, 90, 90))

    -- Arg box
    local ArgBox = Instance.new("TextBox", Popup)
    ArgBox.Size = UDim2.new(1, -20, 0, 52); ArgBox.Position = UDim2.new(0, 10, 0, 48)
    ArgBox.Text = "{}"; ArgBox.TextXAlignment = Enum.TextXAlignment.Left
    pcall(function() ArgBox.Font = Enum.Font.Code end); ArgBox.TextSize = 12; ArgBox.ClearTextOnFocus = false
    ArgBox.BackgroundColor3 = Color3.fromRGB(26, 0, 0); ArgBox.BackgroundTransparency = 0.08
    ArgBox.TextColor3 = Color3.fromRGB(255, 202, 202); ArgBox.MultiLine = true
    ArgBox.BorderSizePixel = 0
    Instance.new("UICorner", ArgBox).CornerRadius = UDim.new(0, 6)

    -- Auto-gen source label (shown after clicking Auto Args)
    -- Sits between ArgBox and history nav, full width
    local pSourceLbl = Instance.new("TextLabel", Popup)
    pSourceLbl.Size = UDim2.new(1, -20, 0, 22)
    pSourceLbl.Position = UDim2.new(0, 10, 0, 102)
    pSourceLbl.BackgroundColor3 = Color3.fromRGB(22, 0, 0)
    pSourceLbl.BackgroundTransparency = 0.3
    pSourceLbl.Font = Enum.Font.Gotham
    pSourceLbl.TextSize = 9
    pSourceLbl.TextColor3 = Color3.fromRGB(130, 55, 55)
    pSourceLbl.TextXAlignment = Enum.TextXAlignment.Left
    pSourceLbl.TextWrapped = true
    pSourceLbl.Text = ""
    pSourceLbl.Visible = false
    pSourceLbl.BorderSizePixel = 0
    Instance.new("UICorner", pSourceLbl).CornerRadius = UDim.new(0, 4)
    Instance.new("UIPadding", pSourceLbl).PaddingLeft = UDim.new(0, 5)

    -- Confidence color table
    local CONF_COLORS = {
        live    = Color3.fromRGB(50, 195, 85),   -- green  - real spy data
        log     = Color3.fromRGB(80, 165, 255),  -- blue   - manually fired
        script  = Color3.fromRGB(195, 185, 50),  -- yellow - decompiled source
        pattern = Color3.fromRGB(215, 125, 35),  -- orange - name guess
        unknown = Color3.fromRGB(130, 55, 55),   -- red    - no data
    }

    local function setSourceLabel(label, confidence)
        pSourceLbl.Text = label
        pSourceLbl.TextColor3 = CONF_COLORS[confidence] or CONF_COLORS.unknown
        pSourceLbl.Visible = label ~= nil and label ~= ""
    end

    -- Hide source label when user manually edits the arg box
    -- (now safe because pSourceLbl and setSourceLabel are both declared above)
    ArgBox:GetPropertyChangedSignal("Text"):Connect(function()
        if pSourceLbl.Visible then
            pSourceLbl.Visible = false
        end
    end)

    -- Arg history nav  (shifted down 24px to make room for source label)
    local pHistLbl  = pLbl("No history", 10, 126, PW-90, 14, 9, false, Color3.fromRGB(118, 50, 50))
    local pHistPrev = pBtn("<", PW-68, 126, 28, 14, false); pHistPrev.TextSize = 9
    local pHistNext = pBtn(">", PW-36, 126, 28, 14, false); pHistNext.TextSize = 9

    -- Row: AutoGen + CopyPath  (shifted down 24px)
    local HALF = math.floor((PW-24)/2)
    local pAutoGen  = pBtn(feat.autogen and "[~] Auto Args" or "[L] Auto Args",  10, 146, HALF, 28, not feat.autogen)
    local pCopyPath = pBtn(feat.clip    and "[C] Path"      or "[L] Path",  14+HALF, 146, HALF, 28, not feat.clip)

    -- Fire
    local pFire = Instance.new("TextButton", Popup)
    pFire.Size = UDim2.new(1,-20,0,36); pFire.Position = UDim2.new(0,10,0,180)
    pFire.Text = ">  Fire Remote"; styleB(pFire)
    pFire.BackgroundColor3 = Color3.fromRGB(112, 0, 0)
    pFire.TextColor3 = Color3.fromRGB(255, 172, 172)

    -- Repeat row
    local pRepeat = pBtn(feat.repeat_f and "[R] Repeat: OFF" or "[L] Repeat", 10, 222, HALF, 24, not feat.repeat_f)
    pRepeat.TextSize = 10
    local pInterval = Instance.new("TextBox", Popup)
    pInterval.Size = UDim2.new(0, HALF, 0, 24); pInterval.Position = UDim2.new(0, 14+HALF, 0, 222)
    pInterval.Text = "1.0"; pcall(function() pInterval.Font = Enum.Font.Code end); pInterval.TextSize = 11
    pInterval.BackgroundColor3 = Color3.fromRGB(26, 0, 0); pInterval.BackgroundTransparency = 0.08
    pInterval.TextColor3 = Color3.fromRGB(212, 170, 170); pInterval.ClearTextOnFocus = false
    pInterval.BorderSizePixel = 0
    pInterval.PlaceholderText = "interval (s)"
    pInterval.PlaceholderColor3 = Color3.fromRGB(90, 40, 40)
    Instance.new("UICorner", pInterval).CornerRadius = UDim.new(0, 6)
    -- Lock interval box visually if not available (Editable may not exist on all executors)
    if not feat.repeat_f then
        pInterval.TextColor3 = Color3.fromRGB(70, 28, 28)
        pcall(function() pInterval.Editable = false end)
    end

    -- Copy code / Script gen
    local pCopyCode  = pBtn(feat.clip      and "[C] Copy Fire Code" or "[L] Code",     10, 252, HALF, 24, not feat.clip)
    pCopyCode.TextSize = 10
    local pScriptGen = pBtn(feat.scriptgen and "[S] Script Gen"     or "[L] Script", 14+HALF, 252, HALF, 24, not feat.scriptgen)
    pScriptGen.TextSize = 10

    -- BL + freq
    local pBLBtn  = pBtn("[B] Blacklist", 10, 282, HALF, 22, not feat.blacklist); pBLBtn.TextSize = 10
    local pFreqLbl = pLbl("Freq: 0.00/s", 14+HALF, 282, HALF, 22, 10, false, Color3.fromRGB(135, 95, 45))
    pFreqLbl.Visible = feat.freq
    pFreqLbl.TextYAlignment = Enum.TextYAlignment.Center

    -- Call count + fav
    local pCallCount = pLbl("Calls: 0", 10, 310, HALF+20, 20, 10, false, Color3.fromRGB(138, 50, 50))
    local pFavBtn    = pBtn("[*] Favorite", PW-116, 310, 106, 20, false); pFavBtn.TextSize = 10

    -- Path
    local pPathLbl = pLbl("Path:", 10, 334, PW-20, 28, 9, false, Color3.fromRGB(108, 42, 42))
    pPathLbl.TextWrapped = true

    -- Resize popup to fit new content
    Popup.Size = UDim2.new(0, C.isMobile and 290 or 318, 0, 372)

    -- ?? POPUP LOGIC ???????????????????????????????????????????????
    local selRemote    = nil
    local histIdx      = {}   -- [key] = current history index
    local repeatOn     = false
    local repeatThread = nil
    local fireCooldown = false
    local allRBtns     = {}   -- for search filter

    local function updateHistLbl()
        if not selRemote then return end
        local k = instPath(selRemote); local h = argHistory[k] or {}
        pHistLbl.Text = #h == 0 and "No history"
            or "History " .. (histIdx[k] or #h) .. "/" .. #h
    end

    local function openPopup(remote, path)
        selRemote = remote
        local key = instPath(remote)
        pTitle.Text    = remote.Name
        pTypeLbl.Text  = remote.ClassName .. "  .  " .. path
        pcall(function() popStroke.Color = remote:IsA("RemoteEvent") end)
            and Color3.fromRGB(148, 16, 16) or Color3.fromRGB(130, 72, 0)
        pFire.Text = remote:IsA("RemoteEvent") and ">  Fire Event" or ">  Call Function"
        ArgBox.Text = "{}"
        pCallCount.Text = "Calls: " .. (callCounts[key] or 0)
        pFavBtn.Text  = favorites[key] and "[*] Favorited" or "[*] Favorite"
        pFavBtn.TextColor3 = favorites[key]
            and Color3.fromRGB(255, 192, 42) or Color3.fromRGB(255, 36, 36)
        pBLBtn.Text = blacklist[key] and "[OK] Unblacklist" or "[B] Blacklist"
        histIdx[key] = #(argHistory[key] or {})
        updateHistLbl()
        -- Clear source label from previous remote
        setSourceLabel("", "unknown")
        Popup.BackgroundTransparency = 1; Popup.Visible = true
        tw(Popup, TweenInfo.new(0.18, Enum.EasingStyle.Back), {BackgroundTransparency = 0})

        -- Live freq display
        if feat.freq then
            task.spawn(function()
                while Popup.Visible and selRemote == remote do
                    pFreqLbl.Text = ("Freq: %.2f/s"):format(getFreq(key))
                    task.wait(0.5)
                end
            end)
        end
    end

    -- History navigation
    pHistPrev.MouseButton1Click:Connect(function()
        if not selRemote then return end
        local k = instPath(selRemote); local h = argHistory[k] or {}
        if #h == 0 then return end
        histIdx[k] = math.max(1, (histIdx[k] or 1) - 1)
        ArgBox.Text = h[histIdx[k]] or "{}"
        setSourceLabel("<- From history  .  entry " .. histIdx[k] .. "/" .. #h, "log")
        updateHistLbl()
    end)
    pHistNext.MouseButton1Click:Connect(function()
        if not selRemote then return end
        local k = instPath(selRemote); local h = argHistory[k] or {}
        if #h == 0 then return end
        histIdx[k] = math.min(#h, (histIdx[k] or 1) + 1)
        ArgBox.Text = h[histIdx[k]] or "{}"
        setSourceLabel("<- From history  .  entry " .. histIdx[k] .. "/" .. #h, "log")
        updateHistLbl()
    end)

    -- Fav toggle
    pFavBtn.MouseButton1Click:Connect(function()
        if not selRemote then return end
        local k = instPath(selRemote); favorites[k] = not favorites[k]
        pFavBtn.Text = favorites[k] and "[*] Favorited" or "[*] Favorite"
        pFavBtn.TextColor3 = favorites[k]
            and Color3.fromRGB(255,192,42) or Color3.fromRGB(255,36,36)
        toast(favorites[k] and "[*] Added to favorites" or "Removed from favorites",
            favorites[k] and "ok" or "info")
    end)

    -- BL toggle
    pBLBtn.MouseButton1Click:Connect(function()
        if not feat.blacklist then toast("[L] Blacklist requires Normal+ mode","warn"); return end
        if not selRemote then return end
        local k = instPath(selRemote); blacklist[k] = not blacklist[k]
        pBLBtn.Text = blacklist[k] and "[OK] Unblacklist" or "[B] Blacklist"
        toast(blacklist[k] and "[B] Blacklisted: " .. selRemote.Name or "[OK] Unblacklisted",
            blacklist[k] and "warn" or "ok")
    end)

    -- AutoGen  (now uses 3-source system with confidence label)
    pAutoGen.MouseButton1Click:Connect(function()
        if not feat.autogen then toast("[L] Requires Normal+ mode","warn"); return end
        if not selRemote then return end

        -- Show scanning toast only if script scan might run (takes a moment)
        local willScan = C.getscripts
        if willScan then
            pAutoGen.Text = "[..] Scanning..."
        end

        task.spawn(function()
            local args, sourceLabel, confidence = smartArgs(selRemote)

            -- Restore button text
            pAutoGen.Text = feat.autogen and "[~] Auto Args" or "[L] Auto Args"

            if #args > 0 then
                ArgBox.Text = fmtArgs(args)
            else
                -- No args - show a helpful empty state
                ArgBox.Text = "{}"
            end

            setSourceLabel(sourceLabel, confidence)

            -- Toast with confidence level
            local toastKind = ({live="ok", log="ok", script="ok", pattern="warn", unknown="warn"})[confidence] or "info"
            local short = ({
                live    = "[OK] Real args from spy log",
                log     = "[OK] Args from previous fire",
                script  = "~ Args from script scan",
                pattern = "[!] Pattern guess - edit if needed",
                unknown = "[!] Generic guess - edit if needed",
            })[confidence] or "Auto-gen complete"
            toast(short, toastKind)
        end)
    end)

    -- Copy path
    pCopyPath.MouseButton1Click:Connect(function()
        if not feat.clip then toast("[L] Requires Normal+ mode","warn"); return end
        if selRemote and copyClip(instPath(selRemote)) then toast("[C] Path copied!","ok") end
    end)

    -- Copy fire code
    pCopyCode.MouseButton1Click:Connect(function()
        if not feat.clip then toast("[L] Requires Normal+ mode","warn"); return end
        if not selRemote then return end
        local ok, args = pcall(parseArgs, ArgBox.Text)
        if not ok then toast("[X] Arg parse error","err"); return end
        local method = selRemote:IsA("RemoteEvent") and "FireServer" or "InvokeServer"
        local inner  = fmtArgs(args):sub(2, -2)
        local code   = "game." .. instPath(selRemote) .. ":" .. method .. "(" .. inner .. ")"
        if copyClip(code) then toast("[C] Code copied!","ok") else toast("Clipboard unavailable","err") end
    end)

    -- Script gen
    pScriptGen.MouseButton1Click:Connect(function()
        if not feat.scriptgen then toast("[L] Requires Normal+ mode","warn"); return end
        if not selRemote then return end
        local ok, args = pcall(parseArgs, ArgBox.Text)
        if not ok then toast("[X] Arg parse error","err"); return end
        if copyClip(genScript(selRemote, args)) then toast("[S] Script copied!","ok")
        else toast("Clipboard unavailable","err") end
    end)

    -- Repeat toggle
    pRepeat.MouseButton1Click:Connect(function()
        if not feat.repeat_f then toast("[L] Requires Normal+ mode","warn"); return end
        repeatOn = not repeatOn
        pRepeat.Text = repeatOn and "[R] Repeat: ON" or "[R] Repeat: OFF"
        pRepeat.TextColor3 = repeatOn and Color3.fromRGB(255,192,42) or Color3.fromRGB(255,36,36)
        if not repeatOn and repeatThread then task.cancel(repeatThread); repeatThread = nil end
    end)

    -- Core fire function
    local function doFire()
        if not selRemote then return end
        if not pcall(function() return selRemote.Parent end) then
            toast("[!] Remote is gone","warn"); return
        end
        if not selRemote.Parent then toast("[!] Remote is gone","warn"); return end

        local ok, parsed = pcall(parseArgs, ArgBox.Text)
        if not ok then toast("[X] Arg parse error","err"); StatusLbl.Text = "Parse error"; return end

        -- Save arg history (only if changed)
        local key = instPath(selRemote)
        argHistory[key] = argHistory[key] or {}
        local last = argHistory[key][#argHistory[key]]
        if last ~= ArgBox.Text then
            table.insert(argHistory[key], ArgBox.Text)
            pruneTable(argHistory[key], CFG.ARG_HIST_MAX)
        end
        histIdx[key] = #argHistory[key]; updateHistLbl()

        -- Increment counts
        callCounts[key] = (callCounts[key] or 0) + 1
        recordCall(key)
        pCallCount.Text = "Calls: " .. callCounts[key]

        -- Log
        local entry = {remote=selRemote, method=selRemote:IsA("RemoteEvent") and "FireServer" or "InvokeServer",
            args=parsed, time=os.time()}
        table.insert(remoteLog, entry); pruneTable(remoteLog, CFG.MAX_REMOTE_LOG)

        if selRemote:IsA("RemoteEvent") then
            local s, e = pcall(function() selRemote:FireServer(table.unpack(parsed)) end)
            if s then toast("[OK] " .. selRemote.Name .. " fired","ok"); StatusLbl.Text = "[OK] Fired!"
            else toast("[X] " .. tostring(e):sub(1,52),"err"); StatusLbl.Text = "[X] Error" end
        else
            local s, r = pcall(function() return selRemote:InvokeServer(table.unpack(parsed)) end)
            if s then toast("[OK] Result: " .. tostring(r):sub(1,38),"ok"); StatusLbl.Text = "[OK] " .. tostring(r)
            else toast("[X] " .. tostring(r):sub(1,52),"err"); StatusLbl.Text = "[X] Error" end
        end
    end

    pFire.MouseButton1Click:Connect(function()
        if fireCooldown then return end
        fireCooldown = true
        task.delay(CFG.FIRE_CD, function() fireCooldown = false end)
        doFire()
        if repeatOn and not repeatThread then
            repeatThread = task.spawn(function()
                while repeatOn and selRemote and pcall(function() return selRemote.Parent end) do
                    task.wait(math.max(0.1, tonumber(pInterval.Text) or 1))
                    if repeatOn then doFire() end
                end
                repeatThread = nil
            end)
        end
    end)

    -- Export spy log
    ExportBtn.MouseButton1Click:Connect(function()
        if not feat.export then toast("[L] Requires Normal+ mode","warn"); return end
        if #spyLog == 0 then toast("Spy log is empty","info"); return end
        local lines = {"-- Remote Explorer v3.1 Spy Log  " .. os.date()}
        for _, e in ipairs(spyLog) do
            if e.remote and pcall(function() return e.remote.Parent end) then
                local ret = e.retval ~= nil and ("  -> " .. tostring(e.retval)) or ""
                table.insert(lines, ("[%s] %s -> %s(%s)%s"):format(
                    os.date("%H:%M:%S", e.time), instPath(e.remote), e.method, fmtArgs(e.args), ret))
            end
        end
        if copyClip(table.concat(lines, "\n")) then
            toast("[C] Exported " .. (#lines-1) .. " entries","ok")
        else toast("Clipboard unavailable","err") end
    end)

    -- Spy pause / clear
    local spyPaused = false   -- MUST be defined before setupHook
    SpyPauseBtn.MouseButton1Click:Connect(function()
        spyPaused = not spyPaused
        SpyPauseBtn.Text = spyPaused and "> Resume" or "[P] Pause"
        SpyPauseBtn.TextColor3 = spyPaused
            and Color3.fromRGB(255,192,42) or Color3.fromRGB(255,36,36)
        toast(spyPaused and "[P] Spy paused" or "> Spy resumed","info")
    end)

    local spyUIEntries = {}
    SpyClearBtn.MouseButton1Click:Connect(function()
        for _, c in ipairs(spyUIEntries) do pcall(function() c:Destroy() end) end
        spyUIEntries = {}; spyCount = 0; SpyBadge.Text = "0"; SpyBadge.Visible = false
        toast("Spy log cleared","info")
    end)

    -- Spy name filter
    SpyFilter:GetPropertyChangedSignal("Text"):Connect(function()
        local q = SpyFilter.Text:lower()
        for _, row in ipairs(spyUIEntries) do
            if row and row.Parent then
                -- NameTag is a StringValue child; read .Value not .Text
                local nt = row:FindFirstChild("NameTag")
                local name = nt and nt.Value or ""
                row.Visible = q == "" or name:lower():find(q, 1, true) ~= nil
            end
        end
    end)

    -- Whitelist toggle
    WLToggle.MouseButton1Click:Connect(function()
        if not feat.blacklist then return end
        whitelistOn = not whitelistOn
        WLToggle.Text = "Whitelist: " .. (whitelistOn and "ON" or "OFF")
        WLToggle.TextColor3 = whitelistOn
            and Color3.fromRGB(255,192,42) or Color3.fromRGB(255,36,36)
        toast("Whitelist " .. (whitelistOn and "ON - spy shows only listed remotes" or "OFF"),"info")
    end)

    -- ================================================================
    --  SPY ROW BUILDER
    -- ================================================================
    local function makeSpyRow(entry)
        -- Guard: remote might have been destroyed
        if not entry.remote then return end
        local remOk = pcall(function() return entry.remote.Parent end)
        if not remOk then return end

        local key = instPath(entry.remote)
        if blacklist[key] then return end
        if whitelistOn and not whitelist[key] then return end

        bumpSpy()
        local isFS = entry.method == "FireServer"
        local row  = Instance.new("Frame", SpyPanel)
        row.Size = UDim2.new(1,-8,0, entry.retval ~= nil and 66 or 54)
        row.BorderSizePixel = 0
        row.BackgroundColor3 = isFS and Color3.fromRGB(33,3,3) or Color3.fromRGB(33,15,0)
        row.BackgroundTransparency = 0.16
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

        -- StringValue for filter (read via .Value)
        local nt = Instance.new("StringValue", row)
        nt.Name = "NameTag"; nt.Value = entry.remote.Name

        -- Method badge
        local badge = Instance.new("TextLabel", row)
        badge.Size = UDim2.new(0,58,0,14); badge.Position = UDim2.new(0,4,0,4)
        badge.BackgroundColor3 = isFS and Color3.fromRGB(150,15,15) or Color3.fromRGB(130,72,0)
        badge.BackgroundTransparency = 0.28; badge.Font = Enum.Font.GothamBold; badge.TextSize = 8
        badge.TextColor3 = Color3.fromRGB(255,255,255); badge.Text = entry.method
        badge.BorderSizePixel = 0
        Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)

        -- Timestamp
        local tLbl = Instance.new("TextLabel", row)
        tLbl.Size = UDim2.new(0,52,0,14); tLbl.Position = UDim2.new(0,66,0,4)
        tLbl.BackgroundTransparency = 1; tLbl.Font = Enum.Font.Gotham; tLbl.TextSize = 9
        tLbl.TextColor3 = Color3.fromRGB(125,50,50); tLbl.Text = os.date("%H:%M:%S", entry.time)

        -- Remote name
        local nLbl = Instance.new("TextLabel", row)
        nLbl.Size = UDim2.new(1,-130,0,15); nLbl.Position = UDim2.new(0,4,0,20)
        nLbl.BackgroundTransparency = 1; nLbl.Font = Enum.Font.GothamBold; nLbl.TextSize = 11
        nLbl.TextColor3 = isFS and Color3.fromRGB(255,112,112) or Color3.fromRGB(255,165,70)
        nLbl.TextXAlignment = Enum.TextXAlignment.Left; nLbl.Text = entry.remote.Name

        -- Args with type tags
        local aLbl = Instance.new("TextLabel", row)
        aLbl.Size = UDim2.new(1,-8,0,14); aLbl.Position = UDim2.new(0,4,0,37)
        aLbl.BackgroundTransparency = 1; pcall(function() aLbl.Font = Enum.Font.Code end); aLbl.TextSize = 9
        aLbl.TextXAlignment = Enum.TextXAlignment.Left; aLbl.TextWrapped = false
        aLbl.TextColor3 = Color3.fromRGB(182,182,182)
        local argParts = {}
        for _, a in ipairs(entry.args) do
            local s, t = fmtArg(a); table.insert(argParts, s .. "[" .. t .. "]")
        end
        aLbl.Text = "  " .. table.concat(argParts, ", ")

        -- Return value row
        if entry.retval ~= nil then
            local rLbl = Instance.new("TextLabel", row)
            rLbl.Size = UDim2.new(1,-8,0,12); rLbl.Position = UDim2.new(0,4,0,52)
            rLbl.BackgroundTransparency = 1; pcall(function() rLbl.Font = Enum.Font.Code end); rLbl.TextSize = 9
            rLbl.TextXAlignment = Enum.TextXAlignment.Left; rLbl.TextWrapped = false
            rLbl.TextColor3 = Color3.fromRGB(195,75,75)
            rLbl.Text = "  -> " .. tostring(entry.retval):sub(1,80)
        end

        -- Copy entry as script
        local cpBtn = pBtn("[C]", PW-50, 4, 42, 22, false)  -- reuse pBtn locally
        local cpB = Instance.new("TextButton", row)
        cpB.Size = UDim2.new(0,42,0,22); cpB.Position = UDim2.new(1,-46,0,4)
        cpB.Text = "[C]"; styleB(cpB); cpB.TextSize = 12
        cpB.MouseButton1Click:Connect(function()
            if not feat.clip then toast("[L] Clip requires Normal+","warn"); return end
            if copyClip(genScript(entry.remote, entry.args, entry.method)) then
                toast("[C] Entry copied!","ok")
            end
        end)
        -- supress unused var warning
        cpBtn = nil; _ = cpBtn

        -- Blacklist from spy row
        local blB = Instance.new("TextButton", row)
        blB.Size = UDim2.new(0,24,0,22); blB.Position = UDim2.new(1,-22,0,4)
        blB.Text = "[B]"; styleB(blB); blB.TextSize = 11
        blB.MouseButton1Click:Connect(function()
            if not feat.blacklist then toast("[L] BL requires Normal+","warn"); return end
            local k2 = instPath(entry.remote); blacklist[k2] = not blacklist[k2]
            toast(blacklist[k2] and "[B] " .. entry.remote.Name .. " blacklisted" or "[OK] Unblacklisted",
                blacklist[k2] and "warn" or "ok")
        end)

        -- Track for pruning (single insertion, single prune pass)
        table.insert(spyUIEntries, row)
        -- Prune oldest if over limit (one pass, no double-prune)
        while #spyUIEntries > CFG.MAX_SPY_UI do
            local old = table.remove(spyUIEntries, 1)
            pcall(function() old:Destroy() end)
        end
    end

    -- ================================================================
    --  HOOK SETUP  (__namecall spy)
    --  NOTE: spyPaused is declared above this so it's in scope
    -- ================================================================
    local hookDone = false
    local function setupHook()
        if hookDone or not feat.spy then return end
        if not (C.hookmethod and C.getnamecall and C.newcclosure) then return end
        hookDone = true

        safeRun(function()
            local oldNC
            oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                local args   = {...}

                -- Quick type check - pcall so destroyed instances don't crash the hook
                local isRemote = false
                pcall(function()
                    isRemote = self:IsA("RemoteEvent") or self:IsA("RemoteFunction")
                end)

                if isRemote and (method == "FireServer" or method == "InvokeServer") then
                    -- Safe full name - pcall in case remote is mid-destroy
                    local key = ""
                    pcall(function() key = self:GetFullName() end)

                    -- Update counts regardless of pause
                    callCounts[key] = (callCounts[key] or 0) + 1
                    recordCall(key)

                    if not spyPaused then
                        if method == "InvokeServer" then
                            -- Fire original first to get return value
                            local rets = {oldNC(self, ...)}
                            local entry = {remote=self, method=method, args=args,
                                retval=rets[1], time=os.time()}
                            table.insert(spyLog, entry); pruneTable(spyLog, CFG.MAX_SPY_LOG)
                            table.insert(remoteLog, entry); pruneTable(remoteLog, CFG.MAX_REMOTE_LOG)
                            task.defer(function() safeRun(makeSpyRow, entry) end)
                            return table.unpack(rets)
                        else
                            local entry = {remote=self, method=method, args=args,
                                retval=nil, time=os.time()}
                            table.insert(spyLog, entry); pruneTable(spyLog, CFG.MAX_SPY_LOG)
                            table.insert(remoteLog, entry); pruneTable(remoteLog, CFG.MAX_REMOTE_LOG)
                            task.defer(function() safeRun(makeSpyRow, entry) end)
                        end
                    end
                end

                return oldNC(self, ...)
            end))
        end)
    end
    pcall(setupHook)

    -- ================================================================
    --  REMOTE LIST  (lazy-loaded, collapsible groups)
    -- ================================================================
    local function makeRemoteBtn(remote, path)
        local key    = instPath(remote)
        local isEvent = remote:IsA("RemoteEvent")

        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-8,0,30); row.BorderSizePixel = 0
        row.BackgroundColor3 = isEvent and Color3.fromRGB(44,0,0) or Color3.fromRGB(44,14,0)
        row.BackgroundTransparency = 0.14
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

        local nameBtn = Instance.new("TextButton", row)
        nameBtn.Size = UDim2.new(1,-66,1,0); nameBtn.BackgroundTransparency = 1
        nameBtn.TextXAlignment = Enum.TextXAlignment.Left
        nameBtn.Font = Enum.Font.Gotham; nameBtn.TextSize = 12; nameBtn.BorderSizePixel = 0
        nameBtn.Text = " " .. remote.Name
        nameBtn.TextColor3 = isEvent and Color3.fromRGB(255,112,112) or Color3.fromRGB(255,172,70)

        -- Call count badge
        local cBadge = Instance.new("TextLabel", row)
        cBadge.Size = UDim2.new(0,30,0,16); cBadge.Position = UDim2.new(1,-62,0.5,-8)
        cBadge.BackgroundColor3 = Color3.fromRGB(62,0,0); cBadge.BackgroundTransparency = 0.4
        cBadge.Text = "x0"; cBadge.Font = Enum.Font.GothamBold; cBadge.TextSize = 9
        cBadge.TextColor3 = Color3.fromRGB(180,82,82); cBadge.BorderSizePixel = 0
        Instance.new("UICorner", cBadge).CornerRadius = UDim.new(0, 4)

        -- Freq badge (only shown in Medium/Ultra)
        local fBadge = Instance.new("TextLabel", row)
        fBadge.Size = UDim2.new(0,30,0,11); fBadge.Position = UDim2.new(1,-62,0.5,2)
        fBadge.BackgroundTransparency = 1; fBadge.Font = Enum.Font.Gotham; fBadge.TextSize = 8
        fBadge.TextColor3 = Color3.fromRGB(148,108,40); fBadge.Text = ""
        fBadge.Visible = feat.freq

        -- RE / RF type tag
        local tag = Instance.new("TextLabel", row)
        tag.Size = UDim2.new(0,24,0,14); tag.Position = UDim2.new(1,-28,0.5,-7)
        tag.BackgroundColor3 = isEvent and Color3.fromRGB(150,15,15) or Color3.fromRGB(130,70,0)
        tag.BackgroundTransparency = 0.28; tag.Text = isEvent and "RE" or "RF"
        tag.Font = Enum.Font.GothamBold; tag.TextSize = 8
        tag.TextColor3 = Color3.fromRGB(255,255,255); tag.BorderSizePixel = 0
        Instance.new("UICorner", tag).CornerRadius = UDim.new(0, 3)

        nameBtn.MouseButton1Click:Connect(function() openPopup(remote, path) end)

        -- Live badge update (throttled - once per second, stops when row destroyed)
        task.spawn(function()
            while row and row.Parent do
                cBadge.Text = "x" .. (callCounts[key] or 0)
                if feat.freq then fBadge.Text = ("%.1f/s"):format(getFreq(key)) end
                task.wait(1)
            end
        end)

        row.Parent = RemoteList
        table.insert(allRBtns, {row=row, name=remote.Name:lower(), key=key})
        return row
    end

    -- Favorites refresh
    local function refreshFav()
        for _, c in ipairs(FavList:GetChildren()) do
            if c ~= FavEmpty and c:IsA("Frame") then c:Destroy() end
        end
        local any = false
        for k, _ in pairs(favorites) do
            local nm = k:match("[^%.]+$") or k
            local ok2, remote = pcall(function() return game:FindFirstChild(nm, true) end)
            if ok2 and remote then
                any = true
                local row = Instance.new("Frame", FavList)
                row.Size = UDim2.new(1,-8,0,28); row.BorderSizePixel = 0
                row.BackgroundColor3 = Color3.fromRGB(50,23,0)
                row.BackgroundTransparency = 0.18
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
                local lb = Instance.new("TextButton", row)
                lb.Size = UDim2.new(1,0,1,0); lb.BackgroundTransparency = 1
                lb.Font = Enum.Font.Gotham; lb.TextSize = 11
                lb.TextColor3 = Color3.fromRGB(255,182,52)
                lb.TextXAlignment = Enum.TextXAlignment.Left
                lb.Text = "  [*]  " .. remote.Name .. " (" .. remote.ClassName .. ")"
                lb.BorderSizePixel = 0
                lb.MouseButton1Click:Connect(function() openPopup(remote, instPath(remote)) end)
            end
        end
        FavEmpty.Visible = not any
    end

    -- Blacklist panel refresh
    local function refreshBL()
        for _, c in ipairs(BlackPanel:GetChildren()) do
            -- skip BLNotice (named child) and WLToggle (it's in MF not BlackPanel)
            if c.Name ~= "BLNotice" and (c:IsA("Frame")) then c:Destroy() end
        end
        local any = false
        for k, _ in pairs(blacklist) do
            any = true
            local nm = k:match("[^%.]+$") or k
            local row = Instance.new("Frame", BlackPanel)
            row.Size = UDim2.new(1,-8,0,28); row.BorderSizePixel = 0
            row.BackgroundColor3 = Color3.fromRGB(38,0,0); row.BackgroundTransparency = 0.14
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
            local lb = Instance.new("TextLabel", row)
            lb.Size = UDim2.new(1,-40,1,0); lb.BackgroundTransparency = 1
            lb.Font = Enum.Font.Gotham; lb.TextSize = 11
            lb.TextColor3 = Color3.fromRGB(195,75,75)
            lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Text = "  [B]  " .. nm
            local remBtn = Instance.new("TextButton", row)
            remBtn.Size = UDim2.new(0,30,0,22); remBtn.Position = UDim2.new(1,-34,0,3)
            remBtn.Text = "X"; styleB(remBtn); remBtn.TextSize = 11
            remBtn.MouseButton1Click:Connect(function()
                blacklist[k] = nil; toast("[OK] Removed from blacklist","ok"); refreshBL()
            end)
        end
        if not any then
            local el = Instance.new("TextLabel", BlackPanel)
            el.Size = UDim2.new(1,-8,0,28); el.BackgroundTransparency = 1
            el.Font = Enum.Font.Gotham; el.TextSize = 11
            el.TextColor3 = Color3.fromRGB(100,35,35); el.Text = "No blacklisted remotes."
        end
    end

    -- Search filter
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = SearchBox.Text:lower()
        for _, e in ipairs(allRBtns) do
            if e.row and e.row.Parent then
                e.row.Visible = q == "" or e.name:find(q, 1, true) ~= nil
            end
        end
    end)

    -- Lazy scan
    local isScanning = false
    local function scanForRemotes()
        if isScanning then return end; isScanning = true
        allRBtns = {}; SearchBox.Text = ""
        for _, c in ipairs(RemoteList:GetChildren()) do c:Destroy() end
        local ll = Instance.new("UIListLayout", RemoteList); ll.Padding = UDim.new(0, 3)
        Instance.new("UIPadding", RemoteList).PaddingTop = UDim.new(0, 4)

        local SVCS = {
            game:GetService("ReplicatedStorage"),
            game:GetService("ReplicatedFirst"),
            game:GetService("StarterGui"),
            workspace, Players,
        }
        local count, seen = 0, {}
        StatusLbl.Text = "[?] Scanning..."

        task.spawn(function()
            for _, svc in ipairs(SVCS) do
                local found = {}
                local descs = {}
                pcall(function() descs = svc:GetDescendants() end)
                local n = 0
                for _, d in ipairs(descs) do
                    n = n + 1
                    if n % CFG.SCAN_YIELD == 0 then task.wait() end  -- yield: no freeze
                    local ok2, isRE = pcall(function() return d:IsA("RemoteEvent") end)
                    local ok3, isRF = pcall(function() return d:IsA("RemoteFunction") end)
                    if (ok2 and isRE) or (ok3 and isRF) then
                        local k = instPath(d)
                        if not seen[k] then
                            seen[k] = true
                            table.insert(found, {r=d, p=k})
                            count = count + 1
                        end
                    end
                end

                if #found > 0 then
                    table.sort(found, function(a,b) return a.r.Name:lower() < b.r.Name:lower() end)

                    -- Collapsible service header
                    local collapsed = false
                    local hdr = Instance.new("TextButton", RemoteList)
                    hdr.Size = UDim2.new(1,-8,0,22); hdr.BackgroundColor3 = Color3.fromRGB(32,0,0)
                    hdr.BackgroundTransparency = 0.04; hdr.Font = Enum.Font.GothamBold; hdr.TextSize = 12
                    hdr.TextColor3 = Color3.fromRGB(255,148,148); hdr.BorderSizePixel = 0
                    hdr.Text = "  ?  " .. svc.Name .. "  (" .. #found .. ")"
                    hdr.TextXAlignment = Enum.TextXAlignment.Left
                    Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 5)

                    local childRows = {}
                    for _, data in ipairs(found) do
                        local row = makeRemoteBtn(data.r, data.p)
                        table.insert(childRows, row)
                        task.wait()  -- yield between each button (prevents frame drops)
                    end

                    hdr.MouseButton1Click:Connect(function()
                        collapsed = not collapsed
                        hdr.Text = (collapsed and "  >  " or "  ?  ") .. svc.Name .. "  (" .. #found .. ")"
                        for _, r in ipairs(childRows) do
                            if r and r.Parent then r.Visible = not collapsed end
                        end
                    end)
                end
            end
            StatusLbl.Text = "[OK] " .. count .. " remotes  |  Mode: " .. chosenMode
            isScanning = false
        end)
    end

    -- Auto-detect NEW remotes (only toasts once per truly new remote, not every cycle)
    local knownRemotes = {}
    task.spawn(function()
        -- Seed known on first pass (so launch scan doesn't spam toast)
        task.wait(2)
        for _, svc in ipairs({game:GetService("ReplicatedStorage"), game:GetService("ReplicatedFirst")}) do
            local ok2, descs = pcall(function() return svc:GetDescendants() end)
            if ok2 then
                for _, d in ipairs(descs) do
                    local isR = false
                    pcall(function() isR = d:IsA("RemoteEvent") or d:IsA("RemoteFunction") end)
                    if isR then knownRemotes[instPath(d)] = true end
                end
            end
        end

        while MF and MF.Parent do
            task.wait(CFG.AUTO_DETECT_S)
            if not (MF and MF.Parent) then break end
            local newNames = {}
            for _, svc in ipairs({game:GetService("ReplicatedStorage"), game:GetService("ReplicatedFirst")}) do
                local ok2, descs = pcall(function() return svc:GetDescendants() end)
                if ok2 then
                    for _, d in ipairs(descs) do
                        local isR = false
                        pcall(function() isR = d:IsA("RemoteEvent") or d:IsA("RemoteFunction") end)
                        if isR then
                            local k = instPath(d)
                            if not knownRemotes[k] then
                                knownRemotes[k] = true
                                table.insert(newNames, d.Name)
                            end
                        end
                    end
                end
            end
            if #newNames > 0 then
                toast("[!] " .. #newNames .. " new remote(s) detected - re-scan to update","info")
            end
        end
    end)

    -- ?? TAB SWITCHING ?????????????????????????????????????????????
    local function showTab(panel, opts)
        opts = opts or {}
        LearnPanel.Visible = false; RemoteList.Visible = false
        FavList.Visible = false; SpyPanel.Visible = false; BlackPanel.Visible = false
        SearchBox.Visible = false; SpyFilter.Visible = false
        SpyPauseBtn.Visible = false; SpyClearBtn.Visible = false
        ExportBtn.Visible = false; WLToggle.Visible = false; StatusLbl.Visible = true
        panel.Visible = true
        if opts.search    then SearchBox.Visible = true end
        if opts.spyFilter then SpyFilter.Visible = true end
        if opts.spyCtrl   then SpyPauseBtn.Visible = true; SpyClearBtn.Visible = true end
        if opts.export    then ExportBtn.Visible = true end
        if opts.wl        then WLToggle.Visible = true end
    end

    LearnTab.MouseButton1Click:Connect(function() showTab(LearnPanel) end)
    RemoteTab.MouseButton1Click:Connect(function()
        showTab(RemoteList, {search = true}); scanForRemotes()
    end)
    FavTab.MouseButton1Click:Connect(function() showTab(FavList); refreshFav() end)
    SpyTab.MouseButton1Click:Connect(function()
        showTab(SpyPanel, {spyFilter=true, spyCtrl=feat.spy, export=feat.export})
        spyCount = 0; SpyBadge.Visible = false
    end)
    BlackTab.MouseButton1Click:Connect(function()
        showTab(BlackPanel, {wl=feat.blacklist}); refreshBL()
    end)

    -- Init
    showTab(LearnPanel)
    task.delay(0.38, function()
        toast(MINFO[chosenMode].icon .. " Launched in " .. chosenMode .. " mode",
            chosenMode == "Ultra" and "ok"
            or chosenMode == "Low" and "warn"
            or "info")
    end)
end)
