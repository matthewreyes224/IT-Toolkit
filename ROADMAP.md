# IT Toolkit Roadmap

## Phase 1 - Functional Baseline

Completed:

- Menu-driven PowerShell interface.
- Windows system information collection.
- Network information collection.
- Separate IPv4 and IPv6 output.
- Default gateway, internet, and DNS diagnostics.
- Storage health checks.
- CPU usage checks.
- RAM usage checks with a 50% warning threshold.
- System uptime checks.
- Full PC health check.
- Timestamped reports saved to the `Reports` directory.
- Overall console health result with detailed diagnostics written to file.
- Dedicated repair-tools menu.

## Phase 2 - Modular Refactor

In progress:

- Convert repeated diagnostic logic into reusable functions.
- Standardize all health functions to return PowerShell objects.
- Keep display logic separate from diagnostic logic.
- Centralize thresholds and configuration values.
- Improve error handling for unavailable adapters, services, drives, and CIM/WMI queries.
- Add consistent PASS / WARNING / FAIL states.
- Expand the `Get-StorageHealth` pattern to CPU, RAM, uptime, network, and system checks.
- Reduce duplicated code between individual menu options and the full health check.

## Future Implementations

### Diagnostics

- Windows Update status.
- Pending reboot detection.
- Event Viewer critical/error summary.
- Windows service health checks.
- Device Manager problem-device detection.
- Battery health reporting for laptops.
- SMART / physical disk health where supported.
- DNS configuration validation.
- Network adapter state and link-speed checks.
- Local firewall profile/status reporting.
- System integrity checks using DISM and SFC status.
- Optional latency and packet-loss testing.

### Repair and Administrative Tools

- Windows Update repair workflow.
- Network stack repair workflow.
- Windows service restart utilities.
- Print spooler repair.
- Temporary-file cleanup.
- Windows component-store maintenance.
- Optional DISM repair commands.
- Guided remediation based on detected failures.

Repair actions will remain explicit user-selected actions and will not run automatically during diagnostic checks.

### Reporting

- Structured CSV and JSON report options.
- HTML health reports.
- Historical report comparison.
- Configurable output directory.
- Machine-readable exit codes.
- Health-score summary.
- Optional export for ticket documentation.

### Engineering Improvements

- Pester unit tests.
- PowerShell module structure (`.psm1`).
- Configuration file for thresholds.
- Logging and exception handling.
- Administrator-rights detection.
- PowerShell version compatibility checks.
- Comment-based help for functions.
- GitHub Actions validation/linting.
- Script signing/documentation for trusted enterprise use.

## Long-Term Goal

Develop IT Toolkit into a reusable Windows support and endpoint-diagnostics framework that can assist help desk, desktop support, systems administration, and endpoint operations workflows without hiding changes or silently modifying systems.
