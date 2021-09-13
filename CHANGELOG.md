# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Open]

### To Add

* add progressbar or information like "[7 / 12] users in progress"
* add translation files
* added default value `$false` to each optional parameter `$beVerbose`
* add user remove logic from [windows_remove_old_users](https://github.com/stevleibelt/windows_remove_old_users)
* add configuration section with a list of processes to stop before starting the cleanup
* add configuration section with a list of processes to start after starting the cleanup

### To Change

* fix not working calculated values of free'ed up disk space by using [Measure-Object](http://woshub.com/powershell-get-folder-sizes/)
* read [this](https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays?view=powershell-7.1)
    * and [this](https://powershellexplained.com/2017-05-27-Powershell-module-building-basics/)
    * and [this](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-script-module?view=powershell-7.1)
* Evaluate how easy it is to use the collection of paths and create full qualifyed paths out of it
    * This way we would be able to log and process real paths instead of paths with wild cards
    * e.g. `C:\foo\*.bar\*` would became `C:\foo\baz.bar` and maybe more
* Refactor "Log-Message" and the other "Log-*" functions
    * Split it into "Log-Message" and "Output-Message" to ease up log with log level verbose but display only with information
    * Maybe create a "outputVerboseLevel" similar to "logLevel" setting
    * or ...
        * Create object Logger and Messenger
        * Create MessengerCollection
        * Pass the MessengerCollection to each function
* Version 2
    * be open for all know operation systems (windows or unix/linux like)
    * detect operation system
        * create case blocks in the global configuration file
        * adapt path handling and so one, if needed
    * check if [this](http://woshub.com/how-to-clean-up-system-volume-information-folder/) is a thing

## [Unreleased]

### Added

* Added configuration value `$startDiskCleanupManager` with default value `$true`
    * If set to `$true`, `cleanmgr /sagerun:1 /verylowdisk` will be executed
* Added statistic output as information message on last line
    * Runtime
    * Number of free-ed up disk space
    * Number of removed files
* Added function `Create-DiskInformation`
* Added the check to only run duplicate check if there are at least two entries in the collection

### Changed

* Changed function names to aligne with [approved verbs](https://docs.microsoft.com/de-de/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.1)

## [0.10.0](https://github.com/bazzline/tatortreiniger/tree/0.10.0) - released at 20210413

### Added

* Added this changelog
* Added changelog to do list
* Added info log about the amount of files to be removed
* Added check if "days to keep" is `0`
    * If the value is `0` we will use the "just give me all items from this path" instead of "just give me items for fitting date" mechanism
    * If the value is `0`, we will call `Remote-Item` on the path without using the result from "Get-Childitem"

### Changed

* Commented out pre configured path `c:\Windows\Temp` - Microsoft tells different stories if it is save to remove the content of this path
* Removed `-File` in the `Get-Childitem` list
* Moved pre configured path `c:\Users\$user\Downloads` from `globalConfiguration.ps1` to `localConfiguration.ps1.dist`

## [0.9.0](https://github.com/bazzline/tatortreiniger/tree/0.9.0) - released at 20210408

### Added

* Initial release
