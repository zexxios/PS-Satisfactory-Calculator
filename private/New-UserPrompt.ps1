function New-UserPrompt {
    param (
        [switch]$StartBuild,
        [PSCustomObject]$ItemPM,
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

            Write-Host -ForegroundColor Cyan "Select item number to begin factory build ($($NumberedList[0].ID)-$($NumberedList[-1].ID)): " -NoNewLine
            $ItemPrompt = Read-Host
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

    } elseif ($ItemPM) {
        do {
            $ResponseSuccess = $null
            Write-Host -ForegroundColor Yellow "How many [$($ItemPM.ItemName)] per minute?: " -NoNewLine
            $PerMinute = Read-Host

            if ($PerMinute) {
                $ResponseSuccess = $true

            } else {
                Write-Host -ForegroundColor Red "Invalid, try again"
            }

        } until ($ResponseSuccess -eq $true)
        
        if ($PerMinute) {
            Write-Output $PerMinute
        }

    } elseif ($SelectRecipe) {
        $NumberedList = Get-NumberedList -Object $SelectRecipe.Recipes

        do {
            $ResponseSuccess = $null

            if (!$RecipeSelection -or $RecipeSelection -eq "list") {
                $i = 1
                $NumberedList | Foreach-Object {
                    Write-Host -ForegroundColor DarkGreen "¤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━¤"
                    #Output header for recipe
                    Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                    Write-Host -ForegroundColor DarkYellow " $($_.Name.Name) Recipe"
                    Write-Host -ForegroundColor DarkGray "-------------------------"

                    #Output machine and items per minute
                    Write-Host -ForegroundColor White "[Output]"
                    Write-Host -ForegroundColor Green "  [$($_.Name.Output.Quantity)] per min"
                    Write-Host ""
                    Write-Host -ForegroundColor White "[Input]"
                    $_.Name.Input | Foreach-Object {
                        Write-Host -ForegroundColor DarkCyan "  [$($_.Quantity)] $($_.ItemName)"
                    }

                    if ($_.Name.Output.Byproduct.Count -ge 1) {
                        Write-Host ""
                        Write-Host -ForegroundColor DarkRed "[Byproduct]"
                        $_.Name.Output.Byproduct | Foreach-Object {
                            Write-Host -ForegroundColor DarkRed "  [$($_.Quantity)] $($_.ItemName)"
                        }
                    }
                    Write-Host ""
                    Write-Host -ForegroundColor White "[Machine]" -NoNewLine
                    Write-Host -ForegroundColor DarkBlue " $($_.Name.Machine)"
                    Write-Host ""

                    if ($i -eq $NumberedList.Count) {
                        Write-Host -ForegroundColor DarkGreen "¤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━¤"
                    }

                    $i++
                }
            }

            Write-Host -ForegroundColor Yellow "Select recipe # to use ($($NumberedList[0].ID) - $($NumberedList[-1].ID)): " -NoNewLine
            $RecipeSelection = Read-Host

            if (($RecipeSelection -ge $NumberedList[0].ID) -and ($RecipeSelection -le $NumberedList[-1].ID)) {
                $ResponseSuccess = $true

            } elseif ($RecipeSelection -ne "list") {
                Write-Host -ForegroundColor Red "Invalid selection, try again (type 'list' to list recipes again)"
            }

        } until ($ResponseSuccess -eq $true)
        
        $RecipeSelection = $SelectRecipe.Recipes | Where-Object {$_.Name -eq "$(($NumberedList | Where-Object {$_.ID -eq $RecipeSelection}).Name.Name)"}

        Write-Output $RecipeSelection
    }
}