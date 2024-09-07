function New-UserPrompt {
    param (
        [switch]$Start,
        [switch]$NewProjectStart,
        [switch]$ExistingProject,
        [switch]$Recipe,
        [switch]$Byproduct,
        [switch]$End,
        [PSCustomObject]$Object
    )
    $Options = @()

    if ($Start) {
        #Set options for prompt
        $Options = "New project", "Reopen existing project"
        $PromptArray = New-PromptArray -Options $Options

        do {
            $ResponseSuccess = $null

            #Present options
            Write-Host ""
            $PromptArray | Foreach-Object {
                Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                Write-Host -ForegroundColor Blue " $($_.Message)"
            }
            Write-Host ""
            Write-Host -ForegroundColor Yellow "Select what you would like to do ($($PromptArray[0].ID)-$($PromptArray[-1].ID)): " -NoNewLine
            $UserResponse = Read-Host

            $Selection = $PromptArray | Where-Object {$_.ID -eq $UserResponse}

            if (!$Selection) {
                $Selection = $PromptArray | Where-Object {$_.Message -eq $UserResponse}
            }

            if ($Selection) {
                $ResponseSuccess = $true

            } else {
                Write-Host -ForegroundColor Red "Invalid selection, try again"
            }

        } until ($ResponseSuccess -eq $true -and $Selection)

        #Set run mode for session
        if ($Selection.ID -eq 1) {
            Write-Host -ForegroundColor Green "Starting a new project..."
            $global:RunMode = "New"


        } elseif ($Selection.ID -eq 2) {
            Write-Host -ForegroundColor Green "Reopening an existing project..."
            $global:RunMode = "Existing"
        }

    } elseif ($NewProjectStart) {
        $NewProject = [PSCustomObject]@{
            ID = (New-GUID).Guid
            Name = $null
            Item = $null
            Quantity = $null
            Details = [PSCustomObject]@{
                ProductionChains = @()
                Totals = @()
                Machines = @()
                Byproducts = @()
            }
            Preferences = [PSCustomObject]@{
                Recipes = @()
            }
        }

        do {
            $Response = $null
            $Success = $null
            $ItemToMake = $null

            if (!$NewProject.Name) {
                Write-Host ""
                Write-Host -ForegroundColor Blue "Provide a name for the project (This can be anything you want): " -NoNewline
                $NewProject.Name = Read-Host
            }

            if (!$NewProject.Item) {
                Write-Host ""
                Write-Host -ForegroundColor Blue "What item do you want to produce in the factory (type 'help'): " -NoNewline
                $Response = Read-Host
                
                if ($Response -eq "help") {
                    Write-Host -ForegroundColor DarkGray "Type the item name, the ID #, or 'list' to see all items"

                } elseif ($Response -eq "list") {
                    Write-Host -ForegroundColor Yellow "Satisfactory - All Machine Craftable Items"
                    $global:ConfigMaster.Items | Where-Object {$_.Tier -ne 0} | Sort-Object Name | Foreach-Object {
                        Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                        Write-Host -ForegroundColor Blue " $($_.Name)"
                    }

                } elseif ($global:ConfigMaster.Items.ID -contains $Response) {
                    $ItemToMake = Invoke-CloneObject -InputObject ($global:ConfigMaster.Items | Where-Object {$_.ID -eq $Response})

                } elseif ($global:ConfigMaster.Items.Name -contains $Response) {
                    $ItemToMake = Invoke-CloneObject -InputObject ($global:ConfigMaster.Items | Where-Object {$_.Name -eq $Response})

                } else {
                    Write-Host -ForegroundColor Red "Invalid selection, try again"
                }

                #Set selected item
                if ($ItemToMake) {
                    $NewProject.Item = $ItemToMake.Name
                }
            }

            if ($NewProject.Item -and !$NewProject.Quantity) {
                Write-Host -ForegroundColor Blue "How many [$($NewProject.Item)] per minute?: " -NoNewline
                $NewProject.Quantity = Read-Host
            }

            if ($NewProject.Name -and $NewProject.Item -and $NewProject.Quantity) {
                Write-Host -ForegroundColor Green "New project [$($NewProject.Name)] will build a factory making $($NewProject.Quantity) $($NewProject.Item) per minute.  Proceed? (Y or N): " -NoNewLine
                $Response = Read-Host

                if ($Response -match "Y") {
                    $Success = $true

                } elseif ($Response -match "N") {
                    Write-Host -ForegroundColor Yellow "Restarting prompts"
                    $NewProject.Name = $null
                    $NewProject.Item = $null
                    $NewProject.Quantity = $null

                } else {
                    Write-Host -ForegroundColor Red "Invalid selection, try again"
                }
            }

        } until ($NewProject.Name -and $NewProject.Item -and $NewProject.Quantity -and $Success -eq $true)

        Write-Output $NewProject

    } elseif ($ExistingProject) {

    } elseif ($Recipe) {
        $AllRecipes = $null
        $Object = Invoke-CloneObject -InputObject $Object
        $AllRecipes = $Object.Recipes

        do {
            $UserSelection = $null

            Write-Host -ForegroundColor Cyan "[$($Object.Name)] has multiple recipes available, select one to use in the production line (type 'help'): " -NoNewLine
            $UserResponse = Read-Host

            $i = 1
            if ($UserResponse -eq "help" -or $UserResponse -eq "h") {
                Write-Host ""
                Write-Host -ForegroundColor DarkGray "Use 'list' to see recipes, use 'detail' to see everything in the recipe"
                Write-Host -ForegroundColor DarkGray "Select the ID or the name of the recipe to continue"
                Write-Host ""

            } elseif ($UserResponse -eq "detail" -or $UserResponse -eq "d") {
                $AllRecipes | Foreach-Object {
                    Write-Host ""
                    Write-Host -ForegroundColor DarkGreen "¤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━¤"
                    #Output header for recipe
                    Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                    Write-Host -ForegroundColor DarkYellow " $($_.Name)"
                    Write-Host -ForegroundColor DarkGray "-------------------------"
        
                    #Output machine and items per minute
                    Write-Host -ForegroundColor White "[Output]"
                    Write-Host -ForegroundColor Green "  $($_.Output.Quantity) per min"
                    Write-Host ""
                    Write-Host -ForegroundColor White "[Input]"
                    $_.Input | Foreach-Object {
                        Write-Host -ForegroundColor DarkCyan "  $($_.Quantity) $($_.ItemName) per min"
                    }
        
                    if ($_.Output.Byproduct.Count -ge 1) {
                        Write-Host ""
                        Write-Host -ForegroundColor DarkRed "[Byproduct]"
                        $_.Output.Byproduct | Foreach-Object {
                            Write-Host -ForegroundColor DarkRed "  $($_.Quantity) $($_.ItemName) per min"
                        }
                    }
                    Write-Host ""
                    Write-Host -ForegroundColor White "[Machine]" -NoNewLine
                    Write-Host -ForegroundColor DarkBlue " $($_.Machine)"
        
                    if ($i -eq $AllRecipes.Count) {
                        Write-Host -ForegroundColor DarkGreen "¤━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━¤"
                    }
                    Write-Host ""
        
                    $i++
                }

            } elseif ($UserResponse -eq "list") {
                Write-Host ""
                $AllRecipes | Foreach-Object {
                    Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                    Write-Host -ForegroundColor Blue " $($_.Name)"
                }
                Write-Host ""

            } elseif ($AllRecipes.ID -contains $UserResponse) {
                $UserSelection = $AllRecipes | Where-Object {$_.ID -eq $UserResponse}

            } elseif ($AllRecipes.Name -contains $UserResponse) {
                $UserSelection = $AllRecipes | Where-Object {$_.Name -eq $UserResponse}

            } else {
                Write-Host -ForegroundColor Red "Invalid selection, try again"
            }
            
        } until ($UserSelection)

        if ($UserSelection) {
            Write-Host ""
            Write-Host -ForegroundColor Green "[$($UserSelection.Name)] recipe has been selected to make [$($Object.Name)]"

            do {
                Write-Host ""
                Write-Host -ForegroundColor DarkGray "Recipe can be added to a preferred list so it won't prompt for selection in this project anymore."
                Write-Host -ForegroundColor Blue "Would you like to add this to the preferred recipe list? (Y or N): " -NoNewline
                $UserResponse = Read-Host

                if ($UserResponse -match "Y") {
                    $Object.Recipes = $UserSelection
                    $global:NewFactory.Preferences.Recipes += ($Object | Select-Object -Exclude ID)

                } elseif ($UserResponse -match "N") {

                } else {
                    $UserResponse = $null
                }

            } until ($UserResponse)

            Write-Output $UserSelection
        }

    } elseif ($Byproduct) {

    } elseif ($End) {

    }
}