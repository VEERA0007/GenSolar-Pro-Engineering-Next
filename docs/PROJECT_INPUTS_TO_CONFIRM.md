# GenSolar Pro — Project-specific requirements to confirm

This file keeps uncertain business choices out of source code. The app should start with editable settings and sample/demo project data clearly labelled as such. Replace each `[TO CONFIRM]` item when the product owner supplies the definitive requirement.

## 1. Organisation and branding
- Legal company name and trading name: [TO CONFIRM]
- Logo, primary/secondary colours and typography: [TO CONFIRM]
- Default currency and number/date format: INR and India formats are current examples, not a hard-coded limitation.
- Company address, GSTIN, contact details, quote footer and document signatories: [TO CONFIRM]
- Document numbering pattern for project, quotation, DPR, drawing and revision: [TO CONFIRM]

## 2. Country, codes and jurisdiction
- Initial deployment countries/states: [TO CONFIRM]
- Applicable electrical, structural, civil, fire, safety and grid standards with exact editions: [TO CONFIRM]
- DISCOM/utility and authority application forms: [TO CONFIRM]
- Whether the product needs multi-country codes and unit systems at launch: [TO CONFIRM]

## 3. Business operating model
- User profiles and permissions (admin, sales, surveyor, designer, structural engineer, electrical engineer, procurement, site engineer, customer): [TO CONFIRM]
- Approval matrix and maker/checker workflow: [TO CONFIRM]
- Number of companies, branches, teams and concurrent users: [TO CONFIRM]
- Lead-to-survey-to-quotation-to-engineering-to-execution process: [TO CONFIRM]
- Customer portal and subcontractor access: [TO CONFIRM]

## 4. Project types and capacity range
- Rooftop on-grid capacity range: [TO CONFIRM]
- Industrial/commercial/utility/ground-mount/hybrid/off-grid/solar-pump support: planned scope; priority order [TO CONFIRM]
- AC coupling, DC coupling and backup configurations: [TO CONFIRM]
- Single site / multi-building / multi-roof / portfolio scale: [TO CONFIRM]

## 5. Equipment catalogue
- Preferred module brands/models/datasheets: [TO CONFIRM]
- Preferred inverter brands/models and MPPT limits: [TO CONFIRM]
- Battery chemistry, brands, voltage families and BMS protocols: [TO CONFIRM]
- Cable, breaker, SPD, transformer, mounting rail, fastener and earthing product catalogues: [TO CONFIRM]
- Who maintains rates, stock and datasheet revisions: [TO CONFIRM]

## 6. Engineering design basis
- Required structural codes, wind basis and editions: [TO CONFIRM]
- Material grades, aluminium/steel section tables, design strengths and deflection criteria: [TO CONFIRM]
- Soil report / geotechnical input format and foundation types: [TO CONFIRM]
- Electrical design standards, cable tables, protection devices and utility short-circuit data: [TO CONFIRM]
- Earthing/lightning design and acceptable test criteria: [TO CONFIRM]
- Solar resource source (PVGIS, NASA POWER, Meteonorm, weather station or other licensed source): [TO CONFIRM]
- Preferred yield validation benchmark and acceptance tolerance: [TO CONFIRM]

## 7. Maps, GPS and weather APIs
- Preferred map provider and licence: [TO CONFIRM]
- Whether offline map packs are required and permitted: [TO CONFIRM]
- Weather/solar API and data licensing: [TO CONFIRM]
- API keys must be supplied through GitHub Actions secrets or a secured backend; never commit them in this ZIP.

## 8. CAD, 3D and document formats
- DXF versions and required CAD compatibility: [TO CONFIRM]
- DWG/SKP support requires a confirmed licensed SDK/converter: [TO CONFIRM]
- PDF sheet sizes/title blocks and drawing templates: [TO CONFIRM]
- 3D export formats (glTF/GLB/IFC/STEP): [TO CONFIRM]
- Required DPR templates and logo/signature fields: [TO CONFIRM]

## 9. Commercial, finance and procurement
- GST/tax treatment and invoice requirements: [TO CONFIRM]
- Quotation markup, discount, contingency, retention and payment milestone rules: [TO CONFIRM]
- Vendor approval, multi-quote comparison and purchase approval limits: [TO CONFIRM]
- Bank/lender financial model assumptions (debt, tax, depreciation, replacement, insurance, incentives): [TO CONFIRM]
- O&M contract structure, SLA, spare parts and monitoring fee: [TO CONFIRM]

## 10. IT, security and deployment
- Cloud provider and data residency: [TO CONFIRM]
- Authentication provider, MFA and account lifecycle: [TO CONFIRM]
- Backup retention, restore objectives and encryption requirements: [TO CONFIRM]
- Android package name, iOS bundle ID, Windows signing and Apple developer account: [TO CONFIRM]
- Google Play/App Store/private distribution strategy: [TO CONFIRM]
- Monitoring/logger integrations (Modbus, SunSpec, vendor APIs, MQTT): [TO CONFIRM]

## 11. Acceptance and quality gates
- Minimum device versions and screen sizes: [TO CONFIRM]
- Required offline test scenarios: [TO CONFIRM]
- Calculation reference examples and expected results supplied by the engineering team: [TO CONFIRM]
- Required PDF/DXF/JSON export round-trip tests: [TO CONFIRM]
- Pilot users, acceptance sign-off roles and release criteria: [TO CONFIRM]

## 12. User decision log

Record every answer from the product owner here. Date each decision, who approved it, affected module, and whether the decision requires a source-code or settings change. Do not infer missing company, legal, API, rate, datasheet or engineering-standard information.
