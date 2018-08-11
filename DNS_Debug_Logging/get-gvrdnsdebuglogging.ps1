function Get-GVRDNSDebugLogging {
    <#
.SYNOPSIS
    Pulls DNS Debug Logging settings
.DESCRIPTION
    Audits the DNS Debug settings required by FIST.  Requires RSAT tools be installed
    Requires that the remote computer be Windows 2012 or higher with DNS services installed
.PARAMETER Computername
    FQDN of the system you would like to run against.  Accepts multiple values.  Accepts Pipeline
.PARAMETER Credential
    Requires a PSCredential object
.EXAMPLE
    C:\PS> Get-GVRDNSDebugging -ComputerName myhost.domain.com -Credential (get-credential)
    Lists DNS Debug log settings on myhost.domain.com
.EXAMPLE
    C:\PS> $cred = (get-credential)
    C:\PS> $all = get-addomain | % replicadirectoryservers | Get-GVRDNSDebugging -Credential $cred
    C:\PS> $all | select PSComputername, Queries, QuestionTransactions, ReceivePackets, UDPPackets, EventLogLevel, LogfilePath, MaxMBFileSize | ft
    Lists FIST required DNS Debug log settings on all domain controllers in AD domain
.NOTES
    Author: Clarence Holbrook
    Date:   August 8, 2018
#>
    [CmdletBinding()]
    param(
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ComputerName,
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )

    begin {
    }

    process {
        try {
            $cim = New-CimSession $ComputerName -Credential $cred

            Get-DnsServerDiagnostics -CimSession $cim
        }
        catch {
            Write-Verbose -Message "$_.Exception.Message"
        }

        #Configure DNS Debug Logging


    }

    end {
    }

} # function