local Common = {} ---@class Common
local MathUtils = require("utility.helper-utils.math-utils")
local TableUtils = require("utility.helper-utils.table-utils")
local CommandsUtils = require("utility.helper-utils.commands-utils")

--- Takes a delay value in seconds and returns the Scheduled Event tick value. Caps it if it's greater than the game's max tick.
---@param delaySeconds double|nil
---@param currentTick uint
---@param commandName string
---@param settingName string
---@return UtilityScheduledEvent_UintNegative1
Common.DelaySecondsSettingToScheduledEventTickValue = function(delaySeconds, currentTick, commandName, settingName)
    local scheduleTick ---@type UtilityScheduledEvent_UintNegative1
    if (delaySeconds ~= nil and delaySeconds > 0) then
        local valueWasOutsideRange ---@type boolean
        scheduleTick, valueWasOutsideRange = MathUtils.ClampToUInt(currentTick + math.floor(delaySeconds * 60))
        if valueWasOutsideRange then
            CommandsUtils.LogPrintWarning(commandName, settingName,
                "capped at max ticks, as excessively large number of delay seconds provided: " .. tostring(delaySeconds),
                nil)
        end
        if scheduleTick == currentTick then
            scheduleTick = -1 ---@type UtilityScheduledEvent_UintNegative1
        end
    else
        scheduleTick = -1 ---@type UtilityScheduledEvent_UintNegative1
    end
    return scheduleTick
end

--- Takes a setting in seconds, applies it to the baseTick and returns it, after capping it if it's greater than the game's max tick.
---@param seconds double|nil
---@param baseTick uint
---@param commandName string
---@param settingName string
---@return uint|nil cappedTicks
Common.SecondsSettingToTickValue = function(seconds, baseTick, commandName, settingName)
    local cappedTicks ---@type uint|nil
    if (seconds ~= nil and seconds > 0) then
        local valueWasOutsideRange ---@type boolean
        cappedTicks, valueWasOutsideRange = MathUtils.ClampToUInt(baseTick + math.floor(seconds * 60))
        if valueWasOutsideRange then
            CommandsUtils.LogPrintWarning(commandName, settingName,
                "capped at max ticks, as excessively large number of seconds provided: " .. tostring(seconds), nil)
        end
    else
        cappedTicks = nil
    end
    return cappedTicks
end

--- A bespoke check for a player's name setting. Includes the setting as mandatory and that there's a player with this name.
---@param playerName string
---@param commandName string
---@param settingName string
---@param commandString? string|nil # If provided it will be included in error messages. Not needed for operational use.
---@return boolean isValid
Common.CheckPlayerNameSettingValue = function(playerName, commandName, settingName, commandString)
    -- Check its a valid populated string first, then that it's a player's name.
    if not CommandsUtils.CheckStringArgument(playerName, true, commandName, settingName, nil, commandString) then
        return false
    elseif game.get_player(playerName) == nil then
        CommandsUtils.LogPrintWarning(commandName, settingName, "is the name of a non present player", commandString)
        return false
    end
    return true
end

---@enum Common_CommandNames
Common.CommandNames = {
    muppet_streamer_v2_aggressive_driver = "muppet_streamer_v2_aggressive_driver",
    muppet_streamer_v2_call_for_help = "muppet_streamer_v2_call_for_help",
    muppet_streamer_v2_schedule_explosive_delivery = "muppet_streamer_v2_schedule_explosive_delivery",
    muppet_streamer_v2_give_player_weapon_ammo = "muppet_streamer_v2_give_player_weapon_ammo",
    muppet_streamer_v2_malfunctioning_weapon = "muppet_streamer_v2_malfunctioning_weapon",
    muppet_streamer_v2_pants_on_fire = "muppet_streamer_v2_pants_on_fire",
    muppet_streamer_v2_player_drop_inventory = "muppet_streamer_v2_player_drop_inventory",
    muppet_streamer_v2_player_inventory_shuffle = "muppet_streamer_v2_player_inventory_shuffle",
    muppet_streamer_v2_spawn_around_player = "muppet_streamer_v2_spawn_around_player",
    muppet_streamer_v2_teleport = "muppet_streamer_v2_teleport",
    muppet_streamer_v2_add_player_to_permission_group = "muppet_streamer_v2_add_player_to_permission_group"
}

--- Allows calling a command via a remote interface.
---@param commandName Common_CommandNames # The command to be run.
---@param options string|table # The options being passed in.
---@return ... # The returns if any.
Common.CallCommandFromRemote = function(commandName, options)
    -- Check the command name is valid.
    if not CommandsUtils.CheckStringArgument(commandName, true, "Remote Interface", "commandName", Common.CommandNames,
        commandName) then
        return nil
    end

    -- Check options are populated.
    if options == nil then
        CommandsUtils.LogPrintError("Remote Interface", commandName, "received no option data", nil)
        return nil
    end

    -- Get the command string equivalent for the remote call.
    local commandString
    if type(options) == "string" then
        -- Options should be a JSON string already so can just pass it through.
        commandString = options
    elseif type(options) == "table" then
        -- Options should be a table of settings, so convert it to JSOn and just pass it through.
        commandString = helpers.table_to_json(options)
    else
        CommandsUtils.LogPrintError("Remote Interface", commandName,
            "received unexpected option data type: " .. type(options),
            TableUtils.TableContentsToJSON(options, nil, true))
        return nil
    end

    -- Make the fake command object to pass in so the feature thinks its a command being called directly.
    ---@type CustomCommandData
    local commandData = {
        name = commandName,
        player_index = nil,
        parameter = commandString,
        tick = game.tick
    }

    -- Call the correct features command with the details.
    if commandName == Common.CommandNames.muppet_streamer_v2_aggressive_driver then
        return MOD.Interfaces.Commands.AggressiveDriver(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_call_for_help then
        return MOD.Interfaces.Commands.CallForHelp(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_schedule_explosive_delivery then
        return MOD.Interfaces.Commands.ExplosiveDelivery(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_give_player_weapon_ammo then
        return MOD.Interfaces.Commands.GiveItems(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_malfunctioning_weapon then
        return MOD.Interfaces.Commands.MalfunctioningWeapon(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_pants_on_fire then
        return MOD.Interfaces.Commands.PantsOnFire(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_player_drop_inventory then
        return MOD.Interfaces.Commands.PlayerDropInventory(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_player_inventory_shuffle then
        return MOD.Interfaces.Commands.PlayerInventoryShuffle(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_spawn_around_player then
        return MOD.Interfaces.Commands.SpawnAroundPlayer(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_teleport then
        return MOD.Interfaces.Commands.Teleport(commandData)
    elseif commandName == Common.CommandNames.muppet_streamer_v2_add_player_to_permission_group then
        return MOD.Interfaces.Commands.AddPlayerToPermissionGroup(commandData)
    end
end

--- Gets a valid lua item prototype for the requested string and raises any errors needed.
---@param itemName string
---@param itemType string
---@param mandatory boolean
---@param commandName string # Used for error messages.
---@param argumentName? string|nil # Used for error messages.
---@param commandString? string|nil # Used for error messages.
---@return LuaItemPrototype|nil itemPrototype
---@return boolean validArgument # If false the argument is invalid for the command and it should probably stop execution.
Common.GetItemPrototypeFromCommandArgument = function(itemName, itemType, mandatory, commandName, argumentName,
    commandString)
    if not CommandsUtils.CheckStringArgument(itemName, mandatory, commandName, argumentName, nil, commandString) then
        return nil, false
    end
    local itemPrototype ---@type LuaItemPrototype|nil
    if itemName ~= nil and itemName ~= "" then
        itemPrototype = prototypes.item[itemName]
        if itemPrototype == nil or itemPrototype.type ~= itemType then
            CommandsUtils.LogPrintError(commandName, argumentName,
                "isn't a valid " .. itemType .. " type: " .. tostring(itemName), commandString)
            return nil, false
        end
    end
    return itemPrototype, true
end

--- Gets a valid lua entity prototype for the requested string and raises any errors needed.
---@param entityName string
---@param entityType string
---@param mandatory boolean
---@param commandName string # Used for error messages.
---@param argumentName? string|nil # Used for error messages.
---@param commandString? string|nil # Used for error messages.
---@return LuaEntityPrototype|nil entityPrototype
---@return boolean validArgument # If false the argument is invalid for the command and it should probably stop execution.
Common.GetEntityPrototypeFromCommandArgument = function(entityName, entityType, mandatory, commandName, argumentName,
    commandString)
    if not CommandsUtils.CheckStringArgument(entityName, mandatory, commandName, argumentName, nil, commandString) then
        return nil, false
    end
    local entityPrototype ---@type LuaEntityPrototype|nil
    if entityName ~= nil and entityName ~= "" then
        entityPrototype = prototypes.entity[entityName]
        if entityPrototype == nil or entityPrototype.type ~= entityType then
            CommandsUtils.LogPrintError(commandName, argumentName,
                "isn't a valid " .. entityType .. " type: " .. tostring(entityName), commandString)
            return nil, false
        end
    end
    return entityPrototype, true
end

--- Gets a LuaEntity by name and checks it is the right type. Raises any error messages required.
---@param entityName string # The entity to get by name
---@param expectedEntityType? string|string[]|nil # The type this entity must be, singular or a list (by value).
---@param commandName string # Used for error messages.
---@param commandString? string|nil # Used for error messages.
---@return LuaEntityPrototype|nil entityPrototype # nil return means its invalid.
Common.GetBaseGameEntityByName = function(entityName, expectedEntityType, commandName, commandString)
    local entityPrototype = prototypes.entity[entityName]
    if entityPrototype == nil then
        CommandsUtils.LogPrintError(commandName, nil, "tried to use base game '" .. entityName ..
            "' entity, but it doesn't exist in this save.", commandString)
        return nil
    end

    if expectedEntityType ~= nil then
        if type(expectedEntityType) == "string" then
            if entityPrototype.type ~= expectedEntityType then
                CommandsUtils.LogPrintError(commandName, nil, "tried to use base game '" .. entityName ..
                    "' entity, but it isn't type '" .. expectedEntityType .. "'.", commandString)
                return nil
            end
        elseif type(expectedEntityType) == "table" then
            local entityPrototype_type = entityPrototype.type
            local aValidType = false
            for _, thisExpectedEntityType in pairs(expectedEntityType) do
                if entityPrototype_type ~= thisExpectedEntityType then
                    aValidType = true
                    break
                end
            end
            if not aValidType then
                CommandsUtils.LogPrintError(commandName, nil,
                    "tried to use base game '" .. entityName .. "' entity, but it isn't one of the types: " ..
                        TableUtils.TableValueToCommaString(expectedEntityType) .. ".", commandString)
                return nil
            end
        end
    end

    return entityPrototype
end

--- Gets a LuaItem by name and checks it is the right type. Raises any error messages required.
---@param itemName string # The item to get by name
---@param expectedItemType? string|string[]|nil # The type this item must be, singular or a list (by value).
---@param commandName string # Used for error messages.
---@param commandString? string|nil # Used for error messages.
---@return LuaItemPrototype|nil itemPrototype # nil return means its invalid.
Common.GetBaseGameItemByName = function(itemName, expectedItemType, commandName, commandString)
    local itemPrototype = prototypes.item[itemName]
    if itemPrototype == nil then
        CommandsUtils.LogPrintError(commandName, nil, "tried to use base game '" .. itemName ..
            "' item, but it doesn't exist in this save.", commandString)
        return nil
    end

    if expectedItemType ~= nil then
        if type(expectedItemType) == "string" then
            if itemPrototype.type ~= expectedItemType then
                CommandsUtils.LogPrintError(commandName, nil, "tried to use base game '" .. itemName ..
                    "' item, but it isn't type '" .. expectedItemType .. "'.", commandString)
                return nil
            end
        elseif type(expectedItemType) == "table" then
            local itemPrototype_type = itemPrototype.type
            local aValidType = false
            for _, thisExpectedItemType in pairs(expectedItemType) do
                if itemPrototype_type ~= thisExpectedItemType then
                    aValidType = true
                    break
                end
            end
            if not aValidType then
                CommandsUtils.LogPrintError(commandName, nil,
                    "tried to use base game '" .. itemName .. "' item, but it isn't one of the types: " ..
                        TableUtils.TableValueToCommaString(expectedItemType) .. ".", commandString)
                return nil
            end
        end
    end

    return itemPrototype
end

--- Gets a LuaFluid by name and checks it is the right type. Raises any error messages required.
---@param fluidName string # The fluid to get by name
---@param commandName string # Used for error messages.
---@param commandString? string|nil # Used for error messages.
---@return LuaFluidPrototype|nil fluidPrototype # nil return means its invalid.
Common.GetBaseGameFluidByName = function(fluidName, commandName, commandString)
    local fluidPrototype = prototypes.fluid[fluidName]
    if fluidPrototype == nil then
        CommandsUtils.LogPrintError(commandName, nil, "tried to use base game '" .. fluidName ..
            "' fluid, but it doesn't exist in this save.", commandString)
        return nil
    end

    return fluidPrototype
end

return Common
