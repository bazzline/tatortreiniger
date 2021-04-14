# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Open]

### To Add

* added default value `$false` to each optional parameter `$beVerbose`

### To Change

* Evaluate how easy it is to use the collection of paths and create full qualifyed paths out of it
    * This way we would be able to log and process real paths instead of paths with wild cards
    * e.g. `C:\foo\*.bar\*` would became `C:\foo\baz.bar` and maybe more
* Refactor "Log-Message" and the other "Log-*" functions
    * Split it into "Log-Message" and "Output-Message" to ease up log with log level verbose but display only with information
    * Maybe create a "outputVerboseLevel" similar to "logLevel" setting

## [Unreleased]

### Added

* Added statistic output as information message on last line
    * Runtime
    * Number of free-ed up disk space
    * Number of removed files
* Added function `Create-DiskInformation`
* Added the check to only run duplicate check if there are at least two entries in the collection

### Changed

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
