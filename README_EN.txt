TWIN TRACK CONTROL — Farming Simulator 25
Version 1.0.0.0

INSTALLATION
1. Copy FS25_TwinTrackControl.zip, without extracting it, to:
   Documents\My Games\FarmingSimulator2025\mods
2. Enable Twin Track Control in the mod list before loading your savegame.
3. Enable manual direction changing in the game settings.
   This is the forward/reverse setting; manual gear shifting is not required.
4. Enter the desired vehicle and press Left Ctrl + Left Alt + T.

KEY BINDINGS
In the game's control settings, find:
"Twin Track Control: toggle track steering".
Assign any convenient key, key combination, or controller button.
Internal action name: TTC_TOGGLE_MODE.

Accelerator and brake inputs use your NORMAL FS25 bindings:
AXIS_ACCELERATE_VEHICLE and AXIS_BRAKE_VEHICLE.
You do not need to bind them separately for this mod.

BEHAVIOR WHEN ENABLED
- Accelerate only: drive while turning left.
- Brake only: drive while turning right.
- Both simultaneously: drive straight; the steering command is 0.
- Release both: apply full service braking until the vehicle stops.
- Select the travel direction using the built-in FS25 forward/reverse control.
- When reversing, steering follows the vehicle's normal physics.
- Normal steering with A/D, a steering wheel, or the mouse is replaced by
  steering through the accelerator and brake inputs while this mode is active.
- Cruise control and the built-in steering assist are disabled so that they
  cannot continue driving or steering against these two inputs.

Digital buttons apply full throttle. Analog pedals retain their throttle
amount: the higher of the two input values is used. Pressing both pedals
always requests straight travel, even if they are pressed by different
amounts, following the rule "both inputs = straight".
A single pressed input requests full steering in its assigned direction,
using the game's normal steering response. When both inputs are pressed
or released, the previous steering command is centered immediately;
the vehicle's inertia still applies.

Pedals must provide independent inputs. If the controller driver combines
them into one axis (Combined Pedals), simultaneous inputs may cancel out
before reaching the game. Disable Combined Pedals if this happens.

SWITCHING BETWEEN VEHICLES
The mode is disabled by default. Enable it manually for each vehicle;
its state is remembered for that vehicle during the current session.
Switching from a tracked vehicle to a wheeled vehicle gives you normal
controls unless you have separately enabled the mode for that vehicle too.
The mod does not automatically detect the vehicle's running gear.
Press the toggle shortcut again to restore normal controls.
After reloading the savegame, the mode is disabled for all vehicles again.
The notification and the action shown in the F1 help panel indicate the
current vehicle's mode.

FORWARD / REVERSE
Positive throttle is passed to the standard FS25 driving system, which
uses the selected travel direction. The script does not shift gears or
change your direction-control settings. The mode cannot be enabled
unless manual direction changing is active.
If you switch back to automatic direction changing while the mode is
active, it will disable itself and display a notification.

FILES AND IMPLEMENTATION
modDesc.xml:
- Mod description, version 1.0.0.0, descVersion 92.
- One configurable action: TTC_TOGGLE_MODE.
- Default binding: KEY_lctrl KEY_lalt KEY_t.
- Ukrainian and English text.
- References to the script and the included icon.dds.

scripts/TwinTrackControl.lua:
- mapInputs: remaps the separate accelerator and brake inputs.
- beforeUpdate: applies the remapping before Drivable.onUpdate.
- actionToggle: toggles the mode for the current vehicle.
- onRegisterActionEvents: registers the binding and F1 help text.
- onLeaveVehicle / clearInputs: clears remaining commands when exiting.
- Separate local spec_drivable.ttcEnabled state for each vehicle.
- DEADZONE = 0.02: an additional 2% threshold for detecting a pressed input.
- RELEASE_BRAKE = 1.0: 100% braking after both inputs are released.

icon.dds: the included mod icon.
README_UK.txt: the Ukrainian guide included in the mod archive.
README_EN.txt: this English guide, supplied separately.

Base-game files, vehicle files, and other mods are not edited. When the
mode is disabled, the standard Drivable code runs. The mode applies to
the current local driver; hired-worker controls are unchanged.
The resulting commands use Drivable's normal network synchronization.
The toggle state is a local driver preference and is not synchronized
separately.

IMPLEMENTATION LIMITS
This mod remaps controls using the vehicle's existing steering physics.
It does not calculate separate speeds, torques, or braking forces for
the left and right tracks. The turning radius depends on the specific
vehicle's XML configuration and physics; turning on the spot is not
guaranteed for every vehicle model.
Other mods that also override driving inputs or physics need to be tested
together with this mod. For an initial test, disable other control mods.

VALIDATION
Lua syntax was checked by executing the code in Lua. modDesc.xml passed
validation against the official GIANTS FS25 schema. All 78 automated
checks passed using the published FS25 Drivable and WheelsUtil functions
with simulated engine objects. These covered inputs, reversing, braking,
toggling, separate vehicle states, and commands for standard network
synchronization. The DDS icon and all file references were also checked.
The development environment could not run FS25 or a multiplayer session.
Suggested in-game check: press both inputs, hold only one, press both
again, then release both. Repeat in reverse, then disable the mode and
check normal controls and switching to a wheeled vehicle.
