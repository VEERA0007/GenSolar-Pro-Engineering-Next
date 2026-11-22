# Architecture

## Principles

1. Feature-first source organization.
2. UI depends on the `ProjectRepository` contract, not the storage implementation.
3. One `SolarProject` owns the survey, PV, yield, electrical, battery, structural, BOM, procurement and delivery section snapshots.
4. Engineering calculations are pure Dart functions with explicit units and input validation.
5. Offline-first behavior is the baseline; synchronization is a future repository adapter.
6. Upstream edits mark existing dependent calculation sections as needing review; stale values are retained but not counted as current.
7. Invalid or incomplete inputs produce errors or REVIEW warnings, never an invented engineering pass.

## Layers

- `app/`: responsive Material 3 shell, navigation and theme.
- `features/`: dashboard, projects, calculator, connected EPC workspace, module directory and settings.
- `core/models/`: project data contract and JSON serialization.
- `core/data/`: repository interface and local `SharedPreferencesAsync` adapter.
- `core/engineering/`: UI-independent calculator functions and workflow result models.
- `core/providers.dart`: Riverpod providers and dependency invalidation graph.
- `shared/widgets/`: reusable cards and headings.

## Navigation and state

The application uses Riverpod 3 Notifiers for the selected top-level destination, project ID and EPC tab. The application shell uses an `IndexedStack` to retain screen state while users move between destinations. The EPC workspace uses a `TabController`; the workflow rail, module cards, dashboard flow cards and Save & continue actions all point to the same tab indices.

## Project data and dependency flow

Each workspace saves its section into `SolarProject.engineeringData` with `schemaVersion`, `savedAtUtc` and `needsReview`. The dependency graph in `markDownstreamReview` is:

- survey → PV, yield, electrical, structural, BOM, CAD, DPR
- PV → yield, electrical, BOM, CAD, DPR
- yield → DPR
- electrical → BOM, DPR
- battery → BOM, DPR
- structural → BOM, DPR
- BOM → procurement, delivery, DPR
- procurement → delivery, DPR
- delivery → DPR
- CAD → DPR

A project is operationally marked `Engineering ready` only after survey, PV, yield, electrical, structural screening, BOM, procurement, delivery, CAD and a current report snapshot are all saved without stale flags. This status is not an engineering approval.

When a section is edited, existing downstream snapshots retain their values but set `needsReview: true` and record a reason. The target section becomes current only after validation and a successful save. Project metadata edits can explicitly flag the survey or PV section itself. CAD is marked captured only after a DXF export/copy is recorded; DPR is marked captured only after PDF/text snapshot export. The DPR snapshot records missing or stale required sections and is not counted as current until a fresh snapshot is generated after review. Input snapshots derive PV dimensions from survey, yield from PV installed capacity, string-count suggestions from module quantity, roof area from survey, and BOM quantities/rates from PV/electrical inputs. Procurement and delivery remain distinct records.

## Persistence

`LocalProjectRepository` is the first cross-platform adapter. Read, save, delete and import operations share a serial operation queue to avoid observing inconsistent values during concurrent UI updates. JSON backup import validates the schema version, size, record count, IDs, names and non-negative finite project capacity before committing the merged set.

`SharedPreferencesAsync` is an initial small-data persistence adapter, not a transactional engineering database. Replace it behind `ProjectRepository` with an indexed transactional database, migrations, integrity checks, encryption where required, backup verification and conflict-aware synchronization before relying on it for large engineering projects or multiple team members.

## Visualizations and exports

The PV tab contains a manual module position grid. The CAD tab derives a scaled 2D plan and conceptual isometric roof view from the same persisted grid and exclusion indexes. DXF uses metre units with roof and PV layers. The DPR tab exports a project-input / preliminary-calculation snapshot to PDF, text and JSON. These outputs are not approved construction documents.

## Platform services

The source is configured for Android, iOS, Web, Windows, macOS and Linux. File import/export is mediated by cross-platform plugins. GPS, maps, weather, camera, AR, notifications, secure key storage and cloud authentication require platform-specific adapters, permission UX and service configuration before they can be described as implemented.

## Engineering result contract (target)

Each release-grade calculation should persist project ID, input revision, engine version, full inputs/units, output values/units, assumptions, limitations, source/standard edition, timestamp, result state and reviewer/sign-off where applicable. Upstream changes must invalidate dependent reports and drawing snapshots. Results remain REVIEW until the required validation and qualified review gates are satisfied.

## Advanced engineering library

`lib/core/engineering/advanced_engineering.dart` contains pure, UI-independent advanced EPC screening calculations. `lib/features/engineering/advanced_engineering_screen.dart` provides the responsive calculator directory and input/result experience. The directory is reachable from **Modules → Advanced engineering library**. Each calculator validates numeric inputs, records the formula/assumptions/warnings, and can persist its output into the active project's `engineeringData.advancedEngineering.calculations` map. An existing DPR snapshot is marked stale when a new result is saved. The user can use non-stale project survey/PV/yield/electrical data to prefill matching inputs; remaining defaults are explicitly sample values and must be verified.

Advanced calculation outputs remain estimates/screening. The full enterprise design modules and required validation gates are defined in `MASTER_ENGINEERING_SCOPE.md`. Owner-specific settings and external service credentials are enumerated in `PROJECT_INPUTS_TO_CONFIRM.md`.
