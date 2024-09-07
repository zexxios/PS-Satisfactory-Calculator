function Format-ConfigMaster {
    #Add IDs to all recipes and items in the game
    if ($global:ConfigMaster.Items) {
        $ItemswithIDs = @()

        if ($global:RunSettings.Preferences.ExcludeEventItems -eq $true) {
            Write-Host -ForegroundColor Cyan "User preferences are set to exclude events, filtering item list"
            $AllItems = $global:ConfigMaster.Items | Where-Object {$_.Tags -notcontains "Event"}

        } else {
            $AllItems = $global:ConfigMaster.Items
        }

        $i = 1
        $AllItems | Sort-Object ItemName | Foreach-Object {

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

        if ($AllItems.Count -eq $ItemsWithIDs.Count) {
            $global:ConfigMaster.Remove("Items")
            $global:ConfigMaster.Add("Items",$ItemswithIDs)
        }
    }
}