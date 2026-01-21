function retrieveEmail (
    [Parameter(Mandatory = $true)]
    [string] $u,

    [Parameter(Mandatory = $true)]
    [string] $outputPath
) {

    $soql_query = "Select DeveloperName from Folder where DeveloperName != null and (Type = 'Email' OR Type = 'EmailTemplate')"

    $output = sf data query --query $soql_query -o $u --json | ConvertFrom-Json

    if (-not $output.result.records) {
        Write-Host "No email folders found."
        return
    }

    $pxml  = "<?xml version='1.0' encoding='UTF-8'?>"
    $pxml += "<Package xmlns='http://soap.sforce.com/2006/04/metadata'>"
    $pxml += "<types>"

    foreach ($result in $output.result.records) {
        $value = $result.DeveloperName

        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        $metadata = sfdx force:mdapi:listmetadata `
            -m EmailTemplate `
            --folder $value `
            -u $u `
            --json | ConvertFrom-Json

        if (-not $metadata.result) {
            continue
        }

        foreach ($d in $metadata.result) {
            $metaValue = $d.fullName

            if ([string]::IsNullOrWhiteSpace($metaValue)) {
                continue
            }

            Write-Host $metaValue
            $pxml += "<members>$metaValue</members>"
        }
    }

    $pxml += "<name>EmailTemplate</name>"
    $pxml += "</types>"
    $pxml += "<version>53.0</version>"
    $pxml += "</Package>"

    Set-Content -Path $outputPath -Value $pxml -Encoding UTF8
}
