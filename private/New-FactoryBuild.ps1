function New-FactoryBuild {
    param (
        [PSCustomObject]$FactoryDefinition
    )
    #Set variables
    $ProductionChains = @()
    $RecipeMultiplier = $null
    $RecipeMultiplier = ($FactoryDefinition.PerMinute / $FactoryDefinition.Recipe.Output.Quantity)

    #Build production chains for each item in recipe
    foreach ($InputItem in $FactoryDefinition.Recipe.Input) {
        $ChainItems = @()
        $i = 0

        $ProductionChainName = $InputItem.ItemName

        #Calculate multiplier
        $QuantityNeeded = ($InputItem.Quantity)*($RecipeMultiplier)
        $RootItem = Invoke-CloneObject -InputObject ($global:ConfigMaster.Items | Where-Object {$_.ItemName -eq $InputItem.ItemName})

        #Prompt user to select recipe
        if ($RootItem.Recipes.Count -gt 1) {
            $RecipeSelection = New-UserPrompt -SelectRecipe $RootItem

        } else {
            $RecipeSelection = $RootItem.Recipes[0]
        }

        if ($RecipeSelection) {
            $ChainItems += [PSCustomObject]@{
                ItemName = $RootItem.ItemName
                Quantity = $QuantityNeeded
                Recipe = $RecipeSelection
            }
        }

        #Find all recipes needed for each chain
        do {
            foreach ($Product in $ProductionChainItems) {
                $ProductionItem = $null

                if ($Product.Tier -ge 1) {
                    $ProductionItem = Invoke-CloneObject -InputObject ($global:ConfigMaster.Items | Where-Object {$_.ItemName -eq $Product.ItemName})

                    foreach ($Ingredient in ($ProductionItem.Recipes[0].Input.ItemName)) {
                        if ($ProductionChainItems.ItemName -notcontains $Ingredient) {
                            Write-Host -ForegroundColor Yellow "Added [$($Ingredient)] to the array"
                            $ProductionChainItems += $global:ConfigMaster.Items | Where-Object {$_.ItemName -eq $Ingredient}
                        }
                    }

                    #Prompt user to select recipe
                    if ($ProductionItem.Recipes.Count -gt 1) {

                    } else {

                    }
                }
            }
            
            $i++

        } until (($i -ge 15) -and ($ProductionChainItems.Tier -contains 0))

        $ProductionChains += [PSCustomObject]@{
            Chain = $ProductionChainName
            Items = $ProductionChainItems
        }
    }
}