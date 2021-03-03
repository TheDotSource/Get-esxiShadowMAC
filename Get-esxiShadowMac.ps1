function Get-esxiShadowMAC {
    <#
    .SYNOPSIS
        Report the "Shadow MAC" address of ESXi physical interfaces.

    .DESCRIPTION
        Report the "Shadow MAC" address of ESXi physical interfaces.

        ESXi assigns a "Shadow" or virtual MAC address to each vmnic for purposes such as beacon probing.

        The function will make an ESXCLI call to discover these for each interface.

        Accepts ESXi host object as input.

    .PARAMETER vmHost
        The ESXi host object to run against.

    .INPUTS
        VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImp. ESXi host object.

    .OUTPUTS
        None.

    .EXAMPLE
        Get-esxiShadowMAC -vmHost $vmHost

        Return a list of all vmnics on $vmHost and their virtual MACs.

    .EXAMPLE
        Get-vmHost | Get-esxiShadowMAC

        Return a list of all vmnics on all ESXi hosts and their virtual MACs.

    .LINK

    .NOTES
        01           Alistair McNair          Initial version.
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl]$vmHost
    )

    begin {

        Write-Verbose ("Function start.")
    } # begin


    process {

        Write-Verbose ("Processing host: " + $vmHost.name)

        ## Get all physical adapters on this host
        Write-Verbose ("Fetching host physical adapters.")

        try {
            $vmNics = ($vmHost | Get-VMHostNetworkAdapter -ErrorAction Stop | Where-Object {$_.devicename -like "vmnic*"}).name
        } # try
        catch {
            throw ("Failed to get phyical adapters. " + $_.exception.message)
        } # catch

        Write-Verbose ("Found " + $vmNics.count + " physical adapters on this host.")


        ## Create an ESXCLi connection to this host
        Write-Verbose ("Creating ESXCli connection to host.")

        try {
            $esxCli = Get-EsxCli -VMHost $vmHost -V2 -ErrorAction Stop
            Write-Verbose ("ESXCli created.")
        } # try
        catch {
            throw ("Failed to create ESXCli connection. " + $_.exception.message)
        } # catch


        ## Set array for results
        $shadowMacs = @()

        ## Iterate through each interface and get the virtual MAC
        foreach ($vmNic in $vmNics) {

            Write-Verbose ("Processing vmnic " + $vmNic)

            ## Set arguments for ESXCLi
            $arguments = $esxcli.network.nic.get.CreateArgs()
            $arguments.nicname = $vmNic


            ## Execute ESXCli to fetch vmnic details
            $vmnicShadow = $esxcli.network.nic.get.Invoke($arguments).VirtualAddress

            ## Add this to results
            $shadowMacs += [pscustomobject]@{"hostName" = $vmHost.name; "parent" = $vmHost.parent.name; "deviceName" = $vmNic; "shadowMac" = $vmnicShadow}

        } # foreach



        Write-Verbose ("Completed host: " + $vmHost.name)

        return $shadowMacs

    } # process

    end {

        Write-Verbose ("Function complete.")
    } # end

} # function