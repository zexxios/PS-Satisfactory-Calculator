function Build-ByproductChain {
    $GroupedByproducts = $global:ActiveProject.Details.Byproducts | Group-Object Byproduct
    $CombinedByproducts = @()
    
    #Calculate totals for byproducts
    $GroupedByproducts | Foreach-Object {
        $Total = $null
        $UsedInChain = $null
        $SourceChains = $null

        foreach ($Item in $_.Group) {
            $Total += $Item.Quantity
            $SourceChains += $Item.Chain
        }

        if ((($global:ActiveProject.Details.ProductionChains | Group-Object Name).Name) -contains $_.Name) {
            $UsedInChain = $true

        } else {
            $UsedInChain = $false
        }

        if ($UsedInChain -eq $true) {
            #Write logic to prompt user to either create a factory chain to use byproduct
            # or send it back into the production chain
            
        } else {

        }

        $CombinedByproducts += [PSCustomObject]@{
            Byproduct = $_.Name
            Quantity = $Total
            Recycle = $false
            UsedInChain = $UsedInChain
            SourceChains = $Chains -Join ", "
        }
    }

    if ($CombinedByproducts) {
        $global:ActiveProject.Details.Byproducts = $CombinedByproducts
    }
}