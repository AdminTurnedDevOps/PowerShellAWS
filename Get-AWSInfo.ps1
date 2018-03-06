Function Get-AWSInfo {
    [cmdletbinding(DefaultParameterSetName = "AWS", SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    param(
        [parameter(Position = 0, 
            Mandatory = $true,
            HelpMessage = 'Please use your profile name with your specific saved access key',
            ParameterSetName = "AWS")]
        [ValidateNotNullOrEmpty()]
        [string]$ProfileName,

        [parameter(Mandatory = $true,
            HelpMessage = 'Please type in your region',
            ParameterSetName = "AWS")]
        [ValidateNotNullOrEmpty()]
        [string]$Region,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AWSErrorLog

    )

    Begin {Write-Verbose 'Starting the collection of AWS Detauls'}
    Process {
        Try {
            $AWSParams = @{
                'ProfileName' = $ProfileName
                'Region'      = $Region
            }

            Write-Verbose 'Defining variables with specific parameters'
            $EC2Instance = Get-EC2Instance @AWSParams
            $EC2Address = Get-EC2Address @AWSParams
            $EC2AvailabilityZone = Get-EC2AvailabilityZone @AWSParams
            $EC2InstanceStatus = Get-EC2InstanceStatus @AWSParams

            Write-Verbose 'Collecting specified members and pushing them to a ps object'
            $AWSObject = [pscustomobject] @{
                'InstanceName'     = $EC2Instance.Instances
                'InstanceOwnerID'  = $EC2Instance.OwnerId
                'NetInterfaceID'   = $EC2Address.NetworkInterfaceId
                'PrivateIP'        = $EC2Address.PrivateIpAddress
                'PublicIP'         = $EC2Address.PublicIp
                'Tags'             = $EC2Address.Tags
                'AvailabilityZone' = $EC2InstanceStatus.AvailabilityZone
                'ZoneState'        = $EC2AvailabilityZone.State
                'ZoneName'         = $EC2AvailabilityZone.ZoneName
            }
            #Some like to view this as a table. If that's what you'd like, you can pipe $AWSObect to Format-Table
            $AWSObject
        }#TRY
        CATCH {
            Write-Warning 'An error has occured. Please review the full error at the log you specified'
            $_ | Out-File $AWSErrorLog
            #Display the error to the screen
            Throw
        }
    }#Process
    End{}
}#Function
Get-AWSInfo