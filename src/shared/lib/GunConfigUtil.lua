local GunConfigUtil = {}

local DEFAULTS = {
    Damage = 10, --// Damage per bullet
    FireRate = 6, --// Bullets shot per second
    FireMode = "Semi", --// Semi or Auto
    MaxAmmo = 30, --// Magazine size
    ReserveAmmo = 90, --// Extra ammo in reserve
    ReloadTime = 2.5, --// Time to reload
    Spread = 0, --// Degrees
    BloomGrowth = 0.25,
    BloomDecay = 1.0,
    MaxBloom = 5.0,
    BulletSpeed = 300,
    Range = 1000, --// Max range of the bullet
    BulletsPerShot = 1, --// Number of bullets shot per fire
}

function GunConfigUtil.GetStat(tool: Tool, key: string)
    if not tool or not key then return nil end
    return tool:GetAttribute(key) or DEFAULTS[key]
end

function GunConfigUtil.GetStats(tool: Tool)
    if not tool then return nil end

    local stats = {}
    for key, default in pairs(DEFAULTS) do
        stats[key] = tool:GetAttribute(key) or default
    end

    return stats
end

return GunConfigUtil