Function Get-RvcVsanDisksInfo {
    <#
    .NOTES
    ===========================================================================
        Created by:    Jase McCarty
        Organization:  VMware
        Blog:          https://jasemccarty.com
        Twitter:       @jasemccarty
    ===========================================================================
    .SYNOPSIS
        This function retrives vSAN host information
    .DESCRIPTION
        This function retrives vSAN host information
    .PARAMETER VsanHost 
        vSAN Host 
    .EXAMPLE
        Get-VsanHostInfo -VsanHost <hostname>
    #> 
    [CmdletBinding()]
    Param([Parameter(Mandatory = $True)][String]$VsanHost)
    
    # Retrieve the disks for the specified host. Only grab disks, and sort them by the capacity
    $HostDisks = (Get-ScsiLun -VmHost $VsanHost).Where{$_.LunType -eq "disk"}|Sort-Object -Property CapacityGB

    # Create the array to put our results in
    $DiskInfoResults=@()

    # Enumerate each disk on the specified host
    Foreach ($HostDisk in $HostDisks) {

        # Create a custom object to store each disk's properties
        $DiskInfo = New-Object -TypeName PSCustomObject 
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name DisplayName -Value ""
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name Model -Value ""
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name Revision -Value ""
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name IsSSd -Value ""    
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name Size -Value ""
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name UsedByVsan -Value ""
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name DiskFormatVersion -Value ""
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name VsanUse -Value ""
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name Hba -Value ""
        Add-Member -InputObject $DiskInfo -MemberType NoteProperty -Name Controller -Value ""
    
        # Add each property to the current record that is added to the array
        $DiskInfo.DisplayName = $HostDisk.ExtensionData.DisplayName
        $DiskInfo.Model = $HostDisk.Model
        $DiskInfo.Revision = $HostDisk.ExtensionData.Revision
        $DiskInfo.IsSSD = $HostDisk.IsSSD 
        $DiskInfo.Size = [math]::Round($HostDisk.CapacityGB)
        $DiskInfo.UsedByVsan = $HostDisk.VsanStatus

        # If the disk is used by vSAN, grab how it is used, and the Disk Format Version
        If ($DiskInfo.UsedByVsan -eq "InUse") {
            $CurrentVsanDisk = Get-VsanDisk -VMHost $VsanHost -CanonicalName $HostDisk.CanonicalName
            $DiskInfo.DiskFormatVersion = $CurrentVsanDisk.DiskFormatVersion
            If ($CurrentVsanDisk.IsCacheDisk -ne $True) {
                $DiskInfo.VsanUse = "Capacity"
            } else {
                $DiskInfo.VsanUse = "Cache"
            }
        }

        # Retrieve the HBA name and the name of the controller 
        $HbaName = $HostDisk.RuntimeName -Split ":"
        $DiskInfo.Hba = $HbaName[0]
        $DiskInfo.Controller = (Get-VMhostHba -VMhost $VsanHost -Device $HbaName[0]).Model

        # Add the current record to the results array
        $DiskInfoResults += $DiskInfo
    }

    # Return the array 
    $DiskInfoResults | Format-Table *
}

# Example
Get-RvcVsanDisksInfo -VsanHost "w3-hs1-050101.eng.vmware.com"
