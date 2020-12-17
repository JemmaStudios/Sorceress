--[[
    sorceress_control.lua

]]

-- constants/properties
rad2deg = 57.2958
isOn = 1        -- um... I mean, what's to explain?
isOff = 0       -- see isOn
isOpen = 1      -- you're getting the idea by now.
isClosed = 0
ignitionOn = 3
not_moving = 0
moving_up = 1
moving_down = -1
canopy_bolt_moving = not_moving --0:not moving, 1: moving up, -1: moving_down
canopy_moving = not_moving
canopy_bolt_stopped = false
hours = {0, 0, 0, 0, 0}
old_hours = {0, 0, 0, 0, 0}
hours_moving = {not_moving, not_moving, not_moving, not_moving, not_moving}
switch_moving = {not_moving, not_moving, not_moving, not_moving}

defineProperty("canopy_bolt_time", 0.50)    -- amount of time in seconds to fully move the canopy bolt lever
defineProperty("canopy_open_time", 1.5) -- how long does it take for the canopy to slide.
defineProperty("canopy_bolt_stop", 0.114) -- how far closed is the canopy if the bolt lever is up
defineProperty("engine_rpm_hour", 2500) -- engine rpm that defines an "hour" run.
defineProperty("engine_hours", 0.0) -- initial engine hours
defineProperty("tach_tape_rollout", 0.3) -- number of seconds for each tach digit to roll when the number changes.
defineProperty("switch_time", 0.15)  -- amount of time in seconds for switches to move.

function canopy_bolt_toggle_handler(phase)
    if phase == SASL_COMMAND_BEGIN then
        if canopy_bolt_moving == moving_up or get(canopy_bolt_rat) == 1  then
            canopy_bolt_moving = moving_down
        else
            canopy_bolt_moving = moving_up
        end
    end
    return 0
end


function canopy_toggle_handler(phase)
    if phase == SASL_COMMAND_BEGIN then
        if canopy_moving == not_moving and canopy_bolt_stopped and get(canopy_bolt_rat) == 0 then
            canopy_moving = moving_down
            canopy_bolt_stopped = false
            return 0
        end
        if canopy_moving == moving_up or get(canopy_open_rat) == 1  then
            canopy_moving = moving_down
        elseif (get(canopy_bolt_rat) == 0) or (get(canopy_bolt_rat) == 1 and canopy_bolt_stopped)  then
            canopy_moving = moving_up
            set (xp_open_canopy, 1)
            canopy_bolt_stopped = false
        end
    end
    return 0
end


function magneto_1_toggle_handler (phase)
    local t = 0
    if phase == SASL_COMMAND_BEGIN then
        if switch_moving[2] == moving_up or get(switch, 2) == isOn then
            switch_moving[2] = moving_down
        else
            switch_moving[2] = moving_up
            t = 1
        end
        set(xp_ignition_on, t + math.ceil(get(switch, 3)*2))
    end
    return 0
end

function magneto_2_toggle_handler (phase)
    local t = 0
    if phase == SASL_COMMAND_BEGIN then
        if switch_moving[3] == moving_up or get(switch, 3) == isOn then
            switch_moving[3] = moving_down
        else
            switch_moving[3] = moving_up
            t = 1
        end
        set(xp_ignition_on, math.ceil(get(switch, 2)) + t*2)
    end
    return 0
end

function battery_toggle_handler(phase)
    if phase == SASL_COMMAND_BEGIN then
        if switch_moving[1] == moving_up or get(switch, 1) == isOn then
            switch_moving[1] = moving_down
        else
            switch_moving[1] = moving_up
        end
    end
    return 1
end    

function starter_toggle_handler(phase)
    if phase < SASL_COMMAND_END then
        switch_moving[4] = moving_up
    else
        switch_moving[4] = moving_down
    end
    return 1
end    

-- look up our datarefs
xp_mix = globalPropertyfae("sim/cockpit2/engine/actuators/mixture_ratio", 1)
yoke_roll = globalPropertyf("sim/cockpit2/controls/yoke_roll_ratio")
yoke_hdg = globalPropertyf("sim/cockpit2/controls/yoke_heading_ratio")
yoke_pitch = globalPropertyf("sim/cockpit2/controls/yoke_pitch_ratio")
ground_speed = globalPropertyf("sim/flightmodel2/position/groundspeed")
parking_brake = globalPropertyf("sim/cockpit2/controls/parking_brake_ratio")
xp_vulkan = globalPropertyf ("sim/graphics/view/using_modern_driver")
xp_rudder = globalPropertyf ("sim/flightmodel/controls/ldruddef")
running = globalPropertyi("sim/operation/prefs/startup_running")         -- 0: cold and dark, 1: engines_running
fuel_valve = globalPropertyi("sim/cockpit2/fuel/fuel_tank_selector")       -- 0: none, 1: left, 2: center, 3: right, 4: all
fuel_supply = globalPropertyiae("sim/cockpit2/fuel/fuel_tank_pump_on", 1)    -- 0: off, 1: on
xp_battery = globalPropertyiae("sim/cockpit2/electrical/battery_on", 1)  -- 0: off, 1: on
xp_open_canopy = globalPropertyi("sim/cockpit2/switches/canopy_open")         -- 0: closed, 1: open
xp_open_can_rat = globalPropertyf("sim/flightmodel2/misc/canopy_open_ratio")  -- 0: closed, 1: open
xp_engine_running = globalPropertyiae("sim/flightmodel/engine/ENGN_running", 1)
xp_engine_rpm = globalPropertyfae("sim/cockpit2/engine/indicators/engine_speed_rpm", 1)
xp_prop_speed_rad = globalPropertyfae("sim/flightmodel2/engines/prop_rotation_speed_rad_sec", 1)
xp_prop_rot_angle = globalPropertyfae ("sim/flightmodel2/engines/prop_rotation_angle_deg", 1)
xp_prop_override = globalPropertyiae("sim/flightmodel2/engines/prop_disc/override", 1)
xp_prop_is_disc = globalPropertyiae("sim/flightmodel2/engines/prop_is_disc", 1)
xp_radio = {}
xp_radio[1] = globalPropertyi("sim/cockpit2/radios/actuators/com1_power")
xp_radio[2] = globalPropertyi("sim/cockpit2/radios/actuators/com2_power")
xp_radio[3] = globalPropertyi("sim/cockpit2/radios/actuators/nav1_power")
xp_radio[4] = globalPropertyi("sim/cockpit2/radios/actuators/nav2_power")
xp_livery = globalPropertys ("sim/aircraft/view/acf_livery_path")
xp_ignition_on = globalPropertyiae ("sim/cockpit2/engine/actuators/ignition_on", 1)


coil_rat = createGlobalPropertyfa ("sorceress/gear/spring_coil_rat", {0.0, 0.0})
coil_psi = createGlobalPropertyfa ("sorceress/gear/spring_coil_psi", {0.0, 0.0})
anchor_psi = createGlobalPropertyfa ("sorceress/gear/spring_anchor_psi", {0.0, 0.0})
canopy_bolt_rat = createGlobalPropertyf ("sorceress/cockpit/canopy_bolt_rat")
canopy_open_rat = createGlobalPropertyf ("sorceress/cockpit/canopy_open_rat")
tach_tape = createGlobalPropertyfa ("sorceress/cockpit/tach_tape", {0.0, 0.0, 0.0, 0.0, 0.0})
tach_hours = createGlobalPropertyf ("sorceress/engine/tach_hours")
switch = createGlobalPropertyfa ("sorceress/engine/switch", {0.0, 0.0, 0.0, 0.0})

sorceress_canopy_lever_cmd = sasl.createCommand("sorceress/cockpit/canopy_bolt_toggle", "Toggles Canopy bolt lever")
sasl.registerCommandHandler( sorceress_canopy_lever_cmd, 0, canopy_bolt_toggle_handler)
sorceress_canopy_cmd = sasl.createCommand("sorceress/cockpit/canopy_toggle", "Toggles Canopy")
sasl.registerCommandHandler( sorceress_canopy_cmd, 0, canopy_toggle_handler)
sorceress_magneto_1_toggle = sasl.createCommand("sorceress/engine/magneto_1_toggle", "Toggle magneto 1 power")
sasl.registerCommandHandler( sorceress_magneto_1_toggle, 0, magneto_1_toggle_handler)
sorceress_magneto_2_toggle = sasl.createCommand("sorceress/engine/magneto_2_toggle", "Toggle magneto 2 power")
sasl.registerCommandHandler( sorceress_magneto_2_toggle, 0, magneto_2_toggle_handler)

xp_canopy_open_cmd = sasl.findCommand ("sim/flight_controls/canopy_open")
xp_canopy_close_cmd = sasl.findCommand ("sim/flight_controls/canopy_close")
xp_battery_toggle_cmd = sasl.findCommand ("sim/electrical/battery_1_toggle")
sasl.registerCommandHandler( xp_battery_toggle_cmd, 0, battery_toggle_handler)
xp_engage_starter_cmd = sasl.findCommand ("sim/starters/engage_starter_1")
sasl.registerCommandHandler( xp_engage_starter_cmd, 0, starter_toggle_handler)

debug_lib.on_debug("The livery selected is: "..get(xp_livery))

function move_switch (i)
    local move_step = 1 / get (switch_time) * timer_lib.SIM_PERIOD
    set(switch, get(switch, i) + (switch_moving[i] * move_step), i)
    if get(switch, i) >= isOn then
        set(switch, isOn, i)
        switch_moving[i] = not_moving
    elseif get(switch, i) <= isOff then
        set(switch, isOff, i)
        switch_moving[i] = not_moving
    end
end


function move_hours (i)
    local move_step = 1 / get (tach_tape_rollout) * timer_lib.SIM_PERIOD
    old_hours[i] = old_hours[i] + move_step
    local t = hours[i]
    if t == 0 then t = 10 end
    if old_hours[i] >= t then
        old_hours[i] = hours[i]
        hours_moving[i] = not_moving
    end
    set (tach_tape, old_hours[i], i)
end

function move_canopy_bolt()
    local move_step = 1 / get (canopy_bolt_time) * timer_lib.SIM_PERIOD
    set(canopy_bolt_rat, get(canopy_bolt_rat) + (canopy_bolt_moving * move_step))
    if get(canopy_bolt_rat) >= isOn then
        set(canopy_bolt_rat, isOn)
        canopy_bolt_moving = not_moving
    elseif get(canopy_bolt_rat) <= isOff then
        set(canopy_bolt_rat, isOff)
        canopy_bolt_moving = not_moving
    end
end

function move_canopy()
    local move_step = 1 / get (canopy_open_time) * timer_lib.SIM_PERIOD
    set(canopy_open_rat, get(canopy_open_rat) + (canopy_moving * move_step))
    set(xp_open_can_rat, get(canopy_open_rat))
    if canopy_moving == moving_down and get(canopy_bolt_rat) == 1 and get(canopy_open_rat) <= get(canopy_bolt_stop) then
        set(canopy_open_rat, get(canopy_bolt_stop))
        canopy_bolt_stopped = true
        canopy_moving = not_moving
    end
    if get(canopy_open_rat) >= isOpen then
        set(canopy_open_rat, isOpen)
        canopy_moving = not_moving
    elseif get(canopy_open_rat) <= isClosed then
        set(canopy_open_rat, isClosed)
        set(xp_open_canopy, isClosed)
        canopy_moving = not_moving
    end
end

function rotate_prop ()
    local rot_step = get(xp_prop_speed_rad) * rad2deg * timer_lib.SIM_PERIOD
    set(xp_prop_rot_angle, get(xp_prop_rot_angle)+rot_step)
end

function set_tach_hours()
    hours[0] = get(engine_hours)
    set(tach_hours, hours[0])
    hours[1] = (hours[0]/0.1) % 10
    hours[2] = math.floor((hours[0]/1) % 10)
    hours[3] = math.floor((hours[0]/10) % 10)
    hours[4] = math.floor((hours[0]/100) % 10)
    hours[5] = math.floor((hours[0] / 1000) % 10)
    for i = 2, 5 do
        if hours[i] ~= old_hours[i] then
            hours_moving[i] = moving_up
        end
    end  
    set (tach_tape, hours[1], 1)
end

function update_engine_hours ()
    local hourly_rate = get(xp_engine_rpm) / get(engine_rpm_hour)
    local second_rate = hourly_rate / 3600
    local hour_step = second_rate * timer_lib.SIM_PERIOD
    set (engine_hours, get (engine_hours) + hour_step)
    set_tach_hours()
end

function do_first_time ()
    -- do startup stuff
    first_time = false
    set (coil_rat, 0.5, 1)
    set (xp_prop_override, 1)
    set (xp_prop_is_disc, 0)
    set (xp_open_canopy, 1)
    set (xp_open_can_rat, 1)
    set (canopy_open_rat, 1)
    set (xp_ignition_on, 0)
    set (xp_battery, 0)
    set_tach_hours()
end

-- on reload and/or startup

first_time = true

function update ()
    if first_time == true then
        do_first_time()
    end
    rotate_prop()
    set (coil_psi, get(xp_rudder), 1)
    set (anchor_psi, get(xp_rudder)*2, 1)
    if canopy_bolt_moving ~= not_moving then
        move_canopy_bolt()
    end
    if canopy_moving ~= not_moving then
        move_canopy()
    end
    for i=2, 5 do
        if hours_moving[i] ~= not_moving then
            move_hours(i)
        end
    end
    for i = 1, 4 do
        if switch_moving[i] ~= not_moving then
            move_switch(i)
        end
    end
    if get(xp_engine_running) == 1 then
        update_engine_hours()
    end
    updateAll (components)
end

function onModuleShutdown()
    config["Initial_engine_hours"] = get(engine_hours)
end
