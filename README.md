# MeetingRoomLicenseChecker

As Microsoft is continuing to improve capabilities in Microsoft Teams, it is becoming more critical to understand the specific licenses in your environment.   While you can go in to each room to see what licenses are appliend, I recently had a customer ask me *how do I know if I have the right licenses applied to my devices?*


This powershell script will check Exchange Online for resource accounts that have a meeting room license or a user-type license (E3/E5/A3/A5/G3/G5) and
print out a table with the details.  It will also identify resource accounts that have no license applied (a room with no technology) as well. 

Note: The script requires either Exchange Admin or Global Reader rights. (Of course, you could use a Global Admin role, but don't do that).

**Now updated to support Teams Room Pro licenses**  
See https://aka.ms/Sept6blog

**Now updated to use Microsoft.Graph.User instead of AzureAD modules**  

Special thanks to Mark Hodge for some of the early examples of this code. 

Feel free to use & share.
