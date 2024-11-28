
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
