<#PSScriptInfo

.VERSION 0.10   

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
Version 0.05:  Reformatted output to break it up by license types
Version 0.06:  Updated to show progress status in checking licenses
Version 0.11:  Updated to support the new SKUs for Meeting Room Pro license  2022-09-22
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
editied: 2022-09-22


#>

Clear-Host
Write-Host "Welcome to Meeting Room License Checker." 
Write-Host "This tool will look through your Exchange Online and AAD to find Room Mailbox UPNs."
Write-host "It will then report which rooms have MTR license, which have no license, and which have some other licenses" 
Write-Host





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
		$Prompt_EXOCreds = Connect-ExchangeOnline  -ShowBanner:$false
		write-host "Connected successfully to your Exchange Online"
	}
Catch
	{
		write-host "Unable to connect to your Exchange Online Environmnet"	
	}

Write-Host "Starting to search for Room Mailbox UPNs and their licenses..." 
[System.Collections.ArrayList]$No_License = @()
[System.Collections.ArrayList]$Non_MeetingRoom_License = @()
[System.Collections.ArrayList]$MeetingRoom_License = @()
[System.Collections.ArrayList]$MeetingRoomPro_License = @()
$Room_UPNs = get-mailbox | where {$_.recipientTypeDetails -eq "roomMailbox"} | select DisplayName, PrimarySmtpAddress, ExternalDirectoryObjectId

Write-Host $Room_UPNs.Length " were found." 
Write-Host 
Write-Host 
Write-Host "Searching for Rooms with licenses..."   #For a list of Product names and service plan identifiers for licensing, see https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference


$i,$x = 0,$Room_UPNs.count   #Setup for counting devices
if ($x -eq $null) {$x = 1}   #run through the loop at least once to print results, otherwise will get a divide/0 error
ForEach ($UPN in $Room_UPNs){
    Write-Progress -activity "Searching for Rooms with licenses..." -status "Scanned: $i of $x" -PercentComplete ((($i++)/ $x) * 100)
    $UPN_license =  Get-AzureADUserLicenseDetail -ObjectID $UPN.ExternalDirectoryObjectId | Select-Object -ExpandProperty SkuPartNumber
    
    $temp = [pscustomobject]@{'DisplayName'=$UPN.DisplayName;'UPN'=$UPN.PrimarySmtpAddress; 'Licenses'=$UPN_license} #pulls out the license from a UPN

    if ($null -eq $UPN_license) {$No_License.add($temp) | Out-Null}  #find rooms without licenses

    
    if ($UPN_license -like "MEETING_ROOM*") {$MeetingRoom_License.add($temp) | Out-Null}   #find rooms with legacy meeting room licenses
    
    if ($UPN_license -like "Microsoft_Teams_Rooms_*") {$MeetingRoomPro_License.add($temp) | Out-Null}   #find rooms with meeting room pro licenses
        
    if (($UPN_license -notlike "MEETING_ROOM*" ) -and ($UPN_license -notlike "Microsoft_Teams_Rooms_*" ) -and ($null -ne $UPN_license) ) {$Non_MeetingRoom_License.add($temp) | Out-Null}  #Check to make build other license list

    $temp = $null
     

}
Write-Host ""

Write-Host $No_License.count "Rooms without any licenses.  (Typically these would be bookable rooms without any Teams Meeting technology.)" -ForegroundColor Cyan
$No_License | Format-Table

Write-Host $MeetingRoom_License.count "Rooms with Legacy MTR Standard licenses." -ForegroundColor Yellow
$MeetingRoom_License | Format-Table

Write-Host $MeetingRoomPro_License.count "Rooms with MTR Pro licenses." -ForegroundColor Green
$MeetingRoomPro_License | Format-Table

Write-Host $Non_MeetingRoom_License.count "Rooms with licenses that do not include Teams Room Pro." -ForegroundColor Red
$Non_MeetingRoom_License | Format-Table

Write-Host "" 
Write-Host "Finished." 