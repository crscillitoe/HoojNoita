dofile_once( "data/scripts/lib/utilities.lua" )

local pollnet = require('mods\\hoojMod\\pollnet')
local json = require('mods\\hoojMod\\json')


-- Reactor is a convenience for running Lua coroutines
local reactor = pollnet.Reactor()

function OnModPreInit()
	print("Hooj - OnModPreInit()") -- First this is called for all mods
end

function OnModInit()
	print("Hooj - OnModInit()") -- After that this is called for all mods


	-- Connect to hooj eventstream
	-- https://overlay.woohooj.in/stream/?channel=events
	reactor:run(function()

		-- Dark wizard arts.
		-- Trick  pollnet into thinking this is a tcp socket, but then just manually send
		-- an HTTP GET and listen to the eventstream instead
		-- IMPORTANT, HTTP messages must end with two newlines.
		local req_sock = pollnet.open_tcp("69.55.54.58:80")
		req_sock:send("GET /stream/?channel=simple-chat HTTP/1.1\r\nHost: overlay.woohooj.in\r\nUser-Agent: curl/7.85.0\r\nAccept: */*\r\n\r\n")

		while true do
			local response = req_sock:await()
			if type(response) ~= "string" then
				goto continue
			end

			local found_start = false
			local start_index = 0
			local end_index = 0

			local index = 1
			for c in response:gmatch"." do
				if (c == "{" and not found_start) then
					start_index = index
					found_start = true
				end

				if (c == "}") then
					end_index = index
				end

				index = index + 1
			end

			if start_index == 0 or end_index == 0 then
				goto continue
			end

			local payload = string.sub(response, start_index, end_index)
			local decoded = json.decode(payload)

			local content = decoded.content
			local author = decoded.author_id

			-- TODO: Parse message for 1/2/3/4 and send to vote
			print(content)

			::continue::
		end
	end)
end


function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
	-- Reactor.update() enables us to
	-- essentially run C coroutines for our eventstream
	reactor:update()
end

--[[

function OnModPostInit()
	StreamingSetVotingEnabled(true)
end

function OnPlayerSpawned( player_entity ) -- This runs when player entity has been created
	GamePrint( "OnPlayerSpawned() - Player entity id: " .. tostring(player_entity) )
end

function OnWorldInitialized() -- This is called once the game world is initialized. Doesn't ensure any world chunks actually exist. Use OnPlayerSpawned to ensure the chunks around player have been loaded or created.
	GamePrint( "OnWorldInitialized() " .. tostring(GameGetFrameNum()) )
end

function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
	GamePrint( "Pre-update hook " .. tostring(GameGetFrameNum()) )
end

function OnMagicNumbersAndWorldSeedInitialized() -- this is the last point where the Mod* API is available. after this materials.xml will be loaded.
	local x = ProceduralRandom(0,0)
	print( "===================================== random " .. tostring(x) )
end
]]--
