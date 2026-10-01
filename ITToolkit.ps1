# ITToolkit.ps1
# Windows IT Support Toolkit
# Current portfolio state: Phase 1 complete, Phase 2 refactor in progress.

$ReportDirectory = Join-Path $PSScriptRoot "Reports"

if (-not (Test-Path $ReportDirectory)) {
    New-Item -Path $ReportDirectory -ItemType Directory | Out-Null
}

function Pause-Toolkit {
    Write-Host ""
    Read-Host "Press ENTER to continue"
}

function Get-SystemInformation {
    $os = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem

    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        UserName     = $env:USERNAME
        Manufacturer = $computer.Manufacturer
        Model        = $computer.Model
        Windows      = $os.Caption
        Version      = $os.Version
        LastBootTime = $os.LastBootUpTime
    }
}

function Get-NetworkInformation {
    $adapter = Get-NetIPConfiguration |
        Where-Object { $_.IPv4DefaultGateway -ne $null } |
        Select-Object -First 1

    if (-not $adapter) {
        return [PSCustomObject]@{
            Interface = "No active routed adapter found"
            IPv4      = "N/A"
            IPv6      = "N/A"
            Gateway   = "N/A"
            DNS       = "N/A"
        }
    }

    $dns = (Get-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue).ServerAddresses

    [PSCustomObject]@{
        Interface = $adapter.InterfaceAlias
        IPv4      = ($adapter.IPv4Address.IPAddress -join ", ")
        IPv6      = ($adapter.IPv6Address.IPAddress -join ", ")
        Gateway   = $adapter.IPv4DefaultGateway.NextHop
        DNS       = ($dns -join ", ")
    }
}

function Test-NetworkDiagnostics {
    $adapter = Get-NetIPConfiguration |
        Where-Object { $_.IPv4DefaultGateway -ne $null } |
        Select-Object -First 1

    $gateway = if ($adapter) { $adapter.IPv4DefaultGateway.NextHop } else { $null }

    $gatewayTest = if ($gateway) {
        Test-Connection -ComputerName $gateway -Count 1 -Quiet -ErrorAction SilentlyContinue
    }
    else {
        $false
    }

    $internetTest = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue

    try {
        Resolve-DnsName "microsoft.com" -ErrorAction Stop | Out-Null
        $dnsTest = $true
    }
    catch {
        $dnsTest = $false
    }

    [PSCustomObject]@{
        DefaultGateway = if ($gatewayTest) { "PASS" } else { "FAIL" }
        Internet       = if ($internetTest) { "PASS" } else { "FAIL" }
        DNS            = if ($dnsTest) { "PASS" } else { "FAIL" }
    }
}

function Get-StorageHealth {
    $drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

    if (-not $drive) {
        return [PSCustomObject]@{
            Drive       = "C:"
            SizeGB      = "N/A"
            FreeGB      = "N/A"
            FreePercent = "N/A"
            Status      = "UNKNOWN"
        }
    }

    $sizeGB = [math]::Round($drive.Size / 1GB, 2)
    $freeGB = [math]::Round($drive.FreeSpace / 1GB, 2)
    $freePercent = if ($drive.Size -gt 0) {
        [math]::Round(($drive.FreeSpace / $drive.Size) * 100, 2)
    }
    else {
        0
    }

    $status = if ($freePercent -lt 15) { "WARNING" } else { "HEALTHY" }

    [PSCustomObject]@{
        Drive       = "C:"
        SizeGB      = $sizeGB
        FreeGB      = $freeGB
        FreePercent = $freePercent
        Status      = $status
    }
}

function Get-CPUHealth {
    $cpu = Get-CimInstance Win32_Processor
    $usage = [math]::Round(($cpu | Measure-Object -Property LoadPercentage -Average).Average, 0)

    [PSCustomObject]@{
        UsagePercent = $usage
        Status       = if ($usage -ge 90) { "WARNING" } else { "HEALTHY" }
    }
}

function Get-RAMHealth {
    $os = Get-CimInstance Win32_OperatingSystem

    $totalKB = [double]$os.TotalVisibleMemorySize
    $freeKB = [double]$os.FreePhysicalMemory
    $usedKB = $totalKB - $freeKB

    $usagePercent = if ($totalKB -gt 0) {
        [math]::Round(($usedKB / $totalKB) * 100, 2)
    }
    else {
        0
    }

    [PSCustomObject]@{
        TotalGB      = [math]::Round($totalKB / 1MB, 2)
        UsedGB       = [math]::Round($usedKB / 1MB, 2)
        UsagePercent = $usagePercent
        Status       = if ($usagePercent -ge 50) { "WARNING" } else { "HEALTHY" }
    }
}

function Get-UptimeHealth {
    $os = Get-CimInstance Win32_OperatingSystem
    $uptime = (Get-Date) - $os.LastBootUpTime

    [PSCustomObject]@{
        LastBootTime = $os.LastBootUpTime
        Uptime       = "{0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
        Status       = if ($uptime.TotalDays -ge 14) { "WARNING" } else { "HEALTHY" }
    }
}

function Show-SystemDiagnostics {
    Write-Host ""
    Write-Host "=== SYSTEM DIAGNOSTICS ==="

    $storage = Get-StorageHealth
    $cpu = Get-CPUHealth
    $ram = Get-RAMHealth
    $uptime = Get-UptimeHealth

    Write-Host ""
    Write-Host "Storage:"
    $storage | Format-List

    Write-Host "CPU:"
    $cpu | Format-List

    Write-Host "RAM:"
    $ram | Format-List

    Write-Host "Uptime:"
    $uptime | Format-List
}

function Invoke-RepairTools {
    do {
        Clear-Host
        Write-Host "=== REPAIR TOOLS ==="
        Write-Host "1. Flush DNS Cache"
        Write-Host "2. Renew DHCP Lease"
        Write-Host "3. Run System File Checker"
        Write-Host "4. Return to Main Menu"
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" {
                ipconfig /flushdns
                Pause-Toolkit
            }
            "2" {
                ipconfig /release
                ipconfig /renew
                Pause-Toolkit
            }
            "3" {
                sfc /scannow
                Pause-Toolkit
            }
            "4" { return }
            default {
                Write-Host "Invalid selection."
                Pause-Toolkit
            }
        }
    } while ($true)
}

function Invoke-FullHealthCheck {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportPath = Join-Path $ReportDirectory "ITToolkit_HealthReport_$timestamp.txt"

    $system = Get-SystemInformation
    $network = Get-NetworkInformation
    $networkTests = Test-NetworkDiagnostics
    $storage = Get-StorageHealth
    $cpu = Get-CPUHealth
    $ram = Get-RAMHealth
    $uptime = Get-UptimeHealth

    $healthStatuses = @(
        $storage.Status
        $cpu.Status
        $ram.Status
        $uptime.Status
        $networkTests.DefaultGateway
        $networkTests.Internet
        $networkTests.DNS
    )

    $overallHealth = if ($healthStatuses -contains "FAIL") {
        "ATTENTION REQUIRED"
    }
    elseif ($healthStatuses -contains "WARNING") {
        "WARNING"
    }
    else {
        "HEALTHY"
    }

    $report = @"
IT TOOLKIT - FULL PC HEALTH REPORT
Generated: $(Get-Date)

=== OVERALL HEALTH ===
$overallHealth

=== SYSTEM INFORMATION ===
$($system | Format-List | Out-String)

=== NETWORK INFORMATION ===
$($network | Format-List | Out-String)

=== NETWORK DIAGNOSTICS ===
$($networkTests | Format-List | Out-String)

=== STORAGE HEALTH ===
$($storage | Format-List | Out-String)

=== CPU HEALTH ===
$($cpu | Format-List | Out-String)

=== RAM HEALTH ===
$($ram | Format-List | Out-String)

=== UPTIME ===
$($uptime | Format-List | Out-String)
"@

    $report | Out-File -FilePath $reportPath -Encoding utf8

    Write-Host ""
    Write-Host "=== FULL PC HEALTH CHECK ==="
    Write-Host "Overall Health: $overallHealth"
    Write-Host "Detailed report saved to:"
    Write-Host $reportPath
}

function Show-MainMenu {
    do {
        Clear-Host
        Write-Host "===================================="
        Write-Host "             IT TOOLKIT"
        Write-Host "===================================="
        Write-Host "1. System Information"
        Write-Host "2. Network Information"
        Write-Host "3. Network Diagnostics"
        Write-Host "4. System Diagnostics"
        Write-Host "5. Repair Tools"
        Write-Host "6. Full PC Health Check"
        Write-Host "7. Exit"
        Write-Host ""

        $choice = Read-Host "Select an option"

        switch ($choice) {
            "1" {
                Get-SystemInformation | Format-List
                Pause-Toolkit
            }
            "2" {
                Get-NetworkInformation | Format-List
                Pause-Toolkit
            }
            "3" {
                Test-NetworkDiagnostics | Format-List
                Pause-Toolkit
            }
            "4" {
                Show-SystemDiagnostics
                Pause-Toolkit
            }
            "5" {
                Invoke-RepairTools
            }
            "6" {
                Invoke-FullHealthCheck
                Pause-Toolkit
            }
            "7" {
                Write-Host "Exiting IT Toolkit."
                break
            }
            default {
                Write-Host "Invalid selection."
                Pause-Toolkit
            }
        }
    } while ($choice -ne "7")
}

Show-MainMenu
