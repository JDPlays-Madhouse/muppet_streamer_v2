-- Groups to exist
--  - No remote view
--  - No hovering (Not a permission change)
--  - Already existing ones
local AddPlayerToPermissionGroup = {}; ---@class AddPlayerToPermissionGroup

local CommandsUtils = require("utility.helper-utils.commands-utils")
local Common = require("scripts.common")
local MalfunctioningWeapon = require("scripts.malfunctioning-weapon")
local AggressiveDriver = require("scripts.aggressive-driver")

---@class AddPlayerToPermissionGroup_ApplyToPlayer
---@field target string # Player's name.
---@field groupName string | nil # Name of the permission group.
---@field revert boolean # Revert the player back to their original group.
---@field forceToCharacter boolean # Force the player out of remote view.
---@

local CommandName = "muppet_streamer_v2_add_player_to_permission_group"
AddPlayerToPermissionGroup.CreateGlobals = function()
end

AddPlayerToPermissionGroup.OnLoad = function()
    CommandsUtils.Register("muppet_streamer_v2_add_player_to_permission_group",
        {"api-description.muppet_streamer_v2_add_player_to_permission_group"},
        AddPlayerToPermissionGroup.AddPlayerToPermissionGroupCommand, true)
    MOD.Interfaces.Commands.AddPlayerToPermissionGroup = AddPlayerToPermissionGroup.AddPlayerToPermissionGroupCommand

end
AddPlayerToPermissionGroup.OnStartup = function()
    for name, GetOrCreatePermissionGroup in pairs(AddPlayerToPermissionGroup.Groups) do
        game.print("Creating permission group " .. name)
        GetOrCreatePermissionGroup()
    end
end

---@param command CustomCommandData
AddPlayerToPermissionGroup.AddPlayerToPermissionGroupCommand = function(command)
    local commandData = CommandsUtils.GetSettingsTableFromCommandParameterString(command.parameter, true, CommandName,
        {"target", "groupName", "revert", "forceToCharacter"});
    if commandData == nil then
        return
    end

    local target = commandData.target
    if not Common.CheckPlayerNameSettingValue(target, CommandName, "target", command.parameter) then
        return
    end ---@cast target string

    local revert = commandData.revert;
    local groupName = commandData.groupName;
    if not CommandsUtils.CheckBooleanArgument(revert, false, CommandName, "revert", command.parameter) then
        revert = false;
    end ---@cast revert boolean

    if not CommandsUtils.CheckStringArgument(groupName, not revert, CommandName, "groupName",
        AddPlayerToPermissionGroup.Groups, command.parameter) then
        return;
    end ---@cast groupName string

    local forceToCharacter = commandData.forceToCharacter;
    if not CommandsUtils.CheckBooleanArgument(forceToCharacter, false, CommandName, "forceToCharacter",
        command.parameter) then
        forceToCharacter = false;
    end ---@cast forceToCharacter boolean

    ---@type AddPlayerToPermissionGroup_ApplyToPlayer
    local data = {
        target = target,
        groupName = groupName,
        revert = revert,
        forceToCharacter = forceToCharacter
    }
    AddPlayerToPermissionGroup.ApplyToPlayer(data)

end

---@param player LuaPlayer
AddPlayerToPermissionGroup.ForceToCharacter = function(player)
    player.exit_remote_view();
end

---@param data AddPlayerToPermissionGroup_ApplyToPlayer
AddPlayerToPermissionGroup.ApplyToPlayer = function(data)
    local targetPlayer = game.get_player(data.target)
    if targetPlayer == nil then
        CommandsUtils.LogPrintWarning(CommandName, nil, "Target player has been deleted since the command was run.", nil)
        return
    end
    local targetPlayer_index, targetPlayer_character = targetPlayer.index, targetPlayer.character;

    if data.revert then
        if storage.originalPlayersPermissionGroup[targetPlayer_index] == nil then
            CommandsUtils.LogPrintWarning(CommandName, "revert",
                "Player is already reverted to original permission group.", nil)
            return
        end
        targetPlayer.permission_group = storage.originalPlayersPermissionGroup[targetPlayer_index];
        storage.originalPlayersPermissionGroup[targetPlayer_index] = nil

        if data.forceToCharacter then
            AddPlayerToPermissionGroup.ForceToCharacter(targetPlayer)
        end
        return
    end

    if data.groupName == nil then
        CommandsUtils.LogPrintWarning(CommandName, "groupName",
            "groupName is required for AddPlayerToPermissionGroup.ApplyToPlayer when revert is false.", nil)
        return
    end

    local group = AddPlayerToPermissionGroup.Groups[data.groupName](); ---@type LuaPermissionGroup

    -- Store the players current permission group. Left as the previously stored group if an effect was already being applied to the player, or captured if no present effect affects them.
    storage.originalPlayersPermissionGroup[targetPlayer_index] =
        storage.originalPlayersPermissionGroup[targetPlayer_index] or targetPlayer.permission_group

    targetPlayer.permission_group = group;
    if data.forceToCharacter then
        AddPlayerToPermissionGroup.ForceToCharacter(targetPlayer)
    end
end

AddPlayerToPermissionGroup.Groups = {
    --- @return LuaPermissionGroup
    MalfunctioningWeapon = MalfunctioningWeapon.GetOrCreatePermissionGroup,
    --- @return LuaPermissionGroup
    AggressiveDriver = AggressiveDriver.GetOrCreatePermissionGroup,
    --- @return LuaPermissionGroup
    NoRemoteView = function()
        local group = game.permissions.get_group("NoRemoteView") or game.permissions.create_group("NoRemoteView") ---@cast group -nil # Script always has permission to create groups.
        group.set_allows_action(defines.input_action.remote_view_entity, false)
        group.set_allows_action(defines.input_action.remote_view_surface, false)
        return group
    end,
    --- @return LuaPermissionGroup
    Default = function()
        local group = game.permissions.get_group("Default") or game.permissions.create_group("Default") ---@cast group -nil # Script always has permission to create groups.
        return group
    end
}; ---@class AddPlayerToPermissionGroupGroups

return AddPlayerToPermissionGroup;
