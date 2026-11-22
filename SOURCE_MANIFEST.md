# GenSolar Pro Engineering — Single-archive source manifest

**Package edition:** 2026-11-22  
**Application:** `GenSolar-Pro-Engineering-Next`  
**Framework:** Flutter 3.50.0 stable / Dart 3.14.0  
**Source language:** Dart  

This is the complete source tree assembled for this delivery. It preserves the new Flutter application, existing workflows and all calculator implementations authored in this package. It is not a binary release and does not include build caches, generated platform runner files, store signing identities, API keys, service credentials or customer records.

## Included in this archive

- Flutter app shell, responsive Material 3 theme and navigation.
- Dashboard, project create/search/edit/delete, active project switching and offline project persistence.
- Project JSON backup and restore.
- Site survey, rectangular PV layout, module exclusions, 2D roof plan and conceptual isometric visualization.
- Solar yield, electrical string screening, battery sizing, wind screening, BOM/BOQ and delivery workflow.
- CAD DXF export and project PDF/text/JSON reporting.
- Advanced Engineering Library with 19 project-linked engineering calculators.
- Calculation/workflow regression tests.
- GitHub Actions CI for Dart validation and six platform build targets.
- Windows/macOS/Linux platform bootstrap scripts.
- Full EPC engineering scope, implementation plan, owner requirements checklist, verification status and manual GitHub instructions.

## Advanced engineering library

The 19 available tools are monthly solar yield, inverter DC/AC allocation, AC cable voltage drop, transformer capacity, wind design-basis screening, mounting-rail beam screening, bolt direct-shear screening, footing soil-bearing screening, earth-rod resistance approximation, solar-pump energy, project financial cash-flow screening, cable-tray fill, power-factor correction, PV string protection screening, cable-ampacity derating, battery C-rate, transformer fault-current approximation, rooftop dead-load screening, and concrete/rebar take-off.

Each saved result records inputs, displayed metrics, formula/method, assumptions, warnings, engine version and timestamp in the active project. These calculators are engineering aids and estimates; they are not a complete clause-by-clause IS/IEC/IEEE design suite or a professional certification.

## Generated files and build outputs

The archive omits generated Flutter platform runner folders and compiled output to keep the project source-focused. Run `scripts/bootstrap_platforms.ps1` on Windows or `scripts/bootstrap_platforms.sh` on macOS/Linux, or let GitHub Actions generate platform runner folders during CI. Then resolve dependencies and run the checks in `README.md`.

## Important requirements

Project-owner decisions that cannot safely be invented (company details, utility, applicable code editions, equipment datasheets, design criteria, weather/map providers, tariff/tax settings, formats, user roles, cloud provider and release signing) are itemized in `docs/PROJECT_INPUTS_TO_CONFIRM.md`. The application uses editable values and explicit assumptions until those inputs are supplied. Never place API keys or signing secrets in this archive.

Start with `README.md`, then `docs/MANUAL_GITHUB_SETUP.md` and `docs/IMPLEMENTATION_PLAN_FROM_ZERO_TO_RELEASE.md`.

## File integrity

`SHA256SUMS.txt` records SHA-256 checksums for every other file in this source archive. From the extracted project root, verify with `sha256sum -c SHA256SUMS.txt` (Linux/macOS with sha256sum installed) or `Get-FileHash` in PowerShell.
