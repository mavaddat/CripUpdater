#Requires -RunAsAdministrator
#Requires -Version 6.0
#Requires -PSEdition Core
if (-not (Test-Path -Path "$env:TEMP\certs" -PathType Container)) {
    New-Item -Path "$env:TEMP\certs" -ItemType Directory | Out-Null  # Create certs directory for storing the certs
}
$cripLocation = "$env:LOCALAPPDATA\Programs\certificate-ripper\crip.exe"
# Allow passing the CRIP install directory as an argument
if($args.Count -gt 0 -and (Test-Path -Path $args[0]) -and (Get-ChildItem -Path $args[0] -Include 'crip.exe' -Recurse | Measure-Object).Count -gt 0) {
    $cripLocation = Get-ChildItem -Path $args[0] -Include 'crip.exe' -Recurse | Select-Object -ExpandProperty FullName -First 1
} elseif( -not (Test-Path -Path $cripLocation -PathType Leaf)) {
    Write-Warning -Message "Could not find CRIP executable at '$cripLocation'"
    exit 1
}
Write-Verbose -Message "Using CRIP executable at '$cripLocation'" -Verbose
&"$cripLocation" export der --destination="$env:TEMP\certs\" --resolve-ca --url="https://repo.maven.apache.org/maven2"  # Attempt to download certs for apache maven
$certs = Get-ChildItem -Path "$env:TEMP\certs\"

# Install the certs into all java keystores
$javas = Get-Command -Name java -All -CommandType Application

for ($i = 0; $i -lt $javas.Count; $i++) {
    $binDir = $javas[$i].Source | Split-Path -Parent
    $keyToolPath = Join-Path -Path $binDir -ChildPath 'keytool.exe'
    if (Test-Path -Path $keyToolPath -PathType Leaf) {
        Write-Progress -Activity "Installing certs for java at '$binDir'" -PercentComplete ($i / $javas.Count * 100) -Id 0
        for ($j = 0; $j -lt $certs.Count; $j++) {
            Write-Progress -Activity 'Installing certs' -Status "Installing cert $j of $($certs.Count)" -PercentComplete ($j / $certs.Count * 100) -Id 1 -ParentId 0
            $cert = $certs[$j].FullName
            $hash = Get-FileHash -Path $cert -Algorithm MD5 | Select-Object -ExpandProperty Hash
            Write-Verbose -Message "Installing cert '$cert' into '$binDir' with hash '$hash'" -Verbose

            # Remove cert if it already exists
            &$keyToolPath *>&1 -delete -alias "$hash" -cacerts -storepass changeit -noprompt | Out-String -Stream | Where-Object { $_ -notmatch 'Alias <.*?> does not exist' } | Write-Verbose -Verbose  # Suppress error if cert does not exist

            # Install cert
            $msgs = &$keyToolPath *>&1 -cacerts -storepass changeit -importcert -file "$cert" -alias "$hash" -noprompt | Out-String
            if ($LASTEXITCODE -eq 0) {
                foreach ($msg in $msgs) {
                    Write-Verbose -Message $msg -Verbose
                }
            }
            else {
                foreach ($msg in $msgs) {
                    Write-Warning -Message $msg
                }
            }
        }
    } else {
        Write-Warning -Message "Could not find keytool.exe at '$binDir'"
    }
}
