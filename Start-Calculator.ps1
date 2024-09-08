$global:RunSettings = $null

#Create functions for prompting folder and file path via Windows explorer
function Get-FolderPath {
    param (
        [string]$Description
    )
    Add-Type -AssemblyName System.Windows.Forms
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
        ShowNewFolderButton = $false
        Description = $Description
    }
    $FolderBrowser.ShowDialog() | Out-Null

    Write-Output $FolderBrowser.SelectedPath
}

function Get-FilePath {
    param (
        [switch]$JSON,
        [string]$Title = "Select the file"
    )
    Add-Type -AssemblyName System.Windows.Forms
    if ($JSON) {
        $FileFilter = "JSON (*.json)|*.json"

    } else {
        $FileFilter = "All files (*.*)|*.*"
    }

    if ((Test-Path -Path "$($global:RunSettings.Preferences.ProjectDirectory)" -ErrorAction SilentlyContinue) -eq $true) {
        $InitialDirectory = "$($global:RunSettings.Preferences.ProjectDirectory)"
    } else {
        $InitialDirectory = [Environment]::GetFolderPath('Desktop')
    }

    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = $InitialDirectory
        Filter = $FileFilter
        Title = $Title
    }

    $FileBrowser.ShowDialog() | Out-Null
    Write-Output $FileBrowser.FileName
}

#Prompt for working directory
$global:CloseCalculator = $null

Write-Host -ForegroundColor Cyan "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"
Write-Host -ForegroundColor Cyan "Welcome to the Satisfactory Calculator"
Write-Host -ForegroundColor DarkGray "Developed by Zexxios"
Write-Host -ForegroundColor DarkGray "Documentation available at https://github.com/zexxios/satisfactorycalculator"
Write-Host -ForegroundColor Cyan "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"
Write-Host ""

if (Get-ChildItem -Path "$((Get-Location).Path)\Start-Calculator.ps1" -ErrorAction SilentlyContinue) {
    $ScriptPath = (Get-Location).Path

} else {
    do {
        Write-Host -ForegroundColor Blue "Select the folder where the satisfactorycalculator is stored (Dialog box for selection may be under this window)"
        $ScriptPath = Get-FolderPath -Description "Select root folder for the calculator files"
        
        if (!(Get-ChildItem -Path "$($ScriptPath)\Start-Calculator.ps1" -ErrorAction SilentlyContinue)) {
            Write-Host -ForegroundColor Red "Invalid folder path, try again"
        }

    } until ((Get-ChildItem -Path "$($ScriptPath)\Start-Calculator.ps1"))
}

#Import all private functions
if ((Test-Path -Path $ScriptPath) -eq $true) {
    $global:RunSettings = $null

    try {
        $AllFunctions = Get-ChildItem -Path "$($ScriptPath)\private"
        $AllFunctions | Foreach-Object {
            $ModuleName = $_.Name.Replace(".ps1","")
            if (Get-Module -Name $ModuleName) {
                Remove-Module -Name $ModuleName
            }
            Import-Module -Name $_.FullName
        }

    } catch {
        throw "Error importing private functions, terminating"
    }

} else {
    throw "Unable to access path [$($ScriptPath)], terminating"
}

do {
    $global:ActiveProject = $null

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

    if ($global:ConfigMaster) {
        #Prompt user for run mode
        New-UserPrompt -Start

        #Format the config master to add IDs to all items and filter based on preferences
        Format-ConfigMaster

        if ($global:RunSettings.Mode -eq "New") {
            #Prompt user for project / factory build questions
            $NewProject = New-UserPrompt -NewProjectStart

            #Add project to project list and set as active
            $global:RunSettings.Projects += $NewProject
            $global:ActiveProject = $global:RunSettings.Projects | Where-Object {$_.ID -eq $NewProject.ID}

            if ($global:ActiveProject.ID) {
                #Build production chains for new factory
                Build-ProductionChains -ItemName $global:ActiveProject.Item -PerMinute $global:ActiveProject.Quantity

                if ($global:ActiveProject.Details.ProductionChains) {
                    $global:ActiveProject.Details.ProductionChains = $global:ActiveProject.Details.ProductionChains | Sort-Object Tier -Descending

                    #Write production line out
                    Write-Host ""
                    Write-Host -ForegroundColor Green "Successfully generated production chains for [$($global:ActiveProject.Name)] project"
                    Write-Output ($global:ActiveProject.Details.ProductionChains | ft)

                    #Calculate totals from production line
                    Build-TotalsFromChains

                    if ($global:ActiveProject.Details.Machines -and $global:ActiveProject.Details.Totals) {
                        $global:ActiveProject.Details.Machines = $global:ActiveProject.Details.Machines | Sort-Object Name
                        $global:ActiveProject.Details.Totals = $global:ActiveProject.Details.Totals | Sort-Object Tier

                        Write-Host ""
                        Write-Host -ForegroundColor Green "Successfully calculated total items and machines for [$($global:ActiveProject.Name)] project"
                        Write-Host ""
                        Write-Host -ForegroundColor Blue "Machines"
                        Write-Output ($global:ActiveProject.Details.Machines | ft)
                        Write-Host ""
                        Write-Host -ForegroundColor Blue "Total Items Produced"
                        Write-Output ($global:ActiveProject.Details.Totals | ft)

                        if ($global:ActiveProject.Details.Byproducts.Count -ge 1) {
                            Build-ByproductChain
                        }

                        #Generate CSV or HTML data if user wants it
                        #Export-Project

                        #End factory build
                        New-UserPrompt -End
                    }
                }
            }
            
        } elseif ($global:RunSettings.Mode -eq "Existing") {
            $NewProject = New-UserPrompt -NewProjectStart
        }

    } else {
        throw "Unable to import JSON files from project"
    }

} until ($global:CloseCalculator -eq $true)

$global:RunSettings = $null