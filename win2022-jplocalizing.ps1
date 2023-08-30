$workdir = "D:\"
$isouri = "https://spec00staticweb.blob.core.windows.net/iso/spec-win-jp.iso"
$autologonuser = "azureadmin"
$autologonpass = "#Password01!"

$log = $workdir + "setuplang.log"

# Download LanguagePack
$iso = $workdir + "lang.iso"
if(Test-Path $iso){ Remove-Item $iso -force }
try
{
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri $isouri -OutFile $iso
    $ProgressPreference = "Continue"
    "200" | Out-File -Append -FilePath $log
    "OK" | Out-File -Append -FilePath $log
}
catch
{
    $_.Exception.Response.StatusCode.value__ | Out-File -Append -FilePath $log
    $_.Exception.Response.StatusDescription | Out-File -Append -FilePath $log
    throw
}

$mountResult = Mount-DiskImage $iso -PassThru
$mountResult | Out-File -Append -FilePath $log
$driveLetter = ($mountResult | Get-Volume).DriveLetter

# Install Language　Pack
$lppath = $driveLetter + ":\LanguagesAndOptionalFeatures\Microsoft-Windows-Server-Language-Pack_x64_ja-jp.cab"
dism /online /add-package /packagepath:$lppath >> $log

# Install Features on Demand
$fodpath = $driveLetter + ":\LanguagesAndOptionalFeatures\Microsoft-Windows-LanguageFeatures-Basic-ja-jp-Package~31bf3856ad364e35~amd64~~.cab"
dism /online /add-package /packagepath:$fodpath >> $log

Dismount-DiskImage $iso | Out-File -Append -FilePath $log
Remove-Item $iso -force

Set-WinSystemLocale -SystemLocale ja-JP
Set-TimeZone -Id "Tokyo Standard Time"

# RunOnce
$runoncecmd = $workdir + "setuplang.ps1"
$unattendxml = $workdir + "unattend.xml"
$autologonreg = "registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

$xml = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
<gs:UserList>
<gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/>
</gs:UserList>
</gs:GlobalizationServices>
"@
$xml | Out-File -FilePath $unattendxml

$cmd = @"
Set-WinHomeLocation -GeoId 122
Set-WinUserLanguageList -LanguageList ja-JP -Force
Set-WinUILanguageOverride -Language ja-JP
Set-WinCultureFromLanguageListOptOut -OptOut 0
Set-WinDefaultInputMethodOverride -InputTip "0411:00000411"
Set-ItemProperty "registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters" -Name "LayerDriver JPN" -Value "kbd106.dll"
control.exe "intl.cpl,,/f:```"$unattendxml```""
Set-ItemProperty -Path "$autologonreg" -Name "AutoAdminLogon" -Value "0"
Set-ItemProperty -Path "$autologonreg" -Name "DefaultUserName" -Value ""
Set-ItemProperty -Path "$autologonreg" -Name "DefaultPassword" -Value ""
"Restart Computer" | Out-File -Append -FilePath "$log"
Restart-Computer -Force
"@
$cmd | Out-File -FilePath $runoncecmd

Set-ItemProperty `
	-Path "registry::\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" `
	-Name "SetupLang" `
	-Value "powershell.exe -ExecutionPolicy RemoteSigned -file `"$runoncecmd`""

"Set RunOnce" | Out-File -Append -FilePath $log

# AutoLogon
Set-ItemProperty -Path $autologonreg -Name "AutoAdminLogon" -Value "1"
Set-ItemProperty -Path $autologonreg -Name "DefaultUserName" -Value $autologonuser
Set-ItemProperty -Path $autologonreg -Name "DefaultPassword" -Value $autologonpass

"Set AutoLogon" | Out-File -Append -FilePath $log

"Restart Computer" | Out-File -Append -FilePath $log
Restart-Computer -Force