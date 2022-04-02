
# Tor Project Statistics PowerShell Module

![yee](https://forthebadge.com/images/badges/built-with-grammas-recipe.svg)

This is a small PowerShell module for pulling Tor relay and bridge data/statistics from the official Tor Project API located here https://metrics.torproject.org/onionoo.html.

The module saves all output files as CSV's for ingestion into PowerBI or for your manual reading pleasure.

#### 02 April 2022 Update: Version 2.0 released
Version 2.0 includes a number of key changes to the way data is collected and processed by the Tor API.

* Module Performance
  * Code improvements have significantly reduced execution time for full data collection and parsing, seeing a performance increase of 88% (5 minutes down to 38 seconds on average)
  * While not currently enforced, PowerShell 7.0 will become the minimum required version in the next release
* New PowerShell Functions
  * Invoke-TorEnrichment
    * This function collects updated IP WHOIS information from ipwhois.io. PowerShell 7.0 is required to execute this.
* Collected Data
  * TorRelayIPs
    * IPv6 addresses and ports are now parsed!
    * Replacement of the IPv4Address and IPv6Address fields with "IPAddress"
    * Replacement of the IPv4Port and IPv6Port fields with "Port"
  * TorRelayFlags
    * New output that captures the individual flags for each relay
  * TorIPInfo
    * New output file from calling Invoke-TorEnrichment
* PowerBI
  * Public dashboard now available
    * https://tor.intelr.net/
  * Data visualisation improvements 
  * Tor.pbit
    * This file will be updated with the next release to include new visuals and additional datasets
  
# Installation

1. Download the code from this github

2. Run Import-Module Tor.psd1

(The module will be published to the PowerShell gallery shortly)

# Usage

There are two functions to this PowerShell module.

### Get-TorSummary

This data is a high level summary of Tor node information.

Get-TorSummary -OutputFolder C:\TorStats\Output

* Required switch: OutputFolder. If your OutputFolder does not exist, it will be created for you.

### Get-TorRelay

This cmdlet outputs relevant information for each Tor relay node from the Tor Project API.

Get-TorRelay -OutputFolder C:\TorStats\Output

* Required switch: OutputFolder. If your OutputFolder does not exist, it will be created for you.

* Optional switch: ReverseLookup. This uses Resolve-DnsName to enrich data where there is not a verified hostname returned by the Tor Project API. **Note** This can take up to 3 hours to execute.

* Optional switch: ExportExitPolicy. This will extract node exit policies. Although not completely parsed, it could be used to identify suitable exit nodes if you have a specific set of requirements.

### Invoke-TorEnrichment

This function uses output from TorRelayIPs.csv to call the ipwhois.io API, enriching all IP addresses with updated IP WHOIS information.

**TorIPInfo.csv**

* New output file from calling Invoke-TorEnrichment, includes a range of supplementary information including ASN, ISP, registered owner and more.

# Command Output

### Get-TorSummary

**TorRelaySummary.csv**

* This contains high level information on each Tor relay, such as nickname, unparsed IP addresses and the last time it was updated in the Onionoo API.

**TorBridgeSummary.csv**

* Similiar to relay summary, this shows available information on each Tor bridge.

### Get-TorRelay

This is where the magic happens. Disclaimer: not all data returned from the API is parsed into the CSV. Specific data that is parsed can be found in the relevant TorRelay* class files.

**TorRelayData.csv**

* This file does most of the heavy lifting. It contains information on the node ISP, bandwidth data and geography.

**TorRelayIPs.csv**

* Contains parsed IPv4 Tor relay address and port information.
  
**Optional: TorRelayExitPolicy.csv**

* The exit policy data on each node and it's exit policy, including what it does or does not allow.
  
## Uses for Data

This module was originally created so I can visualise node information in PowerBI, but also to parse and join data in Microsoft Defender for Endpoint for the purpose of identifying if any devices have contacted/communicated with a Tor relay.

**PowerBI**

The PowerBI template provided is best efforts and can be used as a base framework.

To analyse the data inside PowerBI:

1. Open the TorStats.pbit file

2. When prompted, provide the output folder location you selected when running the Get-TorRelay

3. Profit

**Microsoft Defender for Endpoint Advanced Hunting**

The following command will show you all connection attempts to a Tor relay node, and the process that called it.

    let TorRelayData = (
    externaldata (Nickname:string,Fingerprint:string,EntryAddress:string,IPAddress:string,Port:string,AddressType:string,Hostname:string,CountryCode:string,IsRunning:bool,RelayPublishDate:string,LastChangedIPData:string)
    [h@'https://torinfo.blob.core.windows.net/public/TorRelayIPs.csv'] with (ignoreFirstRecord=true,format="csv")
    | where AddressType == "IPv4"
    );
    TorRelayData
    | join kind=inner DeviceNetworkEvents on $left.IPAddress == $right.RemoteIP
    | join kind=inner (DeviceInfo | distinct DeviceId, PublicIP) on DeviceId
    | project Timestamp, DeviceId, LocalPublicIP = PublicIP, LocalIP, RemoteIP, TorIP = IPAddress, Hostname, CountryCode, ActionType, InitiatingProcessFileName, InitiatingProcessFolderPath

## Published list

If you want the power of the cloud to do your heavy lifting, the output for each CSV can be found below. Each file is updated daily at 12AM and 12PM UTC.

* https://torinfo.blob.core.windows.net/public/TorRelaySummary.csv

* https://torinfo.blob.core.windows.net/public/TorBridgeSummary.csv

* https://torinfo.blob.core.windows.net/public/TorRelayData.csv

* https://torinfo.blob.core.windows.net/public/TorRelayIPs.csv

* https://torinfo.blob.core.windows.net/public/TorRelayFlags.csv

* https://torinfo.blob.core.windows.net/public/TorIPInfo.csv

* https://torinfo.blob.core.windows.net/public/TorRelayExitPolicy.csv

## To-do list

* Parse Tor Bridge information
* Enrich reverse DNS for each Tor relay
