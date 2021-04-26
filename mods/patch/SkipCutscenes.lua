local mod_name = "SkipCutscenes"

local user_setting = Application.user_setting
local set_user_setting = Application.set_user_setting

local MOD_SETTINGS = {
	ACTIVE = {
		["save"] = "cb_skip_level_cutscenes",
		["widget_type"] = "stepper",
		["text"] = "Skip Level Cutscenes",
		["tooltip"] =  "Skip Level Cutscenes\n" ..
			"Toggle skip level cutscenes on / off.\n\n" ..
			"Lets you skip the cutscenes at the beginning of a map by pressing [Space].",
		["value_type"] = "boolean",
		["options"] = {
			{text = "Off", value = false},
			{text = "On", value = true},
		},
		["default"] = 1, -- Default first option is enabled. In this case Off
	},
}

-- Variable to track the need to skip the fade effect
local skip_next_fade = false

-- Enable skippable cutscene development setting
script_data.skippable_cutscenes = true

--[[
	HOOKS
--]]
-- Set up skip for fade effect
Mods.hook.set(mod_name, "CutsceneSystem.skip_pressed", function(func, self)
	skip_next_fade = true
    if user_setting(MOD_SETTINGS.ACTIVE.save) then
        func(self)
    end
end)

-- Skip fade when applicable
Mods.hook.set(mod_name, "CutsceneSystem.flow_cb_cutscene_effect", function(func, self, name, flow_params)
	if name == "fx_fade" and skip_next_fade then
		skip_next_fade = false
	else
        func(self, name, flow_params)
	end
end)

-- Don't restore player input if player already has active input
Mods.hook.set(mod_name, "CutsceneSystem.flow_cb_deactivate_cutscene_logic", function(func, self, event_on_deactivate)
	-- If a popup is open or cursor present, skip the input restore
	if ShowCursorStack.stack_depth > 0 or Managers.popup:has_popup() then
		if event_on_deactivate then
			local level = LevelHelper:current_level(self.world)
			Level.trigger_event(level, event_on_deactivate)
		end

		self.event_on_skip = nil
	else
        func(self, event_on_deactivate)
	end
end)

-- Prevent invalid cursor pop crash if another mod interferes
Mods.hook.set(mod_name, "ShowCursorStack.pop", function(func)
	-- Catch a starting depth of 0 or negative cursors before pop
	if ShowCursorStack.stack_depth <= 0 then
		EchoConsole("[Warning]: Attempt to remove non-existent cursor.")
	else
        func()
	end
end)

--[[
	Add options for this module to the Options UI.
--]]
local function create_options()
	Mods.option_menu:add_group("cut_group", "Cutscenes")
	Mods.option_menu:add_item("cut_group", MOD_SETTINGS.ACTIVE, true)
end

local status, err = pcall(create_options)
if err ~= nil then
	EchoConsole(err)
end