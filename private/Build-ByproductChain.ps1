function Build-ByproductChain {
    $GroupedByproducts = $global:Byproducts | Group-Object Byproduct
    $CombinedByproducts = @()
    
    #Calculate totals for byproducts
    $GroupedByproducts | Foreach-Object {
        $Total = $null
        $UsedInChain = $null

        foreach ($Item in $_.Group) {
            $Total += $Item.Quantity
        }

        if ($global:GroupedItems.Name -contains $_.Name) {
            $UsedInChain = $true

        } else {
            $UsedInChain = $false
        }

        $CombinedByproducts += [PSCustomObject]@{
            Byproduct = $_.Name
            Quantity = $Total
            UsedInChain = $UsedInChain
        }
    }

    #Determine if a byproduct is being made that matches the item
    if ($CombinedByProducts.Byproduct -contains $_.Name) {
        $NameToSearch = $_.Name
        $ByproductMatch = $CombinedByproducts | Where-Object {$_.Byproduct -eq $NameToSearch}
        Write-Host "Byproduct match was found [$($ByproductMatch.Byproduct)]"
    }
}