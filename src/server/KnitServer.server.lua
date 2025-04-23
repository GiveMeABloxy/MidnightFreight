local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddServices(game:GetService("ServerScriptService").Server.services)

Knit.Start():andThen(function()
    print("Knit server started! ✅")
end):catch(warn)

