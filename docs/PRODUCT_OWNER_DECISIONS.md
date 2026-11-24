# GenSolar Pro — Product-owner decision register

This register captures owner-specific choices required to complete integrations safely. Blank choices stay configurable; no API credentials, company legal details, manufacturer limits or code editions are inferred.

| Domain | Decision required | Current safe default | Owner decision / evidence |
|---|---|---|---|
| Identity | Legal entity, logo, GSTIN, document contacts | Brand-neutral GenSolar placeholders | [TO CONFIRM] |
| User roles | Admin, sales, survey, designer, structural/electrical engineer, procurement, site engineer, customer | Local single-user mode | [TO CONFIRM] |
| Geography | Initial states, DISCOMs and authority forms | Configurable site address and manual utility fields | [TO CONFIRM] |
| Standards | Exact IS/IEC/IEEE editions and approval matrix | Mark advanced outputs REVIEW until engineer verifies | [TO CONFIRM] |
| Wind design | Terrain, topography, height, roof zones, coefficients and load combinations | User-sourced factors only; screening label | [TO CONFIRM] |
| PV modules | Brands, model numbers, datasheet revision, temperature coefficients | User-editable generic module input | [TO CONFIRM] |
| Inverters | Manufacturer, models, MPPT voltage/current windows, AC limits | User-entered limits | [TO CONFIRM] |
| Batteries | Chemistry, voltage families, BMS protocol and operating envelopes | Preliminary energy sizing only | [TO CONFIRM] |
| Solar resource | Licensed/approved weather and irradiation source | Explicit manual inputs with source field | [TO CONFIRM] |
| Maps/GPS | Map provider, API terms, offline map rights, privacy/retention | Manual coordinates; GPS/map adapters disabled | [TO CONFIRM] |
| CAD | DXF versions, DWG/3D SDK licensing, title blocks and sheet sizes | Current concept view and DXF screening export | [TO CONFIRM] |
| Commercial | GST treatment, markup, approval limits, payment milestones, finance policy | Editable line item rates; indicative financial screens | [TO CONFIRM] |
| Cloud | Cloud provider, region/data residency, authentication, MFA, retention | Offline local repository | [TO CONFIRM] |
| Logger integration | Inverter/data-logger models, protocols, polling and credentials | No device connection unless model/protocol approved | [TO CONFIRM] |
| Release | Android application ID, signing owner, iOS team, distribution channel | Debug APK and unsigned iOS CI artifacts | [TO CONFIRM] |
| QA | Reference calculations, target devices, pilot approvers and acceptance criteria | Existing automated tests plus explicit review gates | [TO CONFIRM] |

## Decision change control

For each decision, record:
- Date and approver.
- Confirmed value plus supporting policy, licence, standard, datasheet or contract.
- Affected app modules and migration implications.
- Required test cases and approval owner.

Never put API keys, passwords, private signing keys, service account credentials or customer data in this file or source control. Store credentials in a secret manager / protected GitHub Actions secrets and access them through a backend or platform secure storage.
