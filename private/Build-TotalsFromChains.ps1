function Build-TotalsFromChains {
    #Group all production chain items by name
    $GroupedItems = $global:NewFactory.Details.ProductionChains | Group-Object Name

    #Process each item to calculate totals and machines
    $GroupedItems | Foreach-Object {
        #Add quantities for each item and machine
        $_.Group | Foreach-Object -Begin {$ItemTotal = 0} -Process {
            $MachineName = $null
            $MachineMatch = $null

            $ItemTotal += $_.Quantity

            #Look for machine match
            $MachineName = $_.Machine.Name
            $MachineMatch = $global:NewFactory.Details.Machines | Where-Object {$_.Name -eq $MachineName}

            #Add machine to existing or create new machine
            if ($MachineMatch) {
                $MachineMatch.Quantity += $_.Machine.Quantity

            } else {
                $global:NewFactory.Details.Machines += [PSCustomObject]@{
                    Name = $MachineName
                    Quantity = $_.Machine.Quantity
                }
                Write-Output "Added new machine [$($MachineName)]"
            }

        } -End {
            $global:NewFactory.Details.Totals += [PSCustomObject]@{
                Name = $_.Name
                Quantity = $ItemTotal
                Tier = $_.Group.Tier[0]
            }
        }
    }
}