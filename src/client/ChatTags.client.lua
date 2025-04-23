local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

local chatTags = {
    ["Developer"] = Color3.fromRGB(255, 251, 0),
    ["Member"] = Color3.fromRGB(255,70,70),
}

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	
	if message.TextSource then
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		if player:GetRankInGroup(3239513) >= 252 then --//Developer tag.
            props.PrefixText = "<font color='rgb(255,255,0)'>[DEVELOPER]</font> " .. message.PrefixText
        elseif player:IsInGroup(3239513) then --//Member tag.
            props.PrefixText = "<font color='rgb(255,70,70)'>[MEMBER]</font> " .. message.PrefixText
        end
	end
	
	return props
end