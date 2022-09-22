# MeetingRoomLicenseChecker

I have publicly stated that the only license you should use on a Microsoft Teams Room System or Surface Hub is a Microsoft Teams Room License.
See https://www.linkedin.com/feed/update/urn:li:activity:6924332446909927425/

*But I had a customer ask me, how do I know if I have the right licenses applied to my devices?*

This powershell script will check Exchange Online for resource accounts that have a meeting room license or a user-type license (E3/E5/A3/A5/G3/G5) and
print out a table with the details.  It will also identify resource accounts that have no license applied (a room with no technology) as well. 

Note: This requires the user running it to have either Exchange Admin or Global Reader rights. (Of course, you could use a Global Admin role, but don't do that).

**Now updated to support Teams Room Pro licenses**  
See https://aka.ms/Sept6blog



Special thanks to Mark Hodge for helping out! 

Feel free to use & share.
