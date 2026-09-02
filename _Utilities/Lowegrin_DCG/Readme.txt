DCG Campaign Generator for IL-2 Sturmovik/Pacific Fighters Series

Based on the Dynamic Campaign Generator for Combat Flight Simulator 2, this program generates dynamic campaigns for IL-2 Sturmovik and all it's sequels including "1946" by Maddox Games. Over time, the front lines will shift, airfields may be captured and recaptured and objects appear and disappear. Squadrons will transfer closer to the front as friendly ground forces advance or bug-out should the enemy break-through. Armor, truck columns, and trains will also move from city to city during missions and ships from harbor to harbor, starting the next mission at the city or harbor moved to in the previous mission.  uild ups of guns and armor will also appear at the "front" and captured locations will have new defences generated. 

IL-2 DCG will also track plane losses, pilot deaths, and the replacement of both, awards and promotions, as well as the destruction and replacements of moving vehicle and tank columns, trains, and ships, and static ground defenses.  All in all, DCG offers IL-2 players a dynamic world in which to fly.

IL-2 DCG can now fully replace the stock dynamic campaigns ("DGen" and "NGen").  If IL2DCG.exe is used to replace DGen.exe, selections from the DGen campaign selection screen will over-ride selection made in DCG when in single player career mode.  See the Installation and Settings Instructions for more details.  

IL-2 DCG also works with the IL2FB Dedicated Server. From the IL2DCG Menu just set the "IL2 Program Location" to the il2server.exe file in the IL2 Server folder in the same way you would select il2fb.exe in the "Forgotten Battles" folder.  Moreover, it will work in concert with both FB Daemon 2 and IL-2 Server Commander. 

Although IL-2 DCG does all the above and more, it remains a work in progress.  Bug reporting, comments and suggestions are welcomed.  For the latest news, complete instructions, support, and bug reporting visit http://www.lowengrin.com.


--------------------------------------------------------------------------------

Support the Dynamic Campaign Generator

The Dynamic Campaign Generator software is free.  However, those of you who would like to make a financial contribution to help cover the costs of the website and compensate the time spend providing support on forums and by email are more than welcome to do so through PayPal (payable to lowengrin@shaw.ca).


--------------------------------------------------------------------------------



Additions to Version 3.43

Added new planes available in the game's 4.09 patch.  Flights per squadron will now more accurately reflect the current number of aircraft a squadron has as compared to the number of planes per flight.  For example, a squadron with four planes with two planes per flight will be able to fly two flights rather than one.  Made crewseats.dcg campaign folder unique - DCG will use the one in the main data folder if none exist in the campaign folder.  Fixed noseart to display on late-war US planes.  Fixed "IAK" squadrons being treated as German.  Added "Beachhead Reset" option to both the menu and the time table commands; this option allows the user (or campaign creator) to determine what units do when they advance onto a beachhead location - if this option is active, units will be removed, if unchecked, the units will not advance onto the beachead but remain at the location just before the beachhead and defend it.  Improved display of newsbriefs. Tweaked replacement pilot skill levels to bring them more in line with the squadron skill level.

Note: This version of DCG should not be installed over versions older than 3.01. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.01 will NOT work with this version.  After installing, remember to reset your basic options and, if using DGen or NGen Replacement modes, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.42

Added ferry spawning in Dogfight campaigns.  Added a ground contact distance setting so that players may move the spawning distance of tanks and trucks back from zero to five waypoints (on Ground War Editor Panel).  Added command "ShipsRemainSunk On/Off" to Time Table.  Fixed an endless loop in the campaign generation routine when a "Jv", "RAP" or "MTAP" squadron was being used.  Ships that crash will now remain sunk.  Added to code prohibit more than one instance of DCG to run at a time (but it will allow DCG to run as "Dgen.exe" or "NGen.exe" and as "DCG.exe" at the same time).  Added "Random" time passage setting; on this setting, time will advance either one, two or three days between missions.


Additions to Version 3.41

Fixed pre-Normandy '44 campaigns broken in 3.40.  Fixed allegiance issue with squadrons using the B5N2 and B6N2 when the downgrade option is on.  Improved ground-attack escort waypoints.  Through the Ground Objects Editor Panel, users can now add new columns to the active campaign.  Improved logic for the player's slot in the squadron flights.  Made seaplane bases active in Dogfight Mode.  Fixed the transfer from Pearl Harbor to New Guinea campaign.

Note: This version of DCG should not be installed over versions older than 3.01. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.01 will NOT work with this version.  After installing, remember to reset your basic options and, if using DGen or NGen Replacement modes, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.40

Restricted flyable squadrons chances of delayed start times in coop missions.  Tweaked fighter squadron activation.  Removed delay in pilot promotions/rewards in coop campaigns.  Fixes bridge repair time set to "0".  Fixed reset issue with maximum troop number.  Added new waypoints before and after the "halfway" points.  Fixed issue of some human players not transfering to the new campaign when the campaign map changed.  Fixed date advancement when a campaign transfers to a new map.  Fixed issue where "Jabo" squadron mission selection hung mission generation.  Improved reconnaissance chances at lower density levels.  Added recons.dat, squadron.dat and gunner.dat to backup and restore routines.  Stop defending ground units from resetting if at a beachhead - now they will defend the beaches indefinitely.  Fixed armor tracking for IL-2 1.02 campaigns.  Fixed ban weapon syntax for IL2SC dogfight missions.  Activated Murmansk Summer map.  Fixed appearance of Normandy "English Airstrip" when no island is active.  Revised and expanded the Normandy campaigns.  (Do not install 3.40 if in the middle of a Normandy campaign!)

Note: This version of DCG should not be installed over versions older than 3.01. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.01 will NOT work with this version.  After installing, remember to reset your basic options and, if using DGen or NGen Replacement modes, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.39

Spanish messages updated by flaysepulcrast.  Tightened restrictions on bomber air starts when the option is unchecked.  Fixed victory condition messages.  Fixed first campaign mission always starting at midnight or 1:00 am.  Added two new airfields to Kiev '41 campaign.  Added new Kiev '43 campaign.  Modified waypoints for escorts.  Fixed glider bug.  Raised maximum aircraft ceilings to 9500 meters.  Fixed issues with lost stats for coop campaigns.  Tweaked wizard.  Increased Axis squadron activation chances in 1943.  Added Chinese language option. (Thanks, @6!)


Additions to Version 3.38

Tweaked interception routine.  Corrected "halfway" altitude for interceptions.  Tweaked bomber formation code.  Added entries for full auto-generation mode Manchuria campaign.  Fix replicating event bug where a player shot down an "ace" player.  Added option for "No User Loadout".  This option will force players to use the loadout assigned by DCG.


Additions to Version 3.37

Added mini-Manchuria 1945 campaign.  Fixed bug in timetable routine which impacted the "NewColumn" command and other date specific commands.  Fixed "SetDate" time table command.  Fixed bug in "NameColumn" command when the column is a carrier so that the squadrons remain attached even after the name change.  Fixed bug in bomber density control.  Added "Random Nose Art" option (works only on American bombers and some ground-attack planes).  Fixed minute display in briefings.  Fixed crash resulting from a human gunner shooting down a friendly.  Added routine to move inactive human players (on-line modes) to the gunner.dcg file if the squadron has more than 16 human pilots.  Fixed bug in campaign transfer that was creating new squadrons without new pilots.  Fixed bug that centered the X/Y coordinates of a friendly location with a friendly ground unit.  Fixed carrier to airfield transfers.  Added special location designations (ie: "Airfield", "Station") to the messages to allow for translation in briefs/debriefs.  Improved tracking of players switching from pilot to gunner and a bug in gunner kill tally.  Fixed bug that prohibited shipping strikes when there were was no patrol (.prd) file for the map.  Fixed default weapon selection box.  Improved escort paths for flights originating off the map.  Added some randomness (based on range) to land-based bombers making shipping strikes.  Corrected delayed start settings for coop missions so flyable squadrons would not be impacted.  Corrected check for destroyed static object game end.  Added a squadron "SetFuel" time table command.  


Additions to Version 3.36

Fixed aircraft substitution code when newer aircraft are not available for older game versions.  Made starting ranks more historical for each nation.  Fixed "SetPaint" time table option.  Added "SetDate" command (uses DD/MM/YYYY format).  Added "SetMissionTime" command.  Added Schlachtgeschwader squadrons.  Added option for custom name file for American pilots.  Fixed nose dives for air starts from off map airfields.  Increased starting fuel for off map units to 75%.  Offset the patrol triangle from the target so that the target is now in the center of the triangle rather than over one of its points. Made improvements to the New Guinea 1942 campaign.  Fixed Bf-109 E4/B dogfight mode bug.  Increase patrol radius of reconnaissance over water.  Increased maximum allowable stationary objects to 50000.  Added option for custom name file for Dutch pilots.  Set war default end date to December 31st, 1946.  Add "Real" time mission settings which sets the mission to the computer's clock time but days continue to pass at the rate set by the "Time Passage" setting.  Fixed replicating event bug which would create duplicate events in the events.dat file and over time cause DCG to hang.

Note: This version of DCG should not be installed over versions older than 3.01. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.01 will NOT work with this new version.  After installing, remember to reset your basic options and, if using DGen or NGen Replacement modes, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.35

Added an Italy '43 campaign and a Norway '44 campaign.  Integrated Finland '41 into the "Grand Campaign".  Added second airfield to the "English Airbase" on the Normandy map.  Corrected the timetable.dcg time passage settings.  Fixed end date trigger.  Created an "ostcampaign.dcg" file that replaces the "grandcampaign.dcg" file if the player is using the original IL-2 game.  Added "DeployDistance" timetable command for Carrier Taskforces to set distance between ships.  Added "AttackRendezvous" timetable command so units can fly to a specific x/y location on a specific day from which to launch attacks.  Added "SetTaskForceSpeed" timetable command.  Modified squadron set up so that only the first squadron in a group will get the highest ranking pilot available to that nation.  Other squadrons in the group will be commanded by the second highest rank.  Made changes in weather more dynamic and less random.  Fixed stationary object bug where objects were being carried over from one campaign to the next.  Fixed altitude settings at target point.  German messages updated.  Italian messages added compliments of Aeronautica Militare Virtuale Italiana.  Revised Squadron Density effects.  Stopped air starts from beginning in a dive.  Increased taskforce speeds.  Prohibited armour breakthroughs on the first mission of a campaign.  Added the generic French squadron to the list of those that can be carrier based.  


Additions to Version 3.34

Added soda's Mareth Line (Tunisa 1943) campaign.  Carrier strikes must now be preceded by reconnaissance missions - the success of which (with weather) will determine whether the following mission is a strike: successful strikes will also allow for successive strikes.  Damaged planes landing within 5 kilometers of their home field will now be repaired and not lost with the exception of off-map squadrons.  Off-map squadrons always lose damaged planes.  Added code for bomber pilots to be awarded medals.  Changed skill level descriptions on the "Squadron Editor Panel" from "Skill 0", etc., to "Rookie", "Average", "Veteran", and "Ace".  Corrected on-map/off-map status of the "English_Airfield" in the Normandy campaigns.  Fixed the "integer error" in the "Add Squadron" routine.  Fixed ship rate of fire settings.  Fixed victory condition check for single map campaigns.  Corrected "SetTroop" command.  Fixed bug that would create French manually-generated campaigns in the "RU" campaign folder. Added "Very Slow" (three missions/day) and "Extremely Slow (four missions/day) Time Setting options.  Fixed transfer bug that happened only in "Full Auto-generation" Mode.  Fixed bug that removed human player identifier when the player was viewed in the Pilot Panel.  Added option for custom name file for French pilots.


Additions to Version 3.33

Added code to allow armor and trucks to cross rivers by ferry (Burma campaign).  Added a message to the briefing screen for pilots joining the squadron.  Separated the active pilot list on the briefing by flights.  News Briefs must now be defined as "Allied", "Axis" or "Both".  Added new "time table" commands for squadrons: "MaxPlanes", "MinPlanes", "ActivePlanes", "SetSkill", "FlightSize", and "AlwaysActive" to allow campaign designers the ability to set squadron data.  Fixed "NewPlane" command.  Fixed "Player Squadron" bug in on-line campaign generation.  Enhanced "Paratroopers" option to include AI bomber crew chutes - if unchecked, neither paratroopers nor AI bomber crews will appear (saving frame rates in campaigns with mass bombers).  Freed the "General Settings Panel" and "Aircraft Class Settings Panel" from having to have an active campaign to open.  Added plane type to the career mode briefing.  Added general victory conditions to the briefings.  Made Ki-43s flyable and added bomb option.  Prohibited transfers of less than 5 miles.  Added settings for radio use in the "Default" section of the Waypoints Settings Panel and in the timetable.dcg file: Radio [On/Off] [Squadron].  Added setting of paints and markings to the timetable.dcg: SetPaint [Squadron] = [0/1][bitmap.bmp].  Added a troop level setting through the timetable.dcg file.  Added ability to set "AIOnly" through campaign template.  Added static supply trucks to list of objects that always spawn.  Improved CAP over carriers and moving columns.  Tweaked mission success parameters.  Fixed alpha/numeric coordinate display for 3rd party campaigns.  Added reader for PhotoShop produced bitmaps - these images will now correctly display for roster and paint schemes.  Added host options for on-line campaign mode through the game's interface. Fixed troop build up bug (too many troops were being added to a location when a truck convoy/ship/train was located there).  Added possible use of gliders as payloads for C-47 and HE-111 Z when a "dropzone" is specified in the campaign (not that they are very good at landing near the dropzones...). 


Additions to Version 3.32

Modified transportation of armor and vehicle columns by ships and trains.  Only one unit may now be transported by a train or ship and these units can only be picked up at the home port/station and/or spawn point of the carrying unit.  Units being transported are identified in the columns.dcg file with a status (~) = "T". Fixed weapon ban - it was not working for both sides.  Updated Singapore campaign by adding "Nate" and "Sally".  Added "Count Static Planes" control for IL2SC administered dogfight servers.  DCG will now recognize BOE campaign selection.  Added "NewsBrief [Language] [Text]" command to the "timetable.dcg" file so campaign designers can add date specific messages to their briefings.  Increased array size for plane types; fixed missing plane bug.  Fixed dogfight mode plane assignments.  Fixed bug in AI squadron air starts routine which was making almost all AI squadrons start in the air if that option was selected.


Additions to Version 3.31

Added new planes and ground objects for "1946" and "Manchuria" (Version 4.071m).  Added Kiev '41 campaign.  Fixed "no player squadron" bug.  Improved bombing coordinates.  Improved tracking for aces; aces killed or captured should not reappear.  Added Ingress Speed boxes for both the player's "Waypoint Panel" and the "Aircraft Class Settings Panel"; added new Ingress Speed variable in the class.dcg file).  Added altitude in feet for American and Commonwealth single-player campaigns.  Added a time passage command for the timetable.dcg file; campaign designers can now set the time passage as required.  Added "slow" time passage (two missions/day).  Added a ban weapon type for IL2SC server operators.  This new command is available for the timetable.dcg file (see the "TestBed" campaign for the format).  


Additions to Version 3.30

Added tracking for player flying as gunners in coop missions; DCG will now track air kills and the number of missions flown by such players in the gunners.dcg file.  Players who fly both as gunner and pilot will have their gunner kills tallied together with their pilot scores in the pilot.dcg file as before.  Improved aces joining and transfering between squadrons.  Modified squadron.dat file to include players (and exclude AI pilots) if the mode is Coop or Dogfight.  Added pilot management for the player's squadron; a player can change the plane slot assignments of his squadron if the "Squadron Management" option is checked.  Added more options for the timetable.dcg file including payload changes from set dates as well as an add and remove squadrons functions and a remove column function.  Ground attack payloads set to "none" will prohibit any assignment of ground attack missions.  Added timetable option for movie tracks.  Tweaked interception code. Corrected date setting from the grand campaign file.  Fixed "not an integer bug" for (unneeded) number of sorties in on-line games.  Improved "Winter War" campaign.  Fixed the markings being reset to "yes" every mission.  


Additions to Version 3.29

Added a Normandy 1942 campaign which begins in August with the first missions of the USAAF over France.  Linked Normandy 1941, Normandy 1942, and Normandy 1944 campaigns.  Improved Crimea '41 campaign.  Fixed bug in bridge tracking which occurred when any language but English was active.  Fixed bug which would cause the campaign to reach 100% complete after only a few missions if the time passage was set to anything other than "normal".  Tweaked "airstart" code.  Fixed dogfight bug which was spawning full car columns for single vehicles.  Trains can now spawn at "Railyard" locations.  Added a column spawning parameter for the "timetable" file (uses the same record format of the columns.dcg).  Removed on-line campaign bug of double counting kills.


Additions to Version 3.28

Added new function for "Equipment" trains.  As well as repairing static objects and unloading troops and units, this type of train will also resupply armor units to full strength.  Added reprimand messages for the destruction of friendly ground units and ships.  Added static camera placement in master template missions.  Added a "(Distance) to Front" box on the Squadron Editor Panel that shows the distance from the squadron's airfield/carrier to the front's "center" location.  Renamed some "Mode" types and made DCG more intuitive in automatically activating certain features under certain modes.  Added options for IL2 Server Commander.  The server operator can now use the kick feature if plane limits are reached as well as set a time limit on the game length.  Fixed backup routines.  Reduced fuel of "off-map" squadrons to 50%.  Increased escort chances of fighter squadrons based "off-map".  Offset spawning point of armor units slightly to stop the overlap of those units during the first minutes of the mission.  


Additions to Version 3.27

Made Pe-2 and Pe-3 flyable as per the 4.05m add-on.  Added three-part Kurland campaign.  Reworked the Riga '41 and the "Winter War" campaign.  Minor changes to the Crimea '41 campaign.  Replaced gunit.dcg file with gobjects.dcg file which adds information on which version of the game supports which ground object.  If a ground object for a later version is in a campaign, it will be replaced by an object that is available based on the version of the game the user has.  Added a "Set Game Version" so that users can select which game/version they are using.  Altered backup system so that all backups reside in subfolders in the DCG folder rather than in their campaign folders (so allowing a clean delete of the campaign folders by the game when in DGen replace mode).  Fixed static aircraft bug; destroyed static aircraft were being removed from squadrons incorrectly.  Added red text warning on the "Squadron Editor Panel" when a downgrade aircraft is active.  Added an "end date" to aces squadron selection. Fixed dogfight bug where a player dying in any other position than the pilot's would crash the debriefing routine. Fixed "Set Enemy" routine. Removed chances of fighters escorting fighters (now fighters will only do sweeps over the target for fighters employed in a bomber role).  Added a unicode "decoder" for pilot names and the mission summaries in DCG. Added Russian messages (messages_ru.dcg) by Sergey.  Tweaked custom mission selection.  Modified squadron density factors so that it would be more random and maximums would be based on the number of aircraft per flight and not just the number of flights.  Added "bridges.dcg" to store damaged bridge states for non-standard bridges.  Added a "bug out radius" for campaign designers to set the distance at which enemy controlled locations will trigger a squadron to abandon an airfield.  Added automatic transfer of squadrons behind enemy lines when in Dogfight Mode.


Additions to Version 3.26

Added basic tracking of the player's bomber crew for "Full Auto-Generation" career mode; see the "Player's Crew" squadron document for crew information. Reduced time passage of "Moderate" to two days per mission and "Fast" to three days per mission - weather no longer influences. Any "bugout" mission must be flown no matter what the passage of time is. Added new "Balance" drop-down to allow user to set the balance of squadron activation each mission in favour of one side or the other (or leave it on the "default" or "balanced" settings). Added new "Squadron Documents" page showing information on all squadrons based at the player's airfield.  Factored end date of aircraft into the replacement formula. Corrected debrief messages where a squadron is using an alternate aircraft type. Restricted player squadron equipped with fighters without bombs/rockets from doing tank-busting missions.  Fixed division by zero error in flight plan calculation routines.  Fixed payloads for the Bf-109K-4C3. Updated Spanish messages (compliments of Rojo). Made improvements to briefing and debriefing text. Added code to permanently end a career campaign after the briefing announces it's over. Improved paint code to include custom DCG universal schemes for "second line" aircraft. Increased attacker locale maximum to 120. Added support for the import of [House] data from master templates. Campaign designers can now specify in the allcampaigns.dcg and grandcampaign.dcg files whether the campaign has day or night missions; this parameter is optional, can only be "Day" or "Night" and must appear immediately after the date parameter. Improvements made to the Ardennes campaign.  Added a campaign in North-West Germany (for RAF, RNZAF, and Luftwaffe).  Checking "Save Missions" while in Dogfight Mode will now keep unique missions for those running a dogfight campaign.  Improved pilot to squadron associations in Dogfight mode.  


Additions to Version 3.25

Expanded Crimea, Kursk, and Murmansk campaigns. Added six new German aces (compliments of JastaV). Added option to increase the passage of time between missions: Normal = 1 mission per day, Moderate = 2 to 4 days between missions, Fast = 3 to 6 days between missions. On days where there are no player missions, ground combat is resolved by DCG, and some AI pilots gain experience for flying "no contact" missions.  Added weekly aircraft replacement rates.  Reduced number of missions required for promotions. Modified ground combat so that armor will now pursue retreating forces. Improved chances of combat air patrols being available for carriers. Added Hungarian patrol boat from 4.04m patch. Reduced fuel percentage for heavy and medium bombers for distances under 200km. Reduced the visible bridge destruction to avoid mission loading errors. DCG will now import the V-1 rocket from campaign templates.  The launchers can never be permanently destroyed so they should always be placed in rear zones which can not be over-run by the enemy - otherwise they will appear behind enemy lines.  Added a column indicator of "B" ("Bridge Out") for columns blocked by a destroyed bridge. Improved anti-shipping patrols. Added "Default" as an option for flight sizes; with this setting, DCG will select the flight size based on nationality and year. Made server information textbox display for coop and dogfight modes (and not just FBDaemon missions).  Added "File" options to Import/Export campaigns for on-line players - all required files will be saved in a new folder and then passed on to another host who can drop the folder anywhere, import it, and generate a mission without worrying about modifying paths or not having the right files. Modified non-DGen/NGen campaign setup so that the campaign folder is now named after both the starting map and the nationality, for example, "BARBAROSSA_DE". Improved the victory options for FBDaemon dogfight mode.  Improved custom mission generation.


Additions to Version 3.24

Optimized code to generate missions faster. Fixed MAJOR bug in the bridge repair code; the bridges in build 3.23 would never repair.


Additions to Version 3.23

Added new planes from 4.03m patch. Enabled unique ace files for third-party campaigns. Fixed mission radio button bug which was causing a "" not an integer error. Added random option for the number of missons that a bridge will remain destroyed. Added code for bridge damage to show in missions in which it hasn't been repaired. Added a cities.dat file to allow users to modify the list of "home towns". Added code to support third-party name files for Russian, Romanian, and Italian pilots. Added single character flag in columns.dcg file to show movement state of the unit in the last mission: A = advanced, R = retreated, L = "landed" (spawned) or halted due to fuel shortage, C = in contact/combat, X = didn't spawn. Added optional start date to grandcampaign.dcg entries (after map); the campaign will skip to this date if it has not already been reached. Added ability to preset ace schemes through the acepaints.dcg file. NGen files for third party campaigns will automatically be created if the (NGen Replace) mode is selected after the third party campaign is selected; it will not work the other way around. Added the stationary "tanker" to the list of objects that contribute to oil supplies. Added fobjects.dcg file; this file will over-ride the stationary objects displayed at contested areas. Up to three types of units for each side can be assigned to each campaign. Fixed bug where flak was not always spawning at airstrips.


Additions to Version 3.22

Fixed plane selection routine for campaign generation; 1941 templates being used in later periods were not "upgrading" plane types. Added a repair time for bridges from between 1 to 9 missions which can be set by the player on the "Campaign Settings Panel". Separated the column and static object information and the Ground War information by adding a new "Column & Static Object Settings Panel". Fixed bug where mission results would be applied multiple times if the log did not contain a "Mission END" entry. Added a reinforcement supply (respawning) value for moving ground units based on the number of active static trucks vs the number of destroyed/inactive static trucks. The static trucks that can be used are: StudebeckerTruck, ZIS5_PC, Chevrolet_flatbed_US, DiamondT_US, Truck_Type94, OpelBlitz36S, OpelBlitz6700A. These are used in the same way as oil trucks and fuel cars (hidden in factories or placed in the open to look like a carpark). The bonus supply percentages can be set by the player in a specific campaign on the "Ground War Panel" (the default is 30%). Added option to set "radio silence" to any squadron. This can be set by the player on the "Squadron Editor Panel" or by a campaign designer in the campaign template file. Static planes can now have an allegiance of "None"; these will spawn no matter which side controls the airfield and will count towards losses for the side controlling the airfield. Added a "bornplace" radius slider on the "FBDaemon/Dogfight Panel". Players and server operators can now set the "bornplace" radius for dogfight missions. For "test runways", code has been added to set the "bornplace" to the coordinates of the "test runway" rather than the location coordinates. Added new "ace" information messages. Tightened the victory conditions for key locations; now the location must be captured to advance the campaign and not just contested. Fixed bug where a player in a two plane squadron wouldn't appear in the briefing. Czech language support enabled; messages_cz.dcg compliments of Rudidlo.


Additions to Version 3.21

Improved tracking of human players for coop and dogfight missions. Soft-coded maps so that campaign developers can now use the same map for multiple campaigns and in multiple directions. Soft-coded off-map locations in a new offmap.dcg file. Fixed rate of fire for ships in dogfight missions. Fixed airfield information in dogfight briefings. Corrected placement of invasion forces on first landing. Added function to prevent transport squadrons that have been reduced to no planes from resupplying bases. Added function to supply airfields with troops equal to the number of transport planes at the base. Improved rendezvous routine for bombers and escorts.  Improved spacing to reduce collisions during first few minutes of flight for units starting in the air. Correct airfield information for squadrons flying transfer missions. Added "shipyard" and paratroop "dropzone" location types; shipyards will spawn ships at the shipyard harbor and transport planes with a "level bombing" loadout of paratroopers will drop at dropzones. Added cloud cover message to briefing. Fixed tracking of damaged bridges and their impact on column and train movement.


Additions to Version 3.20

Added new planes and Russian armoured trains for the PF 4.02(m) patch. Added "_Port" as a sea route location type which allows the owning side (only) to land troops. Made "ports" able to host seaplane squadrons. Increased number of attacking locales to sixty (from nine). Added a campaign end check for ships; campaigns can now have a specific percentage of a specific ship type specified to end a campaign. Fixed "Random" altitude for player squadron. Fixed "Campaign Default" bug for ship's rate of fire. Fixed routine to add a new squadron to the campaign. Fixed G4M2E "Betty" spawn explosions. Made further fixes to the on-line dogfight naming convention for the class.dcg file. Fixed the update bug for the class.dcg file. Improved initial starting locations for squadrons. Improved squadron spawning routine. Corrected a route in the Balaton.rds file. Improved New Guinea sea routes. Support for the historical Singapore (1) map. Added support for the Post D-Day Normandy (1) map. Soft-coded weather and replacement announcement. Added loadouts for FW-200 Condor. 

Note: This version of DCG should not be installed over versions older than 3.01. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.01 will NOT work with this new version.  After installing, remember to reset your basic options and, if using either "Full Auto-Generation" modes, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.19

Added new "Full Auto-Generation" player defined feature: clicking on the "Globe" while having "Full Auto-Generation" mode active will allow users to select a nation/service and any available campaign in the active list. Clicking the start button will create the necessary data files for the campaign. Players can now create combinations not available in "Full Auto-Generation" mode such as flying with an RAF squadron in Crimea in 1944 or flying with a USAAF squadron in Malaysia in 1941. Look for the "* Player Defined DCG Campaign" in the game new career start screen. Other changes include: fixed campaign transfer bugs; both selection of the next campaign and the number of locations set to "attacker". Locked campaign transfers by the name of the campaign; the name of the map will nolonger impact the path of the campaigns. Fixed bug which was setting some fighter-bomber types to do escorts even when they were specifically assigned ground-attack missions by the player. Fixed lack of escorts from carriers. Fixed downgrade routine which was permanently assigning reserve plane choice as the squadron's main plane rather than a temporary replacement. Squadron Information screen now contains information on the reserve aircraft. Corrected a number of aircraft dogfight and paint scheme IDs so they will now activate properly. Frontline changes made to Lvov '41 campaign. To aid installation and set up, added check of registry for game path.


Additions to Version 3.18

Fixed pilot name bug. Added routine to prevent randomly created pilot names be duplicates. Improved enroute waypoints. Improved taskforce formations. Improved the starting location of squadrons when a new campaign is generated. Made test runways, heavy flak, oil cars and fuel trucks spawn no matter what the action radius is set at. Added more complexity to how the damaging of a bridge will impact tank, vehicles, and train movement.  Now the damaging of any bridge along a road or rail route will hold up tanks, vehicles, and/or trains. In addition, DCG will now select any bridge located between two enemy locations as a possible target. Fixed transit altitude settings bug. 


Additions to Version 3.17

This version of DCG supports FB+AEP+PF version 4.01m. Added the Spitfire Vc variants. Improved bomber formations (which have been made more difficult to keep formation with the 4.01 FM). Improved ground war and especially invasions. Fixed bug which prevented users from viewing Singapore missions in the Full Mission Builder. Fixed crash that occured when not using full Column Density settings. Fixed "too many aircraft on airdrome" bug caused by too many squadron trying to transfer at the same time. Excess now either start in the air or have a delayed start time depending on the user's selected option. The G4M2E can now deliver the "Ohka". Added maximum limit for troop values and set the default to 100. A new option exists in the Ground War Editor for the players/server operators to set the value. "AI Only" checked squadrons will no longer spawn planes in Dogfight mode. Ground units no longer spawn from trains which are in unfriendly territory and the trains are removed. Fixed the toggle setting Flyable/Non-Flyable on the Aircraft Class Panel. Fixed waypoint bug which was treating negative waypoints as bridge waypoints. Fixed transfer missions.


Additions to Version 3.16

This version of DCG supports FB+AEP+PF version 4.0m. Added new planes and ground units. Added New Zealand and Dutch services. Improved column movement. Added Riga 1941 campaign on new Kurland map. Added Singapore 1941 campaign and Murmansk 1941 campaign. Fixed player heavy/medium bomber bug where the lack of a suitable airfield would cause a lock-up in the mission generation. Added (abstract) troop limit value on the Ground War Editor panel.


Additions to Version 3.15

Improved multi-flight formations for bomber squadrons. Corrected density setting calculations for reconnaissance flights. When creating on-line campaigns, the off-line player persona will no longer be added to the lead squadron. Fixed news brief which said a truck was destroyed when it was actually a train. Added new "search & destroy" mission type for ground-attack squadrons. Added new briefing messages on troop concentrations. Added "random" cruise altitude setting for the player's squadron. Fixed bug that was allowing multiple columns to spawn from a single train or ship. Added new (optional) campaign victory conditions based on the destruction of a single stationary object type. Minor changes to the Smolensk and Moscow campaigns. Fixed eventlog parsing bug caused when the eventlog was so large, it was truncated by the game. Added "Camp" and "Depot" as specific location triggers acting similar to "Factory" locations for strategic bombing. Added ability to have more than one seaplane/floatplane squadron per base - additional ones will begin in the air or have a delayed start time.


Additions to Version 3.14

Improved multi-flight formations for dive-bomber and torpedo-bomber squadrons. Added payload selection feature to the Aircraft Class Editor panel. Fixed path bug to allcampaigns.dcg in Online Campaign mode. Stopped armor and trucks from initially spawning at a front that was over water. Fixed "Bridge crashed" bug. Fixed "downgrade" bug which was boasting the number of pilots and planes available in a squadron that was using its "downgrade" plane in a mission. Improved attack waypoint generation for anti-shipping strikes. 


Additions to Version 3.13

Added the ability to place columns from the campaign start based on their location in the master mission template file. Any column placed within 3 kilometers of the marker waypoint for a location (the first waypoint in the road/rail/sea network file) will begin the campaign at that location. Fixed bug that was repeating messages in the coop/dogfight debrief. Added nose art for American bombers. Added "key" locations to the endcampaign.dcg file so each side can have one location which, if captured, will end/advance the campaign. Added a retreat function for ground forces; if badly outnumbered, tank and vehicle units will now retreat. Fixed the location allegiance display bug. Minor changes to the OOB for Smolensk and Moscow. Increased the operating hours of campfires and lights and activated them in bad weather as well. Added optional Transit Speed setting by plane class. Split Rate of Fire settings for captial ships and others.


Additions to Version 3.12

Fixed bug in distance determining routine which impacts paratroop drops, determining the allegiance of railroad stations, harbours, etc. Fixed bug in 3rd Party file selection. Added a debrief message noting which squadron a human player flew for in Coop and Dogfight mode. Fixed some road network errors in Prokhorovka. Removed error message when generating a Full Auto-Generation campaign that would force user to close DCG using Task Manager; now the game will sound a "beep" and no campaign will be created. Added missing Iwo Jima template. Fixed bug that was resurrecting Axis shipping even when the "Ships Remain Sunk" option was checked. Removed drop tanks from CAP flights where the maximum action radius is under 400 kilometers.


Additions to Version 3.11

Added "Ships Remain Sunk" Option to prevent minor ships from respawning; all capital ships remain sunk even if this option is unchecked. Added "Active Front" Option; if checked, additional static front line defenses will spawn (as per usual); if unchecked, no additional static defenses will spawn. Added troop losses due to the destruction of static objects at a location - each friendly static object destroyed reduces the friendly troop numbers at that location by ten points. Added code to determine an "optimal" minimum action radius which is based on the player squadron's distance from the front line. This value will over-ride the player's "Action Radius Setting" if set radius is too small to generate an offensive mission. Added ability to have a unique paint file for 3rd Party campaigns. Allpaints.dcg has been moved from the root folder to the "Data" folder and users should copy their existing allpaints.dcg file into the "Data" folder if they have customized their skins in DCG. Dogfight mode is compatible with FBDaemon 2.4 available at http://www.greatergreen.com/.

Note: With versions older than 3.01, this version of DCG should not be installed over older versions. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.00 will NOT work with this new version.  After installing, remember to reset your basic options and, if using either "Full Auto-Generation" modes, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.10

Fixed campaign transfer. Fixed ship speeds. Fixed generation of Coral Sea scenario if called from a DGen campaign file. Added a time-triggered transfer: Normandy '41 to Normandy '44. Added a time-triggered transfer: from Germany '44 to Berlin '45. Added a time-triggered transfer: from Hungary '44 to Balaton '45. Fixed ID of the clip-winged Spitfire VIII. Added support for 3rd party messages in English, French, German and Spanish. Added Pearl Harbor "mini-campaign".


Additions to Version 3.09

Added skill settings for ships on the Campaign Settings Panel. Added rate of fire settings for ships on the Campaign Settings Panel. Fixed reset of custom campaign parameters. Added seasons to Finnish campaign. Replacement pilots are now at one rank lower than the pilot they are replacing. Fixed custom skin transfer from the master mission to the campaign. Added path display of pilot pictures as well as generic picture for photos where the compression isn't DCG compatible. Pilot experience is only applied to skill levels when "Squadron Defaults" are used. Transfers from one campaign to another are no longer limited by map and campaign but can be by specific "battle" now (for custom campaign designers). 

Note: With versions older than 3.01, this version of DCG should not be installed over older versions. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.00 will NOT work with this new version.  After installing, remember to reset your basic options and, if using either "Full Auto-Generation" modes, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.08

Fixed seaplane base bug where no seaplane base was being assigned (and crashing a player A6M2n "Rufe" campaign in the process). Added Tulagi campaign for USN. Fixed custom "radio button" bug that was causing "blue" briefing screens. Added Chichi Jima campaign. Added "mini" Russo-Finnish Winter War campaign. Added a Kyushu '45 campaign (same as the '44 campaign except that it's a five months later and the player can fly escort for the B-29s). Improved target selection for bombers. Added new (optional) "endcampaign.dcg" file to trigger campaign endings on a specific date. Added new campaign locations.dcg file.


Additions to Version 3.07

Added player control of transit altitude for all plane types on the "Aircraft Class Edit" panel and added options for 300 and 600 meter transit altitudes. Fixed bug for dedicated server campaign setup which gave no country/service option if the FBDaemon option was disabled. Fixed plane/pilot counts for dogfight missions using FBDaemon2. Added trains to dogfight missions. Tweaked New Guinea campaign. Added Marianas_Online map data (Guam '41 now uses this map). Added a USMC late Guadalcanal campaign. Added Kyushu campaign (IJA against B-29s). Removed delayed spawning of flights from off-map airfields. Added dropdown on the Custom Mission Panel to select the briefing screen background sounds. Added promotions and awards for human players in coop and dogfight mode (Track On-Line Players must be toggled in the Options). Removed restriction in coop mode that first squadron must always be active and must always have a human flyable plane. New, simplified process for using third party campaign data through a new "File" option. Improved Poland '39 campaign. Added RAF Polish squadrons. Added code for Daihatsu landing craft to act as transport.

Note: With versions older than 3.01, this version of DCG should not be installed over older versions. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.00 will NOT work with this new version.  After installing, remember to reset your basic options and, if using either "Full Auto-Generation" modes, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.06

The "test runways" and static carriers have been enabled for campaign builders - they must be included in the .rds or .srd files to be active. Improved escort rendezvous with escorted. Improved target selection for tank/truck/train busting and anti-shipping strikes. Enabled "kamikaze" missions. Kokutai 601 and the IJA "Flight Test Center" squadron have been designated "kamikaze" units and should not be used for any other purpose. Improved placement of static objects at contested locations. Simplified selection of supply/patrol routes. Added Iwo Jima and Okinawa campaigns. Fixed plane/pilot count bug for dogfight campaigns using FBDaemon. Added briefing sounds (only the "samples/sounds/Briefing2.wav" file is currently active). Disabled the out-dated import feature.


Additions to Version 3.05 

Fixed ranks (now display the correct nationality/service) in on-line briefings. Added Japanese invasion forces to Midway campaign. Fixed unwanted spawning of player bomber squadrons in air. Added "Seaplane_Base" as a recognizable airfield type. Made F2A Buffalo available as flyable in Midway campaign as per Pacific Fighters 3.03 release. Replaced CVEs with CVs in Marianas and Palau campaigns. Added check for pilot photos in game folders and if not found set them to the default photo. 

Note: With the exception of 3.01 or greater, this version of DCG should not be installed over older versions. Please make a clean install. Campaigns started with versions of DCG numbered less than 3.00 will NOT work with this new version.  After installing, remember to reset your basic options and, if using either "Full Auto-Generation" mode, make sure these options are re-checked before running FB/AEP/FP or FP.


Additions to Version 3.04 

Improved logic behind "Delayed Start Times", "Air Starts", and "Massed Bombers". Added carrier patrol areas for the Pacific Islands campaigns. Stopped problem of using LCVPs as aircraft carriers (CVs). Added Spanish messages. Added new routine for transfering squadrons to new campaign areas. Now only the player's squadron and squadrons named in the new campaign's master file are transfered. Added a Guam '41 campaign (for IJN pilot's who want to fly with no opposition). Linked Guam, Wake, and Guadalcanal campaigns together. Linked Coral Sea, Midway, and Santa Cruz together, and Tarawa, Marianas, and Palau together.


Additions to Version 3.03 

Improved player squadron mission selection. Expanded Marianas campaign. Added "Flying Tigers" to recognized squadron list. Fixed bug which was resetting columns' locations. Expanded Marianas campaign. Added Palau campaign. Updated Normandy campaign to use American destroyers from FP. Added B-24 to some Western Front campaigns. Stopped troops being stationed in enemy territory and at sea. Fixes "File Not Found" error in Coop Campaign mode. Added a "Campaign Aces" list for Full Auto-Generation mode in the "Squadron Document" section.


Additions to Version 3.02 

Fixed 356 Squadriglia being recognized as a Fleet Air Arm squadron. Increased taskforce speeds. Added new taskforce patrol area file (.prd) for carrier operations. Taskforces positions will be spawn within the patrol area based on a number of factors including the action radius. Removed extra waypoints from intercept missions. Added new option to disable FBDaemon connection if not being used. Added campaigns for Santa Cruz and Marianas (Saipan only). Added bombers to some USAAF campaigns. Added rockets and bombs to Yak-1 and Yak-7 variants. Corrected Corsair and P-40E dates. Fixed path routine to full auto-generation campaigns when getting debrief.


Additions to Version 3.01 

Fixed "File Not Found" bug when the first campaign is selected in DCG. Stopped transfers off of carriers. Added Tarawa - pre-invasion bombardment routes only at this point. Fixed missing Dogfight Mode homebases. Fixed date bug in armor upgrade routine. Fixed country names and ranks for France, Slovakia, and Romania. Reduced the number of squadrons able to spawn on a carrier. Fixed bad attack waypoint for ground-attack/anti-shipping strikes. Increase separation between bomber flights and have it maintained through attack points. Fixed tanks/trucks spawning on the wrong side of the front. Added routine to assign a player's navy squadron to a carrier if a carrier is present in the campaign.


Additions to Version 3.00

Reworked plane data from three tables into one (the original class.dcg) file. Available planes are determined by the plane folders found in the "Skin" directory and not by game version. Static planes now display correct markings. Moved all payload data from the class.dcg file into the payloads.dcg file. Fixed upgrade/downgrades so on the first mission of a change, the weapons for the new plane type are used and not for the original plane type. Added aircraft carriers - to start on a carrier, you must use a squadron associated with that carrier or manual transfer your squadron over after creating the campaign.  Added function so capital ships are permanently removed from a campaign. Because armor was not queen of the battlefield in the Pacific, added (in abstract) counts for troops as well. Tweaked anti-shipping strikes and activated medium/heavy bomber anti-shipping strikes. Moved the campaign front setting and supply zone settings to the Ground War panel. Added campaigns for Wake, Coral Sea, New Guinea, Guadalcanal, and Midway with the new services/nations required to fly them. When using DGen/NGen replace options, these new Pacific campaigns are found under "DCG" specified campaigns.  Note: the pilot images in Pacific Fighters are compressed in a format that DCG cannot read so they will not display on the DCG pilot panel. 


--------------------------------------------------------------------------------

Disclaimer 

All use of this program and its related files is at the user's own risk; this includes any hardware or software problems that you imagine are related to the installation of these files.  

As DCG for IL-2 is a work in progress, the creator does not guarantee it's functionality.  Nor will the creator accept any responsibility for any negative effect(s) it may have on your IL-2 game, your computer system, your enjoyment of IL-2, or your relationship with family and/or friends.  

Please report any bugs or send your comments/suggestions by email or post a message at the II/JG1 Forum in the DCG section.

This program was designed for the use and enjoyment of fellow IL-2 enthusiasts.  This package may not be hosted on the Internet or distributed on CD or DVD without the written permission of the author.


--------------------------------------------------------------------------------

Paul Lowengrin, October 26, 2009. 
http://www.lowengrin.com

