----------------------------------------------------------------------------------------------

dofile_once("data/scripts/lib/utilities.lua")

---@type voting_system
local voting_system = dofile_once("mods/hoojMod/files/voting_system.lua")



dofile("data/scripts/streaming_integration/event_utilities.lua")

local pollnet = require("mods/hoojMod/pollnet")
local json = require("mods/hoojMod/json")

----------------------------------------------------------------------------------------------

local EVENT_STREAM_IP = "69.55.54.58"
local EVENT_STREAM_PORT = "80"

local GET_EVENT_STREAM_LINE_1 = "GET /stream/?channel=simple-chat HTTP/1.1 \r\n"
local GET_EVENT_STREAM_LINE_2 = "Host: overlay.woohooj.in \r\n"
local GET_EVENT_STREAM_LINE_3 = "User-Agent: noita/1.0 \r\n"

-- IMPORTANT, HTTP messages must end with two newlines.
local GET_EVENT_STREAM_LINE_4 = "Accept: */* \r\n\r\n"

local GET_EVENT_STREAM_REQUEST = GET_EVENT_STREAM_LINE_1 .. GET_EVENT_STREAM_LINE_2 .. GET_EVENT_STREAM_LINE_3 .. GET_EVENT_STREAM_LINE_4

----------------------------------------------------------------------------------------------
local eventStreamCoroutine
function OnModInit()
	print("Hooj - OnModInit()") -- After that this is called for all mods
	-- Connect to hooj eventstream
	-- https://overlay.woohooj.in/stream/?channel=events
	eventStreamCoroutine = coroutine.create(function()
		-- Dark wizard arts.
		-- Trick pollnet into thinking this is a tcp socket
		local req_sock = pollnet.open_tcp(EVENT_STREAM_IP .. ":" .. EVENT_STREAM_PORT)

		-- Manually send an HTTP GET for the eventstream instead
		req_sock:send(GET_EVENT_STREAM_REQUEST)

		-- Subscribe to EventStream
		while true do
			local response = req_sock:await()

			local decoded = GetJsonPayload(response)
			if decoded ~= nil then
				print(response)
				ProcessVote(decoded.content, decoded.author_id)
			end
		end
	end)
end

----------------------------------------------------------------------------------------------

function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
	coroutine.resume(eventStreamCoroutine)
	voting_system:update()
end

----------------------------------------------------------------------------------------------

function GetJsonPayload(data)
	--[[
		Takes in a data payload from the EventStream, returns json decoded data
		if present in the payload. If no data present, returns nil.
	]]
	local found_start = false
	local start_index = 0
	local end_index = 0

	if type(data) ~= "string" then
		return nil
	end

	local index = 1
	for c in data:gmatch(".") do
		if c == "{" and not found_start then
			start_index = index
			found_start = true
		end

		if c == "}" then
			end_index = index
		end

		index = index + 1
	end

	if start_index == 0 or end_index == 0 then
		return nil
	end

	local payload = string.sub(data, start_index, end_index)
	return json.decode(payload)
end

----------------------------------------------------------------------------------------------

function ProcessVote(content, author)
	--[[
		Takes in a user message and submits it as a vote if necessary
	]]
	local number_content = tonumber(content)
	if number_content and number_content > 0 and number_content < 5 then
		voting_system:receive_message(number_content, author)
	end
end

----------------------------------------------------------------------------------------------

function OnModPreInit()
	print("Hooj - OnModPreInit()") -- First this is called for all mods
end

----------------------------------------------------------------------------------------------

function OnWorldInitialized() -- This is called once the game world is initialized. Doesn't ensure any world chunks actually exist. Use OnPlayerSpawned to ensure the chunks around player have been loaded or created.
	voting_system:clear()
end

----------------------------------------------------------------------------------------------

--[[

function OnModPostInit()
	StreamingSetVotingEnabled(true)
end

function OnPlayerSpawned( player_entity ) -- This runs when player entity has been created
	GamePrint( "OnPlayerSpawned() - Player entity id: " .. tostring(player_entity) )
end


function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
	GamePrint( "Pre-update hook " .. tostring(GameGetFrameNum()) )
end

function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
	local x = ProceduralRandom(0,0)
	print( "===================================== random " .. tostring(x) )
end
]]
--
