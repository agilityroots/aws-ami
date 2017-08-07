#####
# WINDOWS SERVER BOOTSTRAP SCRIPT FOR puppet
#
# bootstrap script mostly inspired by the following links:
# https://stackoverflow.com/a/9949909/682912
# https://gist.githubusercontent.com/masterzen/6714787/raw
####

Start-Transcript -Path 'c:\bootstrap-transcript.txt' -Force
# strict mode for syntax
Set-StrictMode -Version Latest
# Unrestricted execution
Set-ExecutionPolicy Unrestricted
# fail on error
$ErrorActionPreference = "Stop"

$log = 'c:\Bootstrap.txt'

$systemPath = [Environment]::GetFolderPath([Environment+SpecialFolder]::System)
$sysNative = [IO.Path]::Combine($env:windir, "sysnative")
#http://blogs.msdn.com/b/david.wang/archive/2006/03/26/howto-detect-process-bitness.aspx
$Is32Bit = (($Env:PROCESSOR_ARCHITECTURE -eq 'x86') -and ($Env:PROCESSOR_ARCHITEW6432 -eq $null))
Add-Content $log -value "Is 32-bit [$Is32Bit]"

#http://msdn.microsoft.com/en-us/library/ms724358.aspx
$coreEditions = @(0x0c,0x27,0x0e,0x29,0x2a,0x0d,0x28,0x1d)
$IsCore = $coreEditions -contains (Get-WmiObject -Query "Select OperatingSystemSKU from Win32_OperatingSystem" | Select -ExpandProperty OperatingSystemSKU)
Add-Content $log -value "Is Core [$IsCore]"


# move to home, PS is incredibly complex :)
cd $Env:USERPROFILE
Set-Location -Path $Env:USERPROFILE
[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath

# fixing issue downloading files
# https://github.com/agilityroots/biztalk-provisioner/issues/4#issuecomment-317935380
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$client = new-object System.Net.WebClient


#.net 4
if ((Test-Path "${Env:windir}\Microsoft.NET\Framework\v4.0.30319") -eq $false)
{
    $netUrl = if ($IsCore) {'http://download.microsoft.com/download/3/6/1/361DAE4E-E5B9-4824-B47F-6421A6C59227/dotNetFx40_Full_x86_x64_SC.exe' } `
    else { 'http://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe' }

    $client.DownloadFile( $netUrl, 'dotNetFx40_Full.exe')
    Start-Process -FilePath 'C:\Users\Administrator\dotNetFx40_Full.exe' -ArgumentList '/norestart /q  /ChainingPackage ADMINDEPLOYMENT' -Wait -NoNewWindow
    del dotNetFx40_Full.exe
    Add-Content $log -value "Found that .NET4 was not installed and downloaded / installed"
}

#configure powershell to use .net 4
$config = @'
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <!-- http://msdn.microsoft.com/en-us/library/w4atty68.aspx -->
  <startup useLegacyV2RuntimeActivationPolicy="true">
    <supportedRuntime version="v4.0" />
    <supportedRuntime version="v2.0.50727" />
  </startup>
</configuration>
'@

if (Test-Path "${Env:windir}\SysWOW64\WindowsPowerShell\v1.0\powershell.exe")
{
    $config | Set-Content "${Env:windir}\SysWOW64\WindowsPowerShell\v1.0\powershell.exe.config"
    Add-Content $log -value "Configured 32-bit Powershell on x64 OS to use .NET 4"
}
if (Test-Path "${Env:windir}\system32\WindowsPowerShell\v1.0\powershell.exe")
{
    $config | Set-Content "${Env:windir}\system32\WindowsPowerShell\v1.0\powershell.exe.config"
    Add-Content $log -value "Configured host OS specific Powershell at ${Env:windir}\system32\ to use .NET 4"
}

#enable powershell servermanager cmdlets (only for 2008 r2 + above)
if ($IsCore)
{
    DISM /Online /Enable-Feature /FeatureName:MicrosoftWindowsPowerShell /FeatureName:ServerManager-PSH-Cmdlets /FeatureName:BestPractices-PSH-Cmdlets
    Add-Content $log -value "Enabled ServerManager and BestPractices Cmdlets"

    #enable .NET flavors - on server core only -- errors on regular 2008
    DISM /Online /Enable-Feature /FeatureName:NetFx2-ServerCore /FeatureName:NetFx2-ServerCore-WOW64 /FeatureName:NetFx3-ServerCore /FeatureName:NetFx3-ServerCore-WOW64
    Add-Content $log -value "Enabled .NET frameworks 2 and 3 for x86 and x64"
}

#7zip
$7zUri = if ($Is32Bit) { 'http://sourceforge.net/projects/sevenzip/files/7-Zip/9.22/7z922.msi/download' } `
    else { 'http://sourceforge.net/projects/sevenzip/files/7-Zip/9.22/7z922-x64.msi/download' }

$client.DownloadFile( $7zUri, '7z922.msi')
Start-Process -FilePath "msiexec.exe" -ArgumentList '/i 7z922.msi /norestart /q INSTALLDIR="c:\program files\7-zip"' -Wait
SetX Path "${Env:Path};C:\Program Files\7-zip" /m
$Env:Path += ';C:\Program Files\7-Zip'
del 7z922.msi
Add-Content $log -value "Installed 7-zip from $7zUri and updated path"


#vc 2010 redstributable
$vcredist = if ($Is32Bit) { 'http://download.microsoft.com/download/5/B/C/5BC5DBB3-652D-4DCE-B14A-475AB85EEF6E/vcredist_x86.exe'} `
    else { 'http://download.microsoft.com/download/3/2/2/3224B87F-CFA0-4E70-BDA3-3DE650EFEBA5/vcredist_x64.exe' }

$client.DownloadFile( $vcredist, 'vcredist.exe')
Start-Process -FilePath 'C:\Users\Administrator\vcredist.exe' -ArgumentList '/norestart /q' -Wait
del vcredist.exe
Add-Content $log -value "Installed VC++ 2010 Redistributable from $vcredist and updated path"

#vc 2008 redstributable
$vcredist = if ($Is32Bit) { 'http://download.microsoft.com/download/d/d/9/dd9a82d0-52ef-40db-8dab-95376989c03/vcredist_x86.exe'} `
    else { 'http://download.microsoft.com/download/d/2/4/d242c3fb-da5a-4542-ad66-f9661d0a8d19/vcredist_x64.exe' }

$client.DownloadFile( $vcredist, 'vcredist.exe')
Start-Process -FilePath 'C:\Users\Administrator\vcredist.exe' -ArgumentList '/norestart /q' -Wait
del vcredist.exe
Add-Content $log -value "Installed VC++ 2008 Redistributable from $vcredist and updated path"

#curl
$curlUri = if ($Is32Bit) { 'http://www.paehl.com/open_source/?download=curl_724_0_ssl.zip' } `
    else { 'https://dl.uxnr.de/build/curl/curl_winssl_msys2_mingw64_stc/curl-7.53.1/curl-7.53.1.zip' }

if ((Test-Path "C:\Program Files\curl") -eq $false) {
  $client.DownloadFile( $curlUri, 'curl.zip')
  &7z e curl.zip `-o`"c:\program files\curl`" `-y
  if ($Is32Bit)
  {
      $client.DownloadFile( 'http://www.paehl.com/open_source/?download=libssl.zip', 'libssl.zip')
      &7z e libssl.zip `-o`"c:\program files\curl`" `-y
      del libssl.zip
  }
}
SetX Path "${Env:Path};C:\Program Files\Curl" /m
$Env:Path += ';C:\Program Files\Curl'
del curl.zip -ErrorAction SilentlyContinue
Add-Content $log -value "Installed Curl from $curlUri and updated path"

# install puppet
#https://downloads.puppetlabs.com/windows/puppet-3.2.4.msi
$ErrorActionPreference = "Continue"
& 'C:\Program Files\Curl\curl.exe' -# -G -k -L https://downloads.puppetlabs.com/windows/puppet-3.8.7-x64.msi -o puppet-3.8.7.msi 2>$null > "$log"
$ErrorActionPreference = "Stop"
Start-Process -FilePath 'msiexec.exe' -ArgumentList '/qn /passive /i puppet-3.8.7.msi /norestart INSTALLDIR="C:\puppet"' -Wait
SetX Path "${Env:Path};C:\puppet\bin" /m
&sc.exe config puppet start= demand
Write-Host "Installed Puppet"
Add-Content $log -value "Installed Puppet"

&netsh firewall set portopening tcp 445 smb enable
Add-Content $log -value "Ran firewall config to allow incoming smb/tcp"
