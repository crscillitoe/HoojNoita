dofile_once("data/scripts/streaming_integration/event_list.lua")

-- How much time between votes
local VOTING_DELAY_FRAMES = 60 * 10 * 10

-- How much time viewers have to vote
local VOTING_TIME = 60 * 10 * 5

-- Delay after vote has finished before event fires off.
local TIME_TO_RUN = 60 * 5

---@class voting_system
local voting_system = {}

voting_system.gui = GuiCreate()

---@param vote_for integer
---@param vote_by any
function voting_system:receive_message(vote_for, vote_by)
	if self.time_until_vote ~= 0 then
		return
	end
	local prev = self.already_cast_vote[vote_by]
	if prev then
		self.vote_counts[prev] = self.vote_counts[prev] - 1
	end -- change vote
	self.already_cast_vote[vote_by] = vote_for
	self.vote_counts[vote_for] = self.vote_counts[vote_for] + 1
end

function voting_system:clear()
	self.time_until_event = VOTING_TIME
	self.time_until_vote = VOTING_DELAY_FRAMES
	self.time_until_execution = TIME_TO_RUN
	self.vote_counts = { 0, 0, 0, 0 }
	self.cur_events = {}
	self.already_cast_vote = {}
	for _ = 1, 4 do
		local id, ui_name, ui_description, ui_icon = _streaming_get_event_for_vote()
		table.insert(
			self.cur_events,
			{ id = id, ui_name = ui_name, ui_description = ui_description, ui_icon = ui_icon }
		)
	end
end

function voting_system:clear_buffer()
	local content = GlobalsGetValue("HOOJ_STREAM_BUFFER", "") or ""

	if content:len() < 2 then
		return
	end

	---@cast content string
	content = content:sub(2)
	for part in content:gmatch("[^,]+") do
		local message = {}
		for message_part in part:gmatch("[^;]+") do
			table.insert(message, message_part)
		end
		local by = message[1]
		local vote_for = tonumber(message[2] or "no")
		if by and vote_for then
			self:receive_message(vote_for, by)
		end
	end

	GlobalsSetValue("HOOJ_STREAM_BUFFER", "")
end

function voting_system:new_id()
	self.gui_id = self.gui_id + 1
	return self.gui_id
end

function voting_system:render_wait()
	GuiStartFrame(self.gui)
	GuiZSet(self.gui, -10000)
	local sw, sh = GuiGetScreenDimensions(self.gui)
	local rx, ry = sw - 172, sh - 50

	local window_width = 150
	local window_height = 20

	GuiImageNinePiece(self.gui, self:new_id(), rx, ry, window_width, window_height)
	GuiZSet(self.gui, -10001)
	GuiText(self.gui, 35 + rx, ry + 5, "Time Until Vote: " .. self.time_until_vote)
end

function voting_system:render()
	GuiStartFrame(self.gui)
	GuiZSet(self.gui, -10000)
	local sw, sh = GuiGetScreenDimensions(self.gui)
	local rx, ry = sw - 172, sh - 110

	local window_width = 150
	local window_height = 80

	GuiImageNinePiece(self.gui, self:new_id(), rx, ry, window_width, window_height)
	GuiZSet(self.gui, -10001)
	GuiText(self.gui, 15 + rx, ry, "Vote at discord.gg/woohoojin")
	GuiText(self.gui, 35 + rx, ry + 10, "Time Left: " .. self.time_until_event)
	GuiText(self.gui, 15 + rx, ry + 20, "--------------------")


	for event_num, event in ipairs(self.cur_events) do
		local y = (event_num + 2) * 10
		local translated = GameTextGetTranslatedOrNot(event.ui_name)
		GuiText(self.gui, 5 + rx, ry + y, tostring(event_num) .. ") ".. translated)
		local w = GuiGetTextDimensions(self.gui, tostring(self.vote_counts[event_num]))
		GuiText(self.gui, rx + window_width - (w), ry + y, tostring(self.vote_counts[event_num]))
	end

end

function voting_system:run_event()
	local winner = self.cur_events[1]
	do
		local winner_votes = 0
		for event_num, event_votes in ipairs(self.vote_counts) do
			if event_votes > winner_votes then
				winner_votes = event_votes
				winner = self.cur_events[event_num]
			end
		end
	end

	GamePrintImportant(winner.ui_name, winner.ui_description)
	self.to_run = winner.id
end

function voting_system:update()
	self:clear_buffer()
	self.gui_id = 2

	if self.time_until_vote == nil then
		return
	end

	if self.time_until_vote ~= 0 then
		self:render_wait()
		self.time_until_vote = self.time_until_vote - 1
		if self.time_until_event == 0 then
			_streaming_on_vote_start()
		end
		return
	end

	if self.time_until_event ~= 0 then
		self:render()
		self.time_until_event = self.time_until_event - 1
		if self.time_until_event == 0 then
			self:run_event()
		end
		return
	end

	if self.time_until_execution ~= 0 then
		self.has_run_event = true
		self.time_until_execution = self.time_until_execution - 1
		return
	end

	_streaming_run_event(self.to_run, "secret_handshake")
	self:clear()
end

return voting_system
