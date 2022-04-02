function Invoke-TorEnrichment {
    [CmdletBinding()]
    param (
        [string] [Parameter(Mandatory = $true)] $InputFolder
    )
    $RelayIPCSV = "TorRelayIPs.csv"
    $IPInfo = "TorIPInfo.csv"
    $RelayIPs = @()

    # Testing output directory
    if (!(Test-Path($InputFolder))) {
        Write-Host "Error: Input folder does not exist"
        break
    }

    $RelayIPs = Import-CSV $InputFolder\$RelayIPCSV
    $acount = $RelayIPs.count
    Write-Host "Addresses to check: $($acount)"
    if ($acount -ge 7000) {
        Write-Host "There are more than 7,000 addresses. This should take approximately 10 minutes."
    }
    $currentdate = Get-Date -AsUTC
    $output = $RelayIPs | ForEach-Object -parallel {
        class TorIPInfo {
            [string] $Fingerprint
            [string] $IP
            [string] $Type
            [string] $ASN
            [string] $ISP
            [string] $Organisation
            [string] $Continent
            [string] $Country
            [string] $CountryCode
            [string] $CountryPhone
            [string] $Region
            [string] $City
            [string] $Latitude
            [string] $Longitude
            [string] $Timezone
            [datetime] $DateCollected
        }
        Write-Verbose "Checking status for: $($_.IPAddress)"
        $wr = Invoke-RestMethod -Uri "https://ipwhois.app/json/$($_.IPAddress)" -UseBasicParsing
        $DD = [TorIPInfo]::new()
        $DD.DateCollected = $using:currentdate
        $DD.Fingerprint = $_.Fingerprint
        $DD.IP = $wr.ip
        $DD.Type = $wr.type
        $DD.ASN = $wr.asn
        $DD.ISP = $wr.isp
        $DD.Organisation = $wr.org
        $DD.Continent = $wr.continent
        $DD.Region = $wr.region
        $DD.City = $wr.city
        $DD.Country = $wr.country
        $DD.CountryCode = $wr.country_code
        $DD.CountryPhone = $wr.country_phone
        $DD.Latitude = $wr.latitude
        $DD.Longitude = $wr.longitude
        $DD.Timezone = $wr.timezone
        $DD
    } -ThrottleLimit 3

    Write-Host "Saving output to $InputFolder"
    $Output | Export-csv $InputFolder\$IPInfo -NoTypeInformation -Force
}
