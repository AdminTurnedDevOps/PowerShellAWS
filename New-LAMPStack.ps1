Function New-LAMPStack {

    [cmdletbinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    Param (
        [Parameter(ParameterSetName = 'STACK')]
        [string]
        $AWSCredential = (Get-AWSCredential -ListProfileDetail | Select-Object -ExpandProperty ProfileName),
    
        [Parameter(ParameterSetName = 'STACK',
            Mandatory)]
        [string]
        $StackName,
    
        [Parameter(ParameterSetName = 'STACK')]
        [switch]
        $DisableRollback = $false,
    
        [Parameter(ParameterSetName = 'STACK')]
        [switch]
        $EnableTerminalProtection = $false,
    
        [Parameter(ParameterSetName = 'STACK')]
        [switch]
        $ARNnotification = $true,
    
        [Parameter(ParameterSetName = 'STACK',
            Mandatory)]
        [ValidateSet('ROLLBACK', 'DELETE')]
        [string]
        $StackFailure,
    
        [Parameter(ParameterSetName = 'STACK')]
        [psobject]
        $STACKConfigs,
    
        [Parameter(ParameterSetName = 'STACK')]
        [string]
        $stackPolicyURL,
    
        [Parameter(ParameterSetName = 'STACK')]
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
        $region
    
    )
    begin {
        $dbpass = Read-Host "Please enter your DB password"
    
        $dbrootpass = Read-Host "Please enter DB Root Password"
        
        $STACK = @( @{ ParameterKey = "KeyName"; ParameterValue = (Read-Host "Please enter your IAM key name") },
            @{ ParameterKey = "DBUser"; ParameterValue = (Read-Host "Please enter a DB username") },
            @{ ParameterKey = "DBPassword"; ParameterValue = $dbpass},
            @{ ParameterKey = "DBRootPassword"; ParameterValue = $dbrootpass })
        $STACK += $STACKConfigs = @{
    
        }
    }
    
    process {
        try {
            if ($pscmdlet.ShouldProcess($StackName)) {
                if ($stackPolicyURL -notlike $null) {
                    $testURL = Invoke-WebRequest "s3.amazonaws.com"
                    if ($testURL.StatusDescription -like 'OK') {
                        $newCFNStackPARAMS = @{
                            'ProfileName' = $AWSCredential
                            'StackName'   = $StackName
                            'Region'      = $region
                            'TemplateURL' = $stackPolicyURL
                            'Parameter'   = $STACK
                        }
                        New-CFNStack @newCFNStackPARAMS
                        Write-Output "Above is your ARN (unique identifier) to your LAMP stack"
                    }
    
                    else {
                        Write-Warning 'Connection to S3 bucket: Unsuccessful`n Please check that the S3 bucket is valid and you have proper permissions'
                    }
                }
            }#pscmdletIF
        }
        catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }
    end {}
}
