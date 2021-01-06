function Get-TorRelay {
    [CmdletBinding()]
    param (
        [switch] $ExportExitPolicy,
        [string] [Parameter(Mandatory = $true)] $OutputFolder,
        [switch] $ReverseLookup,
        [switch] $EnrichData
    )
    $RelayDataCSV = "TorRelayData.csv"
    $RelayIPCSV = "TorRelayIPs.csv"
    $RelayExitCSV = "TorRelayExitPolicy.csv"
    $RelayCore = @()
    $RelayIPs = @()
    $RelayExitPolicy = @()

    # Testing output directory
    if (!(Test-Path($OutputFolder))) { 
        Try {
            mkdir $OutputFolder -ErrorAction:Stop | Out-Null 
        }
        catch {
            Write-Error "Cannot create configuration folder $($OutputFolder)"
            exit
        }
    }

    Write-Host "Downloading TOR relay data" -ForegroundColor Green
    $Uri = "https://onionoo.torproject.org/details"
    $PageResponse = Invoke-WebRequest $Uri -UseBasicParsing
    $DataOutput = ($PageResponse.Content | convertfrom-json).relays
    if ($ExportExitPolicy) {
        Write-Host "Exporting exit policy data can take over 5 minutes - doing the needful." -ForegroundColor Gray
    }
    foreach ($Relay in $DataOutput) {
        $RelayData = [TorRelayData]::new()
        $RelayData.Nickname = $Relay.nickname
        $RelayData.Fingerprint = $Relay.fingerprint
        $RelayData.FirstSeen = $Relay.first_seen
        $RelayData.LastSeen = $Relay.last_seen
        $RelayData.LastRelayRestart = $Relay.last_restarted
        $RelayData.IsRunning = $Relay.running
        $RelayData.Contact = $Relay.contact
        $RelayData.Country = $Relay.country_name
        $RelayData.CountryCode = $Relay.country
        $RelayData.Region = $Relay.region_name
        $RelayData.City = $Relay.city_name
        if ($null -eq $Relay.as_name) {
            if ($EnrichData) {
                    foreach ($Ip in $Relay.or_addresses) {
                        if ($Ip.StartsWith('[')) {
                        }
                        else {
                            $IPAddr = $Ip.SubString(0, $Ip.IndexOf(":"))
                            $wr = Invoke-WebRequest -Uri "https://ipwhois.app/json/$IPAddr"
                            $parsed = $wr.content | convertfrom-json
                            $RelayData.ASName = $parsed.isp 
                            $RelayData.ASNumber = $parsed.asn
                        }
                    }
            }
            else {
                $RelayData.ASName = $Relay.as_name
                $RelayData.ASNumber = $Relay.as
            }
        }
        else {
            $RelayData.ASName = $Relay.as_name
            $RelayData.ASNumber = $Relay.as
        }
        $RelayData.BandwidthMaxRate = $Relay.bandwidth_rate
        $RelayData.BandwidthBurst = $Relay.bandwidth_burst
        $RelayData.BandwidthActual = $Relay.observed_bandwidth
        $RelayData.BandwidthAdvertised = $Relay.advertised_bandwidth
        $RelayData.Platform = $Relay.Platform
        $RelayData.Version = $Relay.Version
        $RelayCore += $RelayData

        foreach ($Ip in $Relay.or_addresses) {
            if ($Ip.StartsWith('[')) {
                $RelayIPData = [TorRelayIp]::new()
                $RelayIPData.Nickname = $Relay.nickname
                $RelayIPData.Fingerprint = $Relay.fingerprint
                $RelayIPData.EntryAddress = $Ip
                $RelayIPData.IPv6Address = $Ip
                $RelayIPData.AddressType = "IPv6"
                $RelayIPData.Hostname = $Relay.verified_host_names
                $RelayIPData.CountryCode = $Relay.country
                $RelayIPs += $RelayIPData
            }
            else {
                $RelayIPData = [TorRelayIp]::new()
                $RelayIPData.Nickname = $Relay.nickname
                $RelayIPData.Fingerprint = $Relay.fingerprint
                $RelayIPData.EntryAddress = $Ip
                $RelayIPData.IPv4Address = $Ip.SubString(0, $Ip.IndexOf(":"))
                $RelayIPData.IPv4Port = $Ip.Split(":")[-1]
                $RelayIPData.AddressType = "IPv4"
                if ($ReverseLookup) {
                    if ($null -eq $Relay.verified_host_names) {
                        Write-verbose "Performing lookup | $($Ip.SubString(0,$Ip.IndexOf(":")))"
                        $dnslookup = Resolve-DnsName -Name $Ip.SubString(0, $Ip.IndexOf(":")) -TcpOnly -DnsOnly -QuickTimeout -Server 1.1.1.1 -ErrorAction SilentlyContinue
                        if ($null -eq $dnslookup) {
                            $RelayIPData.Hostname = $Relay.verified_host_names
                        }
                        else {
                            $RelayIPData.Hostname = $dnslookup.NameHost
                        }
                    }
                    else {
                        $RelayIPData.Hostname = $Relay.verified_host_names
                    }
                }
                else {
                    $RelayIPData.Hostname = $Relay.verified_host_names
                }
                $RelayIPData.CountryCode = $Relay.country
                $RelayIPs += $RelayIPData
            }
        }
        
        if ($ExportExitPolicy) {
            foreach ($Policy in $Relay.exit_policy) {
                $RelayPolicy = [TorRelayExitPolicy]::new()
                $RelayPolicy.Nickname = $Relay.nickname
                $RelayPolicy.Fingerprint = $Relay.fingerprint
                $RelayPolicy.Policy = $Policy
                $RelayExitPolicy += $RelayPolicy
            }
        }
    }

    Write-Host "Saving output to $OutputFolder"
    $RelayCore | Export-csv $OutputFolder\$RelayDataCSV -NoTypeInformation -Force
    $RelayIPs | Export-csv $OutputFolder\$RelayIPCSV -NoTypeInformation -Force
    if ($ExportExitPolicy) {
        $RelayExitPolicy | Export-csv $OutputFolder\$RelayExitCSV -NoTypeInformation -Force
    }
}