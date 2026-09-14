Tuning dynamic campaign generator
---------------------------------------------------

In accordance with your preferences and configration, you can  place the following lines in file conf.ini 
(all case sensitive):

1. Preferred distance to target

MissionDistance=nn, where nn is your preferred distance to target in kilometers. For instance:

MissionDistance=80

The request is not guaranteed to be fulfilled, if there are no suitable targets within the distance +/-30%, 
any target may be selected.

By default any target may be picked up.

2. Difficulty 

CampaignDifficulty=Easy
CampaignDifficulty=Hard

The default difficulty is medium

Changes your and enemy AI level

3. Air and ground intensity

AirIntensity=Low
AirIntensity=High
GroundIntensity=Low
GroundIntensity=High

Changes number of ground targets of opportunity, number and size of flight groups

Default air and ground intensity are medium
