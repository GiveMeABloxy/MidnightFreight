local Settings = {}

local gameSettings = {
	
	--//Time-Related.
	["CurrentDay"] = 1, --//Current day in-game.
	["TimeStarted"] = nil, --//Time the game starts.
	["TravelDuration"] = 3, --//The amount of time it takes for planes and boats to travel between destinations.
	["DayDuration"] = 1, --//The amount of time a day lasts.
	["CureDelay"] = 30, --//In-game days it takes after discovery to start working on the cure.
	
	--//Travel-Related Infection.
	["AirInfectionBonus"] = 0,
	["WaterInfectionBonus"] = 0,
	["BorderInfectionBonus"] = 0,
	
	--//Climate-Related Infection.
	["UrbanInfectionBonus"] = 0,
	["RuralInfectionBonus"] = 0,
	["HumidInfectionBonus"] = 0,
	["AridInfectionBonus"] = 0,
	
	--//Wealth-Related Infection
	["RichThreshold"] = 7, --//A country's wealth must be this or higher to be considered rich.
	["PoorThreshold"] = 4, --//A country's wealth must be this or lower to be considered poor.
	
	["WealthInfectionBonus"] = 0,
	["PoorInfectionBonus"] = 0,
	["RichInfectionBonus"] = 0,
	
	--//Controls fatality of 100% infection.
	["FatalityRate"] = 0, --//How fatal the plague is.
	["FatalityThreshold"] = 0, --//At what % of fatality it begins to kill people.
	
	--//Base rewards a player can earn
	["BaseCash"] = 50,
	["BaseXP"] = 50,
	
	--//Temperature-Related Infection.
	["HotInfectionBonus"] = 0,
	["ColdInfectionBonus"] = 0,
	
	["InfectionRate"] = 1 / 50, --//Rate dictating how many people are infected per person infected. (Ex. (1 / 100) = 1 new infection every 100 infected people)
	
	--//Country-Related.
	["Awareness"] = 0, --//How aware the countries are of your plague.
	["CureRate"] = 1000, --//How fast countries are working on a cure for your plague.
	["CureProgress"] = 0,
	["CureBubbleChance"] = 0.1, --//Chance of a blue cure bubble appearing from a country that is curing.
	["AirPassengers"] = 300,
	["SeaPassengers"] = 100,
	
	--//Prompt-Related.
	["PromptCooldown"] = 5, --//Cooldown between queued prompts appearing.
	["RandomPromptChance"] = 0.005, --//Everyday chance that a random prompt will appear.

	--//Other.
	["StartingDNA"] = 8,
	["DNAMulti"] = 1,
	["CoinMulti"] = 1,
	
	--//Game settings.
	["PlagueType"] = "",
	["GameMode"] = "",
	["StartCountry"] = "",
	
}

function Settings:GetSettings()
	return gameSettings
end

function Settings:ChangeSettings(setting,newAmount)
	gameSettings[setting] = newAmount
end

return Settings
