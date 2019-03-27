#Requires -Version 5
#Requires -RunAsAdministrator

#Version: 0.0.0.8

#Hyper-V Module https://technet.microsoft.com/itpro/powershell/windows/hyper-v/hyper-v

function New-VMachine
{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True)]
		[string]$Name,
		[uint64]$GBDiskSize = 100,
		[string]$ISOFileName,
		[int]$Processors = 1,
		[uint64]$GBRamMax = 8,
		[uint64]$GBRamMin = 2,
		[uint64]$GBRamStart = 4,
		[switch]$VSwitchEthernet = $false,
		[switch]$VSwitchPrivate = $false,
		[switch]$VSwitchWireless = $false,
		[switch]$UEFIbios = $false	
	)
	
	#Check for and install Hyper-V if necessary
	Install-HyperV
	
	Write-Host "Checking Registry hkcu:\Software\OSDeploy . . ."
	$registryPath = "hkcu:\Software\OSDeploy"
	if (-NOT (Test-Path $registryPath))
	{
		Write-Host "Creating!"
		New-Item $registryPath | Out-Null
	} else {
		Write-Host "OK!"
	}
	
	if (-NOT ((Get-Item "hkcu:\Software\OSDeploy" -EA Ignore).Property -contains "ISOFile")) {New-ItemProperty -Path "hkcu:\Software\OSDeploy" -Name "ISOFile" -Value "" -Force}
	if (-NOT ((Get-Item "hkcu:\Software\OSDeploy" -EA Ignore).Property -contains "ISOPath")) {New-ItemProperty -Path "hkcu:\Software\OSDeploy" -Name "ISOPath" -Value "" -Force}
	
	$ISOFile = Get-ItemPropertyValue 'hkcu:\Software\OSDeploy' 'ISOFile' -ErrorAction SilentlyContinue
	Write-Host "Checking ISOFile Value . . . $ISOFile"
	
	$ISOPath = Get-ItemPropertyValue 'hkcu:\Software\OSDeploy' 'ISOPath' -ErrorAction SilentlyContinue
	Write-Host "Checking ISOPath Value . . . $ISOPath"
	
	If (!$ISOPath) {$ISOPath = "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"}
	
	if (!$ISOFileName)
	{
		if ($ISOFile)
		{
			$shell = New-Object -ComObject Wscript.Shell
			$intAnswer = $shell.popup("Do you want to attach $ISOFile to this Virtual Machine?",0,"OSDeployVM",4)
			if ($intAnswer -eq 6)
			{
				$ISOFileName = $ISOFile
				Set-ItemProperty -Path "hkcu:\Software\OSDeploy" -Name "ISOFile" -Value "$ISOFileName" -Force -ErrorAction SilentlyContinue
			}
		}
	}
	
	if (!$ISOFileName)
	{
		if ($ISOPath)
		{
			$shell = New-Object -ComObject Wscript.Shell
			$shell.Popup("Select an ISO to Mount to the Virtual Machine",0,"OSDeployVM",0x0)
			$ISOFileName = Get-FileNameISO $ISOPath
			Set-ItemProperty -Path "hkcu:\Software\OSDeploy" -Name "ISOPath" -Value "$ISOPath" -Force -ErrorAction SilentlyContinue
			Set-ItemProperty -Path "hkcu:\Software\OSDeploy" -Name "ISOFile" -Value "$ISOFileName" -Force -ErrorAction SilentlyContinue
		}
	}
	
	#Convert Sizes to GB
	$GBDiskSize = $GBDiskSize * 1GB
	$GBRamMin = $GBRamMin * 1GB
	$GBRamMax = $GBRamMax * 1GB
	$GBRamStart = $GBRamStart * 1GB
	
	#Set BIOS or UEFI
	if ($UEFIbios) {$VMGeneration = 2} Else {$VMGeneration = 1}

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/get-vmhost
	Write-Host "Getting VirtualMachinePath . . . $VMPath"
	$VMPath = (Get-VMHost).VirtualMachinePath

	#https://technet.microsoft.com/en-us/itpro/powershell/windows/hyper-v/get-vmswitch
	If ( ! ( Get-VMSwitch | Where {$_.Name -eq "Internal"} ) ) {
		Write-Host ""
		Write-Host "Creating Internal Network Switch . . ."
		New-VMSwitch -Name Internal -SwitchType Internal
	}

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/new-vm
	Write-Host "Creating New VM . . . New-VM -Name $Name -Path $VMPath -Generation $VMGeneration -SwitchName Internal"
	New-VM -Name $Name -Path $VMPath -Generation $VMGeneration -SwitchName Internal
	
	#https://technet.microsoft.com/en-us/itpro/powershell/windows/hyper-v/set-vmprocessor
	Write-Host "Setting Processors . . . Set-VMProcessor $Name -Count $Processors"
	Set-VMProcessor $Name -Count $Processors

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/new-vhd
	Write-Host "Creating New VHD . . . New-VHD -Path $VMPath\$Name\VHD\$Name.vhdx -SizeBytes $GBDiskSize -Dynamic"
	New-VHD -Path $VMPath\$Name\VHD\$Name.vhdx -SizeBytes $GBDiskSize -Dynamic

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/add-vmharddiskdrive
	Write-Host "Adding VM Hard Disk . . . Add-VMHardDiskDrive -VMName $Name -Path $VMPath\$Name\VHD\$Name.vhdx"
	Add-VMHardDiskDrive -VMName $Name -Path $VMPath\$Name\VHD\$Name.vhdx

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/set-vmdvddrive
	#if (!$UEFIbios) Write-Host "Creating VM DVD Drive . . . Set-VMDvdDrive -VMName $Name -ControllerNumber 1 -ControllerLocation 0 -Path $ISOFileName"
	if (!$UEFIbios) { Set-VMDvdDrive -VMName $Name -ControllerNumber 1 -ControllerLocation 0 -Path $ISOFileName }

	#https://technet.microsoft.com/en-us/itpro/powershell/windows/hyper-v/add-vmdvddrive
	#if ($UEFIbios) Write-Host "Creating VM DVD Drive . . . Add-VMDvdDrive -VMName $Name -Path $ISOFileName"
	if ($UEFIbios) { Add-VMDvdDrive -VMName $Name -Path $ISOFileName }

	#https://technet.microsoft.com/en-us/itpro/powershell/windows/hyper-v/set-vmfirmware
	#if ($UEFIbios) Write-Host "Setting VM Firmware . . ."
	if ($UEFIbios) {$vmDvdDrive = Get-VMDvdDrive $Name}
	if ($UEFIbios) {$vmHardDiskDrive = Get-VMHardDiskDrive $Name}
	if ($UEFIbios) {$vmNetworkAdapter = Get-VMNetworkAdapter $Name}
	if ($UEFIbios) {Set-VMFirmware $Name -BootOrder $vmDvdDrive, $vmHardDiskDrive, $vmNetworkAdapter}

	#if ($UEFIbios) Write-Host "Disabling Secure Boot . . . Set-VMFirmware $Name -EnableSecureBoot Off"
	if ($UEFIbios) {Set-VMFirmware $Name -EnableSecureBoot Off}

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/remove-vmscsicontroller
	#if (!$UEFIbios) Write-Host "Removing SCSI Controller . . . Remove-VMScsiController -VMName $Name -ControllerNumber 0 | Remove-VMScsiController"
	if (!$UEFIbios) {Remove-VMScsiController -VMName $Name -ControllerNumber 0 | Remove-VMScsiController}

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/enable-vmintegrationservice
	Write-Host "Enabling Guest Services . . . Enable-VMIntegrationService -VMName $Name -Name Guest Service Interface"
	Enable-VMIntegrationService -VMName $Name -Name "Guest Service Interface"

	#	Specifies the action the virtual machine is to take upon start. Allowed values are Nothing, StartifRunning, and Start.
	Write-Host "Disabling Automatic Start . . . Set-VM -Name $Name -AutomaticStartAction Nothing"
	Set-VM -Name $Name -AutomaticStartAction Nothing

	#	Specifies the number of seconds by which the virtual machine's start should be delayed.
	Write-Host "Setting Automatic Start Delay . . . Set-VM -Name $Name -AutomaticStartDelay 5"
	Set-VM -Name $Name -AutomaticStartDelay 5

	#	Specifies the action the virtual machine is to take when the virtual machine host shuts down. Allowed values are TurnOff, Save, and ShutDown.
	Write-Host "Setting Automatic Stop Action . . . Set-VM -Name $Name -AutomaticStopAction TurnOff"
	Set-VM -Name $Name -AutomaticStopAction TurnOff

	#	Allows you to configure the type of checkpoints created by Hyper-V. The acceptable values for this parameter are:
	#	Disabled. Block creation of checkpoints. 
	#	Standard. Create standard checkpoints. 
	#	Production. Create production checkpoints if supported by guest operating system. Otherwise, create standard checkpoints.
	#	ProductionOnly. Create production checkpoints if supported by guest operating system. Otherwise, the operation fails.
	Write-Host "Setting Checkpoint Type to Standard . . . Set-VM -Name $Name -CheckpointType Standard"
	Set-VM -Name $Name -CheckpointType Standard

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/set-vmmemory
	Write-Host "Setting VM Memory . . . Set-VMMemory -VMName $Name -DynamicMemoryEnabled $true -MinimumBytes $GBRamMin -MaximumBytes $GBRamMax -StartupBytes $GBRamStart"
	Set-VMMemory -VMName $Name -DynamicMemoryEnabled $true -MinimumBytes $GBRamMin -MaximumBytes $GBRamMax -StartupBytes $GBRamStart

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/add-vmnetworkadapter
	if ($VSwitchPrivate) {
		if ( ! ( Get-VMSwitch | Where {$_.Name -eq "Private"} ) ) {
			Write-Host ""
			Write-Host "Creating Private Network Switch . . ."
			New-VMSwitch -Name Private -SwitchType Private
		}
		Add-VMNetworkAdapter -VMName $Name -SwitchName Private -IsLegacy $false
	}
	
	if ($VSwitchEthernet) {
		if ( ! ( Get-VMSwitch | Where {$_.Name -eq "Ethernet"} ) ) {
			$NetAdapterE = Get-NetAdapter -Name ethernet
			if ($NetAdapterE) {
				Write-Host ""
				Write-Host "Creating External Ethernet Network Switch . . ."
				New-VMSwitch -Name Ethernet -NetAdapterName $NetAdapterE.Name -AllowManagementOS $true
			}
		}
		Add-VMNetworkAdapter -VMName $Name -SwitchName Ethernet -IsLegacy $false
	}

	if ($VSwitchWireless) {
		if ( ! ( Get-VMSwitch | Where {$_.Name -eq "Wireless"} ) ) {
			$NetAdapterW = Get-NetAdapter -Name wi-fi
			if ($NetAdapterW) {
				Write-Host ""
				Write-Host "Creating External Wireless Network Switch . . ."
				New-VMSwitch -Name Wireless -NetAdapterName $NetAdapterW.Name -AllowManagementOS $true
			}
		}
		Add-VMNetworkAdapter -VMName $Name -SwitchName Wireless -IsLegacy $false
	}

	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/checkpoint-vm
	Write-Host "Creating Checkpoints . . ."
	Checkpoint-VM -Name $Name -SnapshotName "New VM"
	Checkpoint-VM -Name $Name -SnapshotName "Current Build"

	# 	View Settings as List
	Get-VM -Name $Name | Format-List *
	
	$ComputerName = $env:COMPUTERNAME
	Write-Host "Connecting to VM . . . vmconnect.exe $ComputerName $Name"
	vmconnect.exe $ComputerName $Name
	
	#https://technet.microsoft.com/itpro/powershell/windows/hyper-v/start-vm
	Write-Host "Starting VM . . . Start-VM -Name $Name"
	Start-VM -Name $Name
	
	Write-Host "Script Complete!"
}

#Button Types
#Value	Description   
#0		Show OK button. 
#1		Show OK and Cancel buttons. 
#2		Show Abort, Retry, and Ignore buttons. 
#3		Show Yes, No, and Cancel buttons. 
#4		Show Yes and No buttons. 
#5		Show Retry and Cancel buttons.

function Get-FileNameISO($initialDirectory)
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "ISO (*.iso)| *.iso"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}