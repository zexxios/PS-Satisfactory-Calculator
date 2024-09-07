#Prompt for working directory
Write-Host -ForegroundColor Cyan "///////////////////////////////////////////////////////"
Write-Host -ForegroundColor Cyan "Welcome to the Satisfactory Calculator"
Write-Host -ForegroundColor DarkGray "Developed by Zexxios"
Write-Host -ForegroundColor DarkGray "Documentation available at https://github.com/zexxios/satisfactorycalculator"
Write-Host -ForegroundColor Cyan "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"

if (Get-ChildItem -Path (Get-Location).Path | Where-Object {$_.Name -match "Start-Calculator.ps1"}) {
    $ScriptPath = (Get-Location).Path

} else {
    do {
        Write-Host -ForegroundColor Blue "Provide the file path to the satsifactorycalculator folder: " -NoNewLine
        $ScriptPath = Read-Host
        
        if ((Get-ChildItem -Path $ScriptPath | Where-Object {$_.Name -match "Start-Calculator.ps1"}) -eq $false) {
            Write-Host -ForegroundColor Red "Invalid file path, try again"
        }

    } until ((Get-ChildItem -Path $ScriptPath | Where-Object {$_.Name -match "Start-Calculator.ps1"}) -eq $true)
}

#Import all private functions
if ((Test-Path -Path $ScriptPath) -eq $true) {
    try {
        $AllFunctions = Get-ChildItem -Path "$($ScriptPath)\private"
        foreach ($Function in $AllFunctions) {
            Import-Module $Function.FullName
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

    #Prompt user for run mode
    New-UserPrompt -Start

    #Format the config master to add IDs to all items and filter based on preferences
    Format-ConfigMaster

    if ($global:RunMode -eq "New") {
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
                    #New-UserPrompt -End
                }
            }
        }
        
    } elseif ($global:RunMode -eq "Existing") {
        
    }

} until ($global:CloseCalculator -eq $true)