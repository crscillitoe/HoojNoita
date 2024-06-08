local vote_map = {}
for i = 1, 4 do
	vote_map[tostring(i)] = i
end

function _streaming_on_irc(_, sender_username, message)
	---@cast sender_username string
	if sender_username:find(",") or sender_username:find(";") then
		return
	end -- these will corrupt the buffer for passing things between lua contexts.
	if not vote_map[message] then
		return
	end -- not a vote
	GlobalsSetValue(
		"HOOJ_STREAM_BUFFER",
		(GlobalsGetValue("HOOJ_STREAM_BUFFER", "") or "") .. "," .. sender_username .. ";" .. vote_map[message]
	)
end

local old_run = _streaming_run_event
function _streaming_run_event(arg, secret_handshake)
	if secret_handshake == "secret_handshake" then
		old_run(arg)
	end
end
