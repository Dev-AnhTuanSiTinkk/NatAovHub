-- Hook __newindex bypass
if string.find(identifyexecutor(),"macsploit") then
                    return 
                end
                print("loading [0x02]")
                local lp = game.Players.LocalPlayer
                local gt2 = getrawmetatable(lp)
                local newIndex = gt2.__newindex
                setreadonly(gt2, false)
                gt2.__newindex = newcclosure(function(self, Index, Value)
                    if getgenv().Setting.LocalPlayer.SpeedHack and tostring(Index) == "WalkSpeed" and tostring(self) == "Humanoid"  then
                        Value = getgenv().Setting.LocalPlayer.Speed or 100
                    end
                    return newIndex(self, Index, Value)
                end)
