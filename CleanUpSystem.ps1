#!/usr/bin/env pwsh
####
# Cleanup Window System
####
# @see:
#   https://github.com/Bromeego/Clean-Temp-Files/blob/master/Clear-TempFiles.ps1
# @since 2021-04-06
# @author stev leibelt <artodeto@bazzline.net>
####

Function New-TruncableObject {
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
        Write-Error ":: Error"
        Write-Error "   Could not aquire lock, lock file >>${lockFilePath}<< exists."
        Write-ErrorLog $logFilePath "Could not aquire lock. Lock file >>${lockFilePath}<< exists." $beVerbose

        Exit 1
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

Function Create-DiskInformation {
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

Function Write-StatisticLog {
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


Function Start-CleanUpSystem {
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
    $startDateTime = Get-Date
    $startDiskInformation = Create-DiskInformation

    New-LockFileOrExit $lockFilePath $logFilePath $beVerbose

    Write-DiskspaceLog $logFilePath $startDiskInformation $beVerbose

    $numberOfRemovedFileSystemObjects = Start-PathTruncations $collectionOfTruncableObjects $logFilePath $beVerbose

    $runDateTime = (Get-Date).Subtract($startDateTime)

    $endDiskInformation = Create-DiskInformation

    $statisticObject = Create-StatisticObject $runDatetime $numberOfRemovedFileSystemObjects $startDiskInformation $endDiskInformation

    If ($startDiskCleanupManager -eq $true) {
        Start-DiskCleanupManager $logFilePath $beVerbose
    }

    Write-DiskspaceLog $logFilePath $endDiskinformation $beVerbose

    Write-StatisticLog $logFilePath $statisticObject $beVerbose

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
        Start-Process -FilePath Cleanmgr -ArgumentList '/sagerun:1' '/verylowdisk' -Wait -Verbose
    } Else {
        Start-Process -FilePath Cleanmgr -ArgumentList '/sagerun:1' '/verylowdisk' -Wait
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

    #if path ends with >>\*<<
    $processPath = $true
    If ($path -match '\\\*$') {
        $pathWithoutWildCard = $path.Substring(0,$path.Length-1)

        #if path does not contain another wild card
        If (!$pathWithoutWildCard.Contains('*')) {
            If (!(Test-Path $pathWithoutWildCard)) {
                Write-InfoLog $logFilePath "Path does not exist >>${path}<<. Skipping it." $beVerbose
                $processPath = $false
            }
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

    ForEach ($currentObject In $collectionOfTruncableObjects) {
        #check if path ends with a wildcard
        If ($currentObject.path -match '\$user') {
            ForEach ($currentUserName In $listOfUserNames) {
                $currentUserDirectryPath = $currentObject.path -replace '\$user', $currentUserName
               
                $numberOfRemovedFileSystemObjects = Start-PathTruncation $currentUserDirectryPath $currentObject.days_to_keep_old_file $currentObject.check_for_duplicates $currentObject.check_for_duplicates_greater_than_megabyte $logFilePath $numberOfRemovedFileSystemObjects $beVerbose $isDryRun
            }
        } Else {
            $numberOfRemovedFileSystemObjects = Start-PathTruncation $currentObject.path $currentObject.days_to_keep_old_file $currentObject.check_for_duplicates $currentObject.check_for_duplicates_greater_than_megabyte $logFilePath $numberOfRemovedFileSystemObjects $beVerbose $isDryRun
        }
    }

    Return $numberOfRemovedFileSystemObjects
}

Start-CleanUpSystem
