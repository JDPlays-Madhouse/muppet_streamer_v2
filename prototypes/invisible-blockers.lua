--[[
    Creates a series of different invisible blockers for adhoc use.
    Has types of:
        - all = same layers as a standard building, so collides with everything basically.
        - building = object layer, so blocks all buildings, but units & characters can walk on it. i.e. belts.
        - train = train layer, so only blocks trains.
    They are not selectable in-game by players and have no graphics.
    Make sure to set them as indestructible after creation as this can't be enforced from prototype.
--]]

---@enum InvisibleBlocker_BlockerType
local INVISIBLE_BLOCKER_BLOCKER_TYPE = {
    all = { layers = { player = true, rail = true, object = true } } --[[@as CollisionMask]],
    building = { layers = { object = true } } --[[@as CollisionMask]],
    train = { layers = { rail = true } } --[[@as CollisionMask]]
}

---@param size uint
---@param blockerType string
---@param collisionMask CollisionMask
local function CreateBlocker(size, blockerType, collisionMask)
    ---@type data.SimpleEntityPrototype
    local blockerPrototype = {
        type = "simple-entity",
        name = "muppet_streamer_v2-invisible_blocker-" .. blockerType .. "-" .. size,
        localised_name = { "entity-name.muppet_streamer_v2-invisible_blocker" },
        collision_box = { { -size, -size }, { size, size } },
        collision_mask = collisionMask,
        selection_box = { { -size, -size }, { size, size } }, --Only affects editor mode.
        selectable_in_game = false,
        allow_copy_paste = false,
        flags = { "not-on-map", "not-deconstructable", "not-blueprintable", "not-flammable" },
        hidden = true,
        remove_decoratives = "false"
    }

    data:extend({ blockerPrototype })
end

---@param size uint
local function CreateAllBlockerTypesForSize(size)
    for blockerType, collisionMask in pairs(INVISIBLE_BLOCKER_BLOCKER_TYPE) do
        CreateBlocker(size, blockerType, collisionMask)
    end
end

-- Add the required sizes (all square).
for _, size in pairs({ 1, 2, 4, 8, 16 }) do
    CreateAllBlockerTypesForSize(size)
end
