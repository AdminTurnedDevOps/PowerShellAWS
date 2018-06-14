Function New-AWSKeyPair {

    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param (
        [Parameter(ParameterSetName = 'NewKey',
            HelpMessage = 'Please enter a profile saved locally. By default, this chooses the first')]
        [ValidateNotNullOrEmpty()]
        [string]
        $AWSprofileName = ((Get-AWSCredential -ListProfileDetail)[0] | Select-Object -ExpandProperty ProfileName),

        [Parameter(Position = 0,
            ParameterSetName = 'NewKey',
            Mandatory,
            ValueFromPipeline,
            HelpMessage = 'Please enter a new name for your key')]
        [string]
        $keyName,

        [Parameter(ParameterSetName = 'NewKey')]
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

        [Parameter(Mandatory,
            ParameterSetName = 'NewKey',
            HelpMessage = 'Please store your RSA private key in a secure location. Default is your desktop')]
        [string]
        $RSAPrivateKeyLocation = "C:\users\$env:username\Desktop"
    )
    begin {
        $testPath = Test-Path $RSAPrivateKeyLocation
    
        if (-not($testPath)) {
            Write-Warning 'Path for RSA private key was unreachable. Please try again'
            Break
        }

        else {
            Write-Output "Test to $RSAPrivateKeyLocation : Successful"
        }
    
    }
    process {
        try {
            if ($PSCmdlet.ShouldProcess(($keyName))) {
                $PARAMS = @{'KeyName' = $keyName; 'Region' = $region; 'ProfileName' = $AWSprofileName}
                New-EC2KeyPair @PARAMS | fl | Out-File "$RSAPrivateKeyLocation\RSAKEY.txt"
            }           
        }

        catch {
            $_
            Throw
        }
    }
    end {}
}#Function
