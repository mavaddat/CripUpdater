# Hakky54 Certificate Ripper Updater

[![.NET](https://github.com/mavaddat/CripUpdater/actions/workflows/dotnet.yml/badge.svg)](https://github.com/mavaddat/CripUpdater/actions/workflows/dotnet.yml)

A small utility program to automatically update [Hakky54/certificate-ripper](https://github.com/Hakky54/certificate-ripper).

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