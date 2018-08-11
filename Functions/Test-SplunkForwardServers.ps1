function Test-SplunkForwardServers {
    <#
.SYNOPSIS
    Validate that the Fortive Splunk Forwarders are active on a remote system
.DESCRIPTION
    Validate that the Fortive Splunk Forwarders are active on a remote system
.PARAMETER Computername
    FQDN of the system you would like to run against.  Accepts multiple values.  Accepts Pipeline
.PARAMETER SplunkInstall
    Specifies a path to the 'bin' directory of the splunk install
    Defaults to "C:\Program Files\SplunkUniversalForwarder\bin\"
.PARAMETER Credential
    Requires a PSCredential object
.PARAMETER SplunkLogin
    Enter the login credentials for the splunk application
    Defaults to 'admin:changeme'
.EXAMPLE
    C:\PS> Test-SplunkFowardServers -ComputerName myhost.domain.com -Credential (get-credential)
    Test the fowarders using the default SplunkLogin credential and default install path
.EXAMPLE
    C:\PS> Test-SplunkFowardServers -ComputerName myhost.domain.com -Credential (get-credential) -SplunkLogin 'admin:passw0rd'
    Test the fowarders specifying custom SplunkLogin credential and default install path
.NOTES
    Author: Clarence Holbrook
    Date:   August 8, 2018
#>
    [CmdletBinding()]
    param(
        [Parameter (Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ComputerName,

        [String]$SplunkInstallDirectory = "C:\Program Files\SplunkUniversalForwarder\bin\",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential,

        [string]$SplunkLogin = 'admin:changeme'
    )

    begin {

    }

    process {
        foreach ($l in $ComputerName) {
            $response = Invoke-Command -ComputerName $l -Credential $Credential -ScriptBlock {

                set-location $using:SplunkInstallDirectory ; .\splunk.exe list forward-server -auth $using:SplunkLogin
            } # scriptblock


            $obj = New-Object -TypeName PSObject -Property @{
                Computername = "$l"
                Response     = "$response"
            }

            $obj
        } # foreach $l in $list

    }

    end {
    }
}


