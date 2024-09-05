function Build-ProductionChain {
    Param (
        [string]$ItemName,
        [string]$ProductionLine,
        [switch]$NewChain,
        $PerMinute
    )

    $ItemMatch = $null
    $SelectedRecipe = $null
    $MachineCount = $null
    $Chain = $null

    #Match item to config entry
    $ItemMatch = Invoke-CloneObject ($global:ConfigMaster.Items | Where-Object {$_.ItemName -eq $ItemName})

    if ($ItemMatch.Tier -ne 0) {
        #Determine chain name
        if($NewChain -eq $true) {
            $Chain = $ItemMatch.ItemName

        } elseif ($ProductionLine) {
            $Chain = $ProductionLine
        }

        #Prompt user for recipe selection if more than 1
        if ($ItemMatch.Recipes.Count -gt 1) {
            #Prompt user to choose
            #$SelectedRecipe = New-UserPrompt -SelectRecipe $ItemMatch
            $SelectedRecipe = $ItemMatch.Recipes[0]

        } else {
            $SelectedRecipe = $ItemMatch.Recipes[0]
        }

        #Prompt user for how many per minute to make if root item, calculate automatically is not
        if ($ProductionChains.Count -eq 0) {
            $PerMinute = New-UserPrompt -ItemPM $ItemMatch
        }

        #Calulate machine count
        $MachineCount = ($PerMinute / $SelectedRecipe.Output.Quantity)

        #Add item to production line
        $global:ProductionChains += [PSCustomObject]@{
            ItemName = $ItemMatch.ItemName
            Quantity = $PerMinute
            Tier = $ItemMatch.Tier
            Chain = $Chain
            Recipe = $SelectedRecipe
            Machine = $SelectedRecipe.Machine
            MachineCount = $MachineCount
        }

        if ($SelectedRecipe) {
            foreach ($InputItem in $SelectedRecipe.Input) {
                $CalculateItemPM = $null
                $CalculateItemPM = ($MachineCount * $InputItem.Quantity)

                if ($ProductionChains[0].ItemName -eq $ItemName) {
                    Build-ProductionChain -ItemName $InputItem.ItemName -NewChain -PerMinute $CalculateItemPM
                    
                } elseif ($NewChain -eq $true) {
                    Build-ProductionChain -ItemName $InputItem.ItemName -ProductionLine $ItemName -PerMinute $CalculateItemPM

                } else {
                    Build-ProductionChain -ItemName $InputItem.ItemName -ProductionLine $ProductionLine -PerMinute $CalculateItemPM
                }
            }
        }

    } elseif ($ItemMatch.Tier -eq 0) {
        $global:ProductionChains += [PSCustomObject]@{
            ItemName = $ItemMatch.ItemName
            Tier = $ItemMatch.Tier
            Quantity = $PerMinute
            Chain = $ProductionLine
            Recipe = "Raw Resource"
            Machine = $ItemMatch.Machine
        }

    } else {
        Write-Host "No item match found for [$($ItemName)], fail"
    }
}