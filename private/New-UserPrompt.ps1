function New-UserPrompt {
    param (
        [switch]$Start,
        [switch]$ProjectDirectory,
        [switch]$NewProject,
        [switch]$ExistingProject,
        [switch]$Recipe,
        [switch]$Byproduct,
        [switch]$Reports,
        [switch]$End,
        [PSCustomObject]$Object
    )
    $Options = @()

    if ($Start) {
        if (!$global:RunSettings) {
            $global:RunSettings = [PSCustomObject]@{
                Mode = $null
                Preferences = $null
                Projects = @()
            }

        } else {
            $global:RunSettings.Mode = $null
        }

        #Set options for prompt
        $Options = "New project", "Reopen existing project", "Edit user preferences", "Exit"
        $PromptArray = New-PromptArray -Options $Options

        do {
            #Present options
            Write-Host ""
            $PromptArray | Foreach-Object {
                Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                Write-Host -ForegroundColor Blue " $($_.Message)"
            }
            Write-Host ""
            Write-Host -ForegroundColor Blue "Select what you would like to do ($($PromptArray[0].ID)-$($PromptArray[-1].ID)): " -NoNewLine
            $UserResponse = Read-Host

            if ($PromptArray.ID -contains $UserResponse) {
                $Selection = $PromptArray | Where-Object {$_.ID -eq $UserResponse}

            } elseif ($PromptArray.Message -contains $UserResponse) {
                $Selection = $PromptArray | Where-Object {$_.Message -eq $UserResponse}

            } else {
                Write-Host -ForegroundColor Red "Invalid selection, try again"
            }

            if ($Selection) {
                #Set run mode for session
                if ($Selection.ID -eq 1) {
                    Write-Host -ForegroundColor Green "Starting a new project..."
                    $global:RunSettings.Mode = "New"

                } elseif ($Selection.ID -eq 2) {
                    Write-Host -ForegroundColor Green "Reopening an existing project..."
                    $global:RunSettings.Mode = "Existing"

                } elseif ($Selection.ID -eq 3) {
                    Write-Host -ForegroundColor Green "Starting configuration of user preferences..."
                    $global:RunSettings.Mode = "UserConfig"

                } elseif ($Selection.ID -eq 4) {
                    Write-Host -ForegroundColor Green "Exiting calculator..."
                    $global:RunSettings.Mode = "Exit"
                    $global:CloseCalculator = $true
                }
            }

            if ($global:RunSettings.Mode -and $global:RunSettings.Mode -ne "Exit") {
                do {
                    $WorkCompleted = $null
                    Write-Host ""
                    if (!$global:RunSettings.Preferences) {
                        $FilePath = $null
                        $FolderPath = $null

                        #Prompt user for preference file import
                        if ($global:RunSettings.Mode -eq "UserConfig") {
                            $PreferenceResponse = "Y"

                        } else {
                            if (!$PreferenceResponse) {
                                Write-Host -ForegroundColor Blue "Do you already have a user preference file to import? (Y or N): " -NoNewLine
                                $PreferenceResponse = Read-Host
                            }
                        }
                        
                        if ($PreferenceResponse -match "Y") {
                            Write-Host ""
                            Write-Host -ForegroundColor Yellow "Select your preferences file (Dialog box for selection may be under this window)"
                            $FilePath = Get-FilePath -JSON -Title "Select JSON preference file"

                            if ((Test-Path -Path $FilePath -PathType Leaf) -eq $true) {
                                $global:RunSettings.Preferences = Get-Content -Path $FilePath | ConvertFrom-JSON

                                #Set new file path if file was moved
                                if ($FilePath -ne $global:RunSettings.Preferences.FilePath) {
                                    $RunSettings.Preferences.FilePath = $FilePath
                                }
                                
                                if ((Test-Path -Path $global:RunSettings.Preferences.ProjectDirectory) -eq $false) {
                                    Write-Host -ForegroundColor Red "Unable to validate path to project files in user file"
                                    Set-Preferences -Path $FilePath

                                } else {
                                    Write-Host ""
                                    Write-Host -ForegroundColor Green "Successfully imported user preferences"
                                }

                            } else {
                                Write-Host -ForegroundColor Red "User preference file not found, try again"
                                $FilePath = $null
                            }

                        } elseif ($PreferenceResponse -match "N") {
                            Write-Host -ForegroundColor Blue "Provide a path to save the user preference file (File will be created in this directory)"
                            Write-Host ""
                            $FolderPath = Get-FolderPath -Description "Provide a folder path to save user preference file"

                            if ((Test-Path -Path $FolderPath) -eq $true) {
                                $FilePath = Set-Preferences -New -Path $FolderPath -User

                            } else {
                                Write-Host -ForegroundColor Red "Folder path is invalid, try again"
                                $FolderPath = $null
                            }

                        } else {
                            Write-Host -ForegroundColor Red "Invalid response, try again"
                            $PreferenceResponse = $null
                        }
                    }

                    #Import files for existing projects or run user setting configuration
                    if ($global:RunSettings.Preferences) {
                        $AllProjects = (Get-ChildItem -Path $global:RunSettings.Preferences.ProjectDirectory -Recurse | Where-Object {$_.Name -match ".xml"}) | Select-Object Name,FullName

                        if ($AllProjects.Count -ge 1) {
                            $AllProjects | Foreach-Object {
                                $ProjectContents = $null
                                $ProjectContents = Import-CLIXML -Path $_.FullName
                                $FilePath = $_.FullName
                                
                                if ($ProjectContents.FilePath -ne $FilePath) {
                                    Write-Host "$($FilePath)"
                                    $ProjectContents.FilePath = $FilePath
                                }

                                $global:RunSettings.Projects += $ProjectContents
                            }

                            Write-Host -ForegroundColor Green "Found and imported [$($global:RunSettings.Projects.Count)] existing projects"
                        }

                        if ($global:RunSettings.Mode -eq "Existing") {
                            $AllProjects = (Get-ChildItem -Path $global:RunSettings.Preferences.ProjectDirectory -Recurse | Where-Object {($_.Name -match ".xml")}) | Select-Object Name,FullName

                            if ($AllProjects.Count -ge 1) {
                                $AllProjects | Foreach-Object {
                                    $ProjectContents = Import-CLIXML -Path $_.FullName

                                    if ($ProjectContents.FilePath) {
                                        $ProjectContents.FilePath = $_.FullName

                                    } else {
                                        $ProjectContents | Add-Member -MemberType "NoteProperty" -Name "FilePath" -Value $_.FullName
                                    }

                                    $global:RunSettings.Projects += $ProjectContents
                                    Write-Host -ForegroundColor Green "Successfully imported project [$($ProjectContents.Name)] with ID [$($ProjectContents.ID)]"
                                }

                            } else {
                                Write-Host -ForegroundColor Red "No project files were found in the directory specified in user preferences [$($global:RunSettings.Preferences.ProjectDirectory)]"
                                $global:RunSettings.Mode = $null
                            }

                        } elseif ($global:RunSettings.Mode -eq "UserConfig") {
                            Set-Preferences -Path $FilePath
                            $global:RunSettings.Mode = $null
                        }

                        $WorkCompleted = $true

                    } else {

                    }
        
                } until ($WorkCompleted -eq $true)
            }

        } until ($global:RunSettings.Mode)

    } elseif ($NewProject) {
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
                Miner = $null
                Recipes = @()
            }
            Tags = @()
            FilePath = $null
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
                Write-Host ""

                #Set selected item
                if ($ItemToMake) {
                    $NewProject.Item = $ItemToMake.Name
                }
            }

            #Prompt for quantity
            if ($NewProject.Item -and !$NewProject.Quantity) {
                if ($NewProject.Item.Properties.Form -eq "Solid") {
                    Write-Host -ForegroundColor Blue "How many [$($NewProject.Item)] per minute?: " -NoNewline

                } else {
                    Write-Host -ForegroundColor Blue "How much [$($NewProject.Item)] per minute?: " -NoNewline
                }
                $NewProject.Quantity = Read-Host
                Write-Host ""
            }

            #Prompt for miner
            if (($NewProject.Item) -and ($NewProject.Quantity) -and (!$NewProject.Preferences.Miner)) {
                $Options = Invoke-CloneObject -InputObject ($global:ConfigMaster.Machines | Where-Object {$_.Name -match "Miner"}).Name
                $PromptArray = New-PromptArray -Options $Options
                
                Write-Host ""
                $PromptArray | Foreach-Object {
                    Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                    Write-Host -ForegroundColor Blue " $($_.Message)"
                }
                Write-Host ""

                Write-Host -ForegroundColor Blue "Select which mining machine to use for factory calculations: " -NoNewline
                $Response = Read-Host

                if ($PromptArray.ID -contains $Response) {
                    $NewProject.Preferences.Miner = ($PromptArray | Where-Object {$_.ID -eq $Response}).Message

                } elseif ($PromptArray.Message -contains $Response) {
                    $NewProject.Preferences.Miner = ($PromptArray | Where-Object {$_.Message -eq $Response}).Message

                } else {
                    Write-Host -ForegroundColor Red "Invalid selection, try again"
                }

                Write-Host ""
            }

            if ($NewProject.Name -and $NewProject.Item -and $NewProject.Quantity) {
                Write-Host -ForegroundColor DarkGray "-------------------------"
                Write-Host -ForegroundColor DarkGreen "New Project Configuration"
                Write-Host -ForegroundColor DarkGray "-------------------------"
                Write-Host -ForegroundColor DarkGray "Name"
                Write-Host -ForegroundColor Cyan "   $($NewProject.Name)"
                Write-Host ""
                Write-Host -ForegroundColor DarkGray "Making"
                Write-Host -ForegroundColor Cyan "   $($NewProject.Item)"
                Write-Host ""
                Write-Host -ForegroundColor DarkGray "Rate"
                Write-Host -ForegroundColor Cyan "   $($NewProject.Quantity) per min"
                Write-Host ""
                Write-Host -ForegroundColor DarkGray "Miner"
                Write-Host -ForegroundColor Cyan "   $($NewProject.Preferences.Miner)"
                Write-Host -ForegroundColor DarkGray "-------------------------"
                Write-Host ""
                Write-Host -ForegroundColor Blue "Proceed with project creation? (Y or N): " -NoNewLine
                $Response = Read-Host

                if ($Response -match "Y") {
                    $Success = $true

                } elseif ($Response -match "N") {
                    Write-Host -ForegroundColor Yellow "Restarting project prompts"
                    $NewProject.Name = $null
                    $NewProject.Item = $null
                    $NewProject.Quantity = $null
                    $NewProject.Preferences.Miner = $null

                } else {
                    Write-Host -ForegroundColor Red "Invalid selection, try again"
                }
            }

        } until ($NewProject.Name -and $NewProject.Item -and $NewProject.Quantity -and $Success -eq $true)

        Write-Output $NewProject

    } elseif ($ExistingProject) {
        $Options = $global:RunSettings.Projects.Name
        $PromptArray = New-PromptArray -Options $Options

        #Prompt user to select the project to work on
        


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
                    Write-Host -ForegroundColor DarkGray "-------------------------"
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
                        Write-Host -ForegroundColor DarkGray "___________________________"
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
                Write-Host -ForegroundColor DarkGray "Recipe can be added to a list so it won't prompt for selection in this project anymore"
                Write-Host -ForegroundColor Blue "Add this recipe to the list? (Y or N): " -NoNewline
                $UserResponse = Read-Host
                Write-Host ""

                if ($UserResponse -match "Y") {
                    $Object.Recipes = $UserSelection
                    $global:ActiveProject.Preferences.Recipes += ($Object | Select-Object -Exclude ID)

                } elseif ($UserResponse -match "N") {

                } else {
                    $UserResponse = $null
                }

            } until ($UserResponse)

            Write-Output $UserSelection
        }

    } elseif ($Byproduct) {
    } elseif ($Reports) {
        $Options = "CSV", "HTML", "All"
        $PromptArray = New-PromptArray -Options $Options

        do {
            $WorkCompleted = $null
            $UserResponse = $null

            if (!$ReportResponse) {
                Write-Host -ForegroundColor Blue "Would you like to generate reports from the project? (Y or N): " -NoNewLine
                $ReportResponse = Read-Host
                Write-Host ""
            }

            if ($ReportResponse -match "Y") {
                $PromptArray | Foreach-Object {
                    Write-Host -ForegroundColor Yellow "[$($_.ID)]" -NoNewline
                    Write-Host -ForegroundColor Blue " $($_.Message)"
                }
                Write-Host ""

                Write-Host -ForegroundColor Blue "What kind of report(s) would you like to generate?: " -NoNewLine
                $UserResponse = Read-Host

                if (($PromptArray.ID -contains $UserResponse) -or ($PromptArray.Message -contains $UserResponse)) {
                    $Selection = ($PromptArray | Where-Object {($_.ID -eq $UserResponse) -or ($_.Message -eq $UserResponse)}).Message

                    Export-Project -Selection $Selection
                    
                } else {
                    Write-Host -ForegroundColor Red "Invalid selection, try again"
                }

            } elseif ($ReportResponse -match "N") {
                $WorkCompleted = $true

            } else {
                Write-Host -ForegroundColor Red "Invalid selection, try again"
                $ReportResponse = $null
            }

            Write-Host ""

            
        } until ($WorkCompleted -eq $true)

        
    } elseif ($End) {
        
    }
}