<#
    .SYNOPSIS
        Restores correctly signed netvsc.sys from windows driver store after Citrix PVS Target Device setup on WS2016
    .Description
        After running a Windows Component Cleanup (via DISM, OSDBuilder, ...) this driver has no longer a valid signature.
        This seems to be a problem with Windows itself and occures since netvsc.sys file version 10.0.14393.351 from KB3197954 released on 16/10/27
    .EXAMPLE
    .INPUTS
    .OUTPUTS
    .NOTES
		Script generates a log file when called and exits always with 0.
		Can be perfectly used in MDT/SCCM task sequence.
		Script was made for german OS versions. Users and Groups may need to be renamed accordingly (i.e. Administratoren = Administrators, Benutzer = Users)
	.LINK
#>

Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)

$Vendor = "My Company"
$Product = "netvsc.sys fix"
$Version = "1.0"

$LogPS = "${env:SystemRoot}" + "\Temp\$Vendor $Product $Version PS Wrapper.log"
Start-Transcript $LogPS

Write-Verbose "Taking ownership and setting permissions of netvsc.sys ..." -Verbose
(Start-Process "$env:systemroot\System32\takeown.exe" -ArgumentList "/F $env:systemroot\system32\drivers\netvsc.sys /A" -Passthru -Wait).ExitCode
(Start-Process "$env:systemroot\System32\cacls.exe"   -ArgumentList "$env:systemroot\system32\drivers\netvsc.sys /e /G Administratoren:F" -Passthru -Wait).ExitCode

# Copy File to System32
Write-Verbose "Copy signed file from DriverStore" -Verbose
Get-ChildItem -Path $env:systemroot\System32\DriverStore\FileRepository\wnetvsc.inf_amd* -Recurse | Where {$_.Name -eq "netvsc.sys"} | Sort LastWriteTime -Descending | Select -First 1 | Copy-Item -Destination "$env:systemroot\system32\drivers" -Force

Write-Verbose "Reset ownership of netvsc.sys" -Verbose
(Start-Process "$env:systemroot\System32\cacls.exe"  -ArgumentList "$env:systemroot\system32\drivers\netvsc.sys /e /r SYSTEM" -Passthru -Wait).ExitCode
(Start-Process "$env:systemroot\System32\cacls.exe"  -ArgumentList "$env:systemroot\system32\drivers\netvsc.sys /e /g SYSTEM:F" -Passthru -Wait).ExitCode
(Start-Process "$env:systemroot\System32\cacls.exe"  -ArgumentList "$env:systemroot\system32\drivers\netvsc.sys /e /r Administratoren" -Passthru -Wait).ExitCode
(Start-Process "$env:systemroot\System32\cacls.exe"  -ArgumentList "$env:systemroot\system32\drivers\netvsc.sys /e /r Benutzer" -Passthru -Wait).ExitCode
(Start-Process "$env:systemroot\System32\cacls.exe"  -ArgumentList "$env:systemroot\system32\drivers\netvsc.sys /e /g Benutzer:R" -Passthru -Wait).ExitCode
(Start-Process "$env:systemroot\System32\cacls.exe"  -ArgumentList "$env:systemroot\system32\drivers\netvsc.sys /e /g ""NT SERVICE\TrustedInstaller"":F" -Passthru -Wait).ExitCode
(Start-Process "$env:systemroot\System32\icacls.exe" -ArgumentList "$env:systemroot\system32\drivers\netvsc.sys /setowner ""NT SERVICE\TrustedInstaller""" -Passthru -Wait).ExitCode
Stop-Transcript

# End script, returning always 0 (SUCCESS)
Exit 0
