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

        #Prompt user for recipe selection if more than 1 and there isn't a preferred recipe
        if (($ItemMatch.Recipes.Count -gt 1) -and ($global:NewFactory.Preferences.Recipes.Name -notcontains $ItemMatch.Name)) {
            #Prompt user to choose
            $SelectedRecipe = New-UserPrompt -Recipe -Object $ItemMatch

        } else {
            if ($global:NewFactory.Preferences.Recipes.Name -contains $ItemMatch.Name) {
                $SelectedRecipe = $global:NewFactory.Preferences.Recipes | Where-Object {$_.Name -eq $ItemMatch.Name}

            } else {
                $SelectedRecipe = $ItemMatch.Recipes[0]
            }
        }

        if ($SelectedRecipe) {
            #Calulate machine count
            if ($ItemMatch.Tier -ne 0) {
                $MachineCount = ($PerMinute / $SelectedRecipe.Output.Quantity)

            } else {
                $MachineCount = 0
            }

            #Add item to production line
            $global:NewFactory.Details.ProductionChains += [PSCustomObject]@{
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
                    $global:NewFactory.Details.Byproducts += [PSCustomObject]@{
                        Byproduct = $SelectedRecipe.Output.Byproduct.ItemName
                        Quantity = ($MachineCount * $SelectedRecipe.Output.Byproduct.Quantity)
                        Chain = $ProductionLine
                        Recycle = $null
                    }
                }

                foreach ($InputItem in $SelectedRecipe.Input) {
                    $CalculateItemPM = $null
                    $CalculateItemPM = ($MachineCount * $InputItem.Quantity)

                    if ($global:NewFactory.Details.ProductionChains[0].Name -eq $ItemName) {
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