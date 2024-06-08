local VOTING_DELAY_FRAMES = 60 * 60
local VOTING_TIME = 60 * 10
dofile_once("data/scripts/streaming_integration/event_utilities.lua")

local votes = {}
votes.gui = GuiCreate()

---@param vote_for integer
---@param vote_by integer
function votes:receive_message(vote_for, vote_by)
	if self.time_until_vote ~= 0 then
		return
	end
	if self.already_cast_vote[vote_by] then
		return
	end -- no spamming votes >:(
	self.already_cast_vote[vote_by] = true
	votes.vote_counts[vote_for] = votes.vote_counts[vote_for] + 1
end

function votes:clear()
	self.time_until_event = VOTING_TIME
	self.time_until_vot = VOTING_DELAY_FRAMES
	self.vote_counts = { 0, 0, 0, 0 }
	self.cur_events = {}
	for _ = 1, 4 do
		---@diagnostic disable-next-line: undefined-global
		local id, ui_name, ui_description, ui_icon = _streaming_get_event_for_vote()
		table.insert(
			self.cur_events,
			{ id = id, ui_name = ui_name, ui_description = ui_description, ui_icon = ui_icon }
		)
	end
	self.already_cast_vote = {}
end

function votes:clear_buffer()
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

function votes:new_id()
	self.gui_id = self.gui_id + 1
	return self.gui_id
end

function votes:render()
	GuiStartFrame(self.gui)
	GuiZSet(self.gui, -10000)
	GuiImageNinePiece(self.gui, self:new_id(), 0, 0, 100, 100)
	GuiZSet(self.gui, -10001)
	for event_num, event in ipairs(self.cur_events) do
		GuiText(gui,self:new_id()
	end
end

function votes:run_event()
	local winner
	do
		local winner_votes = 0
		for event_num, event_votes in ipairs(votes.vote_counts) do
			if event_votes > winner_votes then
				winner_votes = event_votes
				winner = event_num
			end
		end
	end
	GamePrintImportant(winner.ui_name, winner.ui_description)
	winner.action(winner)
end

votes:clear()
function votes:update()
	if self.time_until_vote ~= 0 then
		self.time_until_vote = self.time_until_vote - 1
		return
	end
	if self.time_until_event ~= 0 then
		self.time_until_event = self.time_until_event - 1
		return
	end
	votes:run_event()
	votes:clear()
end
