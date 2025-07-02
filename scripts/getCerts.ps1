&"$env:LOCALAPPDATA\Programs\certificate-ripper\crip.exe" export der --destination="$env:TEMP\certs\" --resolve-ca --url="https://repo.maven.apache.org/maven2"
$certs = Get-ChildItem -Path "$env:TEMP\certs\"
Get-Command -Name java -All | ForEach-Object { 
    $binDir = $_.Source | Split-Path -Parent
    $keyToolPath = Join-Path -Path $binDir -ChildPath 'keytool.exe'
    if (Test-Path -Path $keyToolPath -PathType Leaf) {
        foreach ($cert in $certs) {
            $hash = Get-FileHash -Path $cert -Algorithm MD5 | Select-Object -ExpandProperty Hash
            Write-Verbose -Message "Installing cert '$cert' into '$binDir' with hash '$hash'" -Verbose
            &$keyToolPath -delete -alias "$hash" -cacerts -storepass changeit -noprompt
            $msg = &$keyToolPath *>&1 -cacerts -storepass changeit -importcert -file "$cert" -alias "$hash" -noprompt
            if($LASTEXITCODE -eq 0){
                Write-Verbose -Message $msg -Verbose
            } else {
                Write-Error -Message $msg -Verbose
            }
        }
    } 
}
