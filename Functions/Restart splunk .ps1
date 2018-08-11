$list = "vm-is-gsodc07"


foreach ($l in $list) {
    $response = Invoke-Command -ComputerName $l -Credential $cred -ScriptBlock {

        set-location 'C:\Program Files\SplunkUniversalForwarder\bin\' ; .\splunk.exe restart -auth admin:changeme
    } # scriptblock


    $obj = New-Object -TypeName PSObject -Property @{
        Computername = "$l"
        Response     = "$response"
    }

    $obj | fl
} # foreach $l in $list

