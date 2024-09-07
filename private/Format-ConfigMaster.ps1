function Format-ConfigMaster {
    #Add IDs to all recipes and items in the game
    if ($global:ConfigMaster.Items) {
        $ItemswithIDs = @()

        $i = 1
        $ConfigMaster.Items | Sort-Object ItemName | Foreach-Object {

            $Recipes = @()
            $r = 1
            foreach ($Recipe in $_.Recipes) {
                $Recipes += [PSCustomObject]@{
                    ID = $r
                    Name = $Recipe.Name
                    Machine = $Recipe.Machine
                    Input = $Recipe.Input
                    Output = $Recipe.Output
                }

                $r++
            }

            if ($_.Tier -ne 0) {
                $ItemsWithIDs += [PSCustomObject]@{
                    ID = $i
                    Name = $_.ItemName
                    Tier = $_.Tier
                    Recipes = $Recipes
                    Properties = $_.Properties
                }

                $i++

            } else {
                $ItemsWithIDs += [PSCustomObject]@{
                    Name = $_.ItemName
                    Tier = $_.Tier
                    Recipes = $Recipes
                    Properties = $_.Properties
                }
            }            
        }

        if ($global:ConfigMaster.Items.Count -eq $ItemsWithIDs.Count) {
            $global:ConfigMaster.Remove("Items")
            $global:ConfigMaster.Add("Items",$ItemswithIDs)
        }
    }
}