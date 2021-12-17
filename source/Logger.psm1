#!/usr/bin/env pwsh
####
# @since 2021-12-17
# @author stev leibelt <artodeto@bazzline.net>
####

Class Logger {
    #bo properties
    hidden [bool] $BeVerbose
    hidden [int] $GlobalLogLevel
    hidden [string] $Path
    #eo properties

    #bo functions
    Logger ()
    {
        $this.BeVerbose = $false
        $this.GlobalLogLevel = 0
        $this.Path = Join-Path -Path $PSScriptRoot -ChildPath "initial.log"
    }

    Logger (
            [string] $Path,
            [int] $GlobalLogLevel,
            [bool] $BeVerbose
    ) {
        $this.BeVerbose = $BeVerbose
        $this.GlobalLogLevel = $GlobalLogLevel
        $this.Path = $Path
    }

    [void] setPath([string] $Path)
    {
        $this.Path = $Path
    }

    [void] SetGlobalLogLevel([int] $GlobalLogLevel)
    {
        $this.GlobalLogLevel = $GlobalLogLevel
    }

    [void] SetBeVerbose([bool] $BeVerbose)
    {
        $this.BeVerbose = $BeVerbose
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
