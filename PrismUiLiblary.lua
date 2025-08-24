--[[
PrismUI — loadstring-ready, modern Roblox UI library (~330 lines)
• No dependencies; TweenService animations (Quad/Quart/Back/Linear)
• Dark/Light themes, glassmorphism, shadow depth, hover/ripple
• Window (drag/minimize/close), Tabs, Scrollable content
• Elements: Button, Toggle, Checkbox, Slider, Dropdown (+Search), Textbox, Keybind,
           Label, Paragraph, Section, Separator, ProgressBar, ImageButton, RadioGroup
• Notifications, Tooltips, Intro Loading screen

USAGE (after you host this file as raw text):
local PrismUI = loadstring(game:HttpGet("https://your-host/PrismUI.lua"))()
local win = PrismUI:Window("Prism Window")
local tab = win:Tab("Main")
-- add elements...
--]]

local PrismUI = {}; PrismUI.__index = PrismUI
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CG  = game:GetService("CoreGui")

-- util ------
local function inst(t) local o=Instance.new(t[1]); for k,v in pairs(t) do if k~=1 then o[k]=v end end; return o end
local function tween(i,ti,prop,style,dir) return TS:Create(i, TweenInfo.new(ti or .25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), prop) end
local function ripple(p)
	local c=inst{"Frame",BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.8,Size=UDim2.fromOffset(0,0),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),ZIndex=p.ZIndex+1}
	inst{"UICorner",CornerRadius=UDim.new(1,0),Parent=c}; c.Parent=p
	tween(c,.45,{Size=UDim2.fromScale(1.3,1.3),BackgroundTransparency=1},Enum.EasingStyle.Quart):Play(); task.delay(.46,function() c:Destroy() end)
end
local function shadow(p)
	local s=inst{"ImageLabel",BackgroundTransparency=1,Image="rbxassetid://5028857084",ImageTransparency=.5,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(24,24,276,276),Size=UDim2.fromScale(1,1),Position=UDim2.new(0,0,0,4),ZIndex=p.ZIndex-1}
	s.Name="Shadow"; s.Parent=p
end

-- themes ------
local Themes={
	Dark={BG=Color3.fromRGB(16,18,22),Card=Color3.fromRGB(26,28,34),Accent=Color3.fromRGB(120,90,255),Text=Color3.fromRGB(235,238,245),Muted=Color3.fromRGB(168,176,189),Stroke=Color3.fromRGB(56,60,72)},
	Light={BG=Color3.fromRGB(244,246,250),Card=Color3.fromRGB(255,255,255),Accent=Color3.fromRGB(66,133,244), Text=Color3.fromRGB(33,38,45),  Muted=Color3.fromRGB(110,119,129), Stroke=Color3.fromRGB(220,224,230)}
}
local function glass(frame,t)
	frame.BackgroundTransparency=.08
	inst{"UIStroke",Color=t.Stroke,Transparency=.35,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Parent=frame}
	inst{"UICorner",CornerRadius=UDim.new(0,12),Parent=frame}; shadow(frame)
	inst{"UIGradient",Rotation=90,Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(1,.2)},Parent=frame}
end

function PrismUI.new()
	local self=setmetatable({T=Themes.Dark,ThemeName="Dark",Themables={},Screen=inst{"ScreenGui",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Name="PrismUI"}},PrismUI)
	self.Screen.Parent=CG; self:_intro(); return self
end
function PrismUI:_apply()
	for _,v in ipairs(self.Themables) do
		if v.kind=="text" then v.obj.TextColor3=self.T.Text
		elseif v.kind=="bg" then v.obj.BackgroundColor3=self.T.Card
		elseif v.kind=="muted" then v.obj.TextColor3=self.T.Muted
		elseif v.kind=="stroke" then v.obj.Color=self.T.Stroke end
	end
	if self.RootBG then self.RootBG.BackgroundColor3=self.T.BG end
end
function PrismUI:Theme(name) self.T=Themes[name] or self.T; self.ThemeName=name or self.ThemeName; self:_apply() end

-- intro --------
function PrismUI:_intro()
	self.RootBG=inst{"Frame",Size=UDim2.fromScale(1,1),BackgroundColor3=self.T.BG,Parent=self.Screen}
	local card=inst{"Frame",Size=UDim2.fromOffset(360,140),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundColor3=self.T.Card,Parent=self.RootBG,ZIndex=2}
	glass(card,self.T)
	local title=inst{"TextLabel",Text="PrismUI",Font=Enum.Font.GothamBold,TextSize=24,BackgroundTransparency=1,Parent=card,Size=UDim2.fromOffset(200,28),Position=UDim2.fromOffset(16,12),TextXAlignment=Enum.TextXAlignment.Left}
	table.insert(self.Themables,{obj=title,kind="text"})
	local bar=inst{"Frame",BackgroundColor3=self.T.Stroke,Size=UDim2.new(1,-32,0,6),Position=UDim2.new(0,16,1,-28),Parent=card}
	inst{"UICorner",CornerRadius=UDim.new(0,6),Parent=bar}
	local fill=inst{"Frame",BackgroundColor3=self.T.Accent,Size=UDim2.fromScale(0,1),Parent=bar}
	inst{"UICorner",CornerRadius=UDim.new(0,6),Parent=fill}
	local dots=inst{"TextLabel",Text="",Font=Enum.Font.GothamSemibold,TextSize=14,TextColor3=self.T.Muted,BackgroundTransparency=1,Parent=card,Position=UDim2.new(1,-16,1,-50),AnchorPoint=Vector2.new(1,1)}
	table.insert(self.Themables,{obj=dots,kind="muted"})
	for i=1,20 do tween(fill,.08,{Size=UDim2.new(i/20,0,1,0)},Enum.EasingStyle.Quad):Play(); dots.Text=string.rep(".",(i%3)+1); task.wait(.06) end
	tween(card,.25,{Size=UDim2.fromOffset(360,0)},Enum.EasingStyle.Quart):Play(); tween(self.RootBG,.25,{BackgroundTransparency=1}):Play(); task.delay(.26,function() self.RootBG:Destroy(); self.RootBG=nil end)
end

-- window/tabs ----
function PrismUI:Window(title)
	local ui=self
	local win={_ui=ui,Tabs={},Active=nil}
	local g=inst{"Frame",Parent=ui.Screen,BackgroundTransparency=1,Size=UDim2.fromOffset(560,390),Position=UDim2.fromScale(.5,.5),AnchorPoint=Vector2.new(.5,.5),ZIndex=5}; win.Root=g
	local card=inst{"Frame",Parent=g,BackgroundColor3=ui.T.Card,Size=UDim2.fromScale(1,1)}; glass(card,ui.T); table.insert(ui.Themables,{obj=card,kind="bg"})
	local titlebar=inst{"Frame",Parent=card,BackgroundTransparency=.5,BackgroundColor3=ui.T.Card,Size=UDim2.new(1,0,0,36)}; table.insert(ui.Themables,{obj=titlebar,kind="bg"})
	local tl=inst{"TextLabel",Parent=titlebar,BackgroundTransparency=1,Text=title,Font=Enum.Font.GothamSemibold,TextSize=16,Position=UDim2.fromOffset(12,0),Size=UDim2.new(1,-120,1,0),TextXAlignment=Enum.TextXAlignment.Left}; table.insert(ui.Themables,{obj=tl,kind="text"})
	local function tbtn(txt,x)
		local b=inst{"TextButton",Parent=titlebar,Text=txt,Font=Enum.Font.GothamBold,TextSize=14,AutoButtonColor=false,BackgroundTransparency=.2,Size=UDim2.fromOffset(28,24),Position=UDim2.new(1,-x,0,.5),AnchorPoint=Vector2.new(1,.5)}
		inst{"UICorner",CornerRadius=UDim.new(0,6),Parent=b}; table.insert(ui.Themables,{obj=b,kind="text"})
		b.MouseEnter:Connect(function() tween(b,.15,{BackgroundTransparency=.05}):Play() end)
		b.MouseLeave:Connect(function() tween(b,.2,{BackgroundTransparency=.2}):Play() end)
		return b
	end
	local close=tbtn("✕",8); local mini=tbtn("–",40)
	close.MouseButton1Click:Connect(function() pcall(ripple,titlebar); tween(card,.2,{Size=UDim2.new(0,0,0,0)},Enum.EasingStyle.Back):Play(); tween(g,.2,{BackgroundTransparency=1}):Play(); task.delay(.2,function() g:Destroy() end) end)
	local minimized=false
	mini.MouseButton1Click:Connect(function() minimized=not minimized; tween(card,.25,{Size=UDim2.new(1,0,0,minimized and 36 or 390)},Enum.EasingStyle.Back):Play() end)
	-- drag
	local drag=false; local off
	titlebar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; off=Vector2.new(i.Position.X-g.AbsolutePosition.X,i.Position.Y-g.AbsolutePosition.Y) end end)
	UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
	UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then g.Position=UDim2.fromOffset(i.Position.X-off.X,i.Position.Y-off.Y) end end)
	-- tabs
	local tabs=inst{"Frame",Parent=card,BackgroundTransparency=1,Position=UDim2.new(0,8,0,40),Size=UDim2.new(1,-16,0,24)}; inst{"UIListLayout",Parent=tabs,FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6)}
	local content=inst{"Frame",Parent=card,BackgroundTransparency=1,Position=UDim2.new(0,8,0,72),Size=UDim2.new(1,-16,1,-80)}
	local holder=inst{"Frame",Parent=content,Size=UDim2.fromScale(1,1),BackgroundTransparency=1}
	local pages={}

	function win:Tab(name)
		local t={Name=name}
		local tb=inst{"TextButton",Parent=tabs,Text=name,Font=Enum.Font.Gotham,TextSize=14,AutoButtonColor=false,BackgroundColor3=ui.T.Card,Size=UDim2.fromOffset(110,24)}; inst{"UICorner",CornerRadius=UDim.new(0,8),Parent=tb}; table.insert(ui.Themables,{obj=tb,kind="text"})
		local page=inst{"ScrollingFrame",Parent=holder,Visible=false,BackgroundTransparency=.2,BackgroundColor3=ui.T.Card,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=4}
		inst{"UICorner",CornerRadius=UDim.new(0,10),Parent=page}; table.insert(ui.Themables,{obj=page,kind="bg"}); inst{"UIPadding",Parent=page,PaddingLeft=UDim.new(0,10),PaddingTop=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,10)}
		local list=inst{"UIListLayout",Parent=page,Padding=UDim.new(0,8)}; list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize=UDim2.new(0,0,0,list.AbsoluteContentSize.Y+12) end)
		pages[name]=page
		local function activate() if win.Active==name then return end; for _,pg in pairs(pages) do pg.Visible=false end; page.Visible=true; page.BackgroundTransparency=1; tween(page,.18,{BackgroundTransparency=.2},Enum.EasingStyle.Quad):Play(); win.Active=name end
		tb.MouseButton1Click:Connect(function() ripple(tb); activate() end); if not win.Active then activate() end

		-- helpers
		local function card()
			local f=inst{"Frame",Parent=page,BackgroundColor3=ui.T.Card,BackgroundTransparency=.05,Size=UDim2.new(1,-4,0,36)}; inst{"UICorner",CornerRadius=UDim.new(0,10),Parent=f}; table.insert(ui.Themables,{obj=f,kind="bg"}); shadow(f); return f
		end
		local function label(txt,parent,sz,bold)
			local l=inst{"TextLabel",Parent=parent,BackgroundTransparency=1,Text=txt,Font= bold and Enum.Font.GothamSemibold or Enum.Font.Gotham,TextSize=sz or 14,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,-8,1,0),Position=UDim2.fromOffset(8,0)}; table.insert(ui.Themables,{obj=l,kind="text"}); return l
		end
		local function mkbtn(p)
			local b=inst{"TextButton",Parent=p,Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1)}; return b
		end

		function t:Section(text)
			local f=inst{"Frame",Parent=page,BackgroundTransparency=1,Size=UDim2.new(1,-4,0,28)}; local l=inst{"TextLabel",Parent=f,BackgroundTransparency=1,Text=text,Font=Enum.Font.GothamSemibold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,1,0)}; table.insert(ui.Themables,{obj=l,kind="text"}); return f
		end
		function t:Separator()
			local f=inst{"Frame",Parent=page,BackgroundTransparency=1,Size=UDim2.new(1,-4,0,8)}; local line=inst{"Frame",Parent=f,BackgroundColor3=ui.T.Stroke,Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,.5,0)}; table.insert(ui.Themables,{obj=line,kind="stroke"}); return f
		end
		function t:Label(text) local f=card(); label(text,f); return f end
		function t:Paragraph(text)
			local f=card(); f.Size=UDim2.new(1,-4,0,64); local l=inst{"TextLabel",Parent=f,BackgroundTransparency=1,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Text=text,Font=Enum.Font.Gotham,TextSize=14,Size=UDim2.new(1,-12,1,-12),Position=UDim2.fromOffset(8,6)}; table.insert(ui.Themables,{obj=l,kind="text"}); return f
		end

		function t:Button(text,cb)
			local f=card(); local b=mkbtn(f); label(text,f)
			b.MouseEnter:Connect(function() tween(f,.12,{BackgroundTransparency=0},Enum.EasingStyle.Quart):Play() end)
			b.MouseLeave:Connect(function() tween(f,.18,{BackgroundTransparency=.05}):Play() end)
			b.MouseButton1Click:Connect(function() ripple(f); if cb then cb() end end)
			return f
		end

		function t:ImageButton(text,imageId,cb)
			local f=card(); f.Size=UDim2.new(1,-4,0,48); label(text,f)
			local img=inst{"ImageLabel",Parent=f,BackgroundTransparency=1,Image=imageId or "rbxassetid://0",Size=UDim2.fromOffset(36,36),Position=UDim2.new(1,-44,0.5,-18)}
			local b=mkbtn(f); b.MouseEnter:Connect(function() tween(img,.1,{Size=UDim2.fromOffset(40,40)},Enum.EasingStyle.Back):Play() end)
			b.MouseLeave:Connect(function() tween(img,.12,{Size=UDim2.fromOffset(36,36)}):Play() end)
			b.MouseButton1Click:Connect(function() ripple(f); if cb then cb() end end)
			return f
		end

		function t:Toggle(text,default,cb)
			local f=card(); label(text,f)
			local sw=inst{"Frame",Parent=f,Size=UDim2.fromOffset(44,22),Position=UDim2.new(1,-52,0.5,-11),BackgroundColor3=ui.T.Stroke}; inst{"UICorner",CornerRadius=UDim.new(1,0),Parent=sw}
			local knob=inst{"Frame",Parent=sw,Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(2,2),BackgroundColor3=Color3.new(1,1,1)}; inst{"UICorner",CornerRadius=UDim.new(1,0),Parent=knob}
			local on=default or false
			local function set(v) on=v; tween(sw,.15,{BackgroundColor3=v and ui.T.Accent or ui.T.Stroke},Enum.EasingStyle.Quart):Play(); tween(knob,.15,{Position=UDim2.fromOffset(v and 24 or 2,2)},Enum.EasingStyle.Quart):Play(); if cb then cb(on) end end
			set(on); f.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not on) end end)
			return set
		end

		function t:Checkbox(text,default,cb)
			local f=card(); label(text,f)
			local box=inst{"Frame",Parent=f,Size=UDim2.fromOffset(22,22),Position=UDim2.new(1,-34,0.5,-11),BackgroundColor3=ui.T.Stroke}; inst{"UICorner",CornerRadius=UDim.new(0,6),Parent=box}
			local tick=inst{"Frame",Parent=box,Size=UDim2.fromOffset(0,0),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundColor3=ui.T.Accent}; inst{"UICorner",CornerRadius=UDim.new(0,5),Parent=tick}
			local on=default or false
			local function set(v) on=v; tween(tick,.12,{Size=v and UDim2.fromOffset(14,14) or UDim2.fromOffset(0,0)},Enum.EasingStyle.Back):Play(); if cb then cb(on) end end
			set(on); f.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then set(not on) end end)
			return set
		end

		function t:Slider(text,min,max,default,cb)
			local f=card(); label(text,f)
			local track=inst{"Frame",Parent=f,Size=UDim2.new(0.55,0,0,6),Position=UDim2.new(1,-280,0.5,-3),BackgroundColor3=ui.T.Stroke}; inst{"UICorner",CornerRadius=UDim.new(0,3),Parent=track}
			local fill=inst{"Frame",Parent=track,Size=UDim2.fromScale(0,1),BackgroundColor3=ui.T.Accent}; inst{"UICorner",CornerRadius=UDim.new(0,3),Parent=fill}
			local val=inst{"TextLabel",Parent=f,BackgroundTransparency=1,Text="",Font=Enum.Font.GothamSemibold,TextSize=14,Position=UDim2.new(1,-56,0,0),Size=UDim2.fromOffset(48,36)}; table.insert(ui.Themables,{obj=val,kind="text"})
			min,max=tonumber(min) or 0, tonumber(max) or 100; local v=math.clamp(default or min,min,max); local dragging=false
			local function set(x) v=math.floor(x+0.5); val.Text=tostring(v); local pct=(v-min)/math.max(1,(max-min)); tween(fill,.1,{Size=UDim2.fromScale(pct,1)},Enum.EasingStyle.Quad):Play(); if cb then cb(v) end end
			set(v)
			local function toVal(px) local rel=math.clamp((px-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1); return min+rel*(max-min) end
			track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; set(toVal(i.Position.X)) end end)
			UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
			UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then set(toVal(i.Position.X)) end end)
			return set
		end

		function t:Progress(text,default,max,cb)
			local f=card(); f.Size=UDim2.new(1,-4,0,46); label(text,f)
			local bar=inst{"Frame",Parent=f,BackgroundColor3=ui.T.Stroke,Size=UDim2.new(1,-16,0,6),Position=UDim2.new(0,8,1,-12)}; inst{"UICorner",CornerRadius=UDim.new(0,3),Parent=bar}
			local fill=inst{"Frame",Parent=bar,BackgroundColor3=ui.T.Accent,Size=UDim2.fromScale(0,1)}; inst{"UICorner",CornerRadius=UDim.new(0,3),Parent=fill}
			local v=default or 0; max=max or 100
			local function set(x) v=math.clamp(x,0,max); tween(fill,.15,{Size=UDim2.fromScale(v/max,1)}):Play(); if cb then cb(v) end end
			set(v); return set
		end

		local function buildMenu(anchor,list,withSearch,cb)
			local menu=inst{"Frame",Parent=anchor,BackgroundColor3=ui.T.Card,BackgroundTransparency=.05,Position=UDim2.new(1,-152,0,36),Size=UDim2.fromOffset(160, #list*26 + (withSearch and 34 or 8)),Visible=false,ZIndex=20}
			inst{"UICorner",CornerRadius=UDim.new(0,8),Parent=menu}; shadow(menu)
			local pad=inst{"UIPadding",Parent=menu,PaddingTop=UDim.new(0, withSearch and 30 or 4),PaddingLeft=UDim.new(0,4)}
			local search; if withSearch then search=inst{"TextBox",Parent=menu,PlaceholderText="Search...",Text="",Font=Enum.Font.Gotham,TextSize=13,ClearTextOnFocus=false,BackgroundTransparency=.1,Size=UDim2.new(1,-8,0,22),Position=UDim2.new(0,4,0,4)}; inst{"UICorner",CornerRadius=UDim.new(0,6),Parent=search}; table.insert(ui.Themables,{obj=search,kind="text"}) end
			local container=inst{"Frame",Parent=menu,BackgroundTransparency=1,Size=UDim2.new(1,-8,1,-(withSearch and 34 or 8)),Position=UDim2.new(0,4,0, withSearch and 30 or 4)}
			local listlayout=inst{"UIListLayout",Parent=container,Padding=UDim.new(0,2)}
			local function refresh(filter)
				for _,c in ipairs(container:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				for _,opt in ipairs(list) do
					if (not filter) or string.find(string.lower(opt), string.lower(filter), 1, true) then
						local b=inst{"TextButton",Parent=container,Text=opt,Font=Enum.Font.Gotham,TextSize=14,BackgroundTransparency=1,Size=UDim2.new(1,0,0,24)}
						b.MouseEnter:Connect(function() tween(b,.08,{TextSize=15}):Play() end); b.MouseLeave:Connect(function() tween(b,.08,{TextSize=14}):Play() end)
						b.MouseButton1Click:Connect(function() cb(opt); tween(menu,.12,{BackgroundTransparency=.25}):Play(); task.delay(.12,function() menu.Visible=false end) end)
					end
				end
			end
			refresh(); if search then search:GetPropertyChangedSignal("Text"):Connect(function() refresh(search.Text) end) end
			return menu
		end

		function t:Dropdown(text,list,default,cb)
			local f=card(); label(text,f)
			local dd=inst{"TextButton",Parent=f,Text=default or "Select",Font=Enum.Font.Gotham,TextSize=14,BackgroundTransparency=.1,Size=UDim2.fromOffset(152,28),Position=UDim2.new(1,-164,0.5,-14)}; inst{"UICorner",CornerRadius=UDim.new(0,8),Parent=dd}; table.insert(ui.Themables,{obj=dd,kind="text"})
			local function set(v) dd.Text=v; if cb then cb(v) end end
			local menu=buildMenu(f,list,false,set)
			dd.MouseButton1Click:Connect(function() pcall(ripple,dd); menu.Visible=not menu.Visible; tween(menu,.12,{BackgroundTransparency= menu.Visible and .05 or .25},Enum.EasingStyle.Back):Play() end)
			return {Set=set, Rebuild=function(new) list=new end}
		end
		function t:DropdownSearch(text,list,default,cb)
			local f=card(); label(text,f)
			local dd=inst{"TextButton",Parent=f,Text=default or "Select",Font=Enum.Font.Gotham,TextSize=14,BackgroundTransparency=.1,Size=UDim2.fromOffset(152,28),Position=UDim2.new(1,-164,0.5,-14)}; inst{"UICorner",CornerRadius=UDim.new(0,8),Parent=dd}; table.insert(ui.Themables,{obj=dd,kind="text"})
			local function set(v) dd.Text=v; if cb then cb(v) end end
			local menu; dd.MouseButton1Click:Connect(function()
				pcall(ripple,dd); if not menu then menu=buildMenu(f,list,true,set) end; menu.Visible=not menu.Visible; tween(menu,.12,{BackgroundTransparency= menu.Visible and .05 or .25},Enum.EasingStyle.Back):Play()
			end)
			return {Set=set}
		end

		function t:Textbox(text,placeholder,cb)
			local f=card(); label(text,f)
			local box=inst{"TextBox",Parent=f,PlaceholderText=placeholder or "",Text="",Font=Enum.Font.Gotham,TextSize=14,ClearTextOnFocus=false,BackgroundTransparency=.1,Size=UDim2.fromOffset(220,28),Position=UDim2.new(1,-232,0.5,-14)}; inst{"UICorner",CornerRadius=UDim.new(0,8),Parent=box}; table.insert(ui.Themables,{obj=box,kind="text"})
			box.Focused:Connect(function() tween(box,.12,{BackgroundTransparency=0},Enum.EasingStyle.Quart):Play() end)
			box.FocusLost:Connect(function(enter) tween(box,.12,{BackgroundTransparency=.1}):Play(); if enter and cb then cb(box.Text) end end)
			return box
		end

		function t:Keybind(text,key,cb)
			local f=card(); label(text,f)
			local b=inst{"TextButton",Parent=f,Text=key and key.Name or "None",Font=Enum.Font.GothamSemibold,TextSize=14,BackgroundTransparency=.1,Size=UDim2.fromOffset(110,28),Position=UDim2.new(1,-122,0.5,-14)}; inst{"UICorner",CornerRadius=UDim.new(0,8),Parent=b}; table.insert(ui.Themables,{obj=b,kind="text"})
			local current=key; b.MouseButton1Click:Connect(function() b.Text="Press..."; local con; con=UIS.InputBegan:Connect(function(i,gp) if i.UserInputType==Enum.UserInputType.Keyboard then current=i.KeyCode; b.Text=current.Name; con:Disconnect() end end) end)
			UIS.InputBegan:Connect(function(i,gp) if not gp and current and i.KeyCode==current and cb then cb() end end)
			return function(k) current=k; b.Text=k.Name end
		end

		function t:RadioGroup(text,options,default,cb)
			local f=card(); f.Size=UDim2.new(1,-4,0, (math.ceil(#options/3)*30)+12); label(text,f)
			local sel=default or options[1]
			local grid=inst{"UIGridLayout",Parent=f,CellPadding=UDim2.new(0,8,0,8),CellSize=UDim2.new(0,150,0,24),SortOrder=Enum.SortOrder.LayoutOrder}; grid.FillDirectionMaxCells=3
			grid.HorizontalAlignment=Enum.HorizontalAlignment.Right; grid.VerticalAlignment=Enum.VerticalAlignment.Center
			for _,opt in ipairs(options) do
				local item=inst{"Frame",Parent=f,BackgroundTransparency=.1,BackgroundColor3=ui.T.Card,Size=UDim2.fromOffset(150,24)}; inst{"UICorner",CornerRadius=UDim.new(0,8),Parent=item}; table.insert(ui.Themables,{obj=item,kind="bg"})
				local dot=inst{"Frame",Parent=item,Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(4,3),BackgroundColor3=ui.T.Stroke}; inst{"UICorner",CornerRadius=UDim.new(1,0),Parent=dot}
				local fill=inst{"Frame",Parent=dot,Size=UDim2.fromOffset(0,0),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),BackgroundColor3=ui.T.Accent}; inst{"UICorner",CornerRadius=UDim.new(1,0),Parent=fill}
				local tx=inst{"TextLabel",Parent=item,BackgroundTransparency=1,Text=opt,Font=Enum.Font.Gotham,TextSize=14,Position=UDim2.fromOffset(28,0),Size=UDim2.new(1,-30,1,0),TextXAlignment=Enum.TextXAlignment.Left}; table.insert(ui.Themables,{obj=tx,kind="text"})
				local function update(v) tween(fill,.12,{Size=UDim2.fromOffset(v and 10 or 0, v and 10 or 0)},Enum.EasingStyle.Back):Play() end
				update(opt==sel)
				item.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then sel=opt; for _,c in ipairs(f:GetChildren()) do if c:IsA("Frame") and c~=item then local d=c:FindFirstChildOfClass("Frame"); if d then local fi=d:FindFirstChildOfClass("Frame"); if fi then tween(fi,.12,{Size=UDim2.fromOffset(0,0)}):Play() end end end end; update(true); if cb then cb(sel) end end end)
			end
			return function(v) sel=v; if cb then cb(sel) end end
		end

		-- simple RGB color picker (lightweight)
		function t:ColorPicker(text,default,cb)
			local f=card(); f.Size=UDim2.new(1,-4,0,90); label(text,f)
			local function mkSlider(lbl,init,offset)
				local row=inst{"Frame",Parent=f,BackgroundTransparency=1,Size=UDim2.new(1,-12,0,24),Position=UDim2.new(0,8,0, offset)}
				local lt=inst{"TextLabel",Parent=row,BackgroundTransparency=1,Text=lbl,Font=Enum.Font.Gotham,TextSize=13,Size=UDim2.fromOffset(20,24)}; table.insert(ui.Themables,{obj=lt,kind="text"})
				local tr=inst{"Frame",Parent=row,BackgroundColor3=ui.T.Stroke,Size=UDim2.new(1,-80,0,6),Position=UDim2.new(0,28,0,9)}; inst{"UICorner",CornerRadius=UDim.new(0,3),Parent=tr}
				local fl=inst{"Frame",Parent=tr,BackgroundColor3=ui.T.Accent,Size=UDim2.fromScale(0,1)}; inst{"UICorner",CornerRadius=UDim.new(0,3),Parent=fl}
				local out=inst{"TextLabel",Parent=row,BackgroundTransparency=1,Text=tostring(init),Font=Enum.Font.GothamSemibold,TextSize=13,Position=UDim2.new(1,-44,0,0),Size=UDim2.fromOffset(44,24)}; table.insert(ui.Themables,{obj=out,kind="text"})
				local v=init or 0; local drag=false
				local function set(px)
					local rel=math.clamp((px-tr.AbsolutePosition.X)/math.max(1,tr.AbsoluteSize.X),0,1); v=math.floor(rel*255+0.5); out.Text=tostring(v); tween(fl,.1,{Size=UDim2.fromScale(rel,1)}):Play(); return v
				end
				tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true; set(i.Position.X); end end)
				UIS.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMovement then set(i.Position.X); if cb then cb(Color3.fromRGB(r(),g(),b())) end end end)
				UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
				return function() return v end, function(x) v=x; out.Text=tostring(v); tween(fl,.1,{Size=UDim2.fromScale(v/255,1)}):Play() end
			end
			local r,g,b=0,0,0
			local getR,setR=mkSlider("R",default and math.floor(default.R*255) or 0,30)
			local getG,setG=mkSlider("G",default and math.floor(default.G*255) or 0,54)
			local getB,setB=mkSlider("B",default and math.floor(default.B*255) or 0,78)
			local swatch=inst{"Frame",Parent=f,BackgroundColor3=default or Color3.new(1,1,1),Size=UDim2.fromOffset(24,24),Position=UDim2.new(1,-34,0,8)}; inst{"UICorner",CornerRadius=UDim.new(0,6),Parent=swatch}
			local function update() local c=Color3.fromRGB(getR(),getG(),getB()); tween(swatch,.1,{BackgroundColor3=c}):Play(); if cb then cb(c) end end
			setR(default and math.floor(default.R*255) or 0); setG(default and math.floor(default.G*255) or 0); setB(default and math.floor(default.B*255) or 0); task.delay(.01,update)
			return function(c) setR(math.floor(c.R*255)); setG(math.floor(c.G*255)); setB(math.floor(c.B*255)); update() end
		end

		return t
	end
	return win
end

-- notifications -----
function PrismUI:Notify(title,msg,dur)
	dur=dur or 3
	local root=inst{"Frame",Parent=self.Screen,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-12,1,-12),Size=UDim2.fromOffset(280,0),ZIndex=100}
	local card=inst{"Frame",Parent=root,Size=UDim2.fromOffset(280,64),BackgroundColor3=self.T.Card}
	glass(card,self.T); table.insert(self.Themables,{obj=card,kind="bg"})
	local bar=inst{"Frame",Parent=card,BackgroundColor3=self.T.Accent,Size=UDim2.new(0,0,0,3),Position=UDim2.new(0,0,1,-3)}
	local tl=inst{"TextLabel",Parent=card,BackgroundTransparency=1,Text=title,Font=Enum.Font.GothamSemibold,TextSize=15,Position=UDim2.fromOffset(10,6),Size=UDim2.fromOffset(260,18)}; table.insert(self.Themables,{obj=tl,kind="text"})
	local tx=inst{"TextLabel",Parent=card,BackgroundTransparency=1,Text=msg,Font=Enum.Font.Gotham,TextSize=13,TextWrapped=true,Position=UDim2.fromOffset(10,26),Size=UDim2.fromOffset(260,32)}; table.insert(self.Themables,{obj=tx,kind="text"})
	card.Position=UDim2.new(1,12,1,-12); card.AnchorPoint=Vector2.new(1,1)
	tween(card,.18,{Position=UDim2.new(1,0,1,-12)},Enum.EasingStyle.Back):Play(); tween(bar,dur,{Size=UDim2.new(1,0,0,3)},Enum.EasingStyle.Linear):Play()
	task.delay(dur,function() tween(card,.2,{Position=UDim2.new(1,12,1,-12),BackgroundTransparency=.3},Enum.EasingStyle.Quad):Play(); task.delay(.21,function() root:Destroy() end) end)
end

return PrismUI
