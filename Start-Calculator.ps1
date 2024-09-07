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

#Import all JSON files
if ((Test-Path -Path $ScriptPath) -eq $true) {
    $global:ConfigMaster = @{}
    $AllConfigFiles = Get-ChildItem -Path "$($ScriptPath)\Config"

    foreach ($File in $AllConfigFiles) {
        $ConfigName = $null
        $FileContent = $null

        $ConfigName = $File.Name.Replace(".json","")
        $FileContent = Get-Content -Path $File.FullName | ConvertFrom-Json

        $global:ConfigMaster.Add($ConfigName,$FileContent)
    }

    $AllFunctions = Get-ChildItem -Path "$($ScriptPath)\private"
    foreach ($Function in $AllFunctions) {
        Import-Module $Function.FullName
    }
}

if ($global:ConfigMaster) {
    #Format the config master to add IDs to all items
    Format-ConfigMaster

    #Prompt user for run mode
    New-UserPrompt -Start

    if ($global:RunMode -eq "New") {
        $global:NewFactory = $null

        #Prompt user for project / factory build questions
        $global:NewFactory = New-UserPrompt -NewProjectStart

        if ($global:NewFactory.Item) {
            #Build production chains for new factory
            Build-ProductionChains -ItemName $global:NewFactory.Item -PerMinute $global:NewFactory.Quantity

            if ($global:NewFactory.Details.ProductionChains) {
                $global:NewFactory.Details.ProductionChains = $global:NewFactory.Details.ProductionChains | Sort-Object Tier -Descending

                #Write production line out
                Write-Host ""
                Write-Host -ForegroundColor Green "Successfully generated production chains for [$($global:NewFactory.Name)] project"
                Write-Output ($global:NewFactory.Details.ProductionChains | ft)

                #Calculate totals from production line
                Build-TotalsFromChains

                if ($global:NewFactory.Details.Machines -and $global:NewFactory.Details.Totals) {
                    $global:NewFactory.Details.Machines = $global:NewFactory.Details.Machines | Sort-Object Name
                    $global:NewFactory.Details.Totals = $global:NewFactory.Details.Totals | Sort-Object Tier

                    Write-Host ""
                    Write-Host -ForegroundColor Green "Successfully calculated total items and machines for [$($global:NewFactory.Name)] project"
                    Write-Host ""
                    Write-Host -ForegroundColor Blue "Machines"
                    Write-Output ($global:NewFactory.Details.Machines | ft)
                    Write-Host ""
                    Write-Host -ForegroundColor Blue "Total Items Produced"
                    Write-Output ($global:NewFactory.Details.Totals | ft)

                    if ($global:NewFactory.Details.Byproducts.Count -ge 1) {
                        New-UserPrompt -Byproduct

                    }

                    New-UserPrompt -End
                }
            }
        }
        
    } elseif ($global:RunMode -eq "Existing") {

    }
}