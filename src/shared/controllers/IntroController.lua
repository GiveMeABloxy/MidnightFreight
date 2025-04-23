local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local IntroController = Knit.CreateController{
	Name = 'IntroController'
}

--//Game Services
local TweenService = game:GetService("TweenService")

--//Variables
local SKIP_INTRO = true

--//Services & Controllers
local UIController

function IntroController:KnitInit()
    UIController = Knit.GetController("UIController")
end

function IntroController:KnitStart()
    self:BeginIntro()
end

function IntroController:BeginIntro()
    local screenGui = UIController:GetScreenGui()
    local blackDialogue = screenGui:WaitForChild("BlackDialogue")
    local advisory = blackDialogue:WaitForChild("Advisory")
    local roadBackground = blackDialogue:WaitForChild("RoadBackground")

    if SKIP_INTRO then blackDialogue.Visible = false return end

    --//Setting UI gradients so that text is invisible at the beginning.
    for _,text in pairs(advisory:GetChildren()) do
        if not text:IsA("TextLabel") then continue end
        local uiGradient = text:WaitForChild("UIGradient")
        uiGradient.Offset = Vector2.new(0,1)
    end
    task.wait()
    advisory.Visible = true

    --//Tweening UI gradients to make text appear one by one.
    for _,text in pairs(advisory:GetChildren()) do
        if not text:IsA("TextLabel") then continue end
        local uiGradient = text:WaitForChild("UIGradient")
        local gradientTween = TweenService:Create(uiGradient,TweenInfo.new(3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Offset = Vector2.new(0,-0.5)})
        gradientTween:Play()
        if text.Name ~= "5" then
            gradientTween.Completed:Wait()
        end
        
        task.wait(1)
    end

    for _,image in pairs(roadBackground:GetChildren()) do
        if not image:IsA("ImageLabel") then continue end
        TweenService:Create(image,TweenInfo.new(5,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{ImageColor3 = Color3.fromRGB(255,0,0)}):Play()
    end

    task.wait(5)
    blackDialogue.Visible = false

end

return IntroController