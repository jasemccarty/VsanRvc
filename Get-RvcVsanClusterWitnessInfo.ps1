Function Get-RvcVsanClusterWitnessInfo {
    <#
        .NOTES
        ===========================================================================
         Created by:    Jase McCarty
         Organization:  VMware
         Blog:          https://jasemccarty.com
         Twitter:       @jasemccarty
        ===========================================================================
        .SYNOPSIS
            This function retrives the same information returned by the vsan.stretchedcluster.witness_info RVC command
        .DESCRIPTION
            This function retrives the same information returned by the vsan.stretchedcluster.witness_info RVC command
        .PARAMETER Cluster 
            Cluster the Cluster Name
        .EXAMPLE
            Get-RvcVsanClusterWitnessInfo -Cluster vSANCluster

    #>
    [CmdletBinding()]Param([Parameter(Mandatory = $True)][String]$Cluster)
    
    # Retrieve the vSAN Cluster configuration
    $VsanCluster = Get-VsanClusterConfiguration -Cluster $Cluster 

    If (($VsanCluster.VsanEnabled -eq $True) -and ($VsanCluster.StretchedClusterEnabled -eq $True)) {
        # Get Basics
        $PrefFaultDomain = $VsanCluster.PreferredFaultDomain
        $WitnessName = $VsanCluster.WitnessHost

        # Get Advanced Witness Info by grabbing an ESXi host and returning the Witness Unicast Agent information
        $AdvWitInfo = ((Get-Cluster -Name $Cluster | Get-VMHost | Select-Object -First 1 | Get-EsxCli -V2 ).vsan.cluster.unicastagent.list.Invoke()).Where{$_.IsWitness -eq 1}
        $WitnessIP = $AdvWitInfo.IPAddress
        $WitnessUuid = $AdvWitInfo.NodeUuid
        
        # Report the Witness information as the vsan.stretchedcluster.witness_info RVC Command would
        Write-Host "+------------------------+--------------------------------------+"
        Write-Host "  Stretched Cluster      | " $Cluster
        Write-Host "+------------------------+--------------------------------------+"
        Write-Host "  Witness Host Name      | " $WitnessName
        Write-Host "  Witness Host UUID      | " $WitnessUuid
        Write-Host "  Preferred Fault Domain | " $PrefFaultDomain
        Write-Host "  Unicast Agent Address  | " $WitnessIP
        Write-Host "+------------------------+--------------------------------------+"

    } else {
        Write-Host "Cannot find witness host for the cluster. This is not a vSAN stretched cluster"
    }

    }

    # Example Call
    Get-RvcVsanClusterWitnessInfo -Cluster ClusterName
