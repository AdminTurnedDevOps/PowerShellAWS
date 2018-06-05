Function Get-S3 {
    [cmdletbinding()]
    Param (
        [psobject]$AWSCredential = ((Get-AWSCredential -ListProfileDetail)[0] | Select -ExpandProperty ProfileName),

        [switch]$Expand = (Select -ExpandProperty *)
    )
    begin {
        Write-Output "Starting: $($MyInvocation.MyCommand.Name)"
        $aws = Import-Module AWSPowerShell
        if ($aws -like $null) {
            Import-Module AWSPowerShell
        }
    }

    process {
        try {
            [console]::WriteLine('Below are your existing buckets')
            $getS3Bucket = Get-S3Bucket -ProfileName $AWSCredential
            $getS3ACL = Get-S3ACL -ProfileName $AWSCredential
            Foreach ($S3Bucket in $getS3Bucket) {
                $getS3BucketOBJECT = [pscustomobject]::AsPSObject( @{'Name' = $S3Bucket.BucketName; 'Created' = $S3Bucket.CreationDate; } )
                $getS3BucketOBJECT
                $getS3BucketOBJECT | Add-Member -type NoteProperty -name 'GetACL' -value {Get-S3ACL -BucketName $getS3Bucket -ProfileName $awscredential}
            }

            if ($getS3BucketOBJECT -like $null) {
                Write-Warning 'No S3 buckets exists. '
            }
        }

        catch {
            if ($AWSCredential -like $null) {
                Write-Warning 'No AWS credentials were found for this session'
            }                
            #Throw error to screen
            $_
            Throw
        }            
    }
    end {
    }    
}#Function

####################################################################################################################################################################################################################

Function UploadTo-S3Bucket {
    [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'medium')]
    Param (
        [Parameter()]
        [psobject]$AWSCredential = ((Get-AWSCredential -ListProfileDetail)[0] | Select -ExpandProperty ProfileName),

        [Parameter(ParameterSetName = 'NewBucket',
            HelpMessage = 'Please do not use capitals on your S3 bucket name. The cmdlet will fail')]
        [string]$newS3Bucket,

        [Parameter(ParameterSetName = 'NewBucket')]
        [string]$Region = 'us-east-2',

        [Parameter(ParameterSetName='NoNewBucket',
            HelpMessage = 'Please enter the bucket name to save the new S3 object')]
        [string]$bucketName,

        [Parameter(ParameterSetName = 'NoNewBucket',
            HelpMessage = 'Please enter a file name in your S3 bucket')]
        [string]$fileName,

        [switch]$bucketEncryption = (Set-S3BucketEncryption -BucketName $newS3Bucket)
    )
    begin {}

    process {
        try {
            if ($pscmdlet.ShouldProcess($newS3Bucket)) {
                $newBucketPARAMS = @{'BucketName' = $newS3Bucket; 'Region' = $Region; 'ProfileName' = $AWSCredential; 'PublicReadOnly' = $true}
                $newBucket = New-S3Bucket @newBucketPARAMS

                $testBucket = Test-S3Bucket -BucketName $newS3Bucket -ProfileName $AWSCredential
                Write-Output 'Testing S3 bucket'
                Start-Sleep 5
                if ($testBucket -like 'true') {
                    Write-Output 'Test complete'
                }

                else {
                    Write-Warning 'Bucket test: FAIL. Please review configuration'
                }

                if (-not($testBucket)) {
                    $tryAgain = Read-Host "Bucket creation not successful. Would you like to try again? 1 for yes 2 for no"
                    switch ($tryAgain) {
                        '1' {
                            $newS3BucketPARAMS = @{
                                'BucketName'=$newS3Bucket
                                'Region'=$Region
                                'ProfileName'=(Read-Host "Please enter profile name")
                                'PublicReadOnly'=$true
                            }
                            New-S3Bucket @newS3BucketPARAMS
                        }

                        '2' {
                            Write-Output 'Moving on...'
                            Pause
                            Break
                        }

                    }#Switch
                }#secondif       
            }#ifPSCMDLET

            elseif (-not($newS3Bucket)) {
                Write-Output 'No new bucket being created. Moving on...'
                Pause
            }
            
            $WritetoS3PARAMS = @{'BucketName'=$bucketName; 'ProfileName'=$AWSCredential; 'Key'=((Get-Childitem $fileName | Where {$_.LastWriteTime} | Sort-Object -Descending))[0]; 'PublicReadOnly'=$true}
            Write-S3Object @WritetoS3PARAMS


        }#Try

        catch {
            [console]::WriteLine('Testing connection to specified region')
            $testConnectionAWS = Test-Connection "$Region.console.aws.amazon.com"

            if($testConnectionAWS) {
                [console]::WriteLine('Connection to region: Successful')
            }

            else {
                Write-Warning 'Connection to region: UNSUCCESSFUL'
            }
            [console]::WriteLine("Current AWS Profiles available: $(Get-AWSCredential -ListProfileDetail | Select @{Name='Profile' ;expression={$_.ProfileName}} -ExpandProperty ProfileName)")
            Write-Output "Your current profile being used is $AWSCredential. Would you like to try another to create the S3 bucket?"

        }#Catch
    }#Process
    end {}
}
