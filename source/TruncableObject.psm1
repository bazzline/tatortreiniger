#!/usr/bin/env pwsh
####
# @since 2021-12-17
# @author stev leibelt <artodeto@bazzline.net>
####


Class TruncableObject
{
    #bo properties
    hidden [bool] $CheckForDuplicates
    hidden [int] $CheckForDuplicatesGreaterThanMegabyte
    hidden [int] $DaysToKeepOldFiles
    hidden [string] $Path
    #eo properties

    #bo functions
    TruncableObject (
            [bool] $CheckForDuplicates,
            [int] $CheckForDuplicatesGreaterThanMegabyte,
            [int] $DaysToKeepOldFiles,
            [string] $Path
    ) {
        $this.Path = $Path
        $this.DaysToKeepOldFiles = $DaysToKeepOldFiles
        $this.CheckForDuplicates = $CheckForDuplicates
        $this.CheckForDuplicatesGreaterThanMegabyte = $CheckForDuplicatesGreaterThanMegabyte
    }

    [bool] CheckForDuplicates()
    {
        Return $this.CheckForDuplicates
    }

    [int] GetCheckForDuplicatesGreaterThanMegabyte()
    {
        Return $this.CheckForDuplicatesGreaterThanMegabyte
    }

    [int] GetDaysToKeepOldFiles()
    {
        Return $this.DaysToKeepOldFiles
    }

    [string] GetPath()
    {
        Return $this.Path
    }

    [void] SetPath(
    [string] $Path
    ) {
        $this.Path = $Path
    }
    #eo functions
}