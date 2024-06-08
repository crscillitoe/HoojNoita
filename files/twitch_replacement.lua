function _streaming_on_irc(_, sender_username, message)
	GlobalsSetValue(
		"HOOJ_STREAM_BUFFER",
		"," .. (GlobalsGetValue("HOOJ_STREAM_BUFFER", "") or "") .. sender_username .. ";" .. message
	)
end

local old_run = _streaming_run_event
function _streaming_run_event(arg, secret_handshake)
	if secret_handshake == "secret_handshake" then
		old_run(arg)
	end
end
