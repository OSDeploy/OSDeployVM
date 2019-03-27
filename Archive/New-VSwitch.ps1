#Requires -Version 5
#Requires -RunAsAdministrator

#Version: 0.0.0.8

#Hyper-V Module https://technet.microsoft.com/itpro/powershell/windows/hyper-v/hyper-v

function New-VSwitch
{
	[CmdletBinding()]
	Param (
		[switch]$Internal = $false,
		[switch]$Private = $false,
		[switch]$Ethernet = $false,
		[switch]$Wireless = $false
	)
	
	#Check for and install Hyper-V if necessary
	Install-HyperV

If ( ! ( Get-VMSwitch | Where {$_.Name -eq "Internal"} ) ) {
	Write-Host ""
    Write-Host "Creating Internal Switch . . ."
	New-VMSwitch -Name Internal -SwitchType Internal
}

If ( ! ( Get-VMSwitch | Where {$_.Name -eq "Private"} ) ) {
	Write-Host ""
    Write-Host "Creating Private Switch . . ."
	New-VMSwitch -Name Private -SwitchType Private
}

If ( ! ( Get-VMSwitch | Where {$_.Name -eq "Ethernet"} ) ) {
	$NetAdapterE = Get-NetAdapter -Name ethernet
	if ($NetAdapterE) {
        Write-Host ""
		Write-Host "Creating External Ethernet Switch . . ."
		New-VMSwitch -Name Ethernet -NetAdapterName $NetAdapterE.Name -AllowManagementOS $true
	}
}

If ( ! ( Get-VMSwitch | Where {$_.Name -eq "Wireless"} ) ) {
	$NetAdapterW = Get-NetAdapter -Name wi-fi
	if ($NetAdapterW) {
        Write-Host ""
		Write-Host "Creating External Wireless Switch . . ."
		New-VMSwitch -Name Wireless -NetAdapterName $NetAdapterW.Name -AllowManagementOS $true
	}
}


	Write-Host "Creating Ethernet Switch . . ."
	New-VMSwitch -Name Ethernet -SwitchType Private
}



	
	if ($Internal) {
		Write-Host "Checking for Internal Switch . . ."
		$VMSwitchInternal = Get-VMSwitch -Name Internal -ErrorAction SilentlyContinue
		if ($VMSwitchInternal) {Write-Host "Internal Switch Exists!"}
		if (!$VMSwitchInternal) {
			Write-Host "Creating Internal Switch"
			New-VMSwitch -Name Internal -SwitchType Internal
		}
	}
	
	if ($Private) {
		Write-Host ""
		Write-Host "Checking for Private Switch . . ."
		$VMSwitchPrivate = Get-VMSwitch -Name Private -ErrorAction SilentlyContinue
		if ($VMSwitchPrivate) {Write-Host "Private Switch Exists!"}
		if (!$VMSwitchPrivate) {
			Write-Host "Creating Private Switch"
			New-VMSwitch -Name Private -SwitchType Private
		}
	}
	
	if ($Ethernet) {
		Write-Host ""
		Write-Host "Checking for External Ethernet Switch . . ."
		$NetAdapterE = Get-NetAdapter -Name ethernet
		if ($NetAdapterE) {
			$VMSwitchEthernet = Get-VMSwitch -Name Ethernet -ErrorAction SilentlyContinue
			if ($VMSwitchEthernet) {Write-Host "External Ethernet Switch Exists!"}
			if (!$VMSwitchEthernet) {
				Write-Host "Creating External Ethernet Switch"
				New-VMSwitch -Name Ethernet -NetAdapterName $NetAdapterE.Name -AllowManagementOS $true
			}
		}
	}
	
	if ($Wireless) {
		Write-Host ""
		Write-Host "Checking for External Wireless Switch . . ."
		$NetAdapterW = Get-NetAdapter -Name wi-fi
		if ($NetAdapterW) {
			$VMSwitchWireless = Get-VMSwitch -Name Wireless -ErrorAction SilentlyContinue
			if ($VMSwitchWireless) {Write-Host "External Wireless Switch Exists!"}
			if (!$VMSwitchWireless) {
				Write-Host "Creating External Wireless Switch"
				New-VMSwitch -Name Wireless -NetAdapterName $NetAdapterW.Name -AllowManagementOS $true
			}
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