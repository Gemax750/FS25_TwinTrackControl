-- Twin Track Control 1.0.0.0 for Farming Simulator 25.
-- Remap the game's separate accelerator/brake inputs before Drivable combines
-- them. The original Drivable update still handles physics and network traffic.

TwinTrackControl = {}
TwinTrackControl.MOD_NAME = g_currentModName
TwinTrackControl.ACTION_NAME = "TTC_TOGGLE_MODE"
TwinTrackControl.DEADZONE = 0.02
TwinTrackControl.RELEASE_BRAKE = 1.0

function TwinTrackControl.getText(key)
    return g_i18n:getText(key, TwinTrackControl.MOD_NAME)
end

function TwinTrackControl.notify(key)
    if g_currentMission ~= nil then
        g_currentMission:showBlinkingWarning(TwinTrackControl.getText(key), 3500)
    end
end

function TwinTrackControl.isLocalDriver(vehicle)
    return vehicle.isClient
        and vehicle.getIsEntered ~= nil and vehicle:getIsEntered()
        and vehicle:getIsActiveForInput(true, true)
        and not vehicle:getIsAIActive()
        and vehicle:getIsVehicleControlledByPlayer()
end

-- Return throttle, service brake and steering. Left is negative in FS25.
-- Both inputs always request straight travel, even at unequal analog values.
function TwinTrackControl.mapInputs(accelerate, brake)
    accelerate = math.clamp(accelerate or 0, 0, 1)
    brake = math.clamp(brake or 0, 0, 1)

    local leftRequested = accelerate > TwinTrackControl.DEADZONE
    local rightRequested = brake > TwinTrackControl.DEADZONE

    if leftRequested and rightRequested then
        return math.max(accelerate, brake), 0, 0
    elseif leftRequested then
        return accelerate, 0, -1
    elseif rightRequested then
        return brake, 0, 1
    end

    return 0, TwinTrackControl.RELEASE_BRAKE, 0
end

function TwinTrackControl.updateActionText(vehicle)
    local spec = vehicle.spec_drivable
    local action = InputAction[TwinTrackControl.ACTION_NAME]
    local event = spec.actionEvents ~= nil and spec.actionEvents[action] or nil
    if event ~= nil then
        local key = spec.ttcEnabled and "ttc_disable" or "ttc_enable"
        g_inputBinding:setActionEventText(event.actionEventId, TwinTrackControl.getText(key))
    end
end

function TwinTrackControl.clearInputs(vehicle)
    local spec = vehicle.spec_drivable
    local inputs = spec.lastInputValues
    if inputs ~= nil then
        inputs.axisAccelerate = 0
        inputs.axisBrake = 0
        inputs.axisSteer = 0
        inputs.targetSpeed = nil
        inputs.targetDirection = nil
        inputs.cruiseControlState = 0
    end
    spec.axisForward = 0
    spec.axisSide = 0
    spec.idleTurningActive = false
end

function TwinTrackControl.actionToggle(vehicle, actionName, inputValue)
    if not TwinTrackControl.isLocalDriver(vehicle) then
        return
    end

    local spec = vehicle.spec_drivable
    if not spec.ttcEnabled then
        -- Positive throttle must follow the built-in forward/reverse selector;
        -- negative input must remain a brake, never automatic reverse.
        if not vehicle:getIsManualDirectionChangeActive() then
            TwinTrackControl.notify("ttc_needManualDirection")
            return
        end
    end

    spec.ttcEnabled = not spec.ttcEnabled
    TwinTrackControl.clearInputs(vehicle)
    vehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
    TwinTrackControl.updateActionText(vehicle)
    TwinTrackControl.notify(spec.ttcEnabled and "ttc_enabled" or "ttc_disabled")
end

function TwinTrackControl.onRegisterActionEvents(vehicle)
    if not TwinTrackControl.isLocalDriver(vehicle) then
        return
    end

    local action = InputAction[TwinTrackControl.ACTION_NAME]
    if action == nil then
        return
    end

    local _, eventId = vehicle:addActionEvent(vehicle.spec_drivable.actionEvents,
        action, vehicle, TwinTrackControl.actionToggle,
        false, true, false, true, nil)

    if eventId ~= nil then
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_LOW)
        g_inputBinding:setActionEventTextVisibility(eventId, true)
        TwinTrackControl.updateActionText(vehicle)
    end
end

function TwinTrackControl.beforeUpdate(vehicle, dt)
    local spec = vehicle.spec_drivable
    if spec == nil or not spec.ttcEnabled or not TwinTrackControl.isLocalDriver(vehicle) then
        return
    end

    -- A settings change must not turn the release-to-brake action into reverse.
    if not vehicle:getIsManualDirectionChangeActive() then
        spec.ttcEnabled = false
        TwinTrackControl.clearInputs(vehicle)
        TwinTrackControl.updateActionText(vehicle)
        TwinTrackControl.notify("ttc_disabledManualDirection")
        return
    end

    local inputs = spec.lastInputValues
    if inputs == nil then
        return
    end

    local throttle, serviceBrake, steering = TwinTrackControl.mapInputs(
        inputs.axisAccelerate, inputs.axisBrake)

    local isAllowed = vehicle:getIsPlayerVehicleControlAllowed()
    if not isAllowed then
        throttle, serviceBrake, steering = 0, TwinTrackControl.RELEASE_BRAKE, 0
    end

    -- Cruise control and a previous scripted target must not keep the vehicle
    -- moving after both controls are released.
    inputs.cruiseControlState = 0
    inputs.targetSpeed = nil
    inputs.targetDirection = nil
    if spec.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
        vehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
    end

    if vehicle.spec_aiAutomaticSteering ~= nil
        and vehicle.spec_aiAutomaticSteering.steeringEnabled
        and vehicle.setAIAutomaticSteeringEnabled ~= nil then
        vehicle:setAIAutomaticSteeringEnabled(false)
    end

    inputs.axisAccelerate = throttle
    inputs.axisBrake = serviceBrake
    inputs.axisSteer = steering
    inputs.axisSteerIsAnalog = false
    spec.idleTurningActive = false

    -- Do not keep the previous turn when both controls request straight travel.
    -- A single input uses the game's usual steering sensitivity and turn rate.
    if steering == 0 then
        spec.axisSide = 0
    end
end

function TwinTrackControl.onLeaveVehicle(vehicle, wasEntered)
    if wasEntered and vehicle.spec_drivable.ttcEnabled then
        TwinTrackControl.clearInputs(vehicle)
    end
    -- ttcEnabled belongs to this vehicle on this client. Keep it for re-entry
    -- during this session; another vehicle starts with its own mode disabled.
end

-- Install before vehicle types register their Drivable event listeners.
Drivable.onRegisterActionEvents = Utils.appendedFunction(
    Drivable.onRegisterActionEvents, TwinTrackControl.onRegisterActionEvents)
Drivable.onUpdate = Utils.prependedFunction(
    Drivable.onUpdate, TwinTrackControl.beforeUpdate)
Drivable.onLeaveVehicle = Utils.appendedFunction(
    Drivable.onLeaveVehicle, TwinTrackControl.onLeaveVehicle)

print("[TwinTrackControl] Loaded version 1.0.0.0")
