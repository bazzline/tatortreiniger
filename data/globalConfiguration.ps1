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

#bo: general variable section
$beVerbose = $false
#$globalLogLevel = 0  #@see: https://docs.microsoft.com/en-us/dotnet/api/microsoft.extensions.logging.loglevel?view=dotnet-plat-ext-5.0
$isDryRun = $false
$lockFilePath = ($PSScriptRoot + "\CleanUpSystem.lock")
$logDirectoryPath = ($PSScriptRoot + "\log\")
#eo: general variable section

#bo: path section
#  bo: system paths
$collectionOfTruncableObjects.Add((Create-TruncableObject $logDirectoryPath 28)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject "C:\Temp\*" 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject "C:\Windows\Temp\*" 0)) | Out-Null
#$collectionOfTruncableObjects.Add((Create-TruncableObject "C:\Windows\Logs\*\*" 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject "C:\ProgramData\Microsoft\Windows\WER\*" 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject "C:\Windows\System32\LogFiles\*\*" 7)) | Out-Null
#  eo: system paths

#  bo: mozilla firefox
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\entries\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\thumbnails' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\cookies.sqlite' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\webappsstore.sqlite' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\chromeappsstore.sqlite' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Mozilla\Firefox\Profiles\*.default\OfflineCache' 0)) | Out-Null
#  eo: mozilla firefox

#  bo: google chrome
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Cache\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Cache2\entries\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Cookies' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Media Cache' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\Cookies-Journal' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Google\Chrome\User Data\*\JumpListIconsOld' 0)) | Out-Null
#  eo: google chrome

#  bo: microsoft internet explorer and edge
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\Temporary Internet Files\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\INetCache\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\WebCache\*' 0)) | Out-Null
#  eo: microsoft internet explorer and edge

#  bo: chromium
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\Cache\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\GPUCache\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\Media Cache' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\Pepper Data' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Chromium\User Data\Default\Application Cache' 0)) | Out-Null
#  eo: chromium

#  bo: user temp folder
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Temp\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\WER\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\Microsoft\Windows\AppCache\' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Local\CrashDumps\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Roaming\Adobe\Flash Player\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Roaming\Macromedia\Flash Player\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Roaming\Microsoft\Windows\Recent\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Adobe\Flash Player\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Macromedia\Flash Player\*' 0)) | Out-Null
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\AppData\Sun\Java\*' 0)) | Out-Null
#  eo: user temp folder

#  bo: user general
$collectionOfTruncableObjects.Add((Create-TruncableObject 'c:\Users\$user\Downloads' 21 $true 32)) | Out-Null
#  eo: user general
#eo: path section