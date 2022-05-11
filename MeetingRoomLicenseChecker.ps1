<#PSScriptInfo

.VERSION 0.04

.GUID 

.AUTHOR Peter Lurie, Mark Hodge

.COMPANYNAME Microsoft

.COPYRIGHT (c) 2022 Peter Lurie & Mark Hodge

.TAGS Microsoft Teams Room System Surface Hub MEETING_ROOM

.LICENSEURI 
https://creativecommons.org/licenses/by/4.0/?ref=chooser-v1

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Version 0.01:  Quick and dirty build
Version 0.02:  Added error checking and status reporting. Changed to use the current version of ExchangeOnlineManagement 
Version 0.03:  Added support for both Enterprise Premium and Enterprise Pack licenses
Version 0.04:  Fixed spelling & grammar. 

#>

<#
.SYNOPSIS
Reports out the list of resource accounts that have assigned licenses, highlighting the ones with Teams Meeting Room liceses in green
.DESCRIPTION
This script uses AAD & EXO to check for resource accounts and their licenses. 
.PARAMETER 
None


.NOTES
author: Peter Lurie
created: 2022-05-10
editied: 2022-05-11

#>

Clear-Host

#Setup for AAD & ExchangeOnLine V2 EXO V2
Write-Host "Getting ready to connect to AzureAD" 
If (!(Get-Module -listavailable | where {$_.name -like "*AzureAD*"})) 
	{ 
		Install-Module AzureAD -ErrorAction SilentlyContinue 
	} 
Else 
	{ 
		Import-Module AzureAD -ErrorAction SilentlyContinue 
	} 

Try
	{
		$Ask_Creds = Connect-AzureAD
		write-host "Connected successfully to your tenant"
	}
Catch
	{
		write-host "Unable to connect to yourtenant"	
	}



Write-Host "Getting ready to connect to Exchange Online" 
If (!(Get-Module -listavailable | where {$_.name -like "*ExchangeOnlineManagement*"})) 
	{ 
		Install-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue 
	} 
Else 
	{ 
		Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue 
	} 
	
Try
	{
		$Prompt_EXOCreds = Connect-ExchangeOnline
		write-host "Connected successfully to your Exchange Online"
	}
Catch
	{
		write-host "Unable to connect to your Exchange Online Environmnet"	
	}


Write-Host "Starting to search for Room Mailbox UPNs and their licenses..." 
$Room_UPNs = Get-EXOMailbox | where {$_.recipientTypeDetails -eq "roomMailbox"} | select DisplayName, PrimarySmtpAddress, ExternalDirectoryObjectId
Write-Host $Room_UPNs.Length " were found." 

Write-Host 
Write-Host 
Write-Host "Searching for Rooms with licenses..."   #For a list of Product names and service plan identifiers for licensing, see https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference
Write-Host "Format = DisplayName, UPN, Licenses.  Green = Teams Meeting Room license was found.  Red = E3/E5/G3/G5/A3/A5 license found"
ForEach ($UPN in $Room_UPNs){

    $UPN_license =  Get-AzureADUserLicenseDetail -ObjectID $UPN.ExternalDirectoryObjectId | Select-Object -ExpandProperty SkuPartNumber
    
    if ("MEETING_ROOM" -in $UPN_license) {  #Note with this IF/Else construct, we are intentionally excluding rooms without licenses -- rooms that have neither an E/A/G-type license nor a Meetingroom license. We can expect these to be rooms without MTRs or Hubs in them  
        write-host $UPN.DisplayName,  $UPN.PrimarySmtpAddress, $UPN_license -ForegroundColor Green   #This means the MeetingRoom license was found in the room
    }
    Else {
       If (("ENTERPRISEPACK" -in $UPN_license) -or  ("ENTERPRISEPREMIUM" -in $UPN_license)) {    
        write-host $UPN.DisplayName, $UPN.PrimarySmtpAddress, $UPN_license -ForegroundColor Red   #This means that E3/E5/A3/A5/G3/G5 license was found in the room and probably isn't necessary
       }
     }


}

write-host "A grand total of" $Room_UPNs.Length "mailboxes were found, including those with no licenses applied. " 

Write-Host "Done." 