function Invoke-CloneObject ($InputObject) {
    [System.Management.Automation.PSSerializer]::Deserialize(
        [System.Management.Automation.PSSerializer]::Serialize(
            $InputObject
        )
    )
}