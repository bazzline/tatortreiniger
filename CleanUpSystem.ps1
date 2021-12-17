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

Class Logger {
    #bo properties
    [bool]hidden $BeVerbose
    [int]hidden $GlobalLogLevel
    [string]hidden $Path
    [int] static $LogLevelTrace = 0
    [int] static $LogLevelDebug = 1
    [int] static $LogLevelInformation = 2
    [int] static $LogLevelWarning = 3
    [int] static $LogLevelError = 4
    [int] static $LogLevelCritical = 5
    #eo properties

    #bo functions
    Logger (
        [string] $Path,
        [int] $GlobalLogLevel,
        [bool] $BeVerbose
    ) {
        $this.BeVerbose = $BeVerbose
        $this.GlobalLogLevel = $GlobalLogLevel
        $this.Path = $Path
    }

    [void] Debug(
        [string] $Message
    ) {
        $this.LogLine($Message, 0)
    }

    [void] Error(
        [string] $Message
    ) {
        $this.LogLine($Message, 4)
    }


    [void] Info(
        [string] $Message
    ) {
        $this.LogLine($Message, 2)
    }

    [void] LogLine(
        [string] $Message,
        [int] $LogLevel
    ) {
        If ($LogLevel -ge $this.GlobalLogLevel) {
            $Prefix = "[None]"

            Switch ($LogLevel)
            {
                0 { $Prefix = "[Trace]"; Break }
                1 { $Prefix = "[Debug]"; Break }
                2 { $Prefix = "[Information]"; Break }
                3 { $Prefix = "[Warning]"; Break }
                4 { $Prefix = "[Error]"; Break }
                5 { $Prefix = "[Critical]"; Break }
                Default { $Prefix = "[None]"; Break }
            }

            $CurrentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

            $CurrentLogLine = '{0}: {1} - {2}' -f $CurrentDateTime,$Prefix,$Message

            Add-Content -Path $this.Path -Value $CurrentLogLine

            If ($this.BeVerbose) {
                Write-Host $CurrentLogLine -ForegroundColor DarkGray
            }
        }
    }
    #eo functions
}

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
        [string] $lockFilePath,

        [Parameter(Mandatory = $true)]
        [Logger] $Logger
    )

    If (Test-Path $lockFilePath) {

        Write-Host ":: Lock file exists. Maybe an previous run was stopped or is crashed."
        $YesOrNo = Read-Host -Prompt "   Should I remove it? (y|N)"

        If ($YesOrNo.StartsWith("y") -eq $true) {
            $Logger.Debug("Removing existing lock file >>${lockFilePath}<< after asking the user.")

            Remove-Item -Path $lockFilePath
        } Else {
            Write-Error ":: Error"
            Write-Error "   Could not aquire lock, lock file >>${lockFilePath}<< exists."
            Write-ErrorLogAndExit $Logger "Could not aquire lock. Lock file >>${lockFilePath}<< exists." ($CurrentExitCodeCounter++)
        }
    }

    New-Item -ItemType File $lockFilePath
    Set-Content -Path $lockFilePath -Value "${PID}"

    $Logger.Debug("Lock file create, path >>${lockFilePath}<<, content >>${PID}<<")
}

Function Remove-LockFileOrExit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $lockFilePath,

        [Parameter(Mandatory = $true)]
        [Logger] $Logger
    )

    If (Test-Path $lockFilePath) {
        $lockFilePID = Get-Content -Path $lockFilePath

        If ($lockFilePID -eq $PID ){
            Remove-Item -Path $lockFilePath

            $Logger.Debug("Lock file removed, path >>${lockFilePath}<<")
        } Else {
            Write-Error ":: Error"
            Write-Error "   Lockfile in path >>${lockFilePath}<< contains different PID. Expected >>${PID}<<, Actual >>${lockFilePID}<<."
            Write-ErrorLogAndExit $Logger "Lockfile in path >>${lockFilePath}<< contains different PID. Expected >>${PID}<<, Actual >>${lockFilePID}<<." ($CurrentExitCodeCounter++)
        }

    } Else {
        Write-Error ":: Error"
        Write-Error "   Could not release lock. Lock file >>${lockFilePath}<< does not exists."
        Write-ErrorLogAndExit $Logger "Could not release lock. Lock file >>${lockFilePath}<< does not exists." ($CurrentExitCodeCounter++)
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

Function Remove-ItemAndLogResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ItemToRemove,

        [Parameter(Mandatory = $false)]
        [bool] $BeRecursive = $false,

        [Parameter(Mandatory = $true)]
        [Logger] $Logger,

        [Parameter(Mandatory = $false)]
        [bool] $IsDryRun = $false
    )

    If ($IsDryRun) {
        $Logger.Debug("   Would try to remove item >>${ItemToRemove}<<.")
    } Else {
        $Logger.Debug("   Trying to remove item >>${ItemToRemove}<<.")

        If ($BeRecursive -eq $true) {
            Remove-Item -Path "$ItemToRemove" -Force -Recurse -ErrorAction SilentlyContinue
        } Else {
            Remove-Item -Path "$ItemToRemove" -Force -ErrorAction SilentlyContinue
        }

        $RemoveItemWasSucessful = $?

        If ($RemoveItemWasSucessful -ne $true) {
            $Logger.Info("   Item could not be removed.")
        }
    }
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

Function Write-ErrorLogAndExit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Logger] $Logger,

        [Parameter(Mandatory = $true)]
        [string] $LogMessage,

        [Parameter(Mandatory = $true)]
        [int] $ExitCode
    )

    Logger.Error($LogMessage)

    Exit $ExitCode
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
        [Logger] $Logger
    )

    $Logger.Info(":: Starting deletion of recycle bin.")

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

    $Logger.Info(":: Finished deletion of recycle bin.")
}

Function Write-DiskspaceLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Logger] $Logger,

        [Parameter(Mandatory = $true)]
        [object] $DiskInformation
    )

    $Logger.Info("Drive: {0}, Total Size (GB) {1}, Free Size (GB) {2}, Free size in percentage {3}" `
        -f $DiskInformation.device_id, $DiskInformation.total_size_in_gb, $DiskInformation.free_size_in_gb, $DiskInformation.free_size_in_percentage)
    
}

Function Write-StatisticLog
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Logger] $Logger,

        [Parameter(Mandatory = $true)]
        [object] $StatisticObject
    )

    $Logger.Info(":: Statistics ::")

    $Logger.Info("   Runtime: Hours >>{0}<<, Minutes >>{1}<<, Seconds >>{2}<<." `
        -f $StatisticObject.runtime.hours, $StatisticObject.runtime.minutes, $StatisticObject.runtime.seconds)

    $Logger.Info("   Freed up disk space >>{0}<< Number of removed file system objects >>{1}<<." `
        -f $StatisticObject.disk.freed_up_disk_space, $StatisticObject.disk.number_of_removed_file_system_objects)
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
    } Else {
        Write-Error "Could not find path to global configuration >>${globalConfigurationFilePath}<<. Global configuration is mandatory!"
        Exit ($CurrentExitCodeCounter++)
    }

    #we are creating a logger to have at least one running
    $logFilePath = Get-LogFilePath $logDirectoryPath
    $Logger = [Logger]::new($LogFilePath, $globalLogLevel, $beVerbose)

    If ((Test-Path $localConfigurationFilePath)) {
        . $localConfigurationFilePath
    } Else {
        $Logger.Info("Could not find path to local configuration >>${localConfigurationFilePath}<<. This run withouts local configuration!")
    }

    #we have to create a second instance since there is a chance that one of the three variables have been changed
    $logFilePath = Get-LogFilePath $logDirectoryPath
    $Logger = [Logger]::new($logFilePath, $globalLogLevel, $beVerbose)
    #eo: variable definition

    #bo: clean up
    $startDateTime = (Get-Date)
    $startDiskInformation = Create-DiskInformation

    New-LockFileOrExit $lockFilePath $Logger

    Write-DiskspaceLog $Logger $startDiskInformation

    #disable windows update service to enable cleanup of >>c:\windows\softwaredistribution<<
    Get-Service -Name wuauserv | Stop-Service -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose

    #  bo: manipulating the file system
    $numberOfRemovedFileSystemObjects = Start-PathTruncations $collectionOfTruncableObjects $Logger $beVerbose

    If ($deleteRecycleBin -eq $true) {
        Delete-RecycleBin $Logger
    }

    If ($startDiskCleanupManager -eq $true) {
        Start-DiskCleanupManager $Logger
    }
    #  eo: manipulating the file system

    $runDateTime = (Get-Date).Subtract($startDateTime)

    $endDiskInformation = Create-DiskInformation

    $statisticObject = Create-StatisticObject $runDatetime $numberOfRemovedFileSystemObjects $startDiskInformation $endDiskInformation

    Write-DiskspaceLog $Logger $endDiskinformation

    Write-StatisticLog $Logger $statisticObject

    #enable windows update service
    Get-Service -Name wuauserv | Start-Service -ErrorAction SilentlyContinue

    Remove-LockFileOrExit $lockFilePath $Logger
    #eo: clean up
}

Function Start-DiskCleanupManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Logger] $Logger
    )

    $Logger.Info(":: Starting system disk cleanup manager.")

    #@see: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/cleanmgr
    If ($beVerbose -eq $true) {
        Start-Process -FilePath Cleanmgr -ArgumentList '/sagerun:1', '/VERYLOWDISK' -Wait -Verbose
    } Else {
        Start-Process -FilePath Cleanmgr -ArgumentList '/sagerun:1', '/verylowdisk' -Wait
    }

    $Logger.Info(":: Finished system disk cleanup manager.")
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
        [Logger] $Logger,

        [Parameter(Mandatory = $true)]
        [int]$numberOfRemovedFileSystemObjects,

        [Parameter(Mandatory = $false)]
        [bool]$isDryRun = $false
    )

    $DisplayProgessBar = ($beVerbose -ne $true)
    $processPath = $true
    $ProcessedFileItemCounter = 1

    #if path ends with >>\*<<
    $pathEndsWithAStar = ($path -match '\\\*$')
    $pathWithoutStarAtTheEnd = $path.Substring(0, $path.Length-1)

    If ($pathEndsWithAStar) {
        #if path does not contain another wild card
        If (!$pathWithoutStarAtTheEnd.Contains('*')) {
            If (!(Test-Path $pathWithoutStarAtTheEnd)) {
                $Logger.Info("Path does not exist >>${path}<<. Skipping it.")
                $processPath = $false
            }
        }
    } Else {
        If (!(Test-Path $path)) {
            $Logger.Info("Path does not exist >>${path}<<. Skipping it.")
            $processPath = $false
        }
    }

    If ($processPath) {
        $Logger.Info("Truncating path >>${path}<< with days to keep files older than >>${daysToKeepOldFile}<< days.")

        #if we have to check against last modification date
        If ($daysToKeepOldFile -ne 0) {
            $lastPossibleDate = (Get-Date).AddDays(-$daysToKeepOldFile)
            $Logger.Info("   Removing entries older than >>${lastPossibleDate}<<.")

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -ErrorAction SilentlyContinue | 
                Where-Object LastWriteTime -lt $lastPossibleDate

            $numberOfItemsToRemove = $matchingItems.Count

            $Logger.Info("   Removing >>${numberOfItemsToRemove}<< entries.")

            ForEach ($matchingItem In $matchingItems) {
                If ($DisplayProgessBar -eq $true){
                    Write-Progress -Activity ":: Removing items." `
                        -Status "[${ProcessedFileItemCounter} / ${numberOfItemsToRemove}]" `
                        -PercentComplete (($ProcessedFileItemCounter / $numberOfItemsToRemove) * 100) `
                        -Id 1 `
                        -ParentId 0
                    ++$ProcessedFileItemCounter
                }

                $FullQualifiedPath = Join-Path -Path $pathWithoutStarAtTheEnd -ChildPath $matchingItem

                Remove-ItemAndLogResult "${FullQualifiedPath}" $true $Logger $isDryRun
                ++$numberOfRemovedFileSystemObjects
            }
        } Else {
            $Logger.Info("   Removing all entries, no date limit provided.")

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -ErrorAction SilentlyContinue

            $numberOfItemsToRemove = $matchingItems.Count
            
            If (($DisplayProgessBar -eq $true) -and ($numberOfItemsToRemove -gt 0)){
                Write-Progress -Activity ":: Removing items." `
                    -Status "[${ProcessedFileItemCounter} / ${numberOfItemsToRemove}]" `
                    -PercentComplete (($ProcessedFileItemCounter / $numberOfItemsToRemove) * 100) `
                    -Id 1 `
                    -ParentId 0
                ++$ProcessedFileItemCounter
            }
            $Logger.Info("   Removing >>${numberOfItemsToRemove}<< entries.")
            
            $FullQualifiedPath = Join-Path -Path $pathWithoutStarAtTheEnd -ChildPath $matchingItem
            Remove-ItemAndLogResult "${FullQualifiedPath}" $true $Logger $isDryRun
            ++$numberOfRemovedFileSystemObjects
        }

        If ($checkForDuplicates) {
            $listOfFileHashToFilePath = @{}
            $matchingFileSizeInByte = $checkForDuplicatesGreaterThanMegabyte * 1048576 #1048576 = 1024*1024

            $Logger.Debug("Checking for duplicates with file size greater than >>${matchingFileSizeInByte}<< bytes.")

            $matchingItems = Get-ChildItem -Path "$path" -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object Length -ge $matchingFileSizeInByte

            $numberOfItemsToRemove = $matchingItems.Count

            If ($matchingItems.Count -gt 1 ) {
                $Logger.Info("   Checking >>${numberOfItemsToRemove}<< entries of being duplicates.")

                ForEach ($matchingItem In $matchingItems) {
                    $filePathToMatchingItem = $("${path}\${matchingItem}")
                    $Logger.Debug("   Processing matching item file path >>${filePathToMatchingItem}<<.")

                    If (Test-Path -Path $filePathToMatchingItem) {
                        $fileHashObject = Get-FileHash -Path "$filePathToMatchingItem" -Algorithm SHA256

                        $fileHash = $fileHashObject.Hash

                        If ($DisplayProgessBar -eq $true){
                            Write-Progress -Activity ":: Removing items." `
                                -Status "[${ProcessedFileItemCounter} / ${numberOfItemsToRemove}]" `
                                -PercentComplete (($ProcessedFileItemCounter / $numberOfItemsToRemove) * 100) `
                                -Id 1 `
                                -ParentId 0
                            ++$ProcessedFileItemCounter
                        }

                        If ($listOfFileHashToFilePath.ContainsKey($fileHash)) {
                            $Logger.Debug("   Found duplicated hash >>${fileHash}<<, removing >>${filePathToMatchingItem}<<.")

                            $FullQualifiedPath = Join-Path -Path $pathWithoutStarAtTheEnd -ChildPath $matchingItem
                            Remove-ItemAndLogResult "${FullQualifiedPath}" $true $Logger $isDryRun
                            ++$numberOfRemovedFileSystemObjects
                        } Else {
                            $Logger.Debug("   Adding key >>${fileHash}<< with value >>${matchingItem}<<.")

                            $listOfFileHashToFilePath.Add($fileHash, $matchingItem)
                        }
                    } Else {
                        $Logger.Debug("      Filepath is not valid.")
                    }
                }
            } Else {
                $Logger.Debug("   Less than two matching entries in the collection. Skipping duplicate check.")
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
        [Logger] $Logger,

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

        #check if path ends with a wildcard
        If ($CurrentObjectPath -match '\$user') {
            ForEach ($currentUserName In $listOfUserNames) {
                $currentUserDirectoryPath = $CurrentObjectPath -replace '\$user', $currentUserName

                If ($DisplayProgressBar -eq $true) {
                    Write-Progress -Activity ":: Processing list of truncable objects." `
                        -Status "[${CurrentTruncableObjectCounter} / ${TotalAmountOfTruncableObjects}]" `
                        -PercentComplete (($CurrentTruncableObjectCounter / $TotalAmountOfTruncableObjects) * 100) `
                        -CurrentOperation "   Processing path >>${currentUserDirectoryPath}<<" `
                        -Id 0
                }
               
                $numberOfRemovedFileSystemObjects = Start-PathTruncation $currentUserDirectoryPath $currentObject.days_to_keep_old_file $currentObject.check_for_duplicates $currentObject.check_for_duplicates_greater_than_megabyte $Logger $numberOfRemovedFileSystemObjects $isDryRun
            }
        } Else {
            If ($DisplayProgressBar -eq $true) {
                Write-Progress -Activity ":: Processing list of truncable objects." `
                    -Status "[${CurrentTruncableObjectCounter} / ${TotalAmountOfTruncableObjects}]" `
                    -PercentComplete (($CurrentTruncableObjectCounter / $TotalAmountOfTruncableObjects) * 100) `
                    -CurrentOperation "   Processing path >>${CurrentObjectPath}<<" `
                    -Id 0
            }

            $numberOfRemovedFileSystemObjects = Start-PathTruncation $CurrentObjectPath $currentObject.days_to_keep_old_file $currentObject.check_for_duplicates $currentObject.check_for_duplicates_greater_than_megabyte $Logger $numberOfRemovedFileSystemObjects $isDryRun
        }

        ++$CurrentTruncableObjectCounter
    }

    If ($DisplayProgressBar -eq $true) {
        Clear-Host
    }

    Return $numberOfRemovedFileSystemObjects
}

Start-CleanUpSystem
