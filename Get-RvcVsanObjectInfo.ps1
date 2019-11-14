Function Get-RvcVsanObjectInfo {
	<#
	.SYNOPSIS
	This function mimics the output of the RVC vsan.vm_object_info script
	.DESCRIPTION
  This function mimics the output of the RVC vsan.vm_object_info script
  .PARAMETER Cluster
	The vSAN Cluster 
	.PARAMETER VM
	The VM we wish to gather vSAN Object information for

	.EXAMPLE
	PS C:\> Get-RvcVsanObjectInfo -Cluster $VsanCluster -VM $VM

	.NOTES
	Author                                    : Jase McCarty
	Version                                   : 0.1
  Requires                                  : PowerCLI 11.0
                                              William Lam's VSANUUIDtoVM & 
	==========Tested Against Environment==========
	VMware vSphere Hypervisor(ESXi) Version   : 6.7
	VMware vCenter Server Version             : 6.7
	PowerCLI Version                          : PowerCLI 11.0
	PowerShell Core Version                   : 6.1
	#>
	
	# Set our Parameters
	[CmdletBinding()]Param(
	[Parameter(Mandatory=$true)][String]$VsanCluster,
	[Parameter(Mandatory=$true)][String]$VM
	)

    $Cluster = Get-Cluster -Name $VsanCluster
    $VsanVM = Get-VM -Name $VM 
    $VMObjects = Get-VsanObject -VM $VsanVM
    $SPBM_Policies = Get-SpbmStoragePolicy
    Write-Host "VM $VsanVM"

    Foreach ($VMObject in $VMObjects) {

        Switch ($VMObject.Type) {
            "VmNamespace" {
                Write-Host "Namespace directory - " -NoNewline
            }
            "VmSwap" {
                Write-Host "VmSwap - " -NoNewline                
            }
            "VDisk" {
                Write-Host "Virtual Disk - " -NoNewline                
            }
        }

        Write-Host "Storage Policy - " $VMObject.StoragePolicy.Name -NoNewline
        Write-Host (Get-SpbmStoragePolicy -Name $VMObject.StoragePolicy).AnyOfRuleSets.AnyOfRuleSets
        Get-VSANUUIDToVM -Cluster $Cluster -VSANObjectID $VMObject.id 

        Foreach ($VsCp in (Get-VsanComponent -VsanObject $VMObject)) {

            Write-Host "   " $VsCP.Type ": " -NoNewline 
            Write-Host $VsCp.id " (" -NoNewline
            Write-Host "state:" -NoNewline
            If ($VsCp.Status -eq "ACTIVE") {
                Write-Host $VsCp.Status ", " -NoNewline -ForegroundColor Green
            } else {
                Write-Host $VsCp.Status ", " -NoNewline -ForegroundColor Yellow
            }
            Write-Host "capacity disk:" $VsCp.VsanDisk -NoNewline 
            Write-Host " host: " $VsCp.VsanDisk.VsanDiskGroup.VMHost.Name  -NoNewline
            Write-Host ")"
        }
    Write-Host " "
    }    
}
