if string.find(identifyexecutor(),"macsploit") then
                    return 
                end
                local gt = getrawmetatable(game)
                local namecall = gt.__namecall
                setreadonly(gt, false)
                gt.__namecall = newcclosure(function(self, ...)

                    local method = getnamecallmethod()
                    local args = {...}
                    if method == "FireServer" then 
                        if tostring(self) == "RemoteEvent" then 
                            if tostring(args[1]) ~= "true" and tostring(args[1]) ~= "false" and not getgenv().Setting.Pvp.DisableSilentAim then
                                local HookPosition = (getgenv().SilentAimPos and getgenv().PosToHook) or (getgenv().Setting.Pvp.SilentAimNear and getgenv().HitPosition)
                                if HookPosition then
                                    if  #args == 1 and typeof(args[1]) == "Vector3" then
                                        args[1] = HookPosition
                                    end
                                    if #args == 1 and typeof(args[1]) == "CFrame" then
                                        args[1] = CFrame.new(HookPosition)
                                    end
                                end 
                            end
                        end

                    end
                    if method == "InvokeServer" then 
                        
                        if self.Parent ~= nil and tostring(self.Parent) == "Humanoid" then 
                        
                            if tostring(args[2]) ~= "true" and tostring(args[2]) ~= "false" and type(args[2]) == "vector" and not getgenv().Setting.Pvp.DisableSilentAim then
                            --  print(tostring(self),self.Parent,self.Parent.Parent)
                            --  print(tostring(getcallingscript()))
                                local HookPosition = (getgenv().SilentAimPos and getgenv().PosToHook) or (getgenv().Setting.Pvp.SilentAimNear and getgenv().HitPosition)
                                if HookPosition then
                                    --print("hooked 2")
                                    if  typeof(args[2]) == "Vector3" then
                                        args[2] = HookPosition
                                    end
                                    if typeof(args[2]) == "CFrame" then
                                        args[2] = CFrame.new(HookPosition)
                                    end
                                end
                            end
                        end
                    end
                    if method == "GetServerTimeNow" then
                        local callingscript = getcallingscript().Name
                        local func = getgenv().getcallingfunction(3)
                        if  callingscript == "Skyjump" then
                            
                            if debug.getinfo(func).name  == "jumped" then
                                getgenv().SkyFunc = func
                            end
                        else
                            if debug.getinfo(func).name  == "handleAction" then
                                if callingscript == "Dodge" then
                                    getgenv().DodgeFunc = func
                                end
                                if callingscript == "Soru" then 
                                    getgenv().SoruFunc = func
                                end
                            end
                        end
                    end

                    return namecall(self, unpack(args))
                end)
