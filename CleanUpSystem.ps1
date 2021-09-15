#!/usr/bin/env pwsh
####
# Cleanup Window System
####
# @see:
#   https://github.com/Bromeego/Clean-Temp-Files/blob/master/Clear-TempFiles.ps1
#   https://gist.github.com/synikil/47784f432979d97e5dc1181349e1e591
# @since 2021-04-06
# @author stev leibelt <artodeto@bazzline.net>
####

Function Create-TruncableObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $false)]
        [int]$daysToKeepOldFiles = 1,

        [Parameter(Mandatory = $false)]
        [bool]$checkForDuplicates = $false,

        [Parameter(Mandatory = $false)]
        [int]$checkForDuplicatesGreaterThanMegabyte = 64
    )

    Write-Host ":: Please update your configuration. >>Create-TruncableObject<< is deprecarted and has to be replaced with >>New-TruncableObject<<. This function will be deleted at 31.12.2021."

    New-TruncableObject $path $daysToKeepOldFiles $checkForDuplicates $checkForDuplicatesGreaterThanMegabyte
}

Function New-TruncableObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $false)]
        [int]$daysToKeepOldFiles = 1,

        [Parameter(Mandatory = $false)]
        [bool]$checkForDuplicates = $false,

        [Parameter(Mandatory = $false)]
        [int]$checkForDuplicatesGreaterThanMegabyte = 64
    )

    $properties = @{
        path = $path
        days_to_keep_old_file = $daysToKeepOldFiles
        check_for_duplicates = $checkForDuplicates
        check_for_duplicates_greater_than_megabyte = $checkForDuplicatesGreaterThanMegabyte
    }
    $object = New-Object psobject -Property $properties

    return $object
}

Function New-LockFileOrExit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$lockFilePath,

        [Parameter(Mandatory = $true)]
        [string]$logFilePath,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    If (Test-Path $lockFilePath) {

        Write-Host ":: Lock file exists. Maybe an previous run was stopped or is crashed."
        $YesOrNo = Read-Host -Prompt "   Should I remove it? (y|N)"

        If ($YesOrNo.StartsWith("y") -eq $true) {
            Write-DebugLog $logFilePath "Removing existing lock file >>${lockFilePath}<< after asking the user." $beVerbose

            Remove-Item -Path $lockFilePath
        } Else {
            Write-Error ":: Error"
            Write-Error "   Could not aquire lock, lock file >>${lockFilePath}<< exists."
            Write-ErrorLog $logFilePath "Could not aquire lock. Lock file >>${lockFilePath}<< exists." $beVerbose

            Exit 1
        }
    }

    New-Item -ItemType File $lockFilePath
    Set-Content -Path $lockFilePath -Value "${PID}"

    Write-DebugLog $logFilePath "Lock file create, path >>${lockFilePath}<<, content >>${PID}<<" $beVerbose
}

Function Remove-LockFileOrExit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$lockFilePath,

        [Parameter(Mandatory = $true)]
        [string]$logFilePath,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    If (Test-Path $lockFilePath) {
        $lockFilePID = Get-Content -Path $lockFilePath

        If ($lockFilePID -eq $PID ){
            Remove-Item -Path $lockFilePath

            Write-DebugLog $logFilePath "Lock file removed, path >>${lockFilePath}<<" $beVerbose
        } Else {
            Write-Error ":: Error"
            Write-Error "   Lockfile in path >>${lockFilePath}<< contains different PID. Expected >>${PID}<<, Actual >>${lockFilePID}<<."
            Write-ErrorLog $logfilePath  "Lockfile in path >>${lockFilePath}<< contains different PID. Expected >>${PID}<<, Actual >>${lockFilePID}<<." $beVerbose
        }

        Exit 1
    } Else {
        Write-Error ":: Error"
        Write-Error "   Could not release lock. Lock file >>${lockFilePath}<< does not exists."
        Write-ErrorLog $logfilePath "Could not release lock. Lock file >>${lockFilePath}<< does not exists." $beVerbose

        Exit 2
    }
}


Function Get-LogFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path
    )

    If (!(Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path $path
    }

    $date = Get-Date -Format "yyyyMMdd"
    $pathToTheLogFile = '{0}\{1}_{2}.log' -f $path,$env:computername,$date

    return $pathToTheLogFile
}

Function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $true)]
        [int]$logLevel = 3,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    If ($logLevel -ge $globalLogLevel) {
        Switch ($logLevel) {
            0 { $prefix = "[Trace]" }
            1 { $prefix = "[Debug]" }
            2 { $prefix = "[Information]" }
            3 { $prefix = "[Warning]" }
            4 { $prefix = "[Error]" }
            5 { $prefix = "[Critical]" }
            default { $prefix = "[None]" }
        }
        $dateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        $logLine = '{0}: {1} - {2}' -f $dateTime,$prefix,$message

        Add-Content -Path $path -Value $logLine

        If ($beVerbose) {
            Write-Host $logLine -ForegroundColor DarkGray
        }
    }
}

Function Write-DebugLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    Write-LogMessage $path $message 1 $beVerbose
}

Function Write-InfoLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    Write-LogMessage $path $message 2 $beVerbose
}

Function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    Write-LogMessage $path $message 4 $beVerbose
}

Function Create-DiskInformation 
{

    $logicalDisk = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" }

    $totalSizeInGB = "{0:N1}" -f ( $logicalDisk.Size / 1gb)
    $freeSizeInGB = "{0:N1}" -f ( $logicalDisk.Freespace / 1gb )
    $freeSizeInPercentage = "{0:P1}" -f ( $logicalDisk.FreeSpace / $logicalDisk.Size )

    $properties = @{
        device_id = $logicalDisk.DeviceId
        total_size_in_gb = $totalSizeInGb
        free_size_in_gb = $freeSizeInGB
        free_size_in_percentage = $freeSizeInPercentage
    }
    $object = New-Object psobject -Property $properties

    return $object
}

Function Create-StatisticObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.TimeSpan]$runDatetime,

        [Parameter(Mandatory = $true)]
        [int]$numberOfRemovedFileSystemObjects,

        [Parameter(Mandatory = $true)]
        [object]$startDiskInformation,

        [Parameter(Mandatory = $true)]
        [object]$endDiskInformation
    )

    $startFreeSizeInGB = $startDiskInformation.free_size_in_gb -replace ",", "."
    $endFreeSizeInGB = $endDiskInformation.free_size_in_gb -replace ",", "."

    $properties = @{
        runtime = @{
            hours = $runDatetime.Hours
            minutes = $runDatetime.Minutes
            seconds = $runDatetime.Seconds
        }
        disk = @{
            number_of_removed_file_system_objects = $numberOfRemovedFileSystemObjects
            freed_up_disk_space = ($endFreeSizeInGB - $startFreeSizeInGB)
        }
    }

    $object = New-Object psobject -Property $properties

    return $object
}

Function Delete-RecycleBin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $logFilePath,

        [Parameter(Mandatory = $false)]
        [bool] $beVerbose = $false
    )

    Write-InfoLog $logFilePath ":: Starting deletion of recycle bin." $beVerbose

    $IsOlderThanWindowsServer2016 = ( [System.Environment]::OSVersion.Version.Major -lt 10 );

    If ( $IsOlderThanWindowsServer2016 -eq $true ) {
        If ($beVerbose -eq $true) {
            Start-Process -FilePath rd -ArgumentList '/s' '/q' 'C:\$Recycle.Bin' -Wait
        } Else {
            Start-Process -FilePath rd -ArgumentList '/s' 'C:\$Recycle.Bin' -Wait
        }
    } Else {
        If ($beVerbose -eq $true) {
            Clear-RecycleBin -Force -Verbose
        } Else {
            Clear-RecycleBin -Force
        }
    }

    Write-InfoLog $logFilePath ":: Finished deletion of recycle bin." $beVerbose
}

Function Write-DiskspaceLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [object]$diskInformation,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    $message = "Drive: {0}, Total Size (GB) {1}, Free Size (GB) {2}, Free size in percentage {3}" -f $diskInformation.device_id, $diskInformation.total_size_in_gb, $diskInformation.free_size_in_gb, $diskInformation.free_size_in_percentage

    Write-InfoLog $path $message $beVerbose
    
}

Function Write-StatisticLog
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [object]$statisticObject,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    Write-InfoLog $path ":: Statistics ::" $beVerbose

    $message = "   Runtime: Hours >>{0}<<, Minutes >>{1}<<, Seconds >>{2}<<." -f $statisticObject.runtime.hours, $statisticObject.runtime.minutes, $statisticObject.runtime.seconds
    Write-InfoLog $path $message $beVerbose

    $message = "   Freed up disk space >>{0}<< Number of removed file system objects >>{1}<<." -f $statisticObject.disk.freed_up_disk_space, $statisticObject.disk.number_of_removed_file_system_objects
    Write-InfoLog $path $message $beVerbose
}


Function Start-CleanUpSystem
{
    #bo: variable definition
    $currentDate = Get-Date -Format "yyyyMMdd"
    $collectionOfTruncableObjects = New-Object System.Collections.ArrayList
    $globalConfigurationFilePath = ($PSScriptRoot + "\data\globalConfiguration.ps1")
    $localConfigurationFilePath = ($PSScriptRoot + "\data\localConfiguration.ps1")

    #We have to source the files here and not via a function.
    #  If we would source the files via a function, the sourced in variables would exist in the scope of the function only.
    If ((Test-Path $globalConfigurationFilePath)) {
        . $globalConfigurationFilePath
    }

    If ((Test-Path $localConfigurationFilePath)) {
        . $localConfigurationFilePath
    }

    $logFilePath = Get-LogFilePath $logDirectoryPath
    #eo: variable definition

    #bo: clean up
    $startDateTime = (Get-Date)
    $startDiskInformation = Create-DiskInformation

    New-LockFileOrExit $lockFilePath $logFilePath $beVerbose

    Write-DiskspaceLog $logFilePath $startDiskInformation $beVerbose

    #disable windows update service to enable cleanup of >>c:\windows\softwaredistribution<<
    Get-Service -Name wuauserv | Stop-Service -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose

    #  bo: manipulating the file system
    $numberOfRemovedFileSystemObjects = Start-PathTruncations $collectionOfTruncableObjects $logFilePath $beVerbose

    If ($deleteRecycleBin -eq $true) {
        Delete-RecycleBin $logFilePath $beVerbose
    }

    If ($startDiskCleanupManager -eq $true) {
        Start-DiskCleanupManager $logFilePath $beVerbose
    }
    #  eo: manipulating the file system

    $runDateTime = (Get-Date).Subtract($startDateTime)

    $endDiskInformation = Create-DiskInformation

    $statisticObject = Create-StatisticObject $runDatetime $numberOfRemovedFileSystemObjects $startDiskInformation $endDiskInformation

    Write-DiskspaceLog $logFilePath $endDiskinformation $beVerbose

    Write-StatisticLog $logFilePath $statisticObject $beVerbose

    #enable windows update service
    Get-Service -Name wuauserv | Start-Service -ErrorAction SilentlyContinue

    Remove-LockFileOrExit $lockFilePath $logFilePath $beVerbose
    #eo: clean up
}

Function Start-DiskCleanupManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $logFilePath,

        [Parameter(Mandatory = $false)]
        [bool] $beVerbose = $false
    )

    Write-InfoLog $logFilePath ":: Starting system disk cleanup manager." $beVerbose

    #@see: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/cleanmgr
    If ($beVerbose -eq $true) {
        Start-Process -FilePath Cleanmgr -ArgumentList '/sagerun:1', '/VERYLOWDISK' -Wait -Verbose
    } Else {
        Start-Process -FilePath Cleanmgr -ArgumentList '/sagerun:1', '/verylowdisk' -Wait
    }

    Write-InfoLog $logFilePath ":: Finished system disk cleanup manager." $beVerbose
}

Function Start-PathTruncation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [int]$daysToKeepOldFile,

        [Parameter(Mandatory = $true)]
        [bool]$checkForDuplicates,

        [Parameter(Mandatory = $true)]
        [int]$checkForDuplicatesGreaterThanMegabyte,

        [Parameter(Mandatory = $true)]
        [string]$logFilePath,

        [Parameter(Mandatory = $true)]
        [int]$numberOfRemovedFileSystemObjects,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false,

        [Parameter(Mandatory = $false)]
        [bool]$isDryRun = $false
    )

    $DisplayProgessBar = ($beVerbose -ne $true)
    $processPath = $true
    $ProcessedFileItemCounter = 1

    #if path ends with >>\*<<
    If ($path -match '\\\*$') {
        $pathWithoutWildCard = $path.Substring(0,$path.Length-1)

        #if path does not contain another wild card
        If (!$pathWithoutWildCard.Contains('*')) {
            If (!(Test-Path $pathWithoutWildCard)) {
                Write-InfoLog $logFilePath "Path does not exist >>${path}<<. Skipping it." $beVerbose
                $processPath = $false
            }
        }
    } Else {
        If (!(Test-Path $path)) {
            Write-InfoLog $logFilePath "Path does not exist >>${path}<<. Skipping it." $beVerbose
            $processPath = $false
        }
    }

    If ($processPath) {
        Write-InfoLog $logFilePath "Truncating path >>${path}<< with day to keep old file value of >>$daysToKeepOldFile<<." $beVerbose

        If ($daysToKeepOldFile -ne 0) {
            $lastPossibleDate = (Get-Date).AddDays(-$daysToKeepOldFile)
            Write-InfoLog $logFilePath "   Removing entries older than >>${lastPossibleDate}<<." $beVerbose

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -ErrorAction SilentlyContinue | Where-Object LastWriteTime -LT $lastPossibleDate

            $numberOfItemsToRemove = $matchingItems.Count

            Write-InfoLog $logFilePath "   Removing >>${numberOfItemsToRemove}<< entries." $beVerbose

            ForEach ($matchingItem In $matchingItems) {
                If ($DisplayProgessBar -eq $true){
                    Write-Progress -Activity ":: Removing items." -Status "[${ProcessedFileItemCounter} / ${numberOfItemsToRemove}]" -PercentComplete (($ProcessedFileItemCounter / $numberOfItemsToRemove) * 100) -Id 1 -ParentId 0
                    ++$ProcessedFileItemCounter
                }
                Write-DebugLog $logFilePath "   Trying to remove item >>${matchingItem}<<." $beVerbose

                If (!$isDryRun) {
                    Remove-Item -Path "$path\$matchingItem" -Force -ErrorAction SilentlyContinue
                    ++$numberOfRemovedFileSystemObjects
                }
            }
        } Else {
            Write-InfoLog $logFilePath "   Removing all entries, no date limit provided." $beVerbose

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -ErrorAction SilentlyContinue

            $numberOfItemsToRemove = $matchingItems.Count
            
            If (($DisplayProgessBar -eq $true) -and ($numberOfItemsToRemove -gt 0)){
                Write-Progress -Activity ":: Removing items." -Status "[${ProcessedFileItemCounter} / ${numberOfItemsToRemove}]" -PercentComplete (($ProcessedFileItemCounter / $numberOfItemsToRemove) * 100) -Id 1 -ParentId 0
                ++$ProcessedFileItemCounter
            }
            Write-InfoLog $logFilePath "   Removing >>${numberOfItemsToRemove}<< entries." $beVerbose
            
            If (!$isDryRun) {
                Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
                ++$numberOfRemovedFileSystemObjects
            }
        }

        If ($checkForDuplicates) {
            $listOfFileHashToFilePath = @{}
            $matchingFileSizeInByte = $checkForDuplicatesGreaterThanMegabyte * 1048576 #1048576 = 1024*1024

            Write-DebugLog $logFilePath "Checking for duplicates with file size greater than >>${matchingFileSizeInByte}<< bytes." $beVerbose

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -File -ErrorAction SilentlyContinue | Where-Object Length -ge $matchingFileSizeInByte

            $numberOfItemsToRemove = $matchingItems.Count

            If ($matchingItems.Count -gt 1 ) {
                Write-InfoLog $logFilePath "   Checking >>${numberOfItemsToRemove}<< entries of being duplicates." $beVerbose

                ForEach ($matchingItem In $matchingItems) {
                    $fileHashObject = Get-FileHash -Path "$path\$matchingItem" -Algorithm MD5

                    $fileHash = $fileHashObject.Hash

                    If ($DisplayProgessBar -eq $true){
                        Write-Progress -Activity ":: Removing items." -Status "[${ProcessedFileItemCounter} / ${numberOfItemsToRemove}]" -PercentComplete (($ProcessedFileItemCounter / $numberOfItemsToRemove) * 100) -Id 1 -ParentId 0
                        ++$ProcessedFileItemCounter
                    }

                    If ($listOfFileHashToFilePath.ContainsKey($fileHash)) {
                        Write-DebugLog $logFilePath "   Found duplicated hash >>${fileHash}<<, removing >>${path}\${matchingItem}<<." $beVerbose

                        If (!$isDryRun) {
                            Write-DebugLog $logFilePath "   Trying to remove item >>${path}\${matchingItem}<<." $beVerbose

                            Remove-Item -Path "$path\$matchingItem" -Force -ErrorAction SilentlyContinue
                            ++$numberOfRemovedFileSystemObjects
                        }
                    } Else {
                        Write-DebugLog $logFilePath "   Adding key >>${fileHash}<< with value >>${matchingItem}<<." $beVerbose

                        $listOfFileHashToFilePath.Add($fileHash, $matchingItem)
                    }
                }
            } Else {
                Write-DebugLog $logFilePath "   Less than two matching entries in the collection. Skipping duplicate check." $beVerbose
            }
        }
    }

    Return $numberOfRemovedFileSystemObjects
}

Function Start-PathTruncations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$collectionOfTruncableObjects,

        [Parameter(Mandatory = $true)]
        [string] $logFilePath,

        [Parameter(Mandatory = $false)]
        [bool] $beVerbose = $false
    )

    $listOfUserPaths = Get-ChildItem "C:\Users" | Select-Object Name
    $listOfUserNames = $listOfUserPaths.Name
    $numberOfRemovedFileSystemObjects = 0
    $TotalAmountOfTruncableObjects = $collectionOfTruncableObjects.Count
    $CurrentTruncableObjectCounter = 0
    $DisplayProgressBar = ($beVerbose -ne $true)

    If ($DisplayProgressBar -eq $true) {
        Clear-Host
    }

    ForEach ($currentObject In $collectionOfTruncableObjects) {

        $CurrentObjectPath = $currentObject.path

        If ($DisplayProgressBar -eq $true) {
            Write-Progress -Activity ":: Processing list of truncable objects." -Status "[${CurrentTruncableObjectCounter} / ${TotalAmountOfTruncableObjects}]" -PercentComplete (($CurrentTruncableObjectCounter / $TotalAmountOfTruncableObjects) * 100) -CurrentOperation "   Processing path >>${CurrentObjectPath}<<" -Id 0
        }
        #check if path ends with a wildcard
        If ($CurrentObjectPath -match '\$user') {
            ForEach ($currentUserName In $listOfUserNames) {
                $currentUserDirectoryPath = $CurrentObjectPath -replace '\$user', $currentUserName
               
                $numberOfRemovedFileSystemObjects = Start-PathTruncation $currentUserDirectoryPath $currentObject.days_to_keep_old_file $currentObject.check_for_duplicates $currentObject.check_for_duplicates_greater_than_megabyte $logFilePath $numberOfRemovedFileSystemObjects $beVerbose $isDryRun
            }
        } Else {
            $numberOfRemovedFileSystemObjects = Start-PathTruncation $CurrentObjectPath $currentObject.days_to_keep_old_file $currentObject.check_for_duplicates $currentObject.check_for_duplicates_greater_than_megabyte $logFilePath $numberOfRemovedFileSystemObjects $beVerbose $isDryRun
        }

        ++$CurrentTruncableObjectCounter
    }

    Return $numberOfRemovedFileSystemObjects
}

Start-CleanUpSystem
