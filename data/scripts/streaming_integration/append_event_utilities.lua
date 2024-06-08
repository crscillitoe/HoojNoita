local old_streaming_on_irc = _streaming_on_irc
function _streaming_on_irc(is_userstate, sender_username, message, raw)
	--[[
		This may look like we are just calling the old function,
			and that's because we are!

		I'm just redefining it explicitly so we can call it from
			our Discord EventStream processor aswell.

        DOESN'T WORK SADGE
	]]
	if(old_streaming_on_irc ~= nil) then
		old_streaming_on_irc(is_userstate, sender_username, message, raw)
	end
end