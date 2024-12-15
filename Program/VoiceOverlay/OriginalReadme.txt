Voice Overlay Alpha 1.1
-----------------------

This is a tool where you can see INGAME who is speaking in your Teamspeak2 or Ventrilo program.
It simply writes status information and the names of speaking players in front of your screen.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Use at your own risk, it is still Alpha Status
I am not responsible for any hardware failures or game bans or crashes or sth. like that
Just use at your own risk
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

If you need help just visit one of the following sites in the forums you can find in the About Dialog.
Don't spam or lame me, or you won't get any support.

* push the red button to enable
* tested with ventrilo 2.2 and Teamspeak 2
* support for directX8, directX9 and OpenGL
* tested with Cheating Death (CS1.6) and AntiTCC (Unreal2004 / Red Orchestra) and some Punkbuster games (BF1942, Enemy Territory, BF2 Demo)
* muliple playernames with ShortcutMaker
* Minimize to systemtray

Bugfixes Alpha1.1
-----------------
* shows up correct subchannel in Teamspeak
* Punkbuster does not kick in Battlefield2 when you have enabled the workaround (use ShortcutMaker to get a shortcut with workaround enabled)
  Caution: when running VoiceOverlay with BF2 workaround enabled, no directX8 games will work... start version without workaround to use dx8 games
* fixed "not showing" players at the end of a ventrilo / teamspeak tree when they join / leave a channel
* shows channel commanders speaking too
* fixed join / leaf problems when there are more subchannels with the same name
* fixed opengl textposition calculation
* now users can have special characters like ² or ³ in their names
* works with Guild wars and World of Warcraft

Options:
--------
* choose the font you wish
* 8 different text positions possible
* select your colors for every texttype
* Channel: shows the channel you are in
* Status: gives you information about to which program you are connected
* Show me speaking: shows your name when speaking too
* Show all: shows players if they are in your channel or not
* shadow: just a little shadow behind the text for more contrast
* You name: you must set your name you are using in the voice communication program. Careful: it is case sensitive!!

Command line options if you wish to make a link:
------------------------------------------------
* -enable: the program is enabled at startup (that red button)
* -minimize: starts the program in systray
* -name "xxx": sets playername on startup
* -bf2: enables the Battlefield2 workaround so wo will not be kicked from PB

Tested games:
-------------
* Counter-Strike 1.6
* Counter-Strike Source
* UT2004
    - Red Orchestra (MOD)
* Empire Earth 2
* Battlefield 1942
* Battlefield 2 Demo
* Battlefield 2 Fullversion
* Enemy Territory

AntiCheat Progz
---------------
* seems to work with CD
* as far the steam support said it should work wit VAC/VAC2
* not sure if it works with Punkbuster, but i had no problems with BF1942 and BF2 Demo and Enemy Territory

Known bugs
----------
* when you use the omega drivers you must disable the ati tray tools, else some games might crash
* won't work with other hooking applications like fraps atm
* BF2 Demo crashs after shutdown
* you can't see teamspeak users talking who have disabled their phones (because there is a different icon then)
* game will crash if you close VoiceOverlay during playing (while gone with ALT+TAB to windows)

Homepage
--------
www.voiceoverlay.info.ms
www.voice-overlay.info.ms