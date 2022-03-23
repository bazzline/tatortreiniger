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

using module .\source\DiskInformation.psm1
using module .\source\Logger.psm1
using module .\source\TruncableObject.psm1

Function New-TruncableObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [int] $DaysToKeepOldFiles = 1,

        [Parameter(Mandatory = $false)]
        [bool] $CheckForDuplicates = $false,

        [Parameter(Mandatory = $false)]
        [int] $CheckForDuplicatesGreaterThanMegabyte = 64
    )

    return [TruncableObject]::new(
        $CheckForDuplicates,
        $CheckForDuplicatesGreaterThanMegabyte,
        $DaysToKeepOldFiles,
        $Path
    )
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

Function Create-StatisticObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.TimeSpan] $runDatetime,

        [Parameter(Mandatory = $true)]
        [int] $numberOfRemovedFileSystemObjects,

        [Parameter(Mandatory = $true)]
        [DiskInformation] $startDiskInformation,

        [Parameter(Mandatory = $true)]
        [DiskInformation] $endDiskInformation
    )

    $startFreeSizeInGB = $startDiskInformation.GetFreeSizeInGB -replace ",", "."
    $endFreeSizeInGB = $endDiskInformation.GetFreeSizeInGB -replace ",", "."

    $properties = @{
        runtime = @{
            hours = $runDatetime.Hours
            minutes = $runDatetime.Minutes
            seconds = $runDatetime.Seconds
        }
        disk = @{
            number_of_removed_file_system_objects = $numberOfRemovedFileSystemObjects
            freed_up_disk_space = ([math]::Round($endDiskInformation.GetFreeSizeInGB - $startFreeSizeInGB.GetFreeSizeInGB, 2))
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
        [DiskInformation] $DiskInformation
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

Class CleanUpSystem {
    #bo properties
    hidden [string] $CurrentDate
    hidden [int] $CurrentExitCodeCounter
    hidden [object] $CollectionOfMandatoryFilesToLoad
    hidden [object] $CollectionOfOptionalFilesToLoad
    hidden [DiskInformation] $DiskInformation
    hidden [Logger] $Logger
    #eo properties

    #bo functions
    CleanUpSystem (
        [Logger] $Logger,
        [DiskInformation] $DiskInformation
    ) {
        $this.DiskInformation = $DiskInformation
        $this.Logger = $Logger

        $this.CurrentDate = Get-Date -Format "yyyyMMdd"
        $this.CollectionOfMandatoryFilesToLoad = New-Object System.Collections.ArrayList
        $this.CollectionOfOptionalFilesToLoad = New-Object System.Collections.ArrayList
        $this.CurrentExitCodeCounter = 1

        $this.CollectionOfMandatoryFilesToLoad.Add($PSScriptRoot + "\data\globalConfiguration.ps1")
        $this.CollectionOfOptionalFilesToLoad.Add($PSScriptRoot + "\data\localConfiguration.ps1")
    }

    [void] ConfigureLogger(
        [string] $Path
    ) {
        If (!(Test-Path $Path)) {
            New-Item -ItemType Directory -Force -Path $Path
        }

        $Date = Get-Date -Format "yyyyMMdd"
        $FileName = '{0}_{1}.log' -f [System.Net.Dns]::GetHostName(),$Date
        $FilePath = Join-Path $Path -ChildPath $FileName

        $this.Logger.SetPath($FilePath)
    }

    [void] Start ()
    {
        #bo runtime properties
        #   each of the following properites can be overwritten from the optional local configuration
        $beVerbose = $false
        $collectionOfTruncableObjects = New-Object System.Collections.ArrayList
        $deleteRecycleBin = $false #you should use a GPO for this but if you can't just empty the trash bin on each run
        $globalLogLevel = 0  #@see: https://docs.microsoft.com/en-us/dotnet/api/microsoft.extensions.logging.loglevel?view=dotnet-plat-ext-5.0
        $lockFilePath = Join-Path -Path "$PSScriptRoot" -ChildPath "data" -AdditionalChildPath ([System.Net.Dns]::GetHostName() + "-CleanUpSystem.lock")
        $logDirectoryPath = Join-Path -Path "$PSScriptRoot" -ChildPath "data" -AdditionalChildPath "log"
        $isDryRun = $false

        #we first set the global configuration settings
        $this.Logger.SetBeVerbose($beVerbose)
        $this.Logger.SetGlobalLogLevel($globalLogLevel)
        $this.ConfigureLogger($logDirectoryPath)
        #eo runtime properties

        #We have to source the files here and not via a function.
        #  If we would source the files via a function, the sourced in variables would exist in the scope of the function only.
        ForEach ($CurrentFilePath in $this.CollectionOfMandatoryFilesToLoad) {
            If ((Test-Path $CurrentFilePath)) {
                . $CurrentFilePath
            } Else {
                Write-Error "Could not load file. Path is invalid >>${CurrentFilePath}<<. Path is declared as mandatory."
                Exit ($this.CurrentExitCodeCounter++)
            }
        }

        ForEach ($CurrentFilePath in $this.CollectionOfOptionalFilesToLoad) {
            If ((Test-Path $CurrentFilePath)) {
                . $CurrentFilePath
            } Else {
                $this.Logger.Info("Could not load file. to Path is invalid >>${CurrentFilePath}<<. Path is decleared as optional.")
            }
        }

        #and now, we set the variables, possible overwritten by local configration files
        $this.Logger.SetBeVerbose($beVerbose)
        $this.Logger.SetGlobalLogLevel($globalLogLevel)
        $this.ConfigureLogger($logDirectoryPath)
        #eo: variable definition

        #----
        #bo: clean up
        $startDateTime = (Get-Date)

        New-LockFileOrExit $lockFilePath $this.Logger

        Write-DiskspaceLog $this.Logger $this.DiskInformation

        #disable windows update service to enable cleanup of >>c:\windows\softwaredistribution<<
        Get-Service -Name wuauserv | Stop-Service -Force -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose

        #  bo: manipulating the file system
        $numberOfRemovedFileSystemObjects = Start-PathTruncations $collectionOfTruncableObjects $this.Logger $beVerbose

        If ($deleteRecycleBin -eq $true) {
            Delete-RecycleBin $this.Logger
        }

        If ($startDiskCleanupManager -eq $true) {
            Start-DiskCleanupManager $this.Logger
        }
        #  eo: manipulating the file system

        $runDateTime = (Get-Date).Subtract($startDateTime)

        $endDiskInformation = Create-DiskInformation

        $statisticObject = Create-StatisticObject $runDatetime $numberOfRemovedFileSystemObjects $startDiskInformation $endDiskInformation

        Write-DiskspaceLog $this.Logger $endDiskinformation

        Write-StatisticLog $this.Logger $statisticObject

        #enable windows update service
        Get-Service -Name wuauserv | Start-Service -ErrorAction SilentlyContinue

        Remove-LockFileOrExit $lockFilePath $this.Logger
        #eo: clean up
    }
    #eo functions
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
        [TruncableObject] $TruncableObject,

        [Parameter(Mandatory = $true)]
        [Logger] $Logger,

        [Parameter(Mandatory = $true)]
        [int]$numberOfRemovedFileSystemObjects,

        [Parameter(Mandatory = $false)]
        [bool]$isDryRun = $false
    )

    $DisplayProgessBar = ($beVerbose -ne $true)
    $ProcessPath = $true
    $ProcessedFileItemCounter = 1

    #if path ends with >>\*<<
    $pathEndsWithAStar = ($TruncableObject.GetPath() -match '\\\*$')
    $pathWithoutStarAtTheEnd = $path.Substring(0, $path.Length-1)

    If ($pathEndsWithAStar) {
        #if path does not contain another wild card
        If (!$pathWithoutStarAtTheEnd.Contains('*')) {
            If (!(Test-Path $pathWithoutStarAtTheEnd)) {
                $Logger.Info("Path does not exist >>" + $TruncableObject.GetPath() + "<<. Skipping it.")
                $ProcessPath = $false
            }
        }
    } Else {
        If (!(Test-Path $TruncableObject.GetPath())) {
            $Logger.Info("Path does not exist >>" + $TruncableObject.GetPath() + "<<. Skipping it.")
            $ProcessPath = $false
        }
    }

    If ($ProcessPath) {
        $Logger.Info("Truncating path >>" + $TruncableObject.GetPath() + "<< with days to keep files older than >>" + $TruncableObject.GetDaysToKeepOldFiles() + "<< days.")

        #if we have to check against last modification date
        If ($TruncableObject.GetDaysToKeepOldFiles() -ne 0) {
            $lastPossibleDate = (Get-Date).AddDays(-$TruncableObject.GetDaysToKeepOldFiles())
            $Logger.Info("   Removing entries older than >>${lastPossibleDate}<<.")

            $matchingItems = Get-ChildItem -Path $TruncableObject.GetPath() -Recurse -ErrorAction SilentlyContinue |
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

            $matchingItems = Get-ChildItem -Path $TruncableObject.GetPath() -Recurse -ErrorAction SilentlyContinue

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

        If ($TruncableObject.CheckForDuplicates()) {
            $listOfFileHashToFilePath = @{}
            $matchingFileSizeInByte = $TruncableObject.GetCheckForDuplicatesGreaterThanMegabyte() * 1048576 #1048576 = 1024*1024

            $Logger.Debug("Checking for duplicates with file size greater than >>${matchingFileSizeInByte}<< bytes.")

            $matchingItems = Get-ChildItem -Path $TruncableObject.GetPath() -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object Length -ge $matchingFileSizeInByte

            $numberOfItemsToRemove = $matchingItems.Count

            If ($matchingItems.Count -gt 1 ) {
                $Logger.Info("   Checking >>${numberOfItemsToRemove}<< entries of being duplicates.")

                ForEach ($matchingItem In $matchingItems) {
                    $filePathToMatchingItem = $($TruncableObject.GetPath() + "\${matchingItem}")
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
        [System.Collections.ArrayList] $CollectionOfTruncableObjects,

        [Parameter(Mandatory = $true)]
        [Logger] $Logger,

        [Parameter(Mandatory = $false)]
        [bool] $beVerbose = $false
    )

    $ListOfUserPaths = Get-ChildItem "C:\Users" | Select-Object Name

    $CurrentTruncableObjectCounter = 0
    $DisplayProgressBar = ($beVerbose -ne $true)
    $ListOfUserNames = $ListOfUserPaths.Name
    $NumberOfRemovedFileSystemObjects = 0
    $TotalAmountOfTruncableObjects = $CollectionOfTruncableObjects.Count

    If ($DisplayProgressBar -eq $true) {
        Clear-Host
    }

    ForEach ($CurrentTruncableObject In $CollectionOfTruncableObjects) {

        $CurrentObjectPath = $CurrentTruncableObject.GetPath()

        #check if path ends with a wildcard
        If ($CurrentObjectPath -match '\$user') {
            ForEach ($currentUserName In $ListOfUserNames) {
                $CurrentUserDirectoryPath = $CurrentObjectPath -replace '\$user', $currentUserName

                If ($DisplayProgressBar -eq $true) {
                    Write-Progress -Activity ":: Processing list of truncable objects." `
                        -Status "[${CurrentTruncableObjectCounter} / ${TotalAmountOfTruncableObjects}]" `
                        -PercentComplete (($CurrentTruncableObjectCounter / $TotalAmountOfTruncableObjects) * 100) `
                        -CurrentOperation "   Processing path >>${CurrentUserDirectoryPath}<<" `
                        -Id 0
                }

                $CurrentTruncableObject.SetPath($CurrentUserDirectoryPath)
               
                $NumberOfRemovedFileSystemObjects = Start-PathTruncation $CurrentTruncableObject $Logger $numberOfRemovedFileSystemObjects $isDryRun
            }
        } Else {
            If ($DisplayProgressBar -eq $true) {
                Write-Progress -Activity ":: Processing list of truncable objects." `
                    -Status "[${CurrentTruncableObjectCounter} / ${TotalAmountOfTruncableObjects}]" `
                    -PercentComplete (($CurrentTruncableObjectCounter / $TotalAmountOfTruncableObjects) * 100) `
                    -CurrentOperation "   Processing path >>${CurrentObjectPath}<<" `
                    -Id 0
            }

            $NumberOfRemovedFileSystemObjects = Start-PathTruncation $CurrentTruncableObject $Logger $numberOfRemovedFileSystemObjects $isDryRun
        }

        ++$CurrentTruncableObjectCounter
    }

    If ($DisplayProgressBar -eq $true) {
        Clear-Host
    }

    Return $NumberOfRemovedFileSystemObjects
}

$CleanUpSystem = [CleanUpSystem]::new(
    [Logger]::new(),
    [DiskInformation]::new()
)
$CleanUpSystem.Start()
