local CachePool = {}

local ServerStorage = game:GetService("ServerStorage")

local masterFolder = ServerStorage:FindFirstChild("GenerationCache")
if not masterFolder then
    masterFolder = Instance.new("Folder")
    masterFolder.Name = "GenerationCache"
    masterFolder.Parent = ServerStorage
end

--//Get an instance from the cache based on category and ID.
function CachePool:Get(category: string, id: number | string): Instance?
    local poolFolder = masterFolder:FindFirstChild(category)
    if not poolFolder then return nil end

    local cached = poolFolder:FindFirstChild(tostring(id))
    if cached then
        cached.Parent = nil
        return cached
    end

    return nil
end

--//Store an instance into the cache under category and ID.
function CachePool:Store(category: string, id: number | string, instance: Instance)
    local poolFolder = masterFolder:FindFirstChild(category)
    if not poolFolder then
        poolFolder = Instance.new("Folder")
        poolFolder.Name = category
        poolFolder.Parent = masterFolder
    end

    instance.Parent = poolFolder
    instance.Name = tostring(id)
end

--//Clear all instances from a category.
function CachePool:Clear(category: string)
    local poolFolder = masterFolder:FindFirstChild(category)
    if poolFolder then
        poolFolder:ClearAllChildren()
    end
end

--//Get number of instances in a category (for debugging).
function CachePool:Count(category: string): number
    local poolFolder = masterFolder:FindFirstChild(category)
    if poolFolder then
        return #poolFolder:GetChildren()
    end
    return 0
end

return CachePool