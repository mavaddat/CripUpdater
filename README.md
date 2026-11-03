# Hakky54 Certificate Ripper Updater

[![.NET](https://github.com/mavaddat/CripUpdater/actions/workflows/dotnet.yml/badge.svg)](https://github.com/mavaddat/CripUpdater/actions/workflows/dotnet.yml)

A small utility program to automatically update [Hakky54/certificate-ripper](https://github.com/Hakky54/certificate-ripper).

Demo: 

https://github.com/user-attachments/assets/1675527a-a6fa-4e3a-9cb0-aef0aba3042d

## Using with Windows Scheduled Tasks

This program pairs well with two [scheduled tasks in Windows](https://en.wikipedia.org/wiki/Windows_Task_Scheduler):

1. A task to periodically run this updater to keep CRIP current
2. A task to periodically run CRIP to update the Java certificate store

You can either [download the latest release](https://github.com/mavaddat/CripUpdater/releases/latest) or build the project like this:

```pwsh
Set-Location -Path "$env:USERPROFILE\source\repos" # Or, wherever you want to clone the repo
git clone "https://github.com/mavaddat/CripUpdater.git"
Set-Location -Path "./CripUpdater"
dotnet publish --configuration Release -r win-x64
```

Then, in an [elevated PowerShell](https://www.ninjaone.com/blog/open-an-elevated-powershell-prompt/) session, create the scheduled task to update CRIP like this:

```pwsh
Set-Location -Path "$env:USERPROFILE\source\repos\CripUpdater"  # Or, wherever you cloned or downloaded the release

# Register a scheduled task to run the CRIP updater once a month
Register-ScheduledTask -Xml @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$((Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffffff"))</Date>
    <Author>$env:USERDOMAIN/$env:USERNAME</Author>
    <URI>\Update Certificate Ripper</URI>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <UserId>$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)</UserId>
      <LogonType>InteractiveToken</LogonType>
    </Principal>
  </Principals>
  <Settings>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <Hidden>true</Hidden>
    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
  </Settings>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>$((Get-Date).ToString("yyyy-MM-ddTHH:mm:ss"))</StartBoundary>
      <ScheduleByMonthDayOfWeek>
        <Months>
          <January />
          <February />
          <March />
          <April />
          <May />
          <June />
          <July />
          <August />
          <September />
          <October />
          <November />
          <December />
        </Months>
        <Weeks>
          <Week>Last</Week>
        </Weeks>
        <DaysOfWeek>
          <Friday />
        </DaysOfWeek>
      </ScheduleByMonthDayOfWeek>
    </CalendarTrigger>
  </Triggers>
  <Actions Context="Author">
    <Exec>
      <Command>$(Get-ChildItem -Path . -Include CripUpdater.exe -Recurse | Where-Object { $_.Directory -match 'publish' } | Select-Object -First 1 -ExpandProperty FullName)</Command>
    </Exec>
  </Actions>
</Task>
"@
```

Again in an elevated PowerShell session, create the task to update the certificate store like this:

```pwsh
Set-Location -Path "$env:USERPROFILE\source\repos\CripUpdater"  # Or, wherever you cloned or downloaded the release

# Register a scheduled task to update the certificates once a week
Register-ScheduledTask -Xml @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$((Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffffff"))</Date>
    <Author>$env:USERDOMAIN\$env:USERNAME</Author>
    <URI>\Update Java Certificates</URI>
  </RegistrationInfo>
  <Principals>
    <Principal id="Author">
      <UserId>$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <Hidden>true</Hidden>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
  </Settings>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>$((Get-Date).ToString("yyyy-MM-ddTHH:mm:ss"))</StartBoundary>
      <ScheduleByMonthDayOfWeek>
        <Months>
          <January /><February /><March /><April /><May /><June />
          <July /><August /><September /><October /><November /><December />
        </Months>
        <Weeks>
          <Week>1</Week>
        </Weeks>
        <DaysOfWeek>
          <Monday />
        </DaysOfWeek>
      </ScheduleByMonthDayOfWeek>
    </CalendarTrigger>
  </Triggers>
  <Actions Context="Author">
    <Exec>
      <Command>pwsh.exe</Command>
      <Arguments>-NoLogo -NoProfile -ExecutionPolicy Bypass -File "$(Get-ChildItem -Path . -Include getCerts.ps1 -Recurse | Select-Object -First 1 -ExpandProperty FullName)"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
```

## Manually Utilizing with Keystore

Alternatively, the certificate ripper program can be utilized on an ad-hoc, as-needed basis. The technique to update Java's Maven certificates (for every version of Java available to the system) is shown in [this Gist](https://gist.github.com/mavaddat/9cc2ecfe97dd03fcd7ccd9415c05da53):

```pwsh
# 1. Execute certificate-ripper (crip.exe) to fetch Maven Central's TLS/SSL certificates.
# It resolves the Certificate Authority chain (--resolve-ca) and exports them in DER format into the TEMP folder.
&"$env:LOCALAPPDATA\Programs\certificate-ripper\crip.exe" export der --destination="$env:TEMP\certs\" --resolve-ca --url="https://repo.maven.apache.org/maven2"

# 2. Gather all the downloaded certificate files from the temporary destination folder.
$certs = Get-ChildItem -Path "$env:TEMP\certs\"

# 3. Locate all instances of 'java.exe' installed on the machine across your environment PATH variable.
Get-Command -Name java -All | ForEach-Object { 
    
    # 4. Extract the parent directory path containing the current java execution binary (the 'bin' folder).
    $binDir = $_.Source | Split-Path -Parent
    
    # 5. Build the explicit absolute path to 'keytool.exe' inside that specific Java binary directory.
    $keyToolPath = Join-Path -Path $binDir -ChildPath 'keytool.exe'
    
    # 6. Verify that keytool.exe actually exists as a file in this location before proceeding.
    if (Test-Path -Path $keyToolPath -PathType Leaf) {
        
        # 7. Iterate through each certificate found in the temporary folder.
        foreach ($cert in $certs) {
            
            # 8. Generate a unique MD5 hash of the certificate file to safely use as a distinct alias key in the keystore.
            $hash = Get-FileHash -Path $cert -Algorithm MD5 | Select-Object -ExpandProperty Hash
            
            # 9. Output an informative status message to the console logging the upcoming installation steps.
            Write-Verbose -Message "Installing cert '$cert' into '$binDir' with hash '$hash'" -Verbose
            
            # 10. Proactively attempt to delete any existing certificate matching that specific hash alias to prevent conflicts.
            # Uses the standard Java keystore default password ('changeit') and suppresses interaction prompts.
            &$keyToolPath -delete -alias "$hash" -cacerts -storepass changeit -noprompt
            
            # 11. Run keytool to import the new certificate into the Java 'cacerts' trust store under the unique hash alias.
            # Triggers standard error redirection (*>&1) to capture both execution logs and structural errors in the $msg variable.
            $msg = &$keyToolPath *>&1 -cacerts -storepass changeit -importcert -file "$cert" -alias "$hash" -noprompt
            
            # 12. Evaluate if the keytool command completed successfully (Exit Code 0).
            if($LASTEXITCODE -eq 0){
                # Log the successful tool output directly to the verbose console.
                Write-Verbose -Message $msg -Verbose
            } else {
                # Halt or log a high-priority script execution failure if the keystore write function fails.
                Write-Error -Message $msg -Verbose
            }
        }
    } 
}
```
