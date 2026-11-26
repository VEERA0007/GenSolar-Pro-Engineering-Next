# GenSolar Pro Engineering — Next

A fresh Flutter/Dart cross-platform solar EPC workspace. This project is separate from the earlier Kotlin/WebView repository. It uses one active project record across the survey, PV, yield, electrical, battery, wind screening, BOM/BOQ, procurement, construction, CAD preview and DPR workflows.

> **Delivery status:** This source is a connected offline-first EPC MVP with working calculations and project workflows. It is not yet a complete enterprise EPC product, an engineer-certified design package or a signed store release. The precise missing engineering and service integrations are listed below and in `docs/DELIVERY_STATUS.md`.

## Technology baseline

| Layer | Technology |
|---|---|
| Framework | Flutter 3.50.0 stable |
| Language | Dart 3.14.0 |
| UI | Standalone `material_ui` package, Material 3 |
| State and dependency injection | Riverpod 3 |
| Project storage | `SharedPreferencesAsync` repository adapter (offline starter) |
| File import/export | `file_picker` 13 and `file_saver` 0.7 |
| Reports | `pdf` package |
| Automation | GitHub Actions |

The same Flutter source is configured for Android, iOS, Web, Windows, macOS and Linux. A green build on one target does not certify the other targets; each job in `.github/workflows/build.yml` must pass independently.

## Linked project workflow

1. **Projects** — create, search, edit and delete project records. Editing site location flags the survey and dependent engineering; editing target capacity flags the PV design and dependent outputs.
2. **Site survey** — enter coordinates, elevation, roof dimensions, tilt, setbacks and access walkway.
3. **PV layout** — survey dimensions prefill the PV design. Change module size/rating and clearances, compare portrait/landscape rectangular fit, and manually exclude module positions.
4. **Yield** — installed capacity is derived from the saved PV layout. Enter location-specific net yield, PR, additional losses and tariff assumptions.
5. **Electrical** — string count is suggested from the saved module count and modules per string. Review cold Voc, MPPT voltage window and the simplified DC cable drop.
6. **Battery** — size a preliminary battery from critical load, autonomy, DoD, efficiency and nominal voltage.
7. **Wind screening** — derive effective area from the survey and record a preliminary velocity-pressure / force screen.
8. **BOM / BOQ** — module quantity, rating and cable quantity are suggested from PV/electrical data; edit budget rates and allowances.
9. **Procurement / delivery** — save one supplier/PO record and project-linked construction and commissioning checklists.
10. **CAD / DPR** — inspect matching 2D and isometric concept views, export a DXF, then create a project PDF/JSON report snapshot.

The in-workspace delivery rail provides direct navigation and shows captured, not-started and review-required states. CAD is captured only after a DXF export/copy is recorded; DPR is captured only after a PDF/text report snapshot is recorded. An upstream change marks related saved sections and report snapshots as `needsReview` without deleting their values. The CAD export is disabled while the PV layout is stale. DPR snapshots record missing/stale required sections and remain in REVIEW until the current source sections are completed and a new report is generated. **Save & continue** advances only after input and cross-field calculation validation succeeds.

## Implemented application scope

- Responsive Material 3 shell for phone, tablet and desktop widths. Navigation uses an `IndexedStack` so screen state remains alive when changing destinations.
- Dashboard with portfolio KPIs, project workflow, quick actions and recent projects.
- Local project create/search/edit/delete, active-project selection and project-scoped engineering records; site and target-capacity edits invalidate dependent saved sections.
- Serialized local repository operations for project reads/imports/writes/deletes, JSON backup and restore.
- Site survey calculations for roof footprint, slope surface estimate and preliminary usable area.
- Optional local-coordinate roof polygon capture with area/perimeter metrics, concave-boundary support and self-intersection/degenerate-outline validation; PV module placement remains rectangular.
- Rectangular PV layout fit estimate, orientation comparison, module count, DC capacity, setbacks, walkway, module gap, manual cell exclusions and retained results.
- 2D roof plan and conceptual isometric PV preview based on the same saved layout inputs.
- Metre-unit ASCII DXF export with roof and PV module layers.
- Annual energy estimate, indicative monthly chart and indicative tariff value from user-entered assumptions.
- Cold-corrected string Voc, MPPT range and simplified two-conductor DC copper voltage-drop screen.
- Battery usable / nominal energy, equivalent amp-hour estimate and energy-reserve visualization.
- Basic wind pressure and effective-force screening, explicitly marked for qualified-engineer review.
- Preliminary rate-based BOM / BOQ budget schedule.
- One primary supplier / RFQ/PO status record, construction QA checklist and commissioning / handover checklist.
- Project PDF/text/JSON snapshots, DXF and JSON backup restore. CAD/DPR workflow stages are captured only after export, with stale/missing report sections explicitly marked REVIEW.
- Unit tests for project serialization, engineering calculations and workflow dependency propagation.

## Important scope still required for a full enterprise EPC product

- Multi-roof polygon geometry, arbitrary roof boundaries, obstructions, access/fire corridors, elevations and zone-based module optimization.
- Device GPS permission/capture, map layers, offline map packages, site photos and document evidence.
- Source-attributed solar resource and weather API, validated monthly energy simulation, sun path, time-series shade and module/string mismatch model.
- Fully editable multi-layer CAD, robust DXF import/edit/export round trips, dimensions, snapping, cable routing, SLD and fabrication sheets; DWG/SKP require a licensed and tested conversion stack.
- Coordinated building/roof/rail/obstacle 3D scene, sections/elevations and fabrication-grade drawing outputs. The current isometric is a concept visualization only.
- Standards-complete IS 875 Part 3 wind design, load combinations, structural member/connection/foundation verification and signed engineering reviews.
- Complete DC/AC inverter allocation, MPPT input-current validation, conductor ampacity, fault-current, protection coordination, earthing, lightning, transformer and utility interconnection design.
- Battery chemistry, C-rate, temperature/ageing, BMS, surge, hybrid dispatch and manufacturer-backed equipment catalogue checks.
- Multi-vendor RFQ, quotation comparisons, approval workflow, purchase-order line items, staged goods receipts, invoice matching, inventory and audit trail.
- Transactional database and schema migrations, encryption, secure authentication, role-based permissions, cloud sync, conflict resolution and multi-user audit history.
- Revision-controlled DPR/drawing packs, evidence attachments, approvals, e-signatures, statutory approvals and controlled release.
- Device-specific permissions, offline/relaunch/rotation/file-flow testing, store signing, app-store releases and physical-device validation.

Do not interpret a preliminary status as a structural/electrical approval, a signed DPR, a fabrication drawing, a purchase release or construction authorization. Missing or unverified engineering inputs require `REVIEW`; qualified professionals must verify project-specific design and applicable codes before any work is released.

## Install prerequisites

- Flutter **3.50.0 stable**, including Dart **3.14.0**
- Android Studio / Android SDK for Android
- macOS with Xcode for iOS and macOS
- Visual Studio with the C++ desktop workload for Windows
- Clang, CMake, Ninja, GTK and related development libraries for Linux

Install Flutter from <https://docs.flutter.dev/get-started/install>, then verify:

```bash
flutter --version
flutter doctor -v
```

## Bootstrap platform folders

The source archive keeps generated platform runners out of the core Dart tree. From the project root:

**Windows PowerShell**

```powershell
./scripts/bootstrap_platforms.ps1
```

**macOS / Linux**

```bash
chmod +x scripts/bootstrap_platforms.sh
./scripts/bootstrap_platforms.sh
```

Then run:

```bash
flutter pub get
dart format lib test
flutter analyze --fatal-warnings
flutter test --reporter expanded
flutter run
```

## Build targets

```bash
flutter build apk --debug
flutter build web --release
flutter build windows --release
flutter build macos --release
flutter build linux --release
flutter build ios --release --no-codesign
```

iOS requires macOS/Xcode. A distributable IPA and production Android package require signing/provisioning, which is not included in this source archive.

## GitHub implementation

1. Create the empty repository `GenSolar-Pro-Engineering-Next`.
2. Extract this ZIP.
3. Run the platform bootstrap script, then `flutter pub get`.
4. Add the extracted folder to GitHub Desktop and publish it to the new repository's `main` branch.
5. Push the source, open **Actions → GenSolar Pro Engineering – Cross-platform CI** and inspect the `validate` job before platform jobs.
6. Download only the artifact from the matching platform job after that job succeeds.

Do not commit signing keys, service-account JSON, passwords, customer records or API secrets. Add future production credentials through protected GitHub repository secrets.

## Source layout

```text
lib/
  app/                 Application shell and theme
  core/
    data/              Project repository contract and local adapter
    engineering/       UI-independent calculation functions
    models/            Shared immutable project model
    providers.dart     Providers and downstream review dependencies
  features/
    dashboard/         Project overview and pipeline
    projects/          Project create/search/edit/list/delete
    calculator/        Quick PV capacity sizing
    engineering/       Connected survey-to-DPR workflow
    workspaces/        Module directory and scope/status
    settings/           Backup and restore
  shared/widgets/      Reusable widgets
  test/                Unit and workflow regression tests
.github/workflows/     Multi-platform CI
scripts/               Platform bootstrap helpers
docs/                  Delivery status, architecture and roadmap
```

## Expanded advanced engineering library

Open **Modules → Advanced engineering library** to access additional project-linked calculation tools:

- Monthly plane-of-array solar yield with 12 monthly irradiation inputs, PR, losses and degradation.
- Inverter DC/AC allocation.
- Single- and three-phase AC cable voltage-drop screening using entered R/X data.
- Transformer capacity screening.
- Wind design-basis factor screen with user-entered K1–K4 values.
- Mounting rail simply-supported beam bending/deflection screen.
- Bolt-group direct-shear screen.
- Rectangular footing bearing-pressure and concrete-volume screen.
- Earth-electrode resistance approximation.
- Solar water-pump energy and PV array estimate.
- Project financial cash-flow, payback, NPV and LCOE proxy.
- Cable tray geometric fill and power-factor correction.
- PV string fuse screening, cable ampacity derating, battery C-rate and transformer fault-current estimates.
- Rooftop equipment average dead-load screen, concrete quantity and reinforcement take-off.

Advanced calculation inputs/results are saved in the active project under `engineeringData.advancedEngineering.calculations`, including engine version, formula, assumptions, warnings and timestamp. Saving a new engineering result marks an existing DPR snapshot as requiring review.

See `docs/MASTER_ENGINEERING_SCOPE.md` for the full EPC discipline register, calculations, excluded checks and completion gates. See `docs/PROJECT_INPUTS_TO_CONFIRM.md` for company, utility, standards, catalogues, tariffs, API, document and cloud decisions that must come from the product owner. See `docs/IMPLEMENTATION_PLAN_FROM_ZERO_TO_RELEASE.md` for the development sequence.

### Current toolchain

The CI workflow pins Flutter 3.50.0 stable. The official Flutter release notes identify 3.50.0 as the November 2026 stable release; Dart 3.14.0 is the matching language line. Check `.github/workflows/build.yml` for the exact CI toolchain. [Flutter release notes](https://docs.flutter.dev/release/release-notes).

### Important engineering warning

Advanced rail, bolt, footing, wind, earthing, transformer, cable and financial tools are screening calculations. They are not complete IS/IEC/IEEE design implementations or certifications. The exact exclusions and engineering validation requirements are documented next to the scope register. Project standards, code editions, factors, equipment datasheets, soil reports and sign-off rules must be configured and verified by qualified professionals.
