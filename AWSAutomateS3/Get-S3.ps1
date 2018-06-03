Function Upload-AWSVideo {
    Param (
        [psobject]$AWSCredential = ((Get-AWSCredential -ListProfileDetail)[0] | Select -ExpandProperty ProfileName),

        [switch]$Expand = (Select -ExpandProperty CreationDate, BucketName)
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
            Foreach ($S3Bucket in $getS3Bucket) {
                $getS3BucketOBJECT = [pscustomobject]::AsPSObject( @{'Name' = $S3Bucket.BucketName; 'Created' = $S3Bucket.CreationDate; } )
                $getS3BucketOBJECT
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