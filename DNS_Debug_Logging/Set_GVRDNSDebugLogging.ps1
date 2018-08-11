function Set-GVRDNSDebugLogging {
    <#
.SYNOPSIS
    Sets the DNS Debug settings required by FIST.  Works on Server 2012 or above
.DESCRIPTION
    Sets the DNS Debug settings required by FIST.
.PARAMETER Computername
    FQDN of the system you would like to run against.  Accepts multiple values.  Accepts Pipeline
.PARAMETER Path
    The full path and filename of the debugging log file. Defaults to C:\dns_debugging.txt
.PARAMETER Credential
    Requires a PSCredential object
.PARAMETER MaxMBFileSize
    Maximum size of the debugging log file.  Defaults to "1000000"
    Defaults to 'admin:changeme'
.EXAMPLE
    C:\PS> Set-GVRDNSDebugging -ComputerName myhost.domain.com -Credential (get-credential)
    Sets DNS Debugging logging on myhost.domain.com defaulting to C:\dns_debugging.txt and filesize 1000000
.NOTES
    Author: Clarence Holbrook
    Date:   August 8, 2018
#>
    [CmdletBinding()]
    param(
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ComputerName,

        [String]$Path = "C:\dns_debugging.txt",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential,
        [Int]$MaxMBFileSize = "1000000"
    )

    begin {
    }

    process {

        #Configure DNS Debug Logging
        $cim = New-CimSession $ComputerName -Credential $cred

        Set-DnsServerDiagnostics -CimSession $cim -Queries:$true  -QuestionTransactions $true -ReceivePackets $true `
            -UdpPackets $true -EnableLogFileRollover $false -EnableLoggingToFile $true -LogFilePath $Path `
            -MaxMBFileSize $MaxMBFileSize -PassThru

    }

    end {
    }

} # function