local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddControllers(game:GetService("ReplicatedStorage").Shared.controllers)

Knit.Start({
    ServicePromises = false,
}):andThen(function()
    print("Knit client started! 🖥️")
end)