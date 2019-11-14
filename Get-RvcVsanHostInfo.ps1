Function Get-RvcVsanHostInfo {
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
    
# Example
Get-RvcVsanHostInfo -VsanHost "VsanHostName"
