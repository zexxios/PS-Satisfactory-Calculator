function Build-ProductionChains {
    Param (
        [string]$ItemName,
        [string]$ProductionLine,
        [switch]$NewChain,
        [string]$PerMinute
    )

    $ItemMatch = $null
    $SelectedRecipe = $null
    $MachineCount = $null
    $Chain = $null

    #Match item to config entry
    $ItemMatch = Invoke-CloneObject ($global:ConfigMaster.Items | Where-Object {$_.Name -eq $ItemName})

    if ($ItemMatch) {
        #Determine chain name
        if ($NewChain -eq $true) {
            $Chain = $ItemMatch.Name

        } elseif ($ProductionLine) {
            $Chain = $ProductionLine
        }

        #Prompt user for recipe selection if more than 1 and there isn't a preferred recipe stored in the project or the user preferences
        if (($ItemMatch.Recipes.Count -gt 1) -and ($global:ActiveProject.Preferences.Recipes.Name -notcontains $ItemMatch.Name) -and ($global:RunSettings.Preferences.Recipes.Name -notcontains $ItemMatch.Name)) {
            #Prompt user to choose
            $SelectedRecipe = New-UserPrompt -Recipe -Object $ItemMatch

        } else {
            if ($global:RunSettings.Preferences.Recipes.Name -contains $ItemMatch.Name) {
                $SelectedRecipe = ($global:RunSettings.Preferences.Recipes | Where-Object {$_.Name -eq $ItemMatch.Name}).Recipes[0]

            } elseif ($global:ActiveProject.Preferences.Recipes.Name -contains $ItemMatch.Name) {
                $SelectedRecipe = ($global:ActiveProject.Preferences.Recipes | Where-Object {$_.Name -eq $ItemMatch.Name}).Recipes[0]

            } else {
                $SelectedRecipe = $ItemMatch.Recipes[0]
            }
        }

        if ($SelectedRecipe) {
            #Calulate machine count
            if ($ItemMatch.Tier -ne 0) {
                $MachineCount = ($PerMinute / $SelectedRecipe.Output.Quantity)

            } else {
                $MachineMatch = Invoke-CloneObject -InputObject ($global:ConfigMaster.Buildables.Machines | Where-Object {$_.Name -match $ItemMatch.Recipes.Machine})
                if ($MachineMatch.Count -gt 1) {
                    $MachineMatch = $MachineMatch | Where-Object {$_.Name -eq $global:ActiveProject.Preferences.Miner}
                    $SelectedRecipe.Machine = $MachineMatch.Name
                }

                if ($MachineMatch.Output) {
                    $MachineCount = ($PerMinute / $MachineMatch.Output)
                }
            }

            #Add item to production line
            $global:ActiveProject.Details.ProductionChains += [PSCustomObject]@{
                Name = $ItemMatch.Name
                Quantity = $PerMinute
                Tier = $ItemMatch.Tier
                Chain = $Chain
                Recipe = ($SelectedRecipe | Select-Object -Exclude ID)
                Machine = [PSCustomObject]@{
                    Name = $SelectedRecipe.Machine
                    Quantity = $MachineCount
                }
            }

            if ($ItemMatch.Tier -ne 0) {
                #Detect byproducts and add them to the list
                if ($SelectedRecipe.Output.Byproduct.Count -ge 1) {
                    $global:ActiveProject.Details.Byproducts += [PSCustomObject]@{
                        Byproduct = $SelectedRecipe.Output.Byproduct.ItemName
                        Quantity = ($MachineCount * $SelectedRecipe.Output.Byproduct.Quantity)
                        Chain = $ProductionLine
                        Recycle = $null
                    }
                }

                foreach ($InputItem in $SelectedRecipe.Input) {
                    $CalculateItemPM = $null
                    $CalculateItemPM = ($MachineCount * $InputItem.Quantity)

                    if ($global:ActiveProject.Details.ProductionChains[0].Name -eq $ItemName) {
                        Build-ProductionChains -ItemName $InputItem.ItemName -NewChain -PerMinute $CalculateItemPM
                        
                    } elseif ($NewChain -eq $true) {
                        Build-ProductionChains -ItemName $InputItem.ItemName -ProductionLine $ItemName -PerMinute $CalculateItemPM

                    } else {
                        Build-ProductionChains -ItemName $InputItem.ItemName -ProductionLine $ProductionLine -PerMinute $CalculateItemPM
                    }
                }
            }
        }
    }
}