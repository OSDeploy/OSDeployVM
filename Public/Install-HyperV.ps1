#Requires -Version 5
#Requires -RunAsAdministrator

#Version:		0.0.0.8

function Install-HyperV
{
	[CmdletBinding()]
	Param ()

	$VHDCmdlets = $true

	Write-Host "Checking Hyper-V . . ."
	if (-not (Get-Module -Name hyper-v -ListAvailable)) {
		Write-Host "Hyper-V NOT Installed"
		$VHDCmdlets = $false
	} else {
		Write-Host "Hyper-V Installed"
	}
	
	Write-Host ""
	
	Write-Host "Checking Hyper-V Services . . ."
	if ([environment]::OSVersion.Version.Major -ge 10 -and 
	(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Services).state -eq 'Disabled') {
		Write-Host "Hyper-V Services NOT Installed"
		$VHDCmdlets = $false
	} else {
		Write-Host "Hyper-V Services Installed"
	}
	
	Write-Host ""

	if (!$VHDCmdlets) {
		$shell = New-Object -ComObject Wscript.Shell
		$shell.Popup("Hyper-V is not completely installed.  It will be installed and a restart will be required before using OSDeployVM PowerShell Modules",0,"OSDeployVM",0x0)
		Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
		$shell.Popup("Restart your computer to complete the installation of Hyper-V",0,"OSDeployVM",0x0)
		Return
	}
}
