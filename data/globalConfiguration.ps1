#!/usr/bin/env pwsh
####
# Global Configuration File
####
# @see:
#   https://github.com/Bromeego/Clean-Temp-Files/blob/master/Clear-TempFiles.ps1
#   https://github.com/bmrf/tron/blob/master/resources/stage_1_tempclean/tempfilecleanup/TempFileCleanup.bat
# @since 2021-04-07
# @author stev leibelt <artodeto@bazzline.net>
####

#bo: OS determination helper
If ($host.Version.Major -lt 7) {
    If (Test-Path "c:\windows") {
        $IsLinux = $false
        $IsWindows = $true
    } ElseIf (Test-Path "/root") {
        $IsLinux = $true
        $IsWindows = $false
    }
}
#eo: OS determination helper

#bo: windows settings
If ($IsWindows -eq $true) {
    #bo: general variable section
    $startDiskCleanupManager = $true #if set to $true, cleanmgr will be started
    #eo: general variable section

    #bo: path section
    #  bo: system paths
    $collectionOfTruncableObjects.Add((New-TruncableObject $logDirectoryPath 28)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject "C:\Temp\*" 0)) | Out-Null
    #$collectionOfTruncableObjects.Add((New-TruncableObject "C:\Windows\Temp\*" 0)) | Out-Null
    #$collectionOfTruncableObjects.Add((New-TruncableObject "C:\Windows\Logs\*\*" 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject "C:\ProgramData\Microsoft\Windows\WER\*" 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject "C:\Windows\System32\LogFiles\*\*" 7)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject "C:\Windows\SoftwareDistribution\*" 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject "C:\Windows\logs\CBS\*.log" 0)) | Out-Null
    #  eo: system paths

    #  bo: different programm paths
    #iis logs
    $collectionOfTruncableObjects.Add((New-TruncableObject "C:\inetpub\logs\LogFiles\*" 7)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject "C:\Config.Msi" 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject "C:\Intel" 0)) | Out-Null
    #$collectionOfTruncableObjects.Add((New-TruncableObject "C:\PerfLogs" 0)) | Out-Null
    #$collectionOfTruncableObjects.Add((New-TruncableObject "$env:windir\memory.dmp" 0)) | Out-Null
    #$collectionOfTruncableObjects.Add((New-TruncableObject "$env:windir\minidump\*" 0)) | Out-Null
    #$collectionOfTruncableObjects.Add((New-TruncableObject "$env:windir\Prefetch\*" 0)) | Out-Null
    #  eo: different programm paths

    #  bo: lotus/ibm/hcl notes
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\IBM\Notes\Data\IBM_TECHNICAL_SUPPORT\*' 7)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\IBM\Notes\Data\workspace\logs\error-log-*.xml' 7)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\IBM\Notes\Data\workspace\logs\trace-log-*.xml' 7)) | Out-Null
    #  eo: lotus/ibm/hcl notes

    #  bo: mozilla firefox
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\entries\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\thumbnails' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\cookies.sqlite' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\webappsstore.sqlite' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\chromeappsstore.sqlite' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\OfflineCache' 0)) | Out-Null
    #  eo: mozilla firefox

    #  bo: google chrome
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Cache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Cache2\entries\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Cookies' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Media Cache' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Cookies-Journal' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\JumpListIconsOld' 0)) | Out-Null
    #  eo: google chrome

    #  bo: microsoft internet explorer and edge
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\IECompatCache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\IECompatUaCache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\IEDownloadHistory\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\INetCache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\INetCookies\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Terminal Server Client\Cache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\WebCache\*' 0)) | Out-Null
    #  eo: microsoft internet explorer and edge

    #  bo: chromium
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\Cache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\GPUCache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\Media Cache' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\Pepper Data' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\Application Cache' 0)) | Out-Null
    #  eo: chromium

    #  bo: user temp folder
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\CrashDumps\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Teams\Cache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Teams\Service Worker\CacheStorage\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\AppCache\' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\WER\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\Temp\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Local\WebEx\wbxcache\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Roaming\Adobe\Flash Player\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Roaming\Macromedia\Flash Player\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Roaming\Microsoft\Windows\Recent\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Adobe\Flash Player\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Macromedia\Flash Player\*' 0)) | Out-Null
    $collectionOfTruncableObjects.Add((New-TruncableObject 'c:\Users\$user\AppData\Sun\Java\*' 0)) | Out-Null
    #  eo: user temp folder

    #  bo: user general
    #  eo: user general
    #eo: path section
} ElseIf ($IsLinux -eq $true) {
    $collectionOfTruncableObjects.Add((New-TruncableObject '/home/$user/.cache/*' 28)) | Out-Null
}
#eo: windows settings
