function Get-TorRelay {
    [CmdletBinding()]
    param (
        [switch] $ExportExitPolicy,
        [string] [Parameter(Mandatory = $true)] $OutputFolder
        # [switch] $ReverseLookup
    )
    $RelayDataCSV = "TorRelayData.csv"
    $RelayIPCSV = "TorRelayIPs.csv"
    $RelayExitCSV = "TorRelayExitPolicy.csv"
    $RelayFlagCSV = "TorRelayFlags.csv"
    $RelayCore = New-Object System.Collections.Generic.List[TorRelayData]
    $RelayIPs = New-Object System.Collections.Generic.List[TorRelayIP]
    $RelayExitPolicy = New-Object System.Collections.Generic.List[TorRelayExitPolicy]
    $RelayFlags = New-Object System.Collections.Generic.List[TorFlags]

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
    $PageResponse = Invoke-RestMethod $Uri -UseBasicParsing
    $DataOutput = $PageResponse.relays

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
        $RelayData.ASName = $Relay.as_name
        $RelayData.ASNumber = $Relay.as
        $RelayData.BandwidthMaxRate = $Relay.bandwidth_rate
        $RelayData.BandwidthBurst = $Relay.bandwidth_burst
        $RelayData.BandwidthActual = $Relay.observed_bandwidth
        $RelayData.BandwidthAdvertised = $Relay.advertised_bandwidth
        $RelayData.Platform = $Relay.Platform
        $RelayData.Version = $Relay.Version
        $RelayCore.Add($RelayData) | Out-Null

        foreach ($Ip in $Relay.or_addresses) {
            if ($Ip.StartsWith('[')) {
                $rgxip6addr = '(?<=\[).*?(?=])'
                $rgxip6port = '(?<=\]:)[\S]*'
                $ip6port = (Select-String -Pattern $rgxip6port -InputObject $ip).Matches.Value
                $ip6addr = (Select-String -Pattern $rgxip6addr -InputObject $ip).Matches.Value
                $RelayIPData = [TorRelayIp]::new()
                $RelayIPData.Nickname = $Relay.nickname
                $RelayIPData.Fingerprint = $Relay.fingerprint
                $RelayIPData.EntryAddress = $Ip
                $RelayIPData.IPAddress = $ip6addr
                $RelayIPData.Port = $ip6port
                $RelayIPData.AddressType = "IPv6"
                if (!$Relay.verified_host_names){
                    $RelayIPData.Hostname = $Relay.unverified_host_names
                } else {
                    $RelayIPData.Hostname = $Relay.verified_host_names
                }
                $RelayIPData.CountryCode = $Relay.country
                $RelayIPData.IPLastChangeDate = $Relay.last_changed_address_or_port
                $RelayIPs.Add($RelayIPData) | Out-Null
            }
            else {
                $RelayIPData = [TorRelayIp]::new()
                $RelayIPData.Nickname = $Relay.nickname
                $RelayIPData.Fingerprint = $Relay.fingerprint
                $RelayIPData.EntryAddress = $Ip
                $RelayIPData.IPAddress = $Ip.SubString(0, $Ip.IndexOf(":"))
                $RelayIPData.Port = $Ip.Split(":")[-1]
                $RelayIPData.AddressType = "IPv4"
                if (!$Relay.verified_host_names){
                    $RelayIPData.Hostname = $Relay.unverified_host_names
                } else {
                    $RelayIPData.Hostname = $Relay.verified_host_names
                }
                # if ($ReverseLookup) {
                #     if ($null -eq $Relay.verified_host_names) {
                #         Write-verbose "Performing lookup | $($Ip.SubString(0,$Ip.IndexOf(":")))"
                #         $dnslookup = Resolve-DnsName -Name $Ip.SubString(0, $Ip.IndexOf(":")) -TcpOnly -DnsOnly -QuickTimeout -ErrorAction SilentlyContinue
                #         if ($null -eq $dnslookup) {
                #             $RelayIPData.Hostname = $Relay.verified_host_names
                #         }
                #         else {
                #             $RelayIPData.Hostname = $dnslookup.NameHost
                #         }
                #     }
                #     else {
                #         $RelayIPData.Hostname = $Relay.verified_host_names
                #     }
                # }
                # else {
                #     $RelayIPData.Hostname = $Relay.verified_host_names
                # }
                $RelayIPData.CountryCode = $Relay.country
                $RelayIPData.IPLastChangeDate = $Relay.last_changed_address_or_port
                $RelayIPs.Add($RelayIPData) | Out-Null
            }
        }
        foreach ($flag in $Relay.flags) {
            $RelayFlagData = [TorFlags]::new()
            $RelayFlagData.Fingerprint = $Relay.fingerprint
            $RelayFlagData.NodeType = "Relay"
            $RelayFlagData.Flag = $flag
            $RelayFlags.Add($RelayFlagData) | Out-Null
        }
        if ($ExportExitPolicy) {
            foreach ($Policy in $Relay.exit_policy) {
                $RelayPolicy = [TorRelayExitPolicy]::new()
                $RelayPolicy.Nickname = $Relay.nickname
                $RelayPolicy.Fingerprint = $Relay.fingerprint
                $RelayPolicy.Policy = $Policy
                $RelayExitPolicy.Add($RelayPolicy) | Out-Null
            }
        }
    }

    Write-Host "Saving output to $OutputFolder"
    $RelayCore | Export-csv $OutputFolder\$RelayDataCSV -NoTypeInformation -Force
    $RelayIPs | Export-csv $OutputFolder\$RelayIPCSV -NoTypeInformation -Force
    $RelayFlags | Export-csv $OutputFolder\$RelayFlagCSV -NoTypeInformation -Force

    if ($ExportExitPolicy) {
        $RelayExitPolicy | Export-csv $OutputFolder\$RelayExitCSV -NoTypeInformation -Force
    }
}
