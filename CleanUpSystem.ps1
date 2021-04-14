#!/usr/bin/env pwsh
####
# Cleanup Window System
####
# @see:
#   https://github.com/Bromeego/Clean-Temp-Files/blob/master/Clear-TempFiles.ps1
# @since 2021-04-06
# @author stev leibelt <artodeto@bazzline.net>
####

Function Create-TruncableObject {
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

Function Create-LockFileOrExit {
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
        Log-Error $logFilePath "Could not aquire lock. Lock file >>${lockFilePath}<< exists." $beVerbose

        Exit 1
    }

    New-Item -ItemType File $lockFilePath
    Set-Content -Path $lockFilePath -Value "${PID}"

    Log-Debug $logFilePath "Lock file create, path >>${lockFilePath}<<, content >>${PID}<<" $beVerbose
}

Function Release-LockFile {
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

            Log-Debug $logFilePath "Lock file removed, path >>${lockFilePath}<<" $beVerbose
        } Else {
            Write-Error ":: Error"
            Write-Error "   Lockfile in path >>${lockFilePath}<< contains different PID. Expected >>${PID}<<, Actual >>${lockFilePID}<<."
            Log-Error $logfilePath  "Lockfile in path >>${lockFilePath}<< contains different PID. Expected >>${PID}<<, Actual >>${lockFilePID}<<." $beVerbose
        }

        Exit 1
    } Else {
        Write-Error ":: Error"
        Write-Error "   Could not release lock. Lock file >>${lockFilePath}<< does not exists."
        Log-Error $logfilePath "Could not release lock. Lock file >>${lockFilePath}<< does not exists." $beVerbose

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

Function Log-Message {
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

Function Log-Debug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    Log-Message $path $message 1 $beVerbose
}

Function Log-Info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    Log-Message $path $message 2 $beVerbose
}

Function Log-Error {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [string]$message,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    Log-Message $path $message 4 $beVerbose
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

    $properties = @{
        runtime = @{
            hours = $runDatetime.Hours
            minutes = $runDatetime.Minutes
            seconds = $runDatetime.Seconds
        }
        disk = @{
            number_of_removed_file_system_objects = $numberOfRemovedFileSystemObjects
            freed_up_disk_space = ($startDiskInformation.free_size_in_gb - $endDiskInformation.free_size_in_gb)
        }
    }

    $object = New-Object psobject -Property $properties

    return $object
}

Function Log-Diskspace {
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

    Log-Info $path $message $beVerbose
    
}

Function Log-Statistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$path,

        [Parameter(Mandatory = $true)]
        [object]$statisticObject,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose = $false
    )

    Log-Info $path ":: Statistics ::" $beVerbose

    $message = "   Runtime: Hours >>{0}<<, Minutes >>{1}<<, Seconds >>{2}<<." -f $statisticObject.runtime.hours, $statisticObject.runtime.minutes, $statisticObject.runtime.seconds
    Log-Info $path $message $beVerbose

    $message = "   Freed up disk space >>{0}<< Number of removed file system objects >>{1}<<." -f $statisticObject.disk.freed_up_disk_space, $statisticObject.disk.number_of_removed_file_system_objects
    Log-Info $path $message $beVerbose
}


Function CleanUpSystem {
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

    Create-LockFileOrExit $lockFilePath $logFilePath $beVerbose

    Log-DiskSpace $logFilePath $startDiskInformation $beVerbose

    $numberOfRemovedFileSystemObjects = Truncate-Paths $collectionOfTruncableObjects $logFilePath $beVerbose

    $runDateTime = (Get-Date).Subtract($startDateTime)

    $endDiskInformation = Create-DiskInformation

    $statisticObject = Create-StatisticObject $runDatetime $numberOfRemovedFileSystemObjects $startDiskInformation $endDiskInformation

    Log-DiskSpace $logFilePath $endDiskinformation $beVerbose

    Log-Statistics $logFilePath $statisticObject $beVerbose

    Release-LockFile $lockFilePath $logFilePath $beVerbose
    #eo: clean up
}

Function Truncate-Path {
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

        [Parameter(Mandatory = $false)]
        [int]$numberOfRemovedFileSystemObjects = 0,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose,

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
                Log-Info $logFilePath "Path does not exist >>${path}<<. Skipping it." $beVerbose
                $processPath = $false
            }
        }
    }

    If ($processPath) {
        Log-Info $logFilePath "Truncating path >>${path}<< with day to keep old file value of >>$daysToKeepOldFile<<." $beVerbose

        If ($daysToKeepOldFile -ne 0) {
            $lastPossibleDate = (Get-Date).AddDays(-$daysToKeepOldFile)
            Log-Info $logFilePath "   Removing entries older than >>${lastPossibleDate}<<." $beVerbose

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -ErrorAction SilentlyContinue | Where-Object LastWriteTime -LT $lastPossibleDate

            $numberOfItemsToRemove = $matchingItems.Count

            Log-Info $logFilePath "   Removing >>${numberOfItemsToRemove}<< entries." $beVerbose
            
            ForEach ($matchingItem In $matchingItems) {
                Log-Debug $logFilePath "   Trying to remove item >>${matchingItem}<<." $beVerbose

                If (!$isDryRun) {
                    Remove-Item -Path "$path\$matchingItem" -Force -ErrorAction SilentlyContinue
                    ++$numberOfRemovedFileSystemObjects
                }
            }
        } Else {
            Log-Info $logFilePath "   Removing all entries, no date limit provided." $beVerbose

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -ErrorAction SilentlyContinue

            $numberOfItemsToRemove = $matchingItems.Count

            Log-Info $logFilePath "   Removing >>${numberOfItemsToRemove}<< entries." $beVerbose
            
            If (!$isDryRun) {
                Remove-Item -Path "$path" -Recurse -Force -ErrorAction SilentlyContinue
                ++$numberOfRemovedFileSystemObjects
            }
        }

        If ($checkForDuplicates) {
            $listOfFileHashToFilePath = @{}
            $matchingFileSizeInByte = $checkForDuplicatesGreaterThanMegabyte * 1048576 #1048576 = 1024*1024

            Log-Debug $logFilePath "Checking for duplicates with file size greater than >>${matchingFileSizeInByte}<< bytes." $beVerbose

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -File -ErrorAction SilentlyContinue | Where-Object Length -ge $matchingFileSizeInByte

            $numberOfItemsToRemove = $matchingItems.Count

            Log-Info $logFilePath "   Checking >>${numberOfItemsToRemove}<< entries of being duplicates." $beVerbose

            ForEach ($matchingItem In $matchingItems) {
                $fileHashObject = Get-FileHash -Path "$path\$matchingItem" -Algorithm MD5

                $fileHash = $fileHashObject.Hash

                If ($listOfFileHashToFilePath.ContainsKey($fileHash)) {
                    Log-Debug $logFilePath "   Found duplicated hash >>${fileHash}<<, removing >>${path}\${matchingItem}<<." $beVerbose

                    If (!$isDryRun) {
                        Log-Debug $logFilePath "   Trying to remove item >>${path}\${matchingItem}<<." $beVerbose

                        Remove-Item -Path "$path\$matchingItem" -Force -ErrorAction SilentlyContinue
                        ++$numberOfRemovedFileSystemObjects
                    }
                } Else {
                    Log-Debug $logFilePath "   Adding key >>${fileHash}<< with value >>${matchingItem}<<." $beVerbose

                    $listOfFileHashToFilePath.Add($fileHash, $matchingItem)
                }
            }
        }
    }

    Return $numberOfRemovedFileSystemObjects
}

Function Truncate-Paths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$collectionOfTruncableObjects,

        [Parameter(Mandatory = $true)]
        [string]$logFilePath,

        [Parameter(Mandatory = $false)]
        [bool]$beVerbose
    )

    $listOfUserPaths = Get-ChildItem "C:\Users" | Select-Object Name
    $listOfUserNames = $listOfUserPaths.Name
    $numberOfRemovedFileSystemObjects = 0

    ForEach ($currentObject In $collectionOfTruncableObjects) {
        #check if path ends with a wildcard
        If ($currentObject.path -match '\$user') {
            ForEach ($currentUserName In $listOfUserNames) {
                $currentUserDirectryPath = $currentObject.path -replace '\$user', $currentUserName
               
                $numberOfRemovedFileSystemObjects = Truncate-Path $currentUserDirectryPath $currentObject.days_to_keep_old_file $currentObject.check_for_duplicates $currentObject.check_for_duplicates_greater_than_megabyte $logFilePath $numberOfRemovedFileSystemObjects $beVerbose $isDryRun
            }
        } Else {
            $numberOfRemovedFileSystemObjects = Truncate-Path $currentObject.path $currentObject.days_to_keep_old_file $currentObject.check_for_duplicates $currentObject.check_for_duplicates_greater_than_megabyte $logFilePath $numberOfRemovedFileSystemObjects $beVerbose $isDryRun
        }
    }

    Return $numberOfRemovedFileSystemObjects
}

CleanUpSystem
