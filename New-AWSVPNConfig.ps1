Function New-AWSVPNConfig {
    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'high')]
    [OutputType('Region', [string])]
    [OutputType('publicIP', [string])]
    [OutputType('Type', [string])]
    param(
        [Parameter(ParameterSetName = 'VPN')]
        [string]
        $AWSCreds = ($(Get-AWSCredential -ListProfileDetail)[0] | Select -ExpandProperty ProfileName),

        [Parameter(ParameterSetName = 'VPN')]
        [ValidateSet('ap-northeast-1',
            'ap-northeast-2',
            'ap-south-1',
            'ap-southeast-1',
            'ap-southeast-2',
            'ca-central-1',
            'eu-central-1',
            'eu-west-1',
            'eu-west-2',
            'eu-west-3',
            'sa-east-1',
            'us-east-1',
            'us-east-2',
            'us-west-1',
            'us-west-2')]
        [string]
        $region,

        [Parameter(ParameterSetName = 'VPN',
            Position = 0,
            Mandatory,
            HelpMessage = 'Please put in your public IP',
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]
        $publicIP,

        [Parameter(ParameterSetName = 'VPN',
            Position = 1,
            Mandatory,
            HelpMessage = 'Please enter if you would like your VPN connection to be a static or dynamic value')]
        [string]
        [ValidateSet('Static', 'Dynamic')]
        $Type
    )
    begin {
        Write-Output 'AWS credentials being used are:'
        $AWSCreds | Out-String

        $IP = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($publicIP) -and $publicIP -match $IP) {
                foreach ($publicIP in $publicIP) {
                    #Default params for all new objects
                    $defaultParams = @{'ProfileName' = $AWSCreds; 'Region' = $region}

                    #1) new EC2 Customer Gateway
                    $newEC2CustomerGatewayPARAMS = @{
                        'PublicIP' = $publicIP
                        'Type'     = 'ipsec.1'
                    }
                    $param1 = $newEC2CustomerGatewayPARAMS + $defaultParams
                    $NewEC2CustomerGateway = New-EC2CustomerGateway @param1

                    #2) New EC2 VPN Gateway
                    $newEC2VpnGatewayPARAMS = @{
                        'Type' = 'ipsec.1'
                    }
                    $param2 = $newEC2VpnGatewayPARAMS + $defaultParams
                    $newEC2VpnGateway = New-EC2VpnGateway @param2

                    #Custom object for all
                    $newEC2VpnGatewayOBJECT = [pscustomobject] @{
                        'VPNGatewayState'      = $newEC2VpnGateway.State
                        'VPNGatewayID'         = $newEC2VpnGateway.VpnGatewayId
                        'CustomerGatewayId'    = $NewEC2CustomerGateway.CustomerGatewayId
                        'CustomerGatewayState' = $NewEC2CustomerGateway.State
                    }

                    $newEC2VpnGatewayOBJECT

                    $addVPN = Read-Host 'Would you like to add your VPN gateway to a VPC? Choose 1 for yes or 2 for no'
                    switch ($addVPN) {
                        '1' {
                            Add-EC2VpnGateway -VpnGatewayId $newEC2VpnGateway.VpnGatewayId -VpcId (Read-Host 'Please enter a VPC ID') -Region $region -ProfileName $AWSCreds
                        }
                        '2' {
                            Write-Output 'No VPC will be added. Continue'
                            Pause
                        }

                        Default {
                            $null
                        }
                    }

                    #3) New EC2 VPN Connection
                    $newec2VpnConnectionPARAMS = @{
                        'Type'              = 'ipsec.1'
                        'CustomerGatewayId' = $NewEC2CustomerGateway.CustomerGatewayId
                        'VpnGatewayId'      = $newEC2VpnGateway.VpnGatewayId

                    }
                    $param3 = $newec2VpnConnectionPARAMS + $defaultParams
                    New-EC2VpnConnection @param3
                }
            }
        }

        catch {
            Write-Warning 'An error has occured. Please review the output below'
            $PSCmdlet.ThrowTerminatingError($_)
        }

    }#Process
    end {}
}#Function
