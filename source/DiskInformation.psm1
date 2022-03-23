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
        #@see: https://4sysops.com/archives/the-powershell-storage-module-initialize-partition-format-check-disk-usage-and-resize-disk/ - Get disk usage Information with Get-WmiObject
        $LogicalDisk = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq "3" }

        $this.DeviceId = $LogicalDisk.DeviceID
        $this.FreeSizeInGB = [math]::Round($LogicalDisk.Freespace / 1GB, 2)
        #$this.FreeSizeInGB = "{0:N1}" -f ( $LogicalDisk.Freespace / 1gb )
        #$this.FreeSizeInPercentage = "{0:P1}" -f ( $LogicalDisk.FreeSpace / $LogicalDisk.Size )
        $this.FreeSizeInPercentage = [math]::Round(($LogicalDisk.Freespace / $LogicalDisk.Size) * 100, 2)
        #$this.TotalSizeInGB = "{0:N1}" -f ( $LogicalDisk.Size / 1gb)
        $this.TotalSizeInGB = [math]::Round($LogicalDisk.Size / 1GB, 2)
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
