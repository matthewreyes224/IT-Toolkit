# IT Toolkit

A modular PowerShell toolkit for Windows IT support, diagnostics, health monitoring, reporting, and future administrative automation.

## Current Project State

The toolkit currently provides a menu-driven Windows support workflow:

1. **System Information** - computer name, logged-in user, manufacturer, model, Windows version, and last boot time.
2. **Network Information** - active adapter, IPv4 address, IPv6 address, default gateway, and configured DNS servers.
3. **Network Diagnostics** - tests the default gateway, internet connectivity, and DNS resolution.
4. **System Diagnostics** - checks storage, CPU, RAM, and uptime.
5. **Repair Tools** - contains explicit repair actions kept separate from diagnostics so health checks never silently modify the computer.
6. **Full PC Health Check** - collects system, network, storage, CPU, RAM, and uptime data, displays a concise overall health result, and saves detailed diagnostics to a timestamped report.
7. **Exit**

### Verified Behaviors

- C: drive storage status warns when free space falls below **15%**.
- RAM status warns when usage reaches **50% or higher**.
- IPv4 and IPv6 are displayed separately.
- Gateway, internet, and DNS tests are evaluated independently.
- Full health checks display only the overall result in the console while detailed data is written to the `Reports` directory.
- `Get-StorageHealth` is the first completed Phase 2 reusable health function.

## Project Structure

```text
IT-Toolkit/
├── ITToolkit.ps1
├── README.md
├── ROADMAP.md
└── Reports/
    └── .gitkeep
```

## Running the Toolkit

Open PowerShell from the project directory and run:

```powershell
.\ITToolkit.ps1
```

Some repair actions may require PowerShell to be opened as Administrator.

## Development Status

**Phase 1:** Working diagnostic baseline and report generation.

**Phase 2:** In progress. The current goal is to refactor repeated diagnostic logic into reusable functions while preserving the tested behavior of the original toolkit.

See [ROADMAP.md](ROADMAP.md) for planned implementations.
