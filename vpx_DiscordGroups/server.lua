local config = module("vpx_DiscordGroups", "config")

local vpx_DiscordGroups = class("vpx_DiscordGroups", vRP.Extension)

local function contains(t, value)
	for k, v in pairs(t) do
		if v == value then
			return true
		end
	end

	return false
end

local function get_player_discord_id(source)
	local identifiers = GetPlayerIdentifiers(source)

	for i, identifier in ipairs(identifiers) do
		local type, value = table.unpack(splitString(identifier, ':'))
		if type == 'discord' then
			return value
		end
	end
end

local function fetch_guild_member(guild_id, user_id)
	local r = async()
	
	PerformHttpRequest(("https://discord.com/api/guilds/%s/members/%s"):format(guild_id, user_id), function (code, data, headers)
        r(code == 200 and json.decode(data) or nil)
    end, 'GET', '', { Authorization = config.token })

	return r:wait()
end

vpx_DiscordGroups.event = {}
function vpx_DiscordGroups.event:playerJoin(user)
	local discord_id = get_player_discord_id(user.source)
	if discord_id == nil then return end

	local member = fetch_guild_member(config.guildId, discord_id)
	if member == nil then return end

	print(json.encode(member), { indent = 4 })

	for i, entry in ipairs(config.groups) do
		if contains(member.roles, entry.roleId) then
			user:addGroup(entry.group)
		else
			user:removeGroup(entry.group)
		end
	end
end

vRP:registerExtension(vpx_DiscordGroups)