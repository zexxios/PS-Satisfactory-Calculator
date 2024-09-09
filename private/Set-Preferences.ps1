function Set-Preferences {
    param (
        [switch]$New,
        [string]$Path,
        [switch]$User,
        [switch]$Project
    )

    if ($User) {
        if ($New -and $Path) {
            $Preferences = [PSCustomObject]@{
                FilePath = "$($Path)\UserPreferences.json"
                ProjectDirectory = $null
                RecycleByproducts = $null
                DisableEventItems = $null
                DisableProjectRecipeSaving = $null
                CustomItems = @()
                Recipes = @()
            }
    
        } else {
            $Preferences = Invoke-CloneObject ($global:RunSettings.Preferences)
        }
    
        do {
            $ConfigComplete = $null
            $UserResponse = $null

            if (!$Update) {
                if (!$New) {
                    if ((Test-Path -Path $Preferences.ProjectDirectory) -eq $false) {
                        $Update = "ProjectDirectory"
    
                    } else {
                        Write-Host ""
                        if (!$UpdateResponse) {
                            Write-Host -ForegroundColor Blue "Current Settings:"
                            Write-Host -ForegroundColor DarkGray "-----------------"
                            $CurrentSettings = ($Preferences | Get-Member | Where-Object {$_.MemberType -eq "NoteProperty"}).Name
    
                            $CurrentSettings | Sort-Object | Foreach-Object {
                                $Setting = $null
                                $Setting = $Preferences."$($_)"
    
                                Write-Host -ForegroundColor Gray "$($_): " -NoNewline
                                Write-Host -ForegroundColor Yellow "$($Setting)"
                            }
                            Write-Host ""
                            Write-Host -ForegroundColor Blue "Would you like to update any of these settings? (Y or N): " -NoNewline
                            $UpdateResponse = Read-Host
                        }
    
                        if ($UpdateResponse -match "Y") {
                            Write-Host ""
                            $Options = New-PromptArray -Options $CurrentSettings
                            $Options | Foreach-Object {
                                Write-Host -ForegroundColor Yellow "[$($_.ID)] $($_.Message)"
                            }
                            Write-Host ""
                            Write-Host -ForegroundColor Blue "Which of these settings do you want to update?: " -NoNewline
                            $UpdateSelection = Read-Host
    
                            if ($Options.ID -contains $UpdateSelection) {
                                $Update = ($Options | Where-Object {$_.ID -eq $UpdateSelection}).Message
    
                            } elseif ($Options.Message -contains $UpdateSelection) {
                                $Update = ($Options | Where-Object {$_.Message -eq $UpdateSelection}).Message
    
                            } else {
                                Write-Host -ForegroundColor Red "Invalid response, try again"
                                $UpdateSelection = $null
                            }
    
                        } elseif ($UpdateResponse -match "N") {
                            $ConfigComplete = $true
    
                        } else {
                            Write-Host -ForegroundColor Red "Invalid response, try again"
                            $UpdateResponse = $null
                        }
                    }
    
                } else {
                    $Update = "All"
                }
            }
            
            if ($Update) {
                #Prompts for project directory
                if (($Update -eq "ProjectDirectory") -or (($Update -eq "All") -and (!$Preferences.ProjectDirectory))) {
                    if (($Update -eq "All") -and (!$PDPathResponse)) {
                        Write-Host -ForegroundColor White "ProjectDirectory"
                        Write-Host -ForegroundColor DarkGray "  This folder will be used to store all projects, factories, and reports you generate when using the calculator"
                        Write-Host -ForegroundColor DarkGray "  Recommended: Store your user preferences and projects in the same folder.  Files can be organized how you'd like but everything needs to stay under the root directory"
                        Write-Host ""
                        Write-Host -ForegroundColor Blue "Do you want to store projects in the same folder as your preference file? (Y or N): " -NoNewline
                        $PDPathResponse = Read-Host

                        if ($PDPathResponse -match "Y") {
                            $Preferences.ProjectDirectory = $Path

                        } elseif ($PDPathResponse -match "N") {

                        } else {
                            $PDPathResponse = $null
                            Write-Host -ForegroundColor Red "Invalid response, try again"
                        }

                    } else {
                        if ($PDPathResponse -match "N") {
                            $PathDescription = "Provide the full folder path to save new projects"
        
                        } else {
                            $PathDescription = "Provide the full folder path to your existing project folder"
                        }

                        Write-Host -ForegroundColor Blue "$($PathDescription)" -NoNewline
                        $UserResponse = Get-FolderPath -Description $PathDescription

                        if ((Test-Path -Path $UserResponse) -eq $true) {
                            $Preferences.ProjectDirectory = $UserResponse
                            $PDPathResponse = $null
                            $UpdateResponse = $null
                            if (!$New) {
                                $Update = $null
                            }
                            
                        } else {
                            Write-Host -ForegroundColor Red "Path invalid, try again"
                        }
                    }

                } elseif (($Update -eq "RecycleByproducts") -or (($Update -eq "All") -and (!$Preferences.RecycleByproducts))) {
                    Write-Host -ForegroundColor White "RecycleByproducts"
                    Write-Host -ForegroundColor DarkGray "  By enabling this setting, it will calculate totals for the factory to reuse the byproduct in the production line if possible"
                    Write-Host -ForegroundColor Blue "Enable this setting? (Y or N): " -NoNewline
                    $UserResponse = Read-Host

                    if ($UserResponse -match "Y") {
                        $Preferences.RecycleByproducts = $true
                        $UpdateResponse = $null
                        if (!$New) {
                            $Update = $null
                        }

                    } elseif ($UserResponse -match "N") {
                        $Preferences.RecycleByproducts = $false
                        $UpdateResponse = $null
                        if (!$New) {
                            $Update = $null
                        }

                    } else {
                        Write-Host -ForegroundColor Red "Invalid response, try again"
                    }

                } elseif (($Update -eq "DisableEventItems") -or (($Update -eq "All") -and (!$Preferences.DisableEventItems))) {
                    Write-Host -ForegroundColor White "ExcludeEventItems"
                    Write-Host -ForegroundColor DarkGray "  Enabling this setting will always filter holiday and event items such as FICSMAS from the selection list when building factories"
                    Write-Host -ForegroundColor Blue "Enable this setting? (Y or N): " -NoNewline
                    $UserResponse = Read-Host

                    if ($UserResponse -match "Y") {
                        $Preferences.DisableEventItems = $true
                        $UpdateResponse = $null
                        if (!$New) {
                            $Update = $null
                        }

                    } elseif ($UserResponse -match "N") {
                        $Preferences.DisableEventItems = $false
                        $UpdateResponse = $null
                        if (!$New) {
                            $Update = $null
                        }

                    } else {
                        Write-Host -ForegroundColor Red "Invalid response, try again"
                    }

                } elseif (($Update -eq "DisableProjectRecipeSaving") -or (($Update -eq "All") -and !$Preferences.DisableProjectRecipeSaving)) {
                    Write-Host -ForegroundColor White "DisableProjectRecipeSaving"
                    Write-Host -ForegroundColor DarkGray "  Enabling this will set any recipe selections to be stored in the user preference file and will be used in ALL factory builds"
                    Write-Host -ForegroundColor DarkGray "  Hint: if you want to be prompted less for recipe selections during factory building, enable this"
                    Write-Host -ForegroundColor Blue "Enable this setting? (Y or N): " -NoNewline
                    $UserResponse = Read-Host

                    if ($UserResponse -match "Y") {
                        $Preferences.DisableProjectRecipeSaving = $true
                        $UpdateResponse = $null
                        if (!$New) {
                            $Update = $null
                        }

                    } elseif ($UserResponse -match "N") {
                        $Preferences.DisableProjectRecipeSaving = $false
                        $UpdateResponse = $null
                        if (!$New) {
                            $Update = $null
                        }

                    } else {
                        Write-Host -ForegroundColor Red "Invalid response, try again"
                    }

                } elseif (($Update -eq "CustomItems") -or (($Update -eq "All") -and (!$Preferences.CustomItems))) {
                    if (!$CustomItemResponse) {
                        Write-Host -ForegroundColor White "CustomItems"
                        Write-Host -ForegroundColor DarkGray "  This allows for importing of a custom item list.  Use this to add modded items to the game or customize existing items your own (permanently adding/removing recipes)"
                        Write-Host -ForegroundColor DarkGray "  Hint: The file must be organized exactly like the Items.JSON or the calculator will not work"
                        Write-Host -ForegroundColor Blue "Enable this setting? (Y or N): " -NoNewline
                        $CustomItemResponse = Read-Host
                    }
                    
                    if ($CustomItemResponse -match "Y") {
                        Write-Host ""
                        Write-Host -ForegroundColor Blue "Provide the full file path to the custom item JSON file"
                        Write-Host ""
                        $ItemJSONFile = Get-FilePath -JSON -Title "Select custom items JSON file"

                        if ((Test-Path -Path $ItemJSONFile -PathType Leaf) -eq $true) {
                            $Preferences.CustomItems = $ItemJSONFile
                            $UpdateResponse = $null
                            if (!$New) {
                                $Update = $null
                            }

                        } else {
                            Write-Host -ForegroundColor Red "Invalid path to file, try again"
                            $ItemJSONFile = $null
                        }

                    } elseif ($CustomItemResponse -match "N") {
                        $Preferences.CustomItems = "Disabled"
                        $UpdateResponse = $null
                        $CustomItemResponse = $null

                        if (!$New) {
                            $Update = $null

                        } else {
                            $ConfigComplete = $true
                        }

                    } else {
                        Write-Host -ForegroundColor Red "Invalid response, try again"
                        $CustomItemResponse = $null
                    }
                }

                Write-Host ""
            }
    
        } until ($ConfigComplete -eq $true)
        
        if ($Preferences) {
            $ExportPath = "$($Preferences.FilePath)"
            #Export preferences file
            try {

                $Preferences = $Preferences | ConvertTo-JSON
                $Preferences | Out-File -FilePath $ExportPath -Force

            } catch {
                Write-Host -ForegroundColor Red "Error exporting changes to the path [$($ExportPath)]"
                Write-Host -ForegroundColor Red $_
                $global:RunSettings.Mode = "Exit"
            }

            #Update imported preferences with new version
            if ((Test-Path -Path $ExportPath -PathType Leaf) -eq $true) {
                #Overwrite currently imported preferences
                $global:RunSettings.Preferences = ($Preferences | ConvertFrom-JSON)

                if ($New) {
                    Write-Host -ForegroundColor Green "Successfully created new user preference file to [$($ExportPath)]"
                    Write-Output $ExportPath

                } else {
                    Write-Host -ForegroundColor Green "Successfully updated existing user preference file with new settings"
                }
            }
        }
    }
}