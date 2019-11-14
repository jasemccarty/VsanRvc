Function Start-RvcVsanClusterRepairImmediately {
    <#
    .NOTES
    ===========================================================================
        Created by:    Jase McCarty
        Organization:  VMware
        Blog:          https://jasemccarty.com
        Twitter:       @jasemccarty
    ===========================================================================
    .SYNOPSIS
        This function invokes a Repair Objects Immediately operation on a vSAN Cluster
    .DESCRIPTION
        This function invokes a Repair Objects Immediately operation on a vSAN Cluster
    .PARAMETER VsanCluster 
        vSAN Cluster
    .EXAMPLE
        Start-RvcVsanClusterRepairImmediately -VsanCluster <clustername>
    #> 
    [CmdletBinding()]
    Param([Parameter(Mandatory = $True)][String]$VsanCluster)
    
    # Retrieve the vSAN Cluster Object
    $Cluster = Get-Cluster -Name $VsanCluster

    # Get the Cluster's Managed Object Reference (MoRef)
    $ClusterMoRef = $Cluster.ExtensionData.MoRef

    # Check to be certian vSAN is enabled
    If ($Cluster.VsanEnabled -eq $True) {
        # Load the vSAN vC Cluster Health System View
        $ClusterHealthSystem = Get-VsanView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system"

        # Invoke the Fix for all objects
        Write-Host "Issuing a repair all objects command on $VsanCluster"
        $RepairTask = $ClusterHealthSystem.VsanHealthRepairClusterObjectsImmediate($ClusterMoRef,$null) 
    } else {
        Write-Host $VsanCluster "does not have vSAN enabled"
    }
}

# Example
Start-RvcVsanClusterRepairImmediately -VsanCluster "StretchedCluster"
