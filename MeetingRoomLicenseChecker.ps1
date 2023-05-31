﻿<#PSScriptInfo
.VERSION 0.25
.GUID 
.AUTHOR Peter Lurie, Mark Hodge
.COMPANYNAME Microsoft
.COPYRIGHT (c) 2022-2023 Peter Lurie & Mark Hodge
.TAGS Microsoft Teams Room System Surface Hub MEETING_ROOM for Resource Accounts
.LICENSEURI   https://creativecommons.org/licenses/by/4.0/?ref=chooser-v1
.PROJECTURI 
.ICONURI 
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
Version 0.23:  Updated to improve support for CSV output 
Version 0.24:  updating file/path UI
Version 0.25:  to filter on the server vs. local 
#>

<#
.SYNOPSIS
Reports out the list of resource accounts that have assigned licenses, highlighting the ones with Teams Meeting Room liceses in green
.DESCRIPTION
This script uses Graph Powershell & EXO to check for resource accounts and their licenses. 
.PARAMETER 
None
.NOTES
author: Peter Lurie
created: 2022-05-10
editied: 2023-05-30
#>

Function Get-SaveFilePath ([string]$initialDirectory) {  #prompts for filename and path for exporting to CSV, if needed

	Add-Type -AssemblyName System.Windows.Forms
	$SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
	$SaveInitialPath = ".\"
	$SaveFileName = "TeamsMeetingRoomLicenses.csv"
    $SaveFileDialog.initialDirectory = $SaveInitialPath #Sets current starting path
    $SaveFileDialog.filter = "CSV (*.csv)| *.csv"   	#Restricts to CSV by default
	$SaveFileDialog.FileName = $SaveFileName   			#Default filename 
    
	$SaveFileDialog.ShowDialog()   #actually asks for the filepath
	return $SaveFileDialog.filename #Returns filepath for writing to CSV
}

Clear-Host
Write-Host
Write-Host "Welcome to Meeting Room License Checker." -ForegroundColor Green
Write-Host
Write-Host "This tool will look through your Exchange Online and AAD to find Resource Account Mailbox UPNs."
Write-host "It will then report which resource accounts have Teams Room licenses, which have no license, and which have some other licenses"
Write-host "This is ver 0.25." 
Write-Host


#Setup for Graph
Write-Host "Loading Microsoft Graph Modules" 
If (!(Get-Module -listavailable | Where-Object {$_.name -like "*Microsoft.Graph.Users*"})) 
	{ 
		Install-Module Microsoft.Graph.Users  #-ErrorAction SilentlyContinue 
	} 
Else 
	{	Import-Module Microsoft.Graph.Users  #-ErrorAction SilentlyContinue 
	} 
Try
	{	write-host "Getting ready to connect to the Microsoft Graph" 
        Connect-MgGraph -Scopes "User.Read.All"
		write-host "Connected successfully the Microsoft Graph" -ForegroundColor Green
	}
Catch
	{	write-host "Unable to connect to your Microsoft Graph Environment"	-ForegroundColor Red
	}

Write-Host 
Write-Host "Getting ready to connect to Exchange Online." -ForegroundColor Green
If (!(Get-Module -listavailable | Where-Object {$_.name -like "*ExchangeOnlineManagement*"})) 
	{ 	Install-Module ExchangeOnlineManagement  -ErrorAction SilentlyContinue 
	} 
Else 
	{ 	Import-Module ExchangeOnlineManagement  -ErrorAction SilentlyContinue 
	} 
Try
	{	write-host "Connecting to your Exchange Online instance"
        Connect-ExchangeOnline  -ShowBanner:$false #Note if using GCC, DOD, or a soverign cloud, see docs for this command for the correct -ExchangeEnvironmentName.  Default is Commerical cloud
		write-host "Connected successfully to your Exchange Online"  -ForegroundColor Green
	}
Catch
	{	write-host "Unable to connect to your Exchange Online Environment"	 -ForegroundColor Red
	}

Write-Host 
Write-Host "Starting to search for Resource Account Mailbox UPNs and their licenses..." -ForegroundColor Green
$StartElapsedTime = $(get-date)
[System.Collections.ArrayList]$No_License = @()
[System.Collections.ArrayList]$MTR_Premium_License = @()    # Also includes MMR1 license
[System.Collections.ArrayList]$MeetingRoom_License = @()   #Teams Meeting Room Standard license
[System.Collections.ArrayList]$MeetingRoomPro_License = @()  #Optimal license
[System.Collections.ArrayList]$MeetingRoomBasic_License = @()  #Basic license does max out at 25 licenses/tenant
[System.Collections.ArrayList]$MeetingRoomOther_License = @()  #Licenses OTHER than what should be applied to a Teams Room Resource Account
$Report = [System.Collections.Generic.List[Object]]::new()

#Updated to filter server side and not client side.  See next line for new filter. 
#$Room_UPNs = get-mailbox | Where-Object {$_.recipientTypeDetails -eq "roomMailbox"} | Select-Object DisplayName, PrimarySmtpAddress, ExternalDirectoryObjectId  

$Room_UPNs = Get-ExoMailbox -Filter {recipientTypeDetails -eq "RoomMailbox" } | Select-Object DisplayName, PrimarySmtpAddress, ExternalDirectoryObjectId 
Write-Host $Room_UPNs.Length " were found." -ForegroundColor Green
Write-Host "Note that resource accounts can contain 0 or multiple licenses. As such, the total of all licenses discovered may be different than the number of resource accounts" -ForegroundColor Yellow
Write-Host 

$i,$x = 0,$Room_UPNs.count   #Setup for counting devices
if ($null -eq $x) {$x = 1}   #run through the loop at least once to print results, otherwise will get a divide/0 error
# Note that resource accounts can contain multiple licenese.  As such, the sum of all licenses may exceed the number of resource accounts

ForEach ($UPN in $Room_UPNs){
    $i++
	Write-Progress -activity "Searching for resource accounts with licenses..." -status "Scanned: $i of $x" 
    $UPN_license =  Get-MgUserLicenseDetail -UserID $UPN.ExternalDirectoryObjectId | Select-Object -ExpandProperty SkuPartNumber
    $temp = [pscustomobject]@{'DisplayName'=$UPN.DisplayName;'UPN'=$UPN.PrimarySmtpAddress; 'Licenses'=$UPN_license -join ", "} #pulls out the license from a UPN

    if ($null -eq $UPN_license) {$No_License.add($temp) | Out-Null}  #find resource accounts without licenses

	if ($UPN_license -like "MTR_PREM*" -or $UPN_license -like "MMR_P*" ) {$MTR_Premium_License.add($temp) | Out-Null}   #find resource accounts with legacy MTR Premium  
    if ($UPN_license -like "MEETING_ROOM*") {$MeetingRoom_License.add($temp) | Out-Null}   #find resource accounts with legacy Teams Room Standard licenses
    if ($UPN_license -like "Microsoft_Teams_Rooms_Pro*") {$MeetingRoomPro_License.add($temp) | Out-Null}   #find resource accounts with meeting room pro licenses
	if ($UPN_license -like "Microsoft_Teams_Rooms_Basic*") {$MeetingRoomBasic_License.add($temp) | Out-Null}   #find resource accounts with meeting room basic licenses

    if (!(($UPN_license -like "MEETING_ROOM*" ) -or ($UPN_license -like "Microsoft_Teams_Rooms_*" ) -or ($UPN_License -like "MTR_PREM") -or ($UPN_License -like "MMR_P1")-or ($null -eq $UPN_license) ))  {$MeetingRoomOther_License.add($temp) | Out-Null}  #If there are resource accounts that have other licenses, add them too.

    $Report.Add($temp)   #Creating the file for the CSV, if needed later

    $temp = $null
   	}

   

    Write-Progress -Completed -activity "Searching for resource accounts with licenses..."

Write-Host

Write-Host $No_License.count "Resource accounts without any licenses.  (Typically these would be bookable rooms without any Teams Meeting technology or resource accounts yet to be licensed.)" -ForegroundColor Cyan
$No_License | Sort-Object UPN | Format-Table  
Write-Host 
Write-Host 
Write-Host $MeetingRoom_License.count "resource accounts with Legacy Teams Room Standard licenses. (Typically, these licenses should be upgraded to Teams Room Pro at EA Renewal)." -ForegroundColor Yellow
$MeetingRoom_License | Sort-Object UPN | Format-Table
Write-Host 
Write-Host 
Write-Host $MTR_Premium.count "Resource accounts with Teams Room Premium or MMR license. (Typically, these licenses should be migrated to Teams Room Pro at EA Anniversary/Renewal)." -ForegroundColor Red
$MTR_Premium | Sort-Object UPN | Format-Table
Write-Host 
Write-Host 
Write-Host $MeetingRoomPro_License.count "Resource accounts with MTR Pro licenses." -ForegroundColor Green
$MeetingRoomPro_License | Sort-Object UPN | Format-Table
Write-Host 
Write-Host 
Write-Host $MeetingRoomBasic_License.count "Resource accounts with Teams Room System Basic licenses." -ForegroundColor Green
$MeetingRoomBasic_License | Sort-Object UPN | Format-Table
Write-Host 
Write-Host 
Write-Host $MeetingRoomOther_License.count "Resource accounts with licenses other than Teams Room System licenses. (Confirm if these licenses are actually needed)." -ForegroundColor Yellow
$MeetingRoomOther_License | Sort-Object UPN | Format-Table
Write-Host 
Write-Host 

$elapsedTime = $(get-date) - $StartElapsedTime
$totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
Write-Host "Processing took $totalTime."  -ForegroundColor Green
Write-Host 
Write-Host
$answer = read-host -prompt "Do you want to export results to a CSV file?  [y/N]"
If ($answer.ToLower() -eq 'y' ) 
	{
		try {
			$SaveMyFile = Get-SaveFilePath    #Use Get-SaveFilePath function to prompt for filepath information
			$Report |  Sort-Object  UPN  | Export-CSV -Path $SaveMyFile[1] -NoTypeInformation  
			Write-Host "Results Saved." -ForegroundColor green
		}
		catch {
			Write-Host "Unable to save CSV" -ForegroundColor red
			}
	}

	Write-Host 
	Write-host "Note: MgGraph and ExchangeOnline connections were not disconnected.  Use Disconnect-ExchangeOnline and Disconnect-MgGraph if needed."  -ForegroundColor yellow
	Write-Host 
	Write-Host "Done" -ForegroundColor Green