Function Get-VsanHostInfo {
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

    # Print the vSAN Witness Host Information
    $CurrentHost = Get-VMhost -Name $VsanHost

    Write-Host "Host:" $CurrentHost.Name " " -ForegroundColor Green
    Write-Host "  Product:" $CurrentHost.Version ", Build:" $CurrentHost.Build

    # Setup EsxCli for the Current Host 
    $CurrentEsxCli = Get-EsxCli -VMHost $CurrentHost.Name -V2

    # Get the Cluster Details
    $HostClusterInfo = $CurrentEsxCli.vsan.cluster.get.invoke()
    Write-Host "  Cluster info:" -ForegroundColor Green
    Write-Host "    Cluster role:" $HostClusterInfo.LocalNodeState
    Write-Host "    Cluster UUID:" $HostClusterInfo.SubClusterUUID
    Write-Host "    Node UUID   :" $HostClusterInfo.LocalNodeUUID
    Write-Host "    Member UUIDs: " $HostClusterInfo.SubClusterMemberUUIDs
    Write-Host "    Member Hosts: " $HostClusterInfo.SubClusterMemberHostNames
    Write-Host "    Node Type   :" $HostClusterInfo.LocalNodeType
    Write-Host "  Storage info:" -ForegroundColor Green
    Write-Host "    Disk Mappings:"

    # Enumerate all the Disk Groups, and sorting by Cache Device first.
    Foreach ($DiskGroup in (Get-VsanDiskGroup -VMHost $CurrentHost)) {
        $CurrentDiskGroup = $DiskGroup | Get-VsanDisk | Sort-Object -Property IsCacheDisk -Descending
        Foreach ($Disk in $CurrentDiskGroup) {
            If ($Disk.IsCacheDisk -eq $true) {
                Write-Host "      Cache Tier   : " -NoNewline
            } else {
                Write-Host "      Capacity Tier: " -NoNewline
            }
            $DiskCapacity = [math]::Round($Disk.CapacityGB)
            Write-Host $Disk.CanonicalName " - Size:" -NoNewLine
            Write-Host $DiskCapacity "GB" -NoNewLine
            Write-Host " - Disk Version:" $Disk.DiskFormatVersion                
        }
    }

    # Fault Domain Information
    Write-Host "  Fault Domain Info:" -ForegroundColor Green
    Write-Host "  " (Get-VsanFaultDomain -VMhost $CurrentHost)

    # Retrieve any Networking Information
    Write-Host "  Network Info:" -ForegroundColor Green

    # Retrieve any VMkernel interfaces that have vSAN Traffic Tagged
    $HostAdapter = ($CurrentHost | Get-VMHostNetworkAdapter).Where{$_.VsanTrafficEnabled -eq $True}
    If ($HostAdapter) {
        Write-Host "    Adapter: " $HostAdapter.Name "(" $HostAdapter.IP ") - vSAN Traffic"        
    } else {
        Write-Host "    Adapter: "
    }

    # Attempt to return any interfaces that have vSAN Traffic Enabled - Will not work on a vSAN Witness Host
    Try {
        $WitnessAdapter = ($CurrentEsxCli.vsan.network.list.invoke()).Where{$_.TrafficType -eq "witness"}
        If ($WitnessAdapter) {
            $WitnessIP = (Get-VMHostNetworkAdapter -VMhost $CurrentHost).Where{$_.DeviceName -eq $WitnessAdapter.VmkNicName}
            Write-Host "    Adapter: " $WitnessAdapter.VmkNicName "(" $WitnessIP.IP ") - Witness Traffic"
        }
    } Catch {}

    # Attempt to return the Encryption State - Will not work on a vSAN Witness Host
    Try {
        $EncryptionInfo = ($CurrentEsxCli.vsan.encryption.info.get.invoke()).Where{$_.Attribute -eq "enabled"}
        Write-Host "  Encryption enabled:" $EncryptionInfo.Value  -ForegroundColor Green
    } Catch {}
    Write-Host " "
}

Function Get-RvcVsanClusterInfo {
    <#
        .NOTES
        ===========================================================================
         Created by:    Jase McCarty
         Organization:  VMware
         Blog:          https://jasemccarty.com
         Twitter:       @jasemccarty
        ===========================================================================
        .SYNOPSIS
            This function retrives the same information returned by the vsan.cluster_info RVC command
        .DESCRIPTION
            This function retrives the same information returned by the vsan.cluster_info RVC command
        .PARAMETER Cluster 
            Cluster the Cluster Name
        .EXAMPLE
            Get-RvcVsanClusterInfo -Cluster vSANCluster

    #>
    [CmdletBinding()]
    Param([Parameter(Mandatory = $True)][String]$Cluster)

    Write-Host " "

    # Retrieve the vSAN Cluster configuration
    $VsanCluster = Get-VsanClusterConfiguration -Cluster $Cluster 

    If ($VsanCluster.StretchedClusterEnabled -eq $True) {

        # Get the vSAN Witness Host Information
        $VsanWitnessHost = $VsanCluster.WitnessHost

        # Call Get-VsanHostInfo with the vSAN Witness Host
        Get-VsanHostInfo -VsanHost $VsanWitnessHost

    }

    # Retrieve all of the vSAN Data Nodes in the Cluster
    $ClusterHosts = Get-Cluster -Name $Cluster | Get-VMHost | Sort-Object Name

    Foreach ($ClusterHost in $ClusterHosts) {
        # Call Get-VsanHostInfo with the vSAN Witness Host
        Get-VsanHostInfo -VsanHost $ClusterHost
    }
                Write-Host " "

    # Look for any Fault Domains
    $VsanFaultDomains = Get-VsanFaultDomain -Cluster $Cluster
    If ($VsanFaultDomains) {
        Write-Host "Cluster has fault domains configured:" -ForegroundColor Green
        Foreach ($FD in $VsanFaultDomains) {
            Write-Host $FD.Name " Fault Domain Hosts:" -NoNewline
            $FdHosts = $FD | Get-VMHost | Sort-Object -Property Name
            Foreach ($FdHost in $FdHosts) { Write-Host $FdHost " " -NoNewline}
            Write-Host " "
        }
    }

    # If it is a 2 Node or Stretched vSAN Cluster, print the Preferred Fault Domain
    If ($VsanCluster.StretchedClusterEnabled -eq $True) {
        Write-Host " "
        Write-Host "Stretched Cluster Preferred Fault Domain:" $VsanCluster.PreferredFaultDomain -ForegroundColor Green
    }
}

#Example 
Get-RvcVsanClusterInfo -Cluster StretchedCluster



Get-RvcVsanClusterInfo -Cluster StretchedCluster
