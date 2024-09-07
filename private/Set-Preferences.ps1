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
                ProjectDirectory = $null
                RecycleByproducts = $null
                ExcludeEventItems = $null
                CustomItems = @()
                Recipes = @()
            }
    
        } elseif ($Path) {
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
                            Write-Host -ForegroundColor Blue "Provide the full folder path to save new projects: " -NoNewline
        
                        } else {
                            Write-Host -ForegroundColor Blue "Provide the full folder path to your existing project folder: " -NoNewline
                        }

                        $UserResponse = Read-Host

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
                    Write-Host -ForegroundColor Blue "Always try to recycle byproducts back into the production line (will apply to ALL factory builds)? (Y or N): " -NoNewline
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

                } elseif (($Update -eq "ExcludeEventItems") -or (($Update -eq "All") -and (!$Preferences.ExcludeEventItems))) {
                    Write-Host -ForegroundColor Blue "Do you want to exclude event items from the item list (Example: No FICSMAS items)? (Y or N): " -NoNewline
                    $UserResponse = Read-Host

                    if ($UserResponse -match "Y") {
                        $Preferences.ExcludeEventItems = $true
                        $UpdateResponse = $null
                        if (!$New) {
                            $Update = $null
                        }

                    } elseif ($UserResponse -match "N") {
                        $Preferences.ExcludeEventItems = $false
                        $UpdateResponse = $null
                        if (!$New) {
                            $Update = $null
                        }

                    } else {
                        Write-Host -ForegroundColor Red "Invalid response, try again"
                    }

                } elseif (($Update -eq "CustomItems") -or (($Update -eq "All") -and (!$Preferences.CustomItems))) {
                    #Write function to call this
                    if ($Update -eq "All") {
                        $ConfigComplete = $true
                    }

                } elseif (($Update -eq "Recipes") -or (($Update -eq "All") -and (!$Preferences.CustomItems))) {
                    #Write function to call this
                    if ($Update -eq "All") {
                        $ConfigComplete = $true
                    }
                }
            }
    
        } until ($ConfigComplete -eq $true)
        
        if ($Preferences) {
            #Export preferences file
            try {
                if ($New) {
                    $Path = "$($Path)\UserPreferences.json"
                }

                $Preferences | ConvertTo-JSON | Out-File -FilePath $Path -Force

            } catch {
                $ProblemExporting = $true
                Write-Host -ForegroundColor Red "Error exporting changes to the path [$($Path)]"
                Write-Host -ForegroundColor Red $_
            }
            
            #Overwrite currently imported preferences
            $global:RunSettings.Preferences = $Preferences

            if (($New) -and ((Test-Path -Path $Path) -eq $true)) {
                Write-Host -ForegroundColor Green "Successfully exported new user preference file to [$($Path)]"
                Write-Output $Path

            } elseif ((!$ProblemExporting) -and ((Test-Path -Path $Path) -eq $true)) {
                Write-Host -ForegroundColor Green "Successfully updated the existing user preference file in [$($Path)]"
            }
        }
    }
}