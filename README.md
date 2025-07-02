# Crip Updater

A small utility program to automatically update [Hakky54/certificate-ripper](https://github.com/Hakky54/certificate-ripper).

Build and add the scheduled task like this:

```pwsh
Set-Location -Path $env:USERPROFILE\source\repos\CripUpdater  # Or, wherever you cloned the repo
dotnet publish --configuration Release -r win-x64
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