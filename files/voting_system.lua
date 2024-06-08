dofile_once("data/scripts/streaming_integration/event_list.lua")

local VOTING_DELAY_FRAMES = 60 * 10
local VOTING_TIME = 60 * 10

---@class voting_system
local voting_system = {}

voting_system.gui = GuiCreate()

---@param vote_for integer
---@param vote_by integer
function voting_system:receive_message(vote_for, vote_by)
	if self.time_until_vote ~= 0 then
		return
	end
	if self.already_cast_vote[vote_by] then
		local prev = self.already_cast_vote[vote_by]
		self.vote_counts[prev] = self.vote_counts[prev] - 1
	end -- change vote
	self.already_cast_vote[vote_by] = vote_for
	self.vote_counts[vote_for] = self.vote_counts[vote_for] + 1
end

function voting_system:clear()
	self.time_until_event = VOTING_TIME
	self.time_until_vote = VOTING_DELAY_FRAMES
	self.vote_counts = { 0, 0, 0, 0 }
	self.cur_events = {}
	for _ = 1, 4 do
		local id, ui_name, ui_description, ui_icon = _streaming_get_event_for_vote()
		table.insert(
			self.cur_events,
			{ id = id, ui_name = ui_name, ui_description = ui_description, ui_icon = ui_icon }
		)
	end
	self.already_cast_vote = {}
end

function voting_system:clear_buffer()
	local content = GlobalsGetValue("HOOJ_STREAM_BUFFER", "")
	---@cast content string
	content = content:sub(2)
	for part in content:gmatch("[^,]+") do
		local message = {}
		for message_part in part:gmatch("[^;]+") do
			table.insert(message, message_part)
		end
		self:receive_message(message[1], message[2])
	end
end

function voting_system:new_id()
	self.gui_id = self.gui_id + 1
	return self.gui_id
end

function voting_system:render()
	GuiStartFrame(self.gui)
	GuiZSet(self.gui, -10000)
	local rx, ry = 100, 100
	GuiImageNinePiece(self.gui, self:new_id(), rx, ry, 250, 250)
	GuiZSet(self.gui, -10001)
	for event_num, event in ipairs(self.cur_events) do
		local y = event_num * 10
		local translated = GameTextGetTranslatedOrNot(event.ui_name)
		GuiText(self.gui, rx, ry + y, translated)
		local w = GuiGetTextDimensions(self.gui, translated)
		GuiText(self.gui, 25 + rx + w, ry + y, tostring(self.vote_counts[event_num]))
	end
end

function voting_system:run_event()
	local winner
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
	for _, event in ipairs(streaming_events) do
		if event.id == winner.id then
			event.action(event)
		end
	end
end

voting_system:clear()
function voting_system:update()
	self.gui_id = 2
	self:render()
	if self.time_until_vote ~= 0 then
		self.time_until_vote = self.time_until_vote - 1
		return
	end
	if self.time_until_event ~= 0 then
		self.time_until_event = self.time_until_event - 1
		return
	end
	self:run_event()
	self:clear()
end

return voting_system
