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
        Write-Host " "
        Write-Host "This command will trigger the immediate repair of objects that are waiting on one of two events. " -NoNewLine 
        Write-Host "The first category of objects are impacted by components in ABSENT state (caused by failed hosts or hot-unplugged drives). " -NoNewLine 
        Write-Host "vSAN will wait 60 minutes by default as in most such cases the failed components will come back. " -NoNewLine 
        Write-Host "The second category of objects was not repaired previously because under the cluster conditions at the time it wasn't possible. " -NoNewLine 
        Write-Host "vSAN will periodically recheck those objects. Both types of objects will be instructed to attempt a repair immediately. " -NoNewLine 
        Write-Host "This process may take a moment ..."
        Write-Host " "
        $ClusterHealthSystem.VsanHealthRepairClusterObjectsImmediate($ClusterMoRef,$null) 
    } else {
        Write-Host $VsanCluster "does not have vSAN enabled"
    }
}

# Example
Start-RvcVsanClusterRepairImmediately -VsanCluster "StretchedCluster"
