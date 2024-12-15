Version: v1.13

*********************************************
*********************************************
IF YOU WOULD LIKE TO INCLUDE IT IN YOUR PACK, PLEASE coNTACT ME AND ASK 
FOR PERMISSION ON ONE OF THE SITES THAT I AM ACTIVE ON:
- http://ultrapack.il2war.com/index.php/board,26.0.html
- http://www.sas1946.com/main/

AAA Team, don't even bother asking...
*********************************************
*********************************************

Change log
v0.2
- first public version. Introduced moving ships that are in sync for all online players
---------------------------------------------------------------------------------
v0.3
- AI aircrafts attack live player as from now on. So, watch out ;)
---------------------------------------------------------------------------------
v0.4
- incorporated Fireballs CTO mod v4.x
---------------------------------------------------------------------------------
v0.5
- fixed reconnect issue
- minor changes done to AI. AI should target live players more often now
---------------------------------------------------------------------------------
v0.6
- fixed AI not attacking after players in some cases.
- fixed AI not defending themselves
---------------------------------------------------------------------------------
v0.6.1
- fixed AI aircraft spawning on carriers at time 0 or time > 0
---------------------------------------------------------------------------------
v0.7
- enabled positioning of home base object to moving carrier
- fixed problems with enemy recognized as friend if spawned inside home base circle
- fixed loading and processing of targets set in mission
- incorporated Fireballs Carrier mod v5.2
- fixed enemy AI not attacking live player if player is the host
- fixed problem with air spawns over carriers
- fixed recording and playing of online dogfight tracks
---------------------------------------------------------------------------------
v0.71
- ships resync every 10s
- fixed catapult problems on modern carriers
- included Airport Friction Mod (http://il2ultrapack.net46.net/index.php?topic=247.msg1601#new)
- included pad mod (flight map starts at max zoom)
---------------------------------------------------------------------------------
v0.72
- changed trigger for appearing of "refly" button when spawned on carriers
- ships resync lowered to 5s since no FPS loss was noted during testing
---------------------------------------------------------------------------------
v0.73
- slight modifications to time synchronization procedure
---------------------------------------------------------------------------------
v0.74
- completely redone spawn points on all carriers for live players
- increased Home Base refresh rate to 1/4s on briefing/map screens
---------------------------------------------------------------------------------
v0.75
- redone spawn points on carriers (optimized)
- new variables that allow users to control number of spawn points on specific type of CVs
---------------------------------------------------------------------------------
v0.76
- increased ships resync time from 5s to 10s
- decreased Home Base location refresh interval to 1/10s
- added support for Ship Pack 2 MOD.
- added new parameter for [MDS] section for CVL control
---------------------------------------------------------------------------------
v0.77
- removed ships resync
---------------------------------------------------------------------------------
v0.8
- [MDS] and [RespawnTime] sections are now saved if you save mission in FMB
- AirSpawn options added to HomeBase object in FMB
- changed planes colors on the map (player = army color, the rest = white)
- incorporated Fireballs CTO mod v5.3
- static units inside home base circle are converted to home base army, moving objects are not
- fixed problem of planes flying around with folded wings
- reintroduced ships resync
- DS can now act also as simple server commander. Use added software for this (check $ChangeLog$.doc)
- targets that were set in mission will be displayed to players
- new option to show airplanes on map even if NoMapIcons settings is set
- introducing moving front lines
- introducing HomeBase capturing
- new/revisited parameters for number of spawn points on carriers
- enabled tower communication for players
---------------------------------------------------------------------------------
v1.0
- enabled usage of chocks on ground airfields
- enabled instant despawn of AI airplanes once they land and park
- added option to disable AI radio chatter
- added option to restrict users from pressing refly button if they are KIA
- enabled rearming, refueling and repairing of your aircraft
- added support for statistics screen data manipulation
- added radar range settings
- added option to set how long are bomb craters displayed
- added two new tabs for HomeBase objects (AirSpawn/Radars and Capturing)
---------------------------------------------------------------------------------
v1.01
- fixed scout planes recognition
- fixed FMB description for HomeBase radars MAX height
- fixed rearming loads double the amount of bullets
- fixed modify repairs function weapons ammo loading to % of max ammo count
- fixed refly button not enabled after preset period of time
- fixed change FMB GUI settings to IL2 default behavior (minimap drawing, refly button, AI communication...)
- fixed R/R/R only available to same army pilots
- repair function renamed to Un-Jam
---------------------------------------------------------------------------------
v1.1
- fixed inspect/recon target (clients now know when this target was accomplished)
- optimized code for radar functionality
- improved re-fly blocking functionality
- added support for limiting planes and their load outs per Home Base
- added support for limiting Home Base country list
- added support for on-the-fly load outs changing (no arming menu)
- enabled rendering of white (neutral) born places on mini-map
- selectable custom icons sizes on mini-map and briefing screen
- allowing artillery to carry front markers
- enhanced repair functionality now repairs controls, engines and fuel/oil tanks
- added option to un-jam jammed chocks
- added option to hide only players plane on mini-map
- added option to make Home Bases a friction dictators
- added option that makes Home Bases non-selectable in Briefing
- arming screen fuel selection is now in 10% intervals (25% before)
---------------------------------------------------------------------------------
v1.11
- captured base planes have limitations
- fixed new countries loading (countries with spaces in their names)
- added option to include static planes in home base planes counter
- fixed issue with plane limitations (players got removed after plane was no longer available)
- water based home bases can support R/R/R functions
- available planes list in arming screen shows only available planes
---------------------------------------------------------------------------------
v1.12
- fixed static planes not being destroyed in some cases
- fixed planes limitations that were not allowing you to spawn on some HB
- further enhanced country limitations
---------------------------------------------------------------------------------
v1.13
- fixed issue with disappearing home bases
- fixed issue that ignored fly button
- guns are now reloaded with correct number of bullets
- fixed issue with selection of scout planes in FMB
- stationary target icons (bridges, ground, inspect) are no longer checked against radar ranges
- bullet holes and oil stains on the wings no longer appear if the wing was actually not damaged (on some US AC)
- enforced radar function so that it should not crash on some special occasions
- RRR is now available for single and coop game modes
- RRR options are now working if you restrict them only if dedicated objects are present
- smoking engines should stop smoking after they are repaired
- RRR settings are now global (for extra friction areas) and local (optional, for each Home Base)
- human aircraft are now recognized as scout planes.
- releasing planes when player lands and hits refly is fixed
- front markers of colours different from red/blue are now loaded disabled in original IL2)
- most of the MDS variables have it's MAX value limit set to 99999 now
- integration into Coop and Single player game modes. Placing home bases is mandatory for some functions!
- scouts Ground units scan alpha [°] values were changed and are now ranging from 30° to 80° in 5° intervals
- each side can now have unlimited number of scout planes assigned (previously only 3 were allowed)
- added switch that makes scout planes the only ones that can complete recon objective
- recon targets can now move
- totally new server-client time synchronization
- missions can again have static time because of previous line change
- localized!
---------------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////////////
---------------------------------------------------------------------------------
Installation:

- extract to your MODS folder and remove ALL old MDS mods!
- add entries from files in i18n.rar file to your MODS/STD/i18n/ files. If you don't,
  you'll have strange text in FMB.

That's it.
---------------------------------------------------------------------------------
/////////////////////////////////////////////////////////////////////////////////
---------------------------------------------------------------------------------

Included mods:
If you decide to use this mod you don't need these mods as they are incorporated:
- Certificates AI mod (v3.0 is included with this mod)
- Fireballs carrier takeoff mod (v5.3.x is included with this mod)

=====================
---===IMPORTANT===---
=====================
-If you're having problems you can use "Z_ModsConflictsRevealer" tool that is located in
Tools subfolder in your MDS folder (UP installation has tools in different location).
Run "IL2_ModsConflictsRevealer.jar" file to check for possible conflicts with other mods.
If there are any, try disabling them and re-check behavior.


Credit and Thanks
Thanks to users from IL2 UltraPack community for their willingness to help me out in the beginning.
And naturally Oleg Maddox for IL2 and QTim for his tools.


Download
- http://ultrapack.il2war.com/index.php/board,26.0.html

S!
|ZUTI|