Import-Module GroupPolicy
Import-Module ActiveDirectory

$GpoName = "dada-core-gpo"
$Domain = (Get-ADDomain).DNSRoot
$DomainDN = (Get-ADDomain).DistinguishedName
$WallpaperPath = "\\$Domain\SYSVOL\$Domain\scripts\wallpapers\corp_wallpaper.jpg"

$ExistingGPO = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue

if (-not $ExistingGPO) {
    $GPO = New-GPO -Name $GpoName
} else {
    $GPO = $ExistingGPO
}

New-GPLink -Name $GpoName -Target $DomainDN -LinkEnabled Yes -Enforced Yes -ErrorAction SilentlyContinue
Set-GPLink -Name $GpoName -Target $DomainDN -Order 1 -Enforced Yes

Set-GPRegistryValue -Name $GpoName `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "Wallpaper" -Type String -Value $WallpaperPath

Set-GPRegistryValue -Name $GpoName `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "WallpaperStyle" -Type String -Value "2"

$Profiles = @("DomainProfile", "PrivateProfile", "PublicProfile")

foreach ($Profile in $Profiles) {
    $Key = "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\$Profile"
    Set-GPRegistryValue -Name $GpoName `
        -Key $Key `
        -ValueName "EnableFirewall" `
        -Type DWord `
        -Value 0
}