-- i love u, vinhuchi
local ServerHopLibrary = {}

  local getgenv = getgenv or function()
      return shared
  end
  
  local function New(Name, Properties, Children)
      local Object = Instance.new(Name)
  
      -- Properties
      for Name, Value in next, Properties or {} do
          if Name ~= "ThemeTag" and Name ~= "ImageThemeTag" then
              Object[Name] = Value
          end
      end
  
      -- Children
      for _, Child in next, Children or {} do
          Child.Parent = Object
      end
  
      return Object
  end
  
  local function Tween(obj, info, properties, callback)
          local anim = game:GetService("TweenService"):Create(obj, TweenInfo.new(unpack(info)), properties)
          anim:Play()
  
          if callback then
          anim.Completed:Connect(callback)
      end
  
          return anim
      end
  local RunService = game:GetService("RunService")
  local TweenService = game:GetService("TweenService")
  local LocalPlayer = game:GetService("Players").LocalPlayer

  local GUI = New("ScreenGui", {
      Parent = RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui"),
      IgnoreGuiInset = true,
      ResetOnSpawn = false
  })

  function ServerHopLibrary:CreateScreen(Config) 
      assert(Config.Duration, 'Duration is required!')
      assert(Config.Reason, 'Reason is required!')
      local Timeout = Config.Duration
      
      local Screen = {}
      
      Screen.JobId = New("TextLabel", {
          BackgroundTransparency = 1,
          AnchorPoint = Vector2.new(0.5, 0),
          Position = UDim2.new(0.5, 0, 0, 2),
          Size = UDim2.new(1, 0, 0, 20),
          Font = Enum.Font.GothamBold,
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 14,
          TextTransparency = 0.5,
          Text = string.format("JobId: %s", game.JobId or "00000000-0000-0000-0000-000000000000")
      })
      
      Screen.HopText = New('TextLabel', {
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1.000,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0.5, 0, 0.56, 0),
          Size = UDim2.new(1, 0, 0, 35),
          Font = Enum.Font.GothamBold,
          Text = "Hopping Server in " .. Timeout .. "s...",
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 22.000,
          TextWrapped = true,
          TextYAlignment = Enum.TextYAlignment.Top,
      })
  
      Screen.BottomText = New('TextLabel', {
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1.000,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0.5, 0, 0.600000024, 0),
          Size = UDim2.new(1, 0, 0, 20),
          Font = Enum.Font.Gotham,
          Text = "Double click to the screen to abort the process.",
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 14.000,
          TextTransparency = 0.4,
          TextWrapped = true,
      })
      
      Screen.TextHolder = New('Frame', {
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1.000,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0.5, 0, 0.5, 0),
          AutomaticSize = Enum.AutomaticSize.XY
      }, {
          New('UIListLayout', {
              SortOrder = Enum.SortOrder.LayoutOrder,
          }),
          
          New('TextLabel', {
              AnchorPoint = Vector2.new(0.5, 0.5),
              BackgroundColor3 = Color3.fromRGB(255, 255, 255),
              BackgroundTransparency = 1.000,
              BorderColor3 = Color3.fromRGB(0, 0, 0),
              BorderSizePixel = 0,
              Position = UDim2.new(0.5, 0, 0.5, 0),
              Size = UDim2.new(1, 0, 0, 76),
              Font = Enum.Font.GothamBold,
              Text = "",
              TextColor3 = Color3.fromRGB(173, 188, 230),
              TextSize = 80.000,
          }),
          
          Screen.HopText,
          
          New('TextLabel', {
              AnchorPoint = Vector2.new(0.5, 0.5),
              BackgroundColor3 = Color3.fromRGB(255, 255, 255),
              BackgroundTransparency = 1.000,
              BorderColor3 = Color3.fromRGB(0, 0, 0),
              BorderSizePixel = 0,
              Position = UDim2.new(0.5, 0, 0.600000024, 0),
              Size = UDim2.new(1, 0, 0, 20),
              Font = Enum.Font.Gotham,
              Text = "Reason: " .. Config.Reason,
              TextColor3 = Color3.fromRGB(255, 255, 255),
              TextSize = 16.000,
              TextWrapped = true,
          }),
          
          Screen.BottomText
      })
      
      Screen.InnerProgressBar = New("Frame", {
          BackgroundColor3 = Color3.fromRGB(173, 188, 230),
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Size = UDim2.new(1, 0, 1, 0),
      }, {
          New("UICorner", {
              CornerRadius = UDim.new(0, 999),
          }),
      })
  
      Screen.ProgressBar = New("Frame", {
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(17, 17, 27),
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.fromScale(0.5, 0.94),
          Size = UDim2.new(0.35, 0, 0, 8),
      }, {
          New("UICorner", {
              CornerRadius = UDim.new(0, 999),
          }),
  
          Screen.InnerProgressBar
      })
      
      Screen.Frame = New("CanvasGroup", {
          Parent = GUI,
          Size = UDim2.fromScale(1, 1),
          BackgroundColor3 = Color3.fromRGB(0, 0, 0),
          BackgroundTransparency = 0.3,
          GroupTransparency = 1
      }, {
          Screen.JobId,
          Screen.TextHolder,
          Screen.ProgressBar
      })
      
      local Aborted = false
      local LastClickTime = 0
      local DoubleClickTime = 0.25 
  
      Screen.Frame.InputBegan:Connect(function(Input)
          if
              Input.UserInputType == Enum.UserInputType.MouseButton1
              or Input.UserInputType == Enum.UserInputType.Touch
          then
              local CurrentClickTime = RunService.Stepped:Wait()
  
              if (CurrentClickTime - LastClickTime) < DoubleClickTime then
                  Aborted = true
              end
  
              LastClickTime = CurrentClickTime
          end
      end)
      local Finish = false
      local Status = "None"
      task.spawn(function()
          while true do
              if Aborted then
                  Screen.HopText.Text = "Hopping Server aborted by user."
                  Screen.BottomText.Text = "Function Will be Delayed For 15 Second If You Want To Turn off"
                  Tween(Screen.InnerProgressBar, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut}, {Size = UDim2.new(1, 0, 1, 0)})
                  
                  task.delay(1, function()
                      local Timeout = 10
                      
                      while task.wait(1) do
                          if Timeout <= 0 then
                              Screen.TextHolder.Visible = false
                              Screen.JobId.Visible = false
                              Screen.ProgressBar.Visible = false
                              Finish=true
                              Status="Abort"
                              Tween(Screen.Frame, {0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut}, {GroupTransparency = 1}, function()
                                  Screen.Frame:Destroy()
                              end)
                          end
                          
                          Timeout -= 1
                          Screen.HopText.Text = "Deleting UI in " .. Timeout .. "s"
                          Tween(Screen.InnerProgressBar, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut}, {Size = UDim2.new(math.clamp(Timeout / 10, 0, 1), 0, 1, 0)})
                      end
                  end)
                  
                  break
              end
              
              Timeout -= 1
              Screen.HopText.Text = "Hopping Server in " .. Timeout .. "s..."
              Tween(Screen.InnerProgressBar, {0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut}, {Size = UDim2.new(math.clamp(Timeout / 10, 0, 1), 0, 1, 0)})
              
              if Timeout <= 0 then
                  Finish = true
                  Status="Success"
                  break
              end
  
              task.wait(1)
          end
      end)
      
      --local ScreenMotor = Flipper.SingleMotor.new(1)
      
      --ScreenMotor:onStep(function(value)
      --	Screen.Frame.GroupTransparency = value
      --end)
      
      --ScreenMotor:setGoal(Flipper.Spring.new(0, { frequency = 8, damping = 0 }))
      Tween(Screen.Frame, {0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut}, {GroupTransparency = 0})
      repeat task.wait()
      until Finish
      return Status	
  end
return ServerHopLibrary