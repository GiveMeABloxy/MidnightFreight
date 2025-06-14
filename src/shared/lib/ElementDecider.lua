local GenerationRules = require(script.Parent.GenerationRules)

local ElementDecider = {}

--//How many roads we look ahead to avoid conflict with higher-priority elements.
local LOOKAHEAD_BUFFER = 3

--//Returns true if the element is due for forced generation.
local function isForced(rule,roadNumber)
    if rule.MustGenerate and rule.PerRoad and rule.LastGenerated then
        local interval = rule.PerRoad.Value
        return roadNumber % interval == 0
    end
    return false
end

--//Returns true if the element is eligible to be generated.
local function isEligible(name, rule, roadNumber)
    local perRoad = rule.PerRoad.Value
    local cooldown = rule.Cooldown.Value
    
    --//Pre-road interval check.
    if roadNumber % perRoad ~= 0 then
        return false
    end

    --//Global spacing check: this element can't be near any others.
    for otherName, otherRule in pairs(GenerationRules) do
        local last = otherRule.LastGenerated.Value
        if last > 0 and math.abs(roadNumber - last) <= cooldown then
            return false
        end
    end

    return true
end

--//Check if any higher-priority element is due soon.
local function hasHigherPriorityConflict(candidateRule,roadNumber)
    local candidatePriority = candidateRule.Priority
    local candidateCooldown = candidateRule.Cooldown.Value

    for _,other in pairs(GenerationRules) do
        if other.Priority > candidatePriority then
            local interval = other.PerRoad.Value
            local nextRoad = math.ceil(roadNumber / interval) * interval
            if (nextRoad - roadNumber) <= candidateCooldown then
                return true
            end
        end
    end
    return false
end

function ElementDecider:Pick(roadNumber)
    local eligible = {}

    for name,rule in pairs(GenerationRules) do

        --//Skip if the rule is disabled.
        if rule.Enabled == false then
            continue
        end

        if isForced(rule, roadNumber) then
            return name
        end

        if isEligible(name,rule,roadNumber) then
            table.insert(eligible, {
                Name = name,
                Priority = rule.Priority,
                Rule = rule,
            })
        end
    end

    --//Find highest priority among eligible entries.
    local topPriority = -math.huge
    local topEntries = {}

    for _,entry in ipairs(eligible) do
        if entry.Priority > topPriority then
            topPriority = entry.Priority
            topEntries = {entry}
        elseif entry.Priority == topPriority then
            table.insert(topEntries,entry)
        end
    end

    --//Randomly pick from top-priority entries that don't have conflicts.
    while #topEntries > 0 do
        local index = math.random(1,#topEntries)
        local candidate = table.remove(topEntries,index)

        if not hasHigherPriorityConflict(candidate.Rule, roadNumber) then
            return candidate.Name
        end
    end

    return nil
end

return ElementDecider