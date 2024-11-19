local Loading = {} do
    local stop = false
    function Loading:SetValue(value)
        stop = value
    end
    function Loading:SetLoading(main, load, count, mainnumber, miscnumber)
        local Loader, Connect
        if not load or (load and typeof(load) ~= "number") then
               load = 0
        end
        if load >= 1 then
            local NotifyHolder = Instance.new("ScreenGui")
            NotifyHolder.Parent = game:GetService("CoreGui")

            setmetatable(main.Options, {
                __len = function(t)
                    local c = 0
                    for n, r in next, t do
                        c += 1
                    end
                    return c
                end
            })
            Connect = main.Window.Root.DescendantAdded:Connect(
                function(Child)
                    if Child:IsA("TextButton") and main.Loaded < 100 then
                        main.Loaded += (main.Loaded < count and mainnumber) or miscnumber
                    end
                end
            )
            Loader = main:Notify(
                {
                    Title = "[Loading] —— "..main.Name,
                    SubContent = "0% / 100%",
                    Disable = true
                }
            )
            task.spawn(
                function()
                    while true and task.wait() do
                        if not main.GUI.Parent then
                            break
                        elseif Loader then
                            main.NotifyHolder.Parent = NotifyHolder

                            if main.GUI and main.GUI.Enabled then
                                main.GUI.Enabled = false
                            end

                            pcall(
                                function()
                                    Loader.SubContentLabel.Text = (main.Loaded >= 100 and "100") or tostring(main.Loaded).."% / 100%"
                                end
                            )

                            if stop then
                                Loader.SubContentLabel.Text = (main.Loaded >= 100 and "100") or tostring(main.Loaded).."% / 100%"

                                if main.Loaded >= 100 then
                                    if main.GUI.Parent then
                                        main.GUI.Enabled = true
                                        main.NotifyHolder.Parent = main.GUI
                                        NotifyHolder:Destroy()
                                        if Connect.Connected then
                                            Connect:Disconnect()
                                        end
                                        Loader:Close()
                                    end
                                    task.wait(0.55)
                                    break
                                else
                                    main.Loaded += 1
                                end
                            end

                        end
                    end
                end
            )
        else
            main.GUI.Enabled = true
            main.NotifyHolder.Parent = main.GUI
        end
    end

end
return Loading

