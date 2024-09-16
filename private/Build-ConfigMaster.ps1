function Build-ConfigMaster {
    #Import all JSON files
    $global:ConfigMaster = @{}
    $AllConfigFiles = Get-ChildItem -Path "$($ScriptPath)\Config"

    foreach ($File in $AllConfigFiles) {
        $ConfigName = $null
        $FileContent = $null

        $ConfigName = $File.Name.Replace(".json","")
        $FileContent = Get-Content -Path $File.FullName | ConvertFrom-Json

        $global:ConfigMaster.Add($ConfigName,$FileContent)
    }
    
    #Add IDs to all recipes and items in the game
    if ($global:ConfigMaster.Items) {
        $ItemswithIDs = @()
        $AllItems = $global:ConfigMaster.Items

        if ($global:RunSettings.Preferences.CustomItems -ne "Disabled") {
            try {
                $CustomItems = Get-Content -Path $global:RunSettings.Preferences.CustomItems | ConvertFrom-JSON

            } catch {
                Write-Host "Unable to import custom file, verify the path configured in user preferences"
            }

            if ($CustomItems.Count -ge 1) {
                $CustomItems | Foreach-Object {
                    $ItemName = $_.ItemName

                    #Remove identical item if found from original item list
                    if ($AllItems.Items.ItemName -contains $ItemName) {
                        #Replace existing item with custom one
                        $AllItems = $AllItems | Where-Object {$_.ItemName -ne $ItemName}
                    }

                    #Add item to list
                    $AllItems += $_
                }
            }
        }

        if ($global:RunSettings.Preferences.DisableEventItems -eq $true) {
            Write-Host -ForegroundColor Cyan "User preferences are set to exclude events, filtering item list"
            $AllItems = $AllItems | Where-Object {$_.Tags -notcontains "Event"}
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