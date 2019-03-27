#Requires -Version 5
#Requires -RunAsAdministrator

#Version: 0.0.0.8

#Hyper-V Module https://technet.microsoft.com/itpro/powershell/windows/hyper-v/hyper-v

function Set-HyperVDefaults
{
	[CmdletBinding()]
	Param ()
	
	#Check for and install Hyper-V if necessary
	Install-HyperV
	
	Write-Host "Checking for Local Disks . . ."
	$drives = Get-WmiObject win32_logicaldisk| Where-Object {$_.drivetype -eq 3} | foreach-object {$_.name}

	foreach ($drivename in $drives)
	{
		$a = new-object -comobject wscript.shell 
		$intAnswer = $a.popup("Do you want to set your Hyper-V VMs and VHDs to $drivename\VMs",0,"Set-VMPath",4) 
		if ($intAnswer -eq 6) { 
			#Hyper-V Settings - Virtual Hard Disks Default Folder
			$VHDPath = Join-Path -Path $drivename -ChildPath "VMs\VHD"
		
			#Hyper-V Settings - Virtual Machines Default Folder
			$VMPath = Join-Path -path $drivename -ChildPath "VMs\VM"
		
			#Create an empty Directory for storing ISO's
			$ISOPath = Join-Path -Path $drivename -ChildPath "VMs\ISO"

			Write-Host ""
			Write-Host "Creating Local Directories . . ."
			mkdir -Path $VMPath, $VHDPath, $ISOPath -ErrorAction 0
		
			Write-Host ""
			Write-Host "Setting Hyper-V Paths . . ."
			Set-VMHost -VirtualHardDiskPath $VHDPath -VirtualMachinePath $VMPath
			
			$registryPath = "hkcu:\Software\OSDeploy"
			if (-NOT (Test-Path $registryPath)) {
				New-Item $registryPath | Out-Null
			}
			Write-Host ""
			Write-Host "Creating Registry Entries . . ."
			New-ItemProperty -Path "hkcu:\Software\OSDeploy" -Name "ISOFile" -Value "" -Force
			New-ItemProperty -Path "hkcu:\Software\OSDeploy" -Name "ISOPath" -Value "$ISOPath" -Force
		}
	}
	
	if ( ! ( Get-VMSwitch | Where {$_.Name -eq "Internal"} ) ) {
		Write-Host ""
		Write-Host "Creating Internal Network Switch . . ."
		New-VMSwitch -Name Internal -SwitchType Internal
	}

	if ( ! ( Get-VMSwitch | Where {$_.Name -eq "Private"} ) ) {
		Write-Host ""
		Write-Host "Creating Private Network Switch . . ."
		New-VMSwitch -Name Private -SwitchType Private
	}

	if ( ! ( Get-VMSwitch | Where {$_.Name -eq "Ethernet"} ) ) {
		$NetAdapterE = Get-NetAdapter -Name ethernet
		if ($NetAdapterE) {
			Write-Host ""
			Write-Host "Creating External Ethernet Network Switch . . ."
			New-VMSwitch -Name Ethernet -NetAdapterName $NetAdapterE.Name -AllowManagementOS $true
		}
	}

	if ( ! ( Get-VMSwitch | Where {$_.Name -eq "Wireless"} ) ) {
		$NetAdapterW = Get-NetAdapter -Name wi-fi
		if ($NetAdapterW) {
			Write-Host ""
			Write-Host "Creating External Wireless Network Switch . . ."
			New-VMSwitch -Name Wireless -NetAdapterName $NetAdapterW.Name -AllowManagementOS $true
		}
	}
	
	Write-Host ""
	Write-Host "Complete"
}

#Button Types
#Value	Description   
#0		Show OK button. 
#1		Show OK and Cancel buttons. 
#2		Show Abort, Retry, and Ignore buttons. 
#3		Show Yes, No, and Cancel buttons. 
#4		Show Yes and No buttons. 
#5		Show Retry and Cancel buttons.