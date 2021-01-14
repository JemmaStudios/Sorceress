--[[
    sorceress_control.lua

]]

-- constants/properties
local rad2deg = 57.2958
local isOn = 1        -- um... I mean, what's to explain?
local isOff = 0       -- see isOn
local isOpen = 1      -- you're getting the idea by now.
local isClosed = 0
local ignitionOn = 3
local not_moving = 0
local moving_up = 1
local moving_down = -1
local canopy_bolt_moving = not_moving --0:not moving, 1: moving up, -1: moving_down
local canopy_moving = not_moving
local canopy_bolt_stopped = false
local hours = {0, 0, 0, 0, 0}
local old_hours = {0, 0, 0, 0, 0}
local hours_moving = {not_moving, not_moving, not_moving, not_moving, not_moving}
local switch_moving = {not_moving, not_moving, not_moving, not_moving}
local throttle_locked = false
local old_xp_throttle_ratio = 0
local old_xp_throttle_used_ratio = 0
local old_throttle_lock_ratio = 0
local old_xp_fuel_valve = 0
local old_fuel_lever = 0
local fuel_lever_lock_moving = not_moving
local fuel_lever_moving = not_moving
local fuel_lever_moving_to = 0          -- since the lever can be moved more than one position at a time, we need to know the final position.
local com1_vol_moving = not_moving
local old_xp_com1_freq
local old_com1_freq
local com1_moving = {not_moving, not_moving, not_moving, not_moving, not_moving}
local com1_moving_to = {0, 0, 0, 0, 0}
local lohi_moving = not_moving
local old_com1_vol = 0
local old_com1_sq = 0

defineProperty("canopy_bolt_time", 0.50)    -- amount of time in seconds to fully move the canopy bolt lever
defineProperty("canopy_open_time", 1.5) -- how long does it take for the canopy to slide.
defineProperty("canopy_bolt_stop", 0.114) -- how far closed is the canopy if the bolt lever is up
defineProperty("engine_rpm_hour", 2500) -- engine rpm that defines an "hour" run.
defineProperty("engine_hours", 0.0) -- initial engine hours
defineProperty("tach_tape_rollout", 0.3) -- number of seconds for each tach digit to roll when the number changes.
defineProperty("switch_time", 0.15)  -- amount of time in seconds for switches to move.
defineProperty("throttle_lock_multiplier", 15) -- how snappy is the mixture lever with no friction
defineProperty("throttle_lock_multi_limit", 0.75) -- subtracted from the max multiplier to allow longer throw at near max friction
defineProperty("throttle_lock_slip", 0.75) -- the minimum ratio to prevent the throttle from moving at high rpm
defineProperty("throttle_slip_min_rpm", 2000) -- the minimum rpm where throttle slip can begin
defineProperty("throttle_slip_max_rpm", 2300) -- max rpm where throttle slip will happen
defineProperty("throttle_slip_min_chance", 0.1) -- chance of throttle slip at min rpm
defineProperty("throttle_slip_max_chance", 0.85) -- chance of throttle slip at max rpm
defineProperty("throttle_slip_min_step", 0.0005) -- amount of throttle slip at min rpm
defineProperty("throttle_slip_max_step", 0.001) -- amount of throttle slip at max rpm
defineProperty("fuel_lever_lock_time", 0.1) -- amount of time in seconds it takes for fuel lever lock to switch positions
defineProperty("fuel_lever_time", 0.2) -- amount of time in seconds it takes for fuel lever to switch positions
defineProperty("com1_vol_time", 0.4) -- amount of time in seconds it takes the volume knob to go from max to off
defineProperty("com1_dial_time", 0.15) -- amount of time in seconds it takes a com1 freq dial to change 1 digit
defineProperty("lohi_time",0.2) --amount of time in seconds for the lo-hi radio switch to change positions
defineProperty("com1_sq_start", 0.4) -- ratio when squelch starts effecting com volume (to be replaced by static)
defineProperty("com1_sq_end", 0.95) -- ratio when com volume is out and static is max.
defineProperty("com1_sq_bottom", 0.2) -- ratio that communication is under squelched. (starts to get quiet.  shutting off at squelch = 0)

sasl.al.setMasterGain ( 1000 )
radio_on_click = sasl.al.loadSample ("sounds/radio_click.wav")
sasl.al.setSampleGain ( radio_on_click , 200)
sasl.al.setSampleRelative ( radio_on_click , 0)
radio_static = sasl.al.loadSample ("sounds/static.wav")
sasl.al.setSampleGain ( radio_static , 1000)
sasl.al.setSampleRelative ( radio_static , 1)
radio_channel_static = sasl.al.loadSample ("sounds/channel_static.wav")
sasl.al.setSampleGain ( radio_channel_static , 1000)
sasl.al.setSampleRelative ( radio_channel_static , 1)
radio_fm_static = sasl.al.loadSample ("sounds/fm_static.wav")
sasl.al.setSampleGain ( radio_fm_static , 1000)
sasl.al.setSampleRelative ( radio_fm_static , 1)

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

function fuel_lever_lock_toggle_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        if fuel_lever_lock_moving == moving_up or get(fuel_lever_lock_rat) == 1 then
            fuel_lever_lock_moving = moving_down
        else
            fuel_lever_lock_moving = moving_up
        end
    end
    return 1
end

function xp_fuel_valve_off_command_handler(phase)
    if get(fuel_lever_lock_rat) == 1 then
        return 1
    else
        return 0
    end
end

function xp_com1_on_command_handler(phase)
    if phase == SASL_COMMAND_BEGIN then
        com1_vol_moving = moving_up
    end
    return 1
end

function xp_com1_off_command_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        com1_vol_moving = moving_down
    end
    return 1
end

function com1_dial_5_up_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f+10000 > 99999 then
            f = f-100000
        end
        set(com1_freq_hz, f + 10000)    
    end
end

function com1_dial_5_dn_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f-10000 < 0 then
            f = f+100000
        end
        set(com1_freq_hz, f - 10000)
    end
end

function com1_dial_4_up_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f+1000 > 99999 then
            f = f-100000
        end
        set(com1_freq_hz, f + 1000)    
    end
end

function com1_dial_4_dn_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f-1000 < 0 then
            f = f+100000
        end
        set(com1_freq_hz, f - 1000)
    end
end

function com1_dial_3_up_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f+100 > 99999 then
            f = f-100000
        end
        set(com1_freq_hz, f + 100)    
    end
end

function com1_dial_3_dn_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f-100 < 0 then
            f = f+100000
        end
        set(com1_freq_hz, f - 100)
    end
end

function com1_dial_2_up_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f+10 > 99999 then
            f = f-100000
        end
        set(com1_freq_hz, f + 10)    
    end
end

function com1_dial_2_dn_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f-10 < 0 then
            f = f + 100000
        end
        set(com1_freq_hz, f - 10)
    end
end

function com1_dial_1_up_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f + 1 > 99999 then
            f = -1
        end
        set(com1_freq_hz, f + 1)    
    end
end

function com1_dial_1_dn_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        local f = get(com1_freq_hz)
        if f-1 < 0 then
            f = 100000
        end
        set(com1_freq_hz, f - 1)
    end
end

function lohi_lo_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        lohi_moving = moving_down
    end
end

function lohi_hi_handler (phase)
    if phase == SASL_COMMAND_BEGIN then
        lohi_moving = moving_up
    end
end

-- look up our datarefs
xp_mix = globalPropertyfae("sim/cockpit2/engine/actuators/mixture_ratio", 1)
xp_throttle = globalPropertyfae("sim/cockpit2/engine/actuators/throttle_ratio", 1)
xp_throttle_override = globalPropertyi ("sim/operation/override/override_throttles")
xp_throttle_used = globalPropertyfae ("sim/flightmodel/engine/ENGN_thro_use", 1)
yoke_roll = globalPropertyf("sim/cockpit2/controls/yoke_roll_ratio")
yoke_hdg = globalPropertyf("sim/cockpit2/controls/yoke_heading_ratio")
yoke_pitch = globalPropertyf("sim/cockpit2/controls/yoke_pitch_ratio")
ground_speed = globalPropertyf("sim/flightmodel2/position/groundspeed")
parking_brake = globalPropertyf("sim/cockpit2/controls/parking_brake_ratio")
xp_vulkan = globalPropertyf ("sim/graphics/view/using_modern_driver")
xp_rudder = globalPropertyf ("sim/flightmodel/controls/ldruddef")
running = globalPropertyi("sim/operation/prefs/startup_running")         -- 0: cold and dark, 1: engines_running
xp_fuel_valve = globalPropertyi("sim/cockpit2/fuel/fuel_tank_selector")       -- 0: none, 1: left, 2: center, 3: right, 4: all
xp_fuel_pump = globalPropertyiae("sim/cockpit2/fuel/fuel_tank_pump_on", 1)    -- 0: off, 1: on
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
xp_cht = globalPropertyfae("sim/flightmodel2/engines/CHT_deg_C", 1)
xp_egt = globalPropertyfae("sim/cockpit2/engine/indicators/EGT_deg_C", 1)
xp_com1_vol = globalPropertyf ("sim/cockpit2/radios/actuators/audio_volume_com1")
xp_com1_pwr = globalPropertyi ("sim/cockpit2/radios/actuators/com1_power")
xp_com1_freq = globalPropertyi ("sim/cockpit2/radios/actuators/com1_frequency_hz")
xp_nav1_vol = globalPropertyf ("sim/cockpit2/radios/actuators/audio_volume_nav1")
xp_nav1_pwr = globalPropertyi ("sim/cockpit2/radios/actuators/nav1_power")
xp_nav1_freq = globalPropertyi ("sim/cockpit2/radios/actuators/nav1_frequency_hz")
xp_nav1_sel = globalPropertyi ("sim/cockpit2/radios/actuators/audio_selection_nav1")
xp_adf1_vol = globalPropertyf ("sim/cockpit2/radios/actuators/audio_volume_adf1")
xp_adf1_pwr = globalPropertyi ("sim/cockpit2/radios/actuators/adf2_power")
xp_adf1_freq = globalPropertyi ("sim/cockpit/radios/adf1_freq_hz")
xp_adf1_sel = globalPropertyi ("sim/cockpit2/radios/actuators/audio_selection_adf1")

coil_rat = createGlobalPropertyfa ("sorceress/gear/spring_coil_rat", {0.0, 0.0})
coil_psi = createGlobalPropertyfa ("sorceress/gear/spring_coil_psi", {0.0, 0.0})
anchor_psi = createGlobalPropertyfa ("sorceress/gear/spring_anchor_psi", {0.0, 0.0})
canopy_bolt_rat = createGlobalPropertyf ("sorceress/cockpit/canopy_bolt_rat")
canopy_open_rat = createGlobalPropertyf ("sorceress/cockpit/canopy_open_rat")
tach_tape = createGlobalPropertyfa ("sorceress/cockpit/tach_tape", {0.0, 0.0, 0.0, 0.0, 0.0})
tach_hours = createGlobalPropertyf ("sorceress/engine/tach_hours")
switch = createGlobalPropertyfa ("sorceress/engine/switch", {0.0, 0.0, 0.0, 0.0})
throttle_lock_rat = createGlobalPropertyf ("sorceress/cockpit/throttle_friction_lock_rat")
fuel_lever_lock_rat = createGlobalPropertyf ("sorceress/cockpit/fuel_knob_lock_rat")
fuel_lever_pos = createGlobalPropertyf ("sorceress/cockpit/fuel_lever_pos")
cht_deg = createGlobalPropertyfa ("sorceress/engine/cht_deg_f", {0.0, 0.0, 0.0, 0.0})
egt_deg = createGlobalPropertyfa ("sorceress/engine/egt_deg_f", {0.0, 0.0})
com1_sq = createGlobalPropertyf ("sorceress/cockpit/com1_squelch_rat")
com1_freq_dial = createGlobalPropertyfa ("sorceress/cockpit/com1_dial", {0.0, 0.0, 0.0, 0.0, 0.0})
com1_freq_hz = createGlobalPropertyi ("sorceress/radios/com1_freq_hz")
com1_vol = createGlobalPropertyf ("sorceress/radios/audio_volume_com1")
lohi_rat = createGlobalPropertyf ("sorceress/cockpit/radio_lo-hi_rat")

sorceress_canopy_lever_cmd = sasl.createCommand("sorceress/cockpit/canopy_bolt_toggle", "Toggles Canopy bolt lever")
sasl.registerCommandHandler( sorceress_canopy_lever_cmd, 0, canopy_bolt_toggle_handler)
sorceress_canopy_cmd = sasl.createCommand("sorceress/cockpit/canopy_toggle", "Toggles Canopy")
sasl.registerCommandHandler( sorceress_canopy_cmd, 0, canopy_toggle_handler)
sorceress_magneto_1_toggle = sasl.createCommand("sorceress/engine/magneto_1_toggle", "Toggle magneto 1 power")
sasl.registerCommandHandler( sorceress_magneto_1_toggle, 0, magneto_1_toggle_handler)
sorceress_magneto_2_toggle = sasl.createCommand("sorceress/engine/magneto_2_toggle", "Toggle magneto 2 power")
sasl.registerCommandHandler( sorceress_magneto_2_toggle, 0, magneto_2_toggle_handler)
sorceress_fuel_lever_lock_toggle = sasl.createCommand ("sorceress/engine/fuel_lever_lock_toggle", "Toggle fuel lever lock")
sasl.registerCommandHandler (sorceress_fuel_lever_lock_toggle, 0, fuel_lever_lock_toggle_handler)
sorceress_com1_5_up_cmd = sasl.createCommand ("sorceress/radios/actv_com1_5_coarse_up", "Roll up COM1 100 Mhz digit")
sasl.registerCommandHandler (sorceress_com1_5_up_cmd, 0, com1_dial_5_up_handler)
sorceress_com1_5_dn_cmd = sasl.createCommand ("sorceress/radios/actv_com1_5_coarse_dn", "Roll down COM1 100 Mhz digit")
sasl.registerCommandHandler (sorceress_com1_5_dn_cmd, 0, com1_dial_5_dn_handler)
sorceress_com1_4_up_cmd = sasl.createCommand ("sorceress/radios/actv_com1_4_coarse_up", "Roll up COM1 10 Mhz digit")
sasl.registerCommandHandler (sorceress_com1_4_up_cmd, 0, com1_dial_4_up_handler)
sorceress_com1_4_dn_cmd = sasl.createCommand ("sorceress/radios/actv_com1_4_coarse_dn", "Roll down COM1 10 Mhz digit")
sasl.registerCommandHandler (sorceress_com1_4_dn_cmd, 0, com1_dial_4_dn_handler)
sorceress_com1_3_up_cmd = sasl.createCommand ("sorceress/radios/actv_com1_3_coarse_up", "Roll up COM1 1 Mhz digit")
sasl.registerCommandHandler (sorceress_com1_3_up_cmd, 0, com1_dial_3_up_handler)
sorceress_com1_3_dn_cmd = sasl.createCommand ("sorceress/radios/actv_com1_3_coarse_dn", "Roll down COM1 1 Mhz digit")
sasl.registerCommandHandler (sorceress_com1_3_dn_cmd, 0, com1_dial_3_dn_handler)
sorceress_com1_2_up_cmd = sasl.createCommand ("sorceress/radios/actv_com1_2_coarse_up", "Roll up COM1 100 Khz digit")
sasl.registerCommandHandler (sorceress_com1_2_up_cmd, 0, com1_dial_2_up_handler)
sorceress_com1_2_dn_cmd = sasl.createCommand ("sorceress/radios/actv_com1_2_coarse_dn", "Roll down COM1 100 Khz digit")
sasl.registerCommandHandler (sorceress_com1_2_dn_cmd, 0, com1_dial_2_dn_handler)
sorceress_com1_1_up_cmd = sasl.createCommand ("sorceress/radios/actv_com1_1_coarse_up", "Roll up COM1 10 Khz digit")
sasl.registerCommandHandler (sorceress_com1_1_up_cmd, 0, com1_dial_1_up_handler)
sorceress_com1_1_dn_cmd = sasl.createCommand ("sorceress/radios/actv_com1_1_coarse_dn", "Roll down COM1 10 Khz digit")
sasl.registerCommandHandler (sorceress_com1_1_dn_cmd, 0, com1_dial_1_dn_handler)
sorceress_lohi_lo_cmd = sasl.createCommand ("sorceress/radios/lohi_lo", "Move Lo-Hi switch to Lo")
sasl.registerCommandHandler (sorceress_lohi_lo_cmd, 0, lohi_lo_handler)
sorceress_lohi_hi_cmd = sasl.createCommand ("sorceress/radios/lohi_hi", "Move Lo-Hi switch to Hi")
sasl.registerCommandHandler (sorceress_lohi_hi_cmd, 0, lohi_hi_handler)

xp_canopy_open_cmd = sasl.findCommand ("sim/flight_controls/canopy_open")
xp_canopy_close_cmd = sasl.findCommand ("sim/flight_controls/canopy_close")
xp_battery_toggle_cmd = sasl.findCommand ("sim/electrical/battery_1_toggle")
sasl.registerCommandHandler( xp_battery_toggle_cmd, 0, battery_toggle_handler)
xp_engage_starter_cmd = sasl.findCommand ("sim/starters/engage_starter_1")
sasl.registerCommandHandler( xp_engage_starter_cmd, 0, starter_toggle_handler)
xp_fuel_valve_off_cmd = sasl.findCommand ("sim/fuel/fuel_selector_none")
xp_left_fuel_valve_off_cmd = sasl.findCommand ("sim/fuel/left_fuel_selector_none")
sasl.registerCommandHandler(xp_fuel_valve_off_cmd, 1, xp_fuel_valve_off_command_handler )
sasl.registerCommandHandler(xp_left_fuel_valve_off_cmd, 1, xp_fuel_valve_off_command_handler )
xp_com1_on_cmd = sasl.findCommand ("sim/radios/power_com1_on")
sasl.registerCommandHandler(xp_com1_on_cmd, 0, xp_com1_on_command_handler)
xp_com1_off_cmd = sasl.findCommand ("sim/radios/power_com1_off")
sasl.registerCommandHandler (xp_com1_off_cmd, 1, xp_com1_off_command_handler)

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

function move_com1_dial (i)
    local move_step = 1 / get (com1_dial_time) * timer_lib.SIM_PERIOD
    set(com1_freq_dial, get(com1_freq_dial, i) + (com1_moving[i] * move_step), i)
    if com1_moving[i] == moving_up and get(com1_freq_dial, i) >= com1_moving_to[i] then
        if com1_moving_to[i] == 10 then
            com1_moving_to[i] = 0
        end
        set(com1_freq_dial, com1_moving_to[i], i)
        com1_moving[i] = not_moving
    elseif com1_moving[i] == moving_down and get(com1_freq_dial, i) <= com1_moving_to[i] then
        set(com1_freq_dial, com1_moving_to[i], i)
        com1_moving[i] = not_moving
    end
end

function move_fuel_lever_lock ()
    local move_step = 1 / get (fuel_lever_lock_time) * timer_lib.SIM_PERIOD
    set(fuel_lever_lock_rat, get(fuel_lever_lock_rat)+(fuel_lever_lock_moving * move_step))
    if get(fuel_lever_lock_rat) >= isOn then
        set(fuel_lever_lock_rat, isOn)
        fuel_lever_lock_moving = not_moving
    elseif get(fuel_lever_lock_rat) <= isOff then
        set(fuel_lever_lock_rat, isOff)
        fuel_lever_lock_moving = not_moving
    end
end

function move_fuel_lever ()
    local move_step = 1 / get (fuel_lever_time) * timer_lib.SIM_PERIOD
    set(fuel_lever_pos, get(fuel_lever_pos)+(fuel_lever_moving * move_step))
    if  (fuel_lever_moving == moving_up and get(fuel_lever_pos) >= fuel_lever_moving_to) or 
                    (fuel_lever_moving == moving_down and get(fuel_lever_pos) <= fuel_lever_moving_to) then
        if fuel_lever_moving_to == 4 then
            fuel_lever_moving_to = 0
            old_fuel_lever = 0            
        end
        if fuel_lever_moving_to == 0 then
            set(fuel_lever_lock_rat, 0)
        end
        set(fuel_lever_pos, fuel_lever_moving_to)
        fuel_lever_moving = not_moving
        if fuel_lever_moving_to == 4 then
            fuel_lever_moving_to = 0
            old_fuel_lever = 0            
        end
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

function move_com1_volume()
    local move_step = 1 / get (com1_vol_time) * timer_lib.SIM_PERIOD
    set(com1_vol, get(com1_vol) + (com1_vol_moving * move_step))
    if get(com1_vol) >= isOn then
        set(com1_vol, isOn)
        com1_vol_moving = not_moving
    elseif get(com1_vol) <= isOff then
        set(com1_vol, isOff)
        com1_vol_moving = not_moving
    end
end

function move_lohi()
    local move_step = 1 / get (lohi_time) * timer_lib.SIM_PERIOD
    set(lohi_rat, get(lohi_rat) + (lohi_moving * move_step))
    if get(lohi_rat) >= isOn then
        set(lohi_rat, isOn)
        lohi_moving = not_moving
    elseif get(lohi_rat) <= isOff then
        set(lohi_rat, isOff)
        lohi_moving = not_moving
    end
    check_com1_vol ()
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

function check_throttle_lock_rat ()
    if not throttle_locked then
        if get(throttle_lock_rat) == 1 then
            throttle_locked = true
            old_xp_throttle_used_ratio = get(xp_throttle_used)
            old_xp_throttle_ratio = get(xp_throttle)
        end
    else
        if get(throttle_lock_rat) < 1 then
            throttle_locked = false
        end
    end
end

function check_throttle()
    local t_throttle_u = get(xp_throttle_used)
    local t_throttle = get(xp_throttle)
    if old_xp_throttle_used_ratio ~= t_throttle_u then  
        set(xp_throttle, t_throttle_u)
        old_xp_throttle_ratio = t_throttle_u
        old_xp_throttle_used_ratio = t_throttle_u
    elseif old_xp_throttle_ratio ~= t_throttle then
        set(xp_throttle_used, t_throttle)
        old_xp_throttle_ratio = t_throttle
        old_xp_throttle_used_ratio = t_throttle
    end

end

function check_throttle_slip()
    local lock_ratio = 1-get(throttle_lock_rat) / get(throttle_lock_slip)
    -- we should get here unless the lock_ratio is > lock_slip but just in case...
    if lock_ratio > 0 then
        local rpm_range = get(throttle_slip_max_rpm) - get(throttle_slip_min_rpm)
        local rpm_ratio = (get(xp_engine_rpm)-get(throttle_slip_min_rpm))/rpm_range
        local chance_range = get(throttle_slip_max_chance) - get(throttle_slip_min_chance)
        local raw_chance = (get(throttle_slip_min_chance) + (rpm_ratio * chance_range)) * lock_ratio
        if math.random() < raw_chance then --slippage!!
            local step = get(throttle_slip_min_step)+(rpm_ratio*(get(throttle_slip_max_step)-get(throttle_slip_min_step)))
            local t_throttle = get(xp_throttle_used)-step
            set(xp_throttle_used, t_throttle)
    
            old_xp_throttle_ratio = t_throttle    
        end
    end
end

function update_engine_hours ()
    local hourly_rate = get(xp_engine_rpm) / get(engine_rpm_hour)
    local second_rate = hourly_rate / 3600
    local hour_step = second_rate * timer_lib.SIM_PERIOD
    set (engine_hours, get (engine_hours) + hour_step)
    set_tach_hours()
end

function update_xp_fuel_valve ()
    old_xp_fuel_valve = get(xp_fuel_valve)
    if old_xp_fuel_valve <= 1 or old_xp_fuel_valve == 3 then
        fuel_lever_moving_to = old_xp_fuel_valve
    elseif old_xp_fuel_valve == 2 or old_xp_fuel_valve == 4 then
        fuel_lever_moving_to = 2
    end
end

function update_fuel_lever()

    -- set xp fuel valve first
    if fuel_lever_moving_to <= 1 or fuel_lever_moving_to == 3 then
        set (xp_fuel_valve, fuel_lever_moving_to)
    elseif fuel_lever_moving_to == 2 then
        set(xp_fuel_valve, 4)
    end
    
    -- if we are moving from off to right, we want to move there counter clockwise
    if old_fuel_lever == 0 and fuel_lever_moving_to == 3 then
        set(fuel_lever_pos, 4)
        fuel_lever_moving = moving_down
    elseif old_fuel_lever == 3 and fuel_lever_moving_to == 0 then
        fuel_lever_moving_to = 4
        fuel_lever_moving = moving_up
    elseif old_fuel_lever > fuel_lever_moving_to then
        fuel_lever_moving = moving_down
    else
        fuel_lever_moving = moving_up
    end
    old_fuel_lever = fuel_lever_moving_to
end


function cht()
    local t_cht = get(xp_cht) + 9
    set(cht_deg, t_cht * (.93+math.random()/1000), 1)
    set(cht_deg, t_cht * (.95+math.random()/1000), 2)
    set(cht_deg, t_cht, 3)
    set(cht_deg, t_cht * (.98+math.random()/1000), 4)
end

function egt()
    local t_egt = get(xp_egt)
    set(egt_deg, t_egt *(.985+math.random()/1000), 1)
    set(egt_deg, t_egt, 2)
end

function check_com1()
    local i, n, t
    local f = get(com1_freq_hz)
    for i = 1, 5 do
        n = math.floor((f/10^(i-1)) % 10)
        com1_moving_to[i] = n
        t = get(com1_freq_dial, i)
        if n > t  then
            if t == 0 and n > 5 then
                com1_moving[i] = moving_down
                set(com1_freq_dial, 10, i)
            else
                com1_moving[i] = moving_up
            end
        elseif n < t then
            if n == 0 and t > 5 then
                com1_moving[i] = moving_up
                com1_moving_to[i] = 10
            else
                com1_moving[i] = moving_down
            end
        end
    end
    old_com1_freq = f
    if f <= 19 then
        set (xp_adf1_freq, 190)
    elseif f > 19 and f <= 53 then
        set (xp_adf1_freq, f * 10)
    elseif f > 53 and f < 10800 then
        set (xp_adf1_freq, 530)
    elseif f <= 10800 then
        set(xp_nav1_freq, 10800)
    elseif f > 10800 and f <= 11799 then
        set (xp_nav1_freq, f)
    elseif f < 11800 then
        set(xp_com1_freq, 11800)
        set(xp_nav1_freq, 11795)
    elseif f >= 11800 and f <= 13697 then
        set(xp_com1_freq, f)
    elseif f >= 13697 then
        set (xp_com1_freq, 13697)
    end
end

function check_com1_vol ()
    local t_vol = get(com1_vol)
    local f = get (com1_freq_hz)
    local s = get (com1_sq)
    local c_lohi = 1
    local c_sq = 1
    if (old_com1_vol == 0 or t_vol == 0) and old_com1_vol ~= t_vol then
        sasl.al.playSample (radio_on_click)
    end
    if get(lohi_rat) == 0 then
        c_lohi = 0.5
    end
    local com_sq_start = get (com1_sq_start)
    local com_sq_btm = get (com1_sq_bottom)
    if s <= com_sq_btm then
        c_sq = (s / com_sq_btm)
    end
    if s > com_sq_start then
        local sq_rng = get(com1_sq_end) - com_sq_start
        local sq_c = (s - com_sq_start) / sq_rng
        c_sq = 1 - sq_c
        if c_sq < 0 then c_sq = 0 end
        if not sasl.al.isSamplePlaying (radio_static) and t_vol > 0 then
            sasl.al.playSample ( radio_static, true )
        end
        g = t_vol * c_lohi * sq_c * 1000
        sasl.al.setSampleGain ( radio_static , g)
    else
        sasl.al.stopSample (radio_static)
    end
    v = t_vol * c_lohi * c_sq
    set(xp_com1_pwr, 0)
    set(xp_nav1_pwr, 0)
    set(xp_adf1_pwr, 0)
    if f >= 19 and f <= 53 then
        if sasl.al.isSamplePlaying (radio_fm_static) then
            sasl.al.stopSample (radio_fm_static)
        end
        if not sasl.al.isSamplePlaying (radio_channel_static) then
            sasl.al.playSample ( radio_channel_static, true )
        end
        sasl.al.setSampleGain ( radio_channel_static , v * 100)
        set (xp_adf1_vol, v)
        set (xp_adf1_pwr, 3)
        if v > 0 then set (xp_adf1_sel, isOn) end
    elseif f > 53 and f <= 10795 then
        if sasl.al.isSamplePlaying (radio_fm_static) then
            sasl.al.stopSample (radio_fm_static)
        end
        if not sasl.al.isSamplePlaying (radio_channel_static) then
            sasl.al.playSample ( radio_channel_static, true )
        end
        sasl.al.setSampleGain ( radio_channel_static , v * 300)
    elseif f >= 10795 and f <= 11799 then
        if sasl.al.isSamplePlaying (radio_fm_static) then
            sasl.al.stopSample (radio_fm_static)
        end
        if isSamplePlaying (radio_channel_static) then
            sasl.al.stopSample (radio_channel_static)
        end
        set (xp_nav1_vol, v)
        if v > 0 then set (xp_nav1_pwr, isOn) end
        set (xp_nav1_sel, isOn)
    elseif f >= 11800 and f <= 13700 then
        if sasl.al.isSamplePlaying (radio_fm_static) then
            sasl.al.stopSample (radio_fm_static)
        end
        if f ~= get(xp_com1_freq) then -- between channels add static
            if not sasl.al.isSamplePlaying (radio_channel_static) then
                sasl.al.playSample ( radio_channel_static, true )
            end
            sasl.al.setSampleGain ( radio_channel_static , v * 300)
            v = v / 2
        else
            sasl.al.stopSample (radio_channel_static)
        end
       set (xp_com1_vol, v)
       if v > 0 then set (xp_com1_pwr, isOn) end
    elseif f > 13700 then
        if sasl.al.isSamplePlaying (radio_channel_static) then
            sasl.al.stopSample (radio_channel_static)
        end
        if not sasl.al.isSamplePlaying (radio_fm_static) then
            sasl.al.playSample ( radio_fm_static, true )
        end
    end
    old_com1_vol = t_vol
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
    set (xp_fuel_valve, 0)
    set_tach_hours()
    set (xp_throttle_override, 1)
    set (com1_sq, 0.5)
    set (xp_com1_vol, 0)
    set (xp_com1_pwr, 0)
    set (xp_nav1_vol, 0)
    set (xp_nav1_pwr, 0)
    set (com1_freq_hz, get(xp_com1_freq))
    set (xp_adf1_pwr, 0)
    set (xp_adf1_vol, 0)
end

-- on reload and/or startup

first_time = true

function update ()
    if first_time == true then
        do_first_time()
    end

    if old_com1_sq ~= get(com1_sq) then
        check_com1_vol ()
        old_com1_sq = get(com1_sq)
    end 
    
    if old_com1_vol ~= get(com1_vol) then
        check_com1_vol ()
    end

    if old_throttle_lock_ratio ~= get(throttle_lock_rat) then
        check_throttle_lock_rat()
    end

    if old_com1_freq ~= get(com1_freq_hz) then
        check_com1 ()
        check_com1_vol ()    
    end
    
    if throttle_locked then 
        set(xp_throttle, old_xp_throttle_ratio)
        set(xp_throttle_used, old_xp_throttle_used_ratio)
    else
        check_throttle()
    end

    if get(throttle_lock_slip) > get(throttle_lock_rat) and get(xp_engine_rpm) >= get(throttle_slip_min_rpm) then
        check_throttle_slip()
    end

    rotate_prop()
    cht()
    egt()

    -- set (coil_psi, get(xp_rudder), 1)
    -- set (anchor_psi, get(xp_rudder)*2, 1)

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

    for i = 1, 5 do
        if com1_moving[i] ~= not_moving then
            move_com1_dial(i)
        end
    end

    if lohi_moving ~= not_moving then
        move_lohi ()
    end

    if fuel_lever_lock_moving ~= not_moving then
        move_fuel_lever_lock()
    end

    if fuel_lever_moving ~= not_moving then
        move_fuel_lever ()
    end

    if com1_vol_moving ~= not_moving then
        move_com1_volume()
    end

    if old_xp_fuel_valve ~= get(xp_fuel_valve) then
        update_xp_fuel_valve()
    end
    
    if old_fuel_lever ~= fuel_lever_moving_to then
        update_fuel_lever()
    end

    if get(xp_engine_running) == 1 then
        update_engine_hours()
    end

    
    updateAll (components)
end

function onModuleShutdown()
    config["Initial_engine_hours"] = get(engine_hours)
end
