function Get-Recipes {
    param (
        [string]$ItemName
    )
    
    #Lookup item and find all recipes
    if ($ItemName) {
        $ItemMatch = $global:ConfigMaster.Items | Where-Object {$_.ItemName -eq $ItemName}

        if ($ItemMatch) {
            Write-Output $ItemMatch.Recipes
        }
    }
}