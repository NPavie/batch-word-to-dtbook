
# get current script file directory

# in file daisy-pipeline/etc/pipeline.properties, replace line #org.daisy.pipeline.ws.localfs=false by org.daisy.pipeline.ws.localfs=true

$propertiesFile = "$PSScriptRoot\daisy-pipeline\etc\pipeline.properties"
(Get-Content $propertiesFile) -replace '#org.daisy.pipeline.ws.localfs=false', 'org.daisy.pipeline.ws.localfs=true' | Set-Content $propertiesFile

# Start the pipeline server
& $PSScriptRoot\daisy-pipeline\cli\dp2.exe version

$files = Get-ChildItem -Path .\in\ -Filter *.docx
foreach ($file in $files) {
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($file)
    # if folder .\out\$filename does not exists
    if (-not (Test-Path .\out\$filename)) {
        # Here is an exemple of chain that convert word to dtbook and clean it up
        
        # Pass 1 : convert the word file to dtbook
        $tempFolder = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $filename + "_result_1")
        if (Test-Path $tempFolder) {
            Remove-Item $tempFolder -Recurse -Force
        }
        Write-Host "Converting $filename to dtbook in $tempFolder"
        & $PSScriptRoot\daisy-pipeline\cli\dp2.exe word-to-dtbook --source $file --output $tempFolder --extract-shapes true
        # search recusrively for the resulting xml file in previous result folder
        $xmlFiles = Get-ChildItem -Path $tempFolder -Filter *.xml -Recurse
        if ( $xmlFiles.Length -eq 0) {
            Write-Error "Error during word-to-dtbook process of $filename : no xml file found in $tempFolder"
            continue
        }

        # Pass 2 : cleaning up the resulting dtbook
        $tempFolder = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $filename + "_result_2")
        if (Test-Path $tempFolder) {
            Remove-Item $tempFolder -Recurse -Force
        }
        # Cleanup the dtbook
        Write-Host "Cleaning ", $xmlFiles[0], " dtbook into $tempFolder"
        & $PSScriptRoot\daisy-pipeline\cli\dp2.exe dtbook-cleaner --source $xmlFiles[0] --output $tempFolder --repair true
        $xmlFiles = Get-ChildItem -Path $tempFolder -Filter *.xml -Recurse
        # if process result2 succeeded
        if ( $xmlFiles.Length -eq 0) {
            Write-Error "Error during dtbook-cleanup process of $filename : no xml file found in $tempFolder"
            continue
        }
        ## You can add subsequent conversions here

        ## Finalisation : move last temporary folder to out folder
        Write-Host "Moving $tempFolder to $PSScriptRoot\out\$filename"
        # move the result folder to .\out\$filename
        Move-Item $tempFolder $PSScriptRoot\out\$filename
    } else {
        Write-Host "Result folder $PSScriptRoot\out\$filename already exists, delete it to relaunch its conversion"
    }
    
}

# Stop the pipeline
Write-Host "Stopping the pipeline server"
& $PSScriptRoot\daisy-pipeline\cli\dp2.exe halt

# SIG # Begin signature block
# MIIGgQYJKoZIhvcNAQcCoIIGcjCCBm4CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDa6g+0xL9GN4NO
# 99fJexr0z2sPqfSkhuwXVfSeYiqusqCCA6wwggOoMIICkKADAgECAhB28XvAZAdL
# p0/abYbffqF5MA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAkZSMSMwIQYDVQQK
# DBpBc3NvY2lhdGlvbiBWYWxlbnRpbiBIYcO8eTExMC8GA1UEAwwoUMO0bGUgQWRh
# cGF0aW9uIGRlcyBPdXZyYWdlcyBOdW3DqXJpcXVlczAeFw0yNDA3MTgxNDA4NDha
# Fw0yNTA3MTgxNDI4NDhaMGUxCzAJBgNVBAYTAkZSMSMwIQYDVQQKDBpBc3NvY2lh
# dGlvbiBWYWxlbnRpbiBIYcO8eTExMC8GA1UEAwwoUMO0bGUgQWRhcGF0aW9uIGRl
# cyBPdXZyYWdlcyBOdW3DqXJpcXVlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBALBwAFsX3DXDmtwqrGnUA2pA0IeyNRgRdkVvJPHf4wpHVWgUmGyZz0yZ
# hFf+1Wi7zVjhBViQDIDm0hnbFcRhP1qmFAqSBGU6BRKKO0KkaeTC8hYWYM48mXNo
# +ax+tO6deWS6uJ+J7mbWuXMfLwpmWCUhDKpSn0XjWzxfxNAJMJ9AK5Vp4XOw8D7p
# i5pr47Ci9TkadrG+l+mDQcBW3MbOGRJBDmD2jsZCxTWzkdNJXIyKXenoL6SUuBN9
# Cere6kKSvGsmanjFrRVymzlw1Bq9aYQlIz2NZpCz48RNw+/v6rzQDsqh1ZgdHemi
# BYoE2aLHWyUk7q8Oupv/GjpTgz+BgG0CAwEAAaNUMFIwDgYDVR0PAQH/BAQDAgeA
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFN/w
# lO1s0nCgV/7NSYK9TxSsUbjSMA0GCSqGSIb3DQEBCwUAA4IBAQAaBkwdik4wDgo9
# 7GcfNVmsuxzRFLzyOI0YZmeyd4COnhORmnT0mhmCeerpAgEJiMxJsTtB2qK9QhAN
# BDY68VzoRFpqS0NCD4b6K27CPsL9VLfaoygfF3vMmAa5Yol8HUfcw/LtPny7OCB3
# b/tmNYeQPNuUs/mSTmWhUsq3rYWSVIzITZ+L0NwFdd0jNMm1dK7csFInU3IkSMme
# gC3VxE2+0tDvUo13YVZbQ0TQeYr5fMWQXu6qGzq+VWdU85jovZrKnL/LNKumaYhI
# VlrVnogUxZXCHvcSDhKYRphaFBCKkPtlEuL8uptuWxEx7t6IMFH+OwTiDE8W2gQG
# KYDAl2CbMYICKzCCAicCAQEweTBlMQswCQYDVQQGEwJGUjEjMCEGA1UECgwaQXNz
# b2NpYXRpb24gVmFsZW50aW4gSGHDvHkxMTAvBgNVBAMMKFDDtGxlIEFkYXBhdGlv
# biBkZXMgT3V2cmFnZXMgTnVtw6lyaXF1ZXMCEHbxe8BkB0unT9ptht9+oXkwDQYJ
# YIZIAWUDBAIBBQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIB
# FTAvBgkqhkiG9w0BCQQxIgQgpT7ryPSgE9JoVFGxHxP7gRnOBcfYQJ23xqO0eY3b
# RqwwDQYJKoZIhvcNAQEBBQAEggEAehU+Gp9nW5kqAG1P97T/OAyd8K3R7+PuYkhQ
# greZfU8Wti/xbCcpBkTemOCUHB47H4vqSlQLH8Sx9+tViIgPQi116S5GQq/NdMlw
# IT6YSeyWz81kitkI+JVSpvrhWZVgF9TX+9QkJQIi2ytnH20TxO5dTvgbIlC381Eq
# ECh3KyABmteV2EZwbUS0BEITiQz1B/vdW4ySxnuEalldlWjqaoebA/UtRuExJ05e
# FmF6CGg2QcCGQtAHyaxsQV0/L+LTezEIHyek1Bm9JYZCPNxQRES4OTFCcpJ59xmS
# 8xyr0v7C8lbqzNd1fL5pvc/3tehPIrFmAvHWYXVhM/NtN31ZpQ==
# SIG # End signature block
