function Build-TotalsFromChains {
    #Group all production chain items by name
    $GroupedItems = $global:ActiveProject.Details.ProductionChains | Group-Object Name

    #Process each item to calculate totals and machines
    $GroupedItems | Foreach-Object {
        #Add quantities for each item and machine
        $_.Group | Foreach-Object -Begin {$ItemTotal = 0} -Process {
            $MachineName = $null
            $MachineMatch = $null

            $ItemTotal += $_.Quantity

            #Look for machine match
            $MachineName = $_.Machine.Name
            $MachineMatch = $global:ActiveProject.Details.Machines | Where-Object {$_.Name -eq $MachineName}

            #Add machine to existing or create new machine
            if ($MachineMatch) {
                $MachineMatch.Quantity += $_.Machine.Quantity

            } else {
                $global:ActiveProject.Details.Machines += [PSCustomObject]@{
                    Name = $MachineName
                    Quantity = $_.Machine.Quantity
                }
            }

        } -End {
            $global:ActiveProject.Details.Totals += [PSCustomObject]@{
                Name = $_.Name
                Quantity = $ItemTotal
                Tier = $_.Group.Tier[0]
            }
        }
    }

    if ($global:ActiveProject.Details.Machines) {
        $global:ActiveProject.Details.Machines | Foreach-Object -Begin {$MinPower = 0; $MaxPower = 0} -Process {
            $Machine = $null
            $MachineMatch = $null
            $Machine = $_

            $MachineMatch = Invoke-CloneObject ($global:ConfigMaster.Machines | Where-Object {$_.Name -eq $Machine.Name})

            if ($MachineMatch.Count -gt 1) {
                
            }

            if ($MachineMatch.Power) {
                $MinPower = $MachineMatch.Power * $Machine.Quantity

                $Machine | Add-Member -MemberType NoteProperty -Name "Power" -Value $MinPower
                
            } else {
                $MinPower = $MachineMatch.PowerMin * $Machine.Quantity
                $MaxPower = $MachineMatch.PowerMax * $Machine.Quantity

                $Machine | Add-Member -MemberType NoteProperty -Name "MinimumPower" -Value $MinPower
                $Machine | Add-Member -MemberType NoteProperty -Name "MaximumPower" -Value $MaxPower
            }
        }
    }
}