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
    [CmdletBinding()]Param([Parameter(Mandatory = $True)][String]$Cluster)

    Write-Host " "

    # Retrieve the vSAN Cluster configuration
    $VsanCluster = Get-VsanClusterConfiguration -Cluster $Cluster 

    If ($VsanCluster.StretchedClusterEnabled -eq $True) {

        # Print the vSAN Witness Host Information
        $VsanWitnessHost = $VsanCluster.WitnessHost

        Write-Host "Host:" $VsanWitnessHost.Name " " -ForegroundColor Green
        Write-Host "  Product:" $VsanWitnessHost.Version ", Build:" $VsanWitnessHost.Build
        $WitnessEsxCli = Get-EsxCli -VMHost $VsanWitnessHost.Name -V2
        $WitnessClusterGet = $WitnessEsxCli.vsan.cluster.get.invoke()
        Write-Host "  Cluster info:" -ForegroundColor Green
        Write-Host "    Cluster role:" $WitnessClusterGet.LocalNodeState
        Write-Host "    Cluster UUID:" $WitnessClusterGet.SubClusterUUID
        Write-Host "    Node UUID   :" $WitnessClusterGet.LocalNodeUUID
        Write-Host "    Member UUIDs: " $WitnessClusterGet.SubClusterMemberUUIDs
        Write-Host "    Member Hosts: " $WitnessClusterGet.SubClusterMemberHostNames
        Write-Host "    Node Type   :" $WitnessClusterGet.LocalNodeType
        Write-Host "  Storage info:" -ForegroundColor Green
        Write-Host "    Disk Mappings:"
        Write-Host "      Cache Tier   :" (($VsanWitnessHost | Get-VsanDiskGroup | Get-VsanDisk).Where{$_.IsCacheDisk -eq $True}).CanonicalName
        Write-Host "      Capacity Tier:" (($VsanWitnessHost | Get-VsanDiskGroup | Get-VsanDisk).Where{$_.IsCacheDisk -ne $True}).CanonicalName
        Write-Host "  Fault Domain Info:" -ForegroundColor Green
        Write-Host "  " (Get-VsanFaultDomain -VMhost $VsanWitnessHost)
        Write-Host "  Network Info:" -ForegroundColor Green
        $VsanWitnessHostAdapter = ($VsanWitnessHost | Get-VMHostNetworkAdapter).Where{$_.VsanTrafficEnabled -eq $True}
        If ($VsanWitnessHostAdapter) {
            Write-Host "    Adapter: " $VsanWitnessHostAdapter.Name "(" $VsanWitnessHostAdapter.IP ")"           
        } else {
            Write-Host "    Adapter: "
        }
    }

    # Retrieve all of the vSAN Data Nodes in the Cluster
    $ClusterHosts = Get-Cluster -Name $Cluster | Get-VMHost | Sort-Object Name

    Foreach ($ClusterHost in $ClusterHosts) {
                # Print the vSAN Witness Host Information
                $CurrentHost = $ClusterHost.Name

                Write-Host "Host:" $ClusterHost.Name " " -ForegroundColor Green
                Write-Host "  Product:" $ClusterHost.Version", Build:" $ClusterHost.Build
                $ClusterHostEsxCli = Get-EsxCli -VMHost $ClusterHost.Name -V2
                $ClusterHostInfo = $ClusterHostEsxCli.vsan.cluster.get.invoke()
                Write-Host "  Cluster info: " -ForegroundColor Green
                Write-Host "    Cluster role: " $ClusterHostInfo.LocalNodeState
                Write-Host "    Cluster UUID: " $ClusterHostInfo.SubClusterUUID
                Write-Host "    Node UUID   : " $ClusterHostInfo.LocalNodeUUID
                Write-Host "    Member UUIDs: " $ClusterHostInfo.SubClusterMemberUUIDs
                Write-Host "    Member Hosts: " $ClusterHostInfo.SubClusterMemberHostNames
                Write-Host "    Node Type   : " $ClusterHostInfo.LocalNodeType
                Write-Host "  Storage info:" -ForegroundColor Green
                Write-Host "    Disk Mappings: "
                Foreach ($DiskGroup in (Get-VsanDiskGroup -VMHost $CurrentHost)) {
                    $CurrentDiskGroup = $DiskGroup | Get-VsanDisk | Sort-Object -Property IsCacheDisk -Descending
                    Foreach ($Disk in $CurrentDiskGroup) {
                        If ($Disk.IsCacheDisk -eq $true) {
                            Write-Host "      Cache Tier   : " -NoNewline
                        } else {
                            Write-Host "      Capacity Tier: " -NoNewline
                        }
                        Write-Host $Disk.CanonicalName                
                    }
                    Write-Host "  Fault Domain Info:" -ForegroundColor Green
                    Write-Host "  " (Get-VsanFaultDomain -VMhost $ClusterHost)
                    Write-Host "  Network Info:" -ForegroundColor Green
                    $ClusterHostAdapter = ($ClusterHost | Get-VMHostNetworkAdapter).Where{$_.VsanTrafficEnabled -eq $True}
                    If ($ClusterHostAdapter) {
                        Write-Host "    Adapter: " $ClusterHostAdapter.Name "(" $ClusterHostAdapter.IP ") - vSAN Traffic"        
                    } else {
                        Write-Host "    Adapter: "
                    }
                    $WitnessTrafficAdapter = ($ClusterHostEsxCli.vsan.network.list.invoke()).Where{$_.TrafficType -eq "witness"}
                    If ($WitnessTrafficAdapter) {
                        $WitnessTrafficIP = (Get-VMHostNetworkAdapter -VMhost $ClusterHost).Where{$_.DeviceName -eq $WitnessTrafficAdapter.VmkNicName}
                        Write-Host "    Adapter: " $WitnessTrafficAdapter.VmkNicName "(" $WitnessTrafficIP.IP ") - Witness Traffic"
                    }


                    $EncryptionInfo = ($ClusterHostEsxCli.vsan.encryption.info.get.invoke()).Where{$_.Attribute -eq "enabled"}
                        Write-Host "  Encryption enabled:" $EncryptionInfo.Value  -ForegroundColor Green
                }
                Write-Host " "
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
    If ($VsanCluster.StretchedClusterEnabled -eq $True) {
        Write-Host " "
        Write-Host "Stretched Cluster Preferred Fault Domain:" $VsanCluster.PreferredFaultDomain -ForegroundColor Green
    }
}

Get-RvcVsanClusterInfo -Cluster StretchedCluster
