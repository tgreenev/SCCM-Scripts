Start-Transcript C:\Logs\DellPSLog.txt

<#
Downlaod the actual module from https://www.powershellgallery.com/packages/DellBIOSProvider/2.2.0.330
Use a program like 7Zip to extract it and remove the version number from the folder name
so the folder number is just "dellbiosprovider." If you are in a Remote Signed or All Signed 
enviorment, you may want to sign each PS1, PSD1 and PSM1 file or else the module may not load. 
You may be able to get away with "Get-Module dellbiosprovider -Confirm:$false" but I have not tested that.

Change the $DellModule variable to where you put the extracted folder.

To encrypt your password, I followed: https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-2/
#>

#Make sure we are on a Dell system
$DellBiosChecker = (Get-CimInstance -ClassName win32_bios).Manufacturer
if ($DellBiosChecker -like "*dell*") {
    #Check to see if DellBiosModule loaded
    $IsDellModule = Get-Module dellbiosprovider
    if ($null -eq $IsDellModule) {
        $DellModule = "\\share\dellbiosprovider\"
        $PSMod = $env:PSModulePath.split(";")[1]
        Copy-Item -path $DellModule -Destination $PSMod -Recurse -Force -ErrorAction SilentlyContinue -Verbose
        Start-Sleep -Seconds 2
        Remove-Item "$psmod\dellbiosprovider\DellAESKey.txt" -Force -Confirm:$false -Verbose
        Remove-Item "$psmod\dellbiosprovider\DellAESPass.txt" -Force -Confirm:$false -Verbose
        Import-Module dellbiosprovider -Verbose
    }
    Start-Sleep -Seconds 2
    #Must retrieve password using AES
    $AESKey = Get-Content \\share\DellAESKey.txt
    $PwdFile = Get-Content \\share\DellAESPass.txt
    $BiosPassword = $PwdFile | ConvertTo-SecureString -Key $AESKey

    Set-Location DellSmbios:\
    #Need to check if admin passowrd is set, if so, we will change it
    $CheckAdminPassword = (Get-Item -Path DellSmbios:\Security\IsAdminPasswordSet).CurrentValue
    if ($CheckAdminPassword -eq "False") {
        Set-Item -Path DellSmbios:\Security\AdminPassword $([System.Net.NetworkCredential]::new("", $biospassword).Password)
    }
    Start-Sleep -Seconds 2
    $PowerMgmt = Get-ChildItem DellSmbios:\PowerManagement\
    if ($PowerMgmt.Attribute -contains "DeepSleepCtrl") { Set-Item -Path DellSmbios:\PowerManagement\DeepSleepCtrl Disabled -PasswordSecure $BiosPassword -Verbose }
    if ($PowerMgmt.Attribute -contains "BlockSleep") { Set-Item -Path DellSmbios:\PowerManagement\BlockSleep Enabled -PasswordSecure $BiosPassword -Verbose }
    if ($PowerMgmt.Attribute -contains "WakeOnLan") { Set-Item -Path DellSmbios:\PowerManagement\WakeOnLan LanOnly -PasswordSecure $BiosPassword -Verbose }
    Set-Location $env:SystemDrive
}
else {
    Write-Host "This is not a Dell system but a $DellBiosChecker"
}


