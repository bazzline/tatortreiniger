#!/usr/bin/env pwsh
####
# @since 2021-12-17
# @author stev leibelt <artodeto@bazzline.net>
####

Class DiskInformation
{
    #bo properties
    hidden [string] $DeviceId
    hidden [string] $FreeSizeInGb
    hidden [string] $FreeSizeInPercentage
    hidden [string] $TotalSizeInGb
    #eo properties

    #bo methods
    DiskInformation()
    {
        $LogicalDisk = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" }

        $this.DeviceId = $LogicalDisk.DeviceId
        $this.FreeSizeInGB = "{0:N1}" -f ( $LogicalDisk.Freespace / 1gb )
        $this.FreeSizeInPercentage = "{0:P1}" -f ( $LogicalDisk.FreeSpace / $LogicalDisk.Size )
        $this.TotalSizeInGB = "{0:N1}" -f ( $LogicalDisk.Size / 1gb)
    }

    [DiskInformation] Reload()
    {
        return [DiskInformation]::new()
    }

    [string] GetDeviceId()
    {
        return $this.DeviceId
    }

    [string] GetFreeSizeInGB()
    {
        return $this.FreeSizeInGb
    }

    [string] GetFreeSizeInPercentage()
    {
        return $this.FreeSizeInPercentage
    }

    [string] GetTotalSizeInGB()
    {
        return $this.TotalSizeInGb
    }
    #eo methods
}