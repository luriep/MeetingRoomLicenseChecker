# MeetingRoomLicenseChecker

As Microsoft is continuing to improve capabilities in Microsoft Teams, it is becoming more critical to understand the specific licenses in your environment.   While you can go in to each room to see what licenses are appliend, I recently had a customer ask me *how do I know if I have the right licenses applied to my devices?*


This powershell script will check Exchange Online for resource accounts that have a meeting room license or a user-type license (E3/E5/A3/A5/G3/G5) and
print out a table with the details.  It will also identify resource accounts that have no license applied (a room with no technology) as well. 

Note: The script requires  Exchange Admin (recommended) or Global Reader (recommended)  or Global Admin rights. It only reads data, it does not make any changes to the environment.


Note:  This has not been tested in Microsoft 365 GCC, Microsoft 365 GCC High, Microsoft 365 DoD, O365GermanyCloud or Office 365 operated by 21Vianet

Feel free to use & share.
