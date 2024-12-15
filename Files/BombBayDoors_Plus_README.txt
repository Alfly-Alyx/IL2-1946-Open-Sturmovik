BombBayDoors_Plus_2_5_3
=======================

IMPORTANT NOTE: Depending on which options you choose, this mod may involve adding lines to the conf.ini file in your IL-2 game folder. BEFORE YOU MAKE ANY CHANGES TO THE CONF.INI FILE, MAKE A COPY OF IT, just to be safe.

The mod lets the user or server modify the way several controls work. You can pick and choose which of the options you use. Here's a summary

- Manually open/close bomb bay doors. (P2V Neptune added in 2.5)
- Manually open/close side cockpit door on Spitfire XII and XIV.
- Display TAS in addition to IAS in the speedbar. (also requires the HUDConfig mod)
- Separate gear up/down controls.
- Separate tailhook up/down controls.
- Separate radiator open/close controls.
- Toggle music on/off while flying.
- Modified airshow smoke.
- The server can set various limited external view options while 'No External Views' is turned on.
- The server can set various limited padlock options while 'No Padlock' is turned on.
- Dump Fuel key for F9F Panther.

To install, extract the BombBayDoors_Plus folder in the rar file to the MODS folder in your IL-2 1946 game folder.

You will need to remove or disable any existing versions of the BombBayDoors or Hotkeys mods. Also this mod is not compatible with the PAT Smoke mod.


Intstructions:

By default the only thing the BombBayDoors_Plus mod does is give you manual control over the bomb bay doors and the side cockpit door on Spitfire XIV (and these can be easily disabled). For everything else, you choose which options to use by adding lines to the [Mods] section of the conf.ini file in your IL-2 1946 game folder, or the [Mods] section of the mission (.mis) file if it is a mission parameter.  See the Notes at the end of this README for more details.

Manually open/close bomb bay doors
----------------------------------

With this option, whatever key you assign to 'Power 10' in your controls becomes a toggle to open/close the bomb bay doors on aircraft that have bomb bay doors. When this option is set, you can only release your bombs after opening the bay doors. It has no effect on aircraft that do not have bomb bay doors.

This option is turned on by default. To disable it, in the [Mods] section of your conf.ini add the line:  BombBayDoors=0


Manually open/close side cockpit door on Spitfire XII and XIV
-------------------------------------------------------------

With this option, whatever key you assign to 'Power 40' in your controls becomes a toggle to open/close the side cockpit door on the Spitfire XII and XIV.

This option is turned on by default. To disable it, in the [Mods] section of your conf.ini add the line:  SideDoor=0


Display TAS in addition to IAS in the speedbar
----------------------------------------------

This function also requires the HUDConfig mod.

With this option, when you cycle through your speedbar you will have three additional settings: kmh TAS, knots TAS, and mph TAS.

In the [Mods] section of your conf.ini add the line:  SpeedbarTAS=1


Separate gear up/down controls
------------------------------

With this option, your Toggle Gear control only acts as Gear Down, and whatever key you assign to 'Magneto Previous' is Gear Up.

In the [Mods] section of your conf.ini add the line:  SeparateGearUpDown=1


Separate tailhook up/down controls
----------------------------------

With this option, your Toggle Tailhook control only acts as Tailhook Down, and whatever key you assign to 'Magneto Next' is Tailhook Up.

In the [Mods] section of your conf.ini add the line:  SeparateHookUpDown=1


Separate radiator open/close controls
-------------------------------------

With this option, your Cowl Flaps (radiator) control only opens your radiator, and whatever key you assign to 'Power 30' closes your radiator.

In the [Mods] section of your conf.ini add the line:  SeparateRadiatorOpenClose=1


Toggle music on/off while flying
--------------------------------

With this option, you can turn the Takeoff and In-flight music on and off with whatever key you assign to 'Power 20'. You can't turn off the Crash music because...well...because your dead. In the game, as in life, you'll find there are lots of thing you're no longer able to do once you're dead.

In the [Mods] section of your conf.ini add the line:  ToggleMusic=1


Dump Fuel key for the F9F Panther
---------------------------------

With this option, you can dump the fuel in the wingtip tanks of the Panther with whatever key you assign to 'Power 50'. As in real life, the you can only dump the fuel in the wingtip tanks. The main tanks hold approx 75% of a full fuel load and wingtip tanks the remaining 25%. So you can only dump fuel in excess of 75%. It takes about one minute to dump fully-loaded wingtip tanks.

In the [Mods] section of your conf.ini add the line:  DumpFuel=1


Modified airshow smoke
----------------------

With this option, the normal wingtip smoke is moved to a single smoke stream coming from the middle of the aircraft, and you have the choice of red, white or blue smoke.

In the [Mods] section of your conf.ini add ONE of the following lines:

	AirShowSmoke=1       <----- red smoke
	AirShowSmoke=2       <----- white smoke
	AirShowSmoke=3       <----- blue smoke

The smoke mod by default uses the same "quality" of smoke as the normal wingtip smoke. Hopefully others who know a lot more about effects than I do will develop some nice smoke effects files that can just be dropped into the mod. 


External view levels (mission parameter)
----------------------------------------

With this option, with 'No External Views' turned on in the difficulty settings, all players who have this mod will still have limited external views. The external view level can be either 0, 1, or 2.

Level - 0 (views that allow you to see your own aircraft)
- External (F2)
- Chase (F8)
- Flyby (F3)

Level 1 (All level 0 views, plus additional views that allow you to see friendly aircraft)
- Next Friendly (Shift+F2)
- Next Friendly Chase (Shift+F8)

Level 2 (All level 0 and 1 views, plus additional views that allow you to see enemy aircraft)
- Next Enemy (Ctrl+F2)
- Next Enemy Chase (Ctrl+F8)

On the server, in the [Mods] section of the mission (.mis) file add the line:  ExternalViewLevel  0  (or 1 or 2)


External view only while player is on the ground (mission parameter)
--------------------------------------------------------------------

This option further restricts whatever the ExternalViewLevel parameter is set to, to only work when the player's aircraft is on the ground. When used without ExternalViewLevel, it has no effect.

On the server, in the [Mods] section of the mission (.mis) file add the line:  ExternalViewGround  1


External view only when player is dead (mission parameter)
----------------------------------------------------------

This option further restricts whatever the ExternalViewLevel parameter is set to, to only work when the player is dead. When used without ExternalViewLevel, it has no effect.

On the server, in the [Mods] section of the mission (.mis) file add the line:  ExternalViewDead  1


Padlock levels (mission parameter)
----------------------------------

With this option, with 'No Padlock' turned on in the difficulty settings, all players who have this mod will still have limited padlock. The padlock level can be either 1 or 2.

Level 1 (friendly padlocks)
- Padlock Friendly (Shift+F4)
- Padlock Friendly Ground (Shift+F5)

Level 2 (All level 1 padlocks, plus adds enemy padlocks) 
- Padlock Enemy (F4)
- Padlock Enemy Ground (F5)

On the server, in the [Mods] section of the mission (.mis) file add the line:  PadlockLevel  1  (or 2)


External padlock levels (mission parameter)
-------------------------------------------

With this option, with 'No Padlock' turned on in the difficulty settings, all players who have this mod will still have limited external padlock. The external padlock level can be either 1 or 2.

Level 1 (friendly external padlocks)
- External Padlock Friendly Air (Shift+F6)
- External Padlock Friendly Ground (Shift+F7)

Level 2 (All level 1 padlocks, plus adds enemy external padlocks) 
- External Padlock Enemy Air (F6)
- External Padlock Enemy Ground (F7)
- External Padlock Closest Enemy Ground (Alt+F7)

On the server, in the [Mods] section of the mission (.mis) file add the line:  ExternalPadlockLevel  1  (or 2)



Notes
-----

- After adding a [Mods] section to a mission file, if you later edit and save the mission in the FMB, the [Mods] section will go away. You'll have to manually add it again with Notepad or other text editor.

- You can use the samples below to copy/paste the lines for any option you choose. Depending on which mods you already have installed you may already have a [Mods] section in the conf.ini or mission file. If so, just add the lines to the existing [Mods] section. Notice a slight difference in the format of parameters in the two files. In the conf.ini, the paramater name and value are separated by an '=' sign, whereas in the mission file the name and value are separated by one or more spaces.

Sample [Mods] section for conf.ini:

[Mods]
BombBayDoors=0      <----- This will DISABLE the manual bomb bay door control. It is enabled by default.
SpeedbarTAS=1
SeparateGearUpDown=1
SeparateHookUpDown=1
SeparateRadiatorOpenClose=1
ToggleMusic=1
AirShowSmoke=3
DumpFuel=1

Sample [Mods] section for a mission file:

[Mods]
  ExternalViewLevel  2
  ExternalViewGround  1
  ExternalViewDead  1
  PadlockLevel  2
  ExternalPadlockLevel 1

- Although it is not required for the TAS speedbar displays to function properly, you can modify 'KIAS' to read 'knots' on the speedbar by changing the 'SPD.gb' parameter in 'files\i18n\hud_log_ru.properties'.

- These parameters from earlier versions will still work in this version, but they may not in future versions, so don't use them in any new missions:

-- ViewExternalSelf - equivalent to setting ExternalViewLevel to 0.
-- ViewExternalFriendlies - equivalent setting ExternalViewLevel to level 1.
-- ViewExternalOnGround - equivalent to ExternalViewGround.
-- ViewExternalWhenDead - equivalent to ExternalViewDead.


VERSION HISTORY

New in version 2.5.3
====================

- Fixed some additional issues with the limited external views.

New in version 2.5.2
====================

- Fixed some major issues with the limited external views.
- Added support for new P-51 Mustangs.

New in version 2.5
==================

- Manual bomb bay door operation for the P2V Neptune.
- Dump Fuel hotkey for the F9F Panther.
- Reworked the external view options.
- Added padlock options.

New in version 2.4
==================

- Fixed problem where side cockpit door would not work for SpitfireXII if the SpitfireXIV mod not installed.
- Fixed issues where players with mod could not see side door opening on other aircraft.

New in version 2.3
==================

- Added manual control of side cockpit door for SpitfireXIV.


New in version 2.0
==================

- combined BombBayDoors mod and Hotkeys mod into a single mod.
- Added manual control of bomb bay doors for several new bombers.
- Added separate radiator open/close controls.
- Added toggle in-flight music on/off control.
- Added modified airshow smoke.
- Added external view of friendlies only.
- Various bug fixes.
