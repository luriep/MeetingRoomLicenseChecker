# MeetingRoomLicenseChecker

I have publicly stated that the only license you should use on a Microsoft Teams Room System or Surface Hub is a Microsoft Teams Room License.
See https://www.linkedin.com/feed/update/urn:li:activity:6924332446909927425/
But I had a customer ask me, how do I know if I have the right licenses applied to my devices?  

This powershell script will check Exchange Online for resource accounts that have a meeting room standard license (or have a E3/E5/A3/A5/G3/G5-type license) and
report them back as red (wrong license) or green with the proper one. 

Special thanks to Mark Hodge for helping out! 
