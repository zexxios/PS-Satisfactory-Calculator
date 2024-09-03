#Set variables
$ScriptPath = "C:\Users\Zac\OneDrive - Zac McKenna Enterprises\VSCode\GitHub\satsifactorycalculator"

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
}

#Prompt user to select item or type item name
$FactoryDefinition = New-UserPrompt -ListItems

#Build the factory
if ($FactoryItem) {
    $FactoryBuild = New-FactoryBuild -FactoryItem $FactoryDefinition
}
