function New-UserPrompt {
    param (
        [switch]$StartBuild,
        [PSCustomObject]$SelectRecipe
    )
    $NumberedList = @()

    if ($StartBuild) {
        #Collect all items from the list
        $AllItems = ($global:ConfigMaster.Items | Where-Object {$_.Tier -ne 0}).ItemName | Sort-Object
        $NumberedList = Get-NumberedList -Object $AllItems

        #Display items to user for selection
        if ($NumberedList) {
            Write-Host -ForegroundColor Yellow "Satisfactory - All Machine Craftable Items"
            $NumberedList | Foreach-Object {
                Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                Write-Host -ForegroundColor Blue " $($_.Name)"
            }

            $ItemPrompt = Read-Host "Select item number to begin factory build ($($NumberedList[0].ID)-$($NumberedList[-1].ID))"
            $ItemSelection = Invoke-CloneObject -InputObject ($global:ConfigMaster.Items | Where-Object {$_.ItemName -eq "$(($NumberedList | Where-Object {$_.ID -eq $ItemPrompt}).Name)"})

            if ($ItemSelection.Recipes.Count -gt 1) {
                $AvailableRecipes = Get-Recipes -ItemName $ItemSelection.ItemName
                $NumberedList = Get-NumberedList -Object $AvailableRecipes

                #Prompt user to select recipe if needed
                if ($NumberedList.Count -gt 1) {
                    #Write each object from the numbered list to the user in the console
                    $NumberedList | Foreach-Object {
                        Write-Host -ForegroundColor DarkGray "===================================="
                        Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                        Write-Host -ForegroundColor Green " - $($_.Name.Name) - $($_.Name.Output.Quantity) per min"
                        Write-Host ""
                        Write-Host -ForegroundColor DarkCyan "Inputs:"
                        $_.Name.Input | Foreach-Object {
                            Write-Host -ForegroundColor DarkCyan "  [$($_.Quantity)]-[$($_.ItemName)]"
                        }
            
                        if ($_.Name.Output.Byproduct.Count -ge 1) {
                            Write-Host ""
                            Write-Host -ForegroundColor DarkRed "Byproduct Warning"
                            $_.Name.Output.Byproduct | Foreach-Object {
                                Write-Host -ForegroundColor DarkRed "  [$($_.Quantity)]-[$($_.ItemName)]"
                            }
                        }
                    }

                    $RecipeSelection = Read-Host "Select recipe # to use"
                    $RecipeSelection = $ItemSelection.Recipes | Where-Object {$_.Name -eq "$(($NumberedList | Where-Object {$_.ID -eq $RecipeSelection}).Name.Name)"}
    
                } else {
                    $RecipeSelection = $ItemSelection.Recipes[0]
                }

            } else {
                $RecipeSelection = $ItemSelection.Recipes[0]
            }

            #Prompt user for how many per minute to create
            $ItemsPerMinute = Read-Host "How many [$($ItemSelection.ItemName)] per minute?"

            if ($ItemSelection -and $RecipeSelection -and $ItemsPerMinute) {
                $FactoryBuild = [PSCustomObject]@{
                    ItemName = $ItemSelection.ItemName
                    PerMinute = $ItemsPerMinute
                    Tier = $ItemSelection.Tier
                    Stack = $ItemSelection.Stack
                    SinkPoints = $ItemSelection.SinkPoints
                    Form = $ItemSelection.Form
                    Radioactive = $ItemSelection.Radioactive
                    Recipe = $RecipeSelection
                }

                Write-Output $FactoryBuild
            }
        }

    } elseif ($SelectRecipe) {
        $NumberedList = Get-NumberedList -Object $SelectRecipe.Recipes

        $i = 1
        $NumberedList | Foreach-Object {
            Write-Host -ForegroundColor DarkGray "===================================="
            Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
            Write-Host -ForegroundColor Green " - $($_.Name.Name) - $($_.Name.Output.Quantity) per min"
            Write-Host ""
            Write-Host -ForegroundColor DarkCyan "Inputs:"
            $_.Name.Input | Foreach-Object {
                Write-Host -ForegroundColor DarkCyan "  [$($_.Quantity)]-[$($_.ItemName)]"
            }

            if ($_.Name.Output.Byproduct.Count -ge 1) {
                Write-Host ""
                Write-Host -ForegroundColor DarkRed "Byproduct Warning"
                $_.Name.Output.Byproduct | Foreach-Object {
                    Write-Host -ForegroundColor DarkRed "  [$($_.Quantity)]-[$($_.ItemName)]"
                }
            }

            if ($i -eq $NumberedList.Count) {
                Write-Host -ForegroundColor DarkGray "===================================="
            }

            $i++
        }

        $RecipeSelection = Read-Host "Select recipe # to use ($($NumberedList[0].ID) - $($NumberedList[-1].ID))"
        $RecipeSelection = $SelectRecipe.Recipes | Where-Object {$_.Name -eq "$(($NumberedList | Where-Object {$_.ID -eq $RecipeSelection}).Name.Name)"}

        Write-Output $RecipeSelection
    }
}