# NFR Catalog - DP-MD18-EN (distilled, self-contained)

Full list of the Non-Functional Requirements of the Stellantis (ex-PSA) repository
`DP-MD18-EN` V11, distilled for offline use. The authoritative source is the bundled
workbook `assets/templates/DP-MD18-EN_Non-Functional_Requirements.xlsm` (sheet "NFR repository").
Requirements are FIXED: you never add, modify or remove one. You only decide, per NFR,
`Relevant` (Yes/No) and `Status`, and write a justification in `Comments / Valorization`.

Columns below:
- **Dispensation** = who may set it Not relevant and under which condition ("No dispense possible" = mandatory).
- **Triggers** = context flags that make the NFR relevant. `D/I/C/T` followed by the levels
  (e.g. `C34` = triggered when Confidentiality is 3 or 4). `RTO` = triggered by an RTO class,
  `DP` = triggered when the system processes personal data, `SOX` = triggered for SOX scope.
  Empty triggers = generic requirement (assessed on functional/technical applicability, not on DICT).

## 1 Functional Suitability

### 1.1 Functional completeness

**NFR-1101** - The scheduling entities results are produced on time

- Detail: The functional specifications must indicate for each batch the time when the result must be ready to use.
- Dispensation: IT-PM can set the status to "Not relevant" if there is no scheduling entities
- Triggers: (generic)

### 1.2 Functional correctness

**NFR-1201** - For processes which uses a functional date, the programs must use a functional date independent from the machine's date

- Dispensation: IT-PM can set the status to "Not relevant" if there is no processes using a functional date
- Triggers: (generic)

**NFR-1202** - The system's scheduling entities produce consistent, complete results

- Detail: A planning entity is a sequence of processing. To be done for all systems using batch processes.
- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-1203** - The time's reference must be guaranteed and its good usage must be checked periodically

- Dispensation: No dispense possible
- Triggers: T234

**NFR-1204** - 7 digits LCDV coding must be implemented on all new application using LCDV codification

- Detail: The LCDV, Common Language of Vehicle Description, is used to describe the vehicle diversity of PSA. It exists since 1985 and has evolved from 5 digits to 7 digits since 2007.
- Dispensation: IT-PM can set the status to "Not relevant" if the LCDV codification is not used in the system
- Triggers: (generic)

### 1.3 Functional appropriateness

### 1.4 Compliance

**NFR-1401** - A high level description and risk analysis on personal data has been conducted on the prestudy scope

- Detail: Analyse the risks of a new processing. The risks concern the impacts on the data subjects (Persons) if the personal data were destroyed, modified (loss of integrity) or involuntary disclosed.
- Dispensation: No dispense possible
- Triggers: DP

**NFR-1402** - The details of personal data used are defined, including data minimization and retention period

- Detail: Collect only personal data that is strictly necessary for the defined purpose(s). A maximal retention period must be fixed, after which personal data must be destroyed or anonymized in a secure, irreversible way.
- Dispensation: No dispense possible
- Triggers: DP

**NFR-1403** - A complete Privacy Impact Assessment (PIA) risk analysis on personal data has been conducted

- Detail: Conduct a risk analysis (see NFR-1401), when the risk is high (E,F) a Data iProtection Impact Assessment (DPIA), must be done to analyse the risks of the new processing and determine the measures to be implemented to avoid and minimize the impacts.
- Dispensation: B-PM can set the status to "Not relevant" if no important risk has been identified in the high level risk analysis
- Triggers: DP

**NFR-1404** - The information on the system are up to date in the record of processing register ("data protection authority" declaration)

- Detail: Check if the new project/processing can be associated to one or more existing processing in the Group’s register “records of processing”.
- Dispensation: No dispense possible
- Triggers: DP

**NFR-1405** - The exercise of the rights of the natural person on their personal data are specified

- Detail: Implement the adequate technical or organisational features, in order to facilitate the exercise of his rights by a data subject (end user). The rights of the natural persons in the GDPR: access, rectification, erasure, restriction, portability…
- Dispensation: No dispense possible
- Triggers: DP

**NFR-1406** - When intending to work with a non-EU supplier, the supplier must accept the EU legal obligations

- Detail: Before choosing a non-EU supplier, ensure that the supplier has signed the "Standard Contractual Clauses" (SCC) of the European Union.
- Dispensation: IT-PM can set the status to "Not relevant" if there is no non-EU supplier
- Triggers: DP

**NFR-1407** - The personal data sent to a subcontractor for developments or tests purpose are anonymized or pseudonymized. If real data is mandatory, a data protection agreement must be signed

- Detail: Make sure that the data sent to a subcontractor  for development or testing are anonymized or pseudonymised. When a real risk for data subject is proven for a processing and when data anonymization is not possible, a way of reducing the risk for data subject is the pseudonymization. If real data is mandatory, a data protection agreement must be signed.
- Dispensation: IT-PM can set the status to "Not relevant" if there is no personal data sent to any subcontractor
- Triggers: DP

**NFR-1408a** - SOX processings must be identified and functionally described

- Dispensation: No dispense possible
- Triggers: SOX

**NFR-1408b** - SOX processings must be identified and technically described

- Detail: DLTI - Critical JOBS - Change log - LDAP Configuration. Usage of the current model of DLTI.
- Dispensation: No dispense possible
- Triggers: SOX

**NFR-1409** - The configuration of the OS must respect the SOX compliance rules

- Detail: OS must be implemented following SOX compliance rules .
- Dispensation: No dispense possible
- Triggers: SOX

**NFR-1410** - The configuration of the database must respect the SOX compliance rules

- Detail: DB must be integrated with Stellantis security tools and following SOX compliance rules.
- Dispensation: No dispense possible
- Triggers: SOX

**NFR-1411** - SOX Schedulers should be properly configured

- Detail: Usage of $Universe only - no crontab for critical job - job logs - incident generated in case failure for critical jobs.
- Dispensation: No dispense possible
- Triggers: SOX

## 2 Performance efficiency

### 2.1 Time behaviour

**NFR-2101** - The target system architecture is able to meet performance expectations and performance has to be monitored during the RUN

- Detail: The system's infrastructure must be adapted to the performance requirements. Tests must be done using metrology tools.
- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-2102** - The users requirements about the system response times are validated with the business and tested

- Detail: Global response times, or specific response times for some screens or functions, must be written in the functional specifications.
- Dispensation: No dispense possible
- Triggers: (generic)

### 2.2 Resource utilisation

**NFR-2201** - The system has a purging procedure for functional data, using data archive if required

- Detail: The functional specifications must indicate retention period and archiving needs for all data witch need this information.
- Dispensation: B-PM can set the status to "Not relevant" but it is a risk on system stability and performances. No dispense possible for personal data
- Triggers: D1234

**NFR-2202** - The system has purging procedures for technical data

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-2203** - The system has an operational procedure to re-organize the database(s)

- Dispensation: TPM can set the status to "Verified" if the choosen DBMS do it automaticaly
- Triggers: (generic)

**NFR-2204** - The resources of the system are regularly monitored, analysed and in adequation with the current needs of the application

- Detail: Resources include Bandwidth, CPU utilization, memory usage, storage. Needs of the application concern data volumes and number of users.
- Dispensation: No dispense possible
- Triggers: (generic)

### 2.3 Capacity

**NFR-2301** - The system's initial capacity is able to deal with the starting needs and also their anticipated increase

- Detail: Capacity means data volumes and number of users. It includes exceptional but anticipated needs.
- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-2302** - The increase of resource needs related to the increase of the business must be anticipated

- Detail: Resources include Bandwidth, CPU utilization, memory usage, storage. The BUILD must put in place the partnership contract.
- Dispensation: No dispense possible
- Triggers: (generic)

## 3 Compatibility

### 3.1 Co-existence

**NFR-3101** - The system is able to coexist with others

- Detail: The system use authorized hardware, products and infrastructure services, and meet group codification standards.
- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-3102** - Except derogation, the system uses the up to date certified technical stack

- Detail: OS, DB, MW versions for the impacted infrastructure under good support and not being close to EOS datest.
- Dispensation: IT-PM can set the status to "Not relevant" if the build is a blackbox and risks are supported by the project
- Triggers: (generic)

### 3.2 Interoperability

**NFR-3201** - IP services of the system are identified (map of flows)

- Dispensation: IT-PM can set the status to "Not relevant" if there is no IP service
- Triggers: C1234

**NFR-3202** - The usage of the system through the PSALib' environment must be operational (technical and organization aspects)

- Dispensation: IT-PM can set the status to "Not relevant" if PSALib' is not used by the system
- Triggers: (generic)

## 4 Usability

### 4.1 Appropriateness recognisability

**NFR-4101** - The system proposes useful languages for the user interface

- Detail: Indicate in the functional specifications all available HMI languages and the ways to select the good one (automatic using OS language, flags, ...).
- Dispensation: IT-PM can set the status to "Not relevant" if there is no multilinguism
- Triggers: (generic)

### 4.2 Learnability

### 4.3 Operability

### 4.4 User error protection

### 4.5 User interface aesthetics

**NFR-4501** - The system meets standard ergonomic rules and business graphic charters

- Detail: No scrolls, access to the functions with 3 clicks, progress bar during long treatments … Must be written in functional specification and shown in mock-up.
- Dispensation: IT-PM can set the status to "Not relevant" if there is no or minimal user interface
- Triggers: (generic)

### 4.6 Accessibility

**NFR-4601** - The system meets users specific accessibility needs

- Detail: Special materials (wireless terminal, specific display, …), adapted screen modes (high contrast, …), work offline, …
- Dispensation: IT-PM can set the status to "Not relevant" if there is no specific accessibility needs
- Triggers: (generic)

## 5 Reliability

### 5.1 Maturity

**NFR-5101** - The system must be designed and realized to be operated by the Operations with their usual tools

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5102** - For hardware managed outside DDCE, the maintenance was forecasted and the critical hardware was identified

- Dispensation: IT-PM can set the status to "Not relevant" if there is no hardware managed outside DDCE
- Triggers: (generic)

**NFR-5103** - Process scheduling must be fully automatic

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5104** - Any job submitted by a user shall be under exclusive control of application

- Dispensation: IT-PM can set the status to "Not relevant" if there is no batch submited by users in the system
- Triggers: (generic)

**NFR-5105** - System's operational information is complete and up to date in operational repositories (CMDB)

- Dispensation: No dispense possible
- Triggers: D1234

**NFR-5106a** - The change templates are up to date for each functional version

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5106b** - The change templates are up to date for each technical version

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5107** - Anticipation planing for the CAB (DDCE changes coordination) must be up to date

- Detail: Planing must be up to date all along the project life for major versions, or for main business events.
- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5108** - Any new application or any new applicative occurrence or major evolution must use IndusGen tools

- Dispensation: No dispense possible
- Triggers: (generic)

### 5.2 Availability

**NFR-5201** - The system is monitored and generate automatically incidents to the good entities

- Dispensation: No dispense possible
- Triggers: D1234

**NFR-5202** - Degraded processes exist and are tested (IT or/and organizational)

- Dispensation: B-PM can set the status to "Not relevant" but it is a risk on system stability and performances for operation and maintenance phase
- Triggers: D34

**NFR-5203a** - Business sector on-call is operational

- Dispensation: No dispense possible
- Triggers: D4

**NFR-5203b** - IT studies on-call is operational

- Dispensation: No dispense possible
- Triggers: D4

**NFR-5203c** - Technical integrators on-call is operational

- Dispensation: No dispense possible
- Triggers: D34

**NFR-5203d** - Infrastructure teams on-call is operational

- Dispensation: IT-PM can set the status to "Verified" if the hosting is internal (automatically done in this case)
- Triggers: D34

**NFR-5204** - Maintenance contracts, with response times tailored to DICT level, are up to date

- Dispensation: IT-PM can set the status to "Verified" if the hosting is internal or on the 3 main cloud providers
- Triggers: D1234

**NFR-5205** - Time ranges for user's activities, for batch processings and for technical maintenance are validated with the users

- Detail: Technical maintenance ranges can be automatically used to reboot VM, deploy patches or others usage by IT.
- Dispensation: No dispense possible
- Triggers: (generic)

### 5.3 Fault tolerance

**NFR-5301** - Any application batch program must generate a return code reflecting its execution end status

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5302** - All system batchs (job, script, netbatch stage, etc.) can be restarted

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5303** - The technical environment (electricity, cooling, etc.) is securized with hardware redundancy

- Dispensation: IT-PM can set the status to "Verified" if the hosting is internal or on the 3 main cloud providers
- Triggers: D34

**NFR-5304** - IT Hardware redundancy (server farms, clusters, etc.) is implemented

- Dispensation: No dispense possible
- Triggers: D34

### 5.4 Recoverability

**NFR-5401** - The system includes a tested operational back-up and recovery mechanism

- Detail: Test of restoration mandatory with IPE.
- Dispensation: No dispense possible
- Triggers: D1234,SOX

**NFR-5402** - The system has tested shut-down and restart plans for hardware, OS, products and system itself

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5403** - The operational application lead (POA) of the system has a range of functional tests to apply during a restart

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-5404a** - System needs class 1 infrastructure and must do a DRP (PRA) test

- Dispensation: No dispense possible
- Triggers: RTO=1

**NFR-5404b** - System needs class 2 infrastructure and must do a DRP (PRA) test

- Dispensation: No dispense possible
- Triggers: RTO=2

**NFR-5404c** - System needs class 3 infrastructure

- Dispensation: No dispense possible
- Triggers: RTO=3

**NFR-5404d** - System needs class 4 infrastructure

- Dispensation: No dispense possible
- Triggers: RTO=4

## 6 Security

### 6.0 Overall security requirements

**NFR-6001** - Physical access to computer rooms is strictly limited to operational response needs

- Dispensation: IT-PM can set the status to "Verified" if the hosting is internal or on the 3 main cloud providers
- Triggers: D1234,I1234,C1234

**NFR-6002** - Source code control, search for vulnerabilities in the code and penetration testing are done

- Detail: If I and C < 3, only the code analysis is mandatory. Mandatory in case of Personal Data with high risk for natural person.
- Dispensation: No dispense possible
- Triggers: D34,I1234,C34

**NFR-6003a** - Treatment of non-critical security vulnerabilities is done as soon as possible without exceeding 3 months

- Detail: Must be done before the end of the BUILD phase, or must be planed to be done after, if any non-critical security vulnerability is detected during BUILD.
- Dispensation: No dispense possible
- Triggers: D34,I34,C34

**NFR-6003b** - Treatment of non-critical security vulnerabilities is done as soon as possible

- Detail: Must be done before the end of the BUILD phase, or must be planed to be done after, if any non-critical security vulnerability is detected during BUILD.
- Dispensation: No dispense possible
- Triggers: D12,I12,C12

**NFR-6003c** - Treatment of critical security vulnerabilities is done as soon as possible without exceeding 10 days, driven by a safety crisis cell

- Detail: Must be done before the end of the BUILD phase if any critical security vulnerability is detected during BUILD. No need for a crisis cell if it is before the J9/GOPROD milesotone.
- Dispensation: No dispense possible
- Triggers: D1234,I1234,C1234

**NFR-6004a** - User access rights must be reviewed once a year

- Detail: Must be reviewed once at the end of the BUILD phase.
- Dispensation: IT-PM can set the status to "Not relevant" if no user rights exist for the application
- Triggers: D123,I123,C12,SOX

**NFR-6004b** - User access rights must be reviewed twice a year

- Detail: Must be reviewed once at the end of the BUILD phase.
- Dispensation: IT-PM can set the status to "Not relevant" if no user rights exist for the application
- Triggers: D4,I4,C34

**NFR-6004c** - Technical and functional administrator access rights must be reviewed once a year

- Detail: Must be reviewed once at the end of the BUILD phase.
- Dispensation: No dispense possible
- Triggers: D12,I12,C12,SOX

**NFR-6004d** - Technical and functional administrator access rights must be reviewed twice a year

- Detail: Must be reviewed once at the end of the BUILD phase.
- Dispensation: No dispense possible
- Triggers: D34,I34,C34

**NFR-6006** - The system must provide tools for application "reporting" (dashboards, etc.)

- Dispensation: B-PM can set the status to "Not relevant" if a manual process to check logs is planned
- Triggers: T34

**NFR-6007** - Servers or proxies exposed on Internet should use certificates issued by certificate authorities known by default

- Detail: The usage of specific certification authority or specific installations should be avoided.
- Dispensation: IT-PM can set the status to "Not relevant" if there is no server or proxy exposed on Internet
- Triggers: (generic)

**NFR-6008** - The results of the safety compliance checks of the supporting technical environments is compatible with the DICT

- Dispensation: IT-PM can set the status to "Not relevant" if the hosting is external
- Triggers: D1234,I1234,C1234,T1234,SOX

**NFR-6009** - Access to application must be closed when outside of users' working hours

- Dispensation: IT-PM can set the status to "Not relevant" if not relevant regarding the business context (indicated by the B-PM)
- Triggers: I34

### 6.1 Confidentiality

**NFR-6101** - All exchanges must be encrypted

- Dispensation: No dispense possible
- Triggers: C1234

**NFR-6104** - Data backups and archives must have enhanced protection (encryption or safe)

- Dispensation: No dispense possible
- Triggers: C4

**NFR-6105** - Protection must be enhanced when data backups or archives are stored by a third party

- Dispensation: IT-PM can set the status to "Not relevant" if there is no data backups or archives are stored by a third party
- Triggers: C23

**NFR-6106** - The system's security must be enhanced by a strict segmentation of server host network or server itself, or by a hardened operating system

- Dispensation: No dispense possible
- Triggers: C4

**NFR-6107** - Active network services must be limited to what is strictly necessary

- Dispensation: No dispense possible
- Triggers: I34,C34

**NFR-6108** - The system is deployed on an environment dedicated for itself or for a group of systems

- Dispensation: No dispense possible
- Triggers: C4

**NFR-6109** - Protection of data must be strengthened (dedicated storage or encryption)

- Detail: In case of Personal Data (Data Privacy), to be considered according the risks on the natural person (non authorized disclosure of personal data).
- Dispensation: IT-PM can set the status to "Not relevant" if C=2 or 3 and if there is no personal data stored, even temporarily
- Triggers: C4

**NFR-6110** - Physical access to servers and storage arrays must follow specific procedures (control, traceability and authorization)

- Dispensation: No dispense possible
- Triggers: C4

**NFR-6111** - Differences between access rights defined in the security reference and the actual rights on the systems in operation must be checked

- Dispensation: No dispense possible
- Triggers: D34,I34,C234,T34,SOX

**NFR-6112** - The test environments (including preproductions) use anonymized or pseudonymized data

- Detail: If real data are mandatory, all servers containing personal or confidential data must implement all "data privacy" non-functional requirements. 
- Dispensation: IT-PM can set the status to "Not relevant" if real data are mandatory for tests
- Triggers: C34

**NFR-6113** - The DICT of any third party application that use system's data must be consistent with the DICT of the system

- Dispensation: No dispense possible
- Triggers: C34

**NFR-6114a** - Data must be "safe erased" during the restitution process of the supports

- Dispensation: IT-PM can set the status to "Verified" if the hosting is internal or on the 3 main cloud providers
- Triggers: C123

**NFR-6114b** - Data must be erased (Qualified erasing) or support must be destroyed during the restitution process of the supports, with formal tracking

- Dispensation: IT-PM can set the status to "Verified" if the hosting is internal or on the 3 main cloud providers
- Triggers: C4

**NFR-6115** - Data extractions and downloads/upload (printing and others) must be controled (technical and / or procedure)

- Dispensation: No dispense possible
- Triggers: C34

**NFR-6117** - The data hosting in external storage is compliant with the confidentiality of the data

- Dispensation: IT-PM can set the status to "Not relevant" if there is no external storage
- Triggers: C1234

### 6.2 Integrity

**NFR-6201** - For technical administrative actions, whenever the protocol allows it, use the infrastructure administrative gateway

- Dispensation: RSECU can set the status to "Not relevant" if used protocols are not accepted by the gateway
- Triggers: D1234,I1234,C1234

**NFR-6202** - The installation of developments is under the exclusive responsibility of technical integrators (concept of separating roles)

- Dispensation: No dispense possible
- Triggers: I1234

**NFR-6203** - Technical integrators seals system's components after receipt

- Dispensation: No dispense possible
- Triggers: I4

**NFR-6204** - Evolutions of system's versions must be registered

- Dispensation: No dispense possible
- Triggers: T34,SOX

**NFR-6205a** - Technical configuration's modifications must be registered

- Dispensation: No dispense possible
- Triggers: T3,SOX

**NFR-6205b** - Technical configuration's modifications must be registered (strict monitoring, a simple declaration does not suffice)

- Dispensation: No dispense possible
- Triggers: T4

**NFR-6206** - The means to detect version's evolutions of the system must be implemented

- Dispensation: No dispense possible
- Triggers: I34,T34,SOX

**NFR-6207a** - The system ensures the operational integrity of its data

- Detail: In case of Personal Data (Data Privacy), to be considered according the risks on the natural person (alteration of personal data).
- Dispensation: No dispense possible
- Triggers: I34,SOX

**NFR-6207b** - The system ensures the operational integrity of its traceability data

- Dispensation: No dispense possible
- Triggers: T34,SOX

**NFR-6208** - The user's session must be controlled and protected

- Dispensation: IT-PM can set the status to "Not relevant" if there is no sessions management
- Triggers: I234

**NFR-6209** - The integrity of the code in production must be controlled

- Dispensation: No dispence possible
- Triggers: I4

### 6.3 Non-repudiency

**NFR-6301** - Operational back-up and recovery mechanism for traceability data is implemented and tested

- Dispensation: No dispense possible
- Triggers: T34,SOX

**NFR-6302** - The integration with the Corporate SOC is set

- Dispensation: IT-PM can set the status to "Not relevant" if the hosting is external
- Triggers: T234

**NFR-6303** - SOX logs must be properly generated and retention included

- Detail: Usage of $Universe only - no crontab for critical job - job logs - incident generated in case failure for critical jobs.
- Dispensation: No dispense possible
- Triggers: SOX

### 6.4 Accountability

**NFR-6401** - Control procedures of the deviant behaviors are defined and implemented

- Dispensation: No dispense possible
- Triggers: I34,C34,T234,SOX

**NFR-6402** - The traceability chart corresponding to Business's traceability requirements (which are mandatory) is defined

- Detail: Content (users' and administrators' actions), conservation time, publication and analysis of traceability data, confidentiality level for traceability data.
- Dispensation: No dispense possible
- Triggers: T34

**NFR-6403** - Accesses of third party applications must be traced

- Detail: Trace name, @IP, …
- Dispensation: No dispense possible
- Triggers: T34

**NFR-6404** - The shelf life of activity logs is at least 1 year

- Dispensation: IT-PM can set the status to "Not feasable" if it is not possible due to other constraints (GDPR, local law …)
- Triggers: T234,SOX

### 6.5 Authenticity (and rights administration)

**NFR-6501** - System's access rights policy is defined (named owner, access services, ...) and managed

- Detail: Define access rights in functional specification, create the access rights matrix and reference it in REFLEX.
- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-6502** - Administration of user rights complies with the current logical security tool

- Dispensation: No dispense possible
- Triggers: I234,SOX

**NFR-6503** - All users (human or technical like batch, …) for who an authentication is needed must be authenticated with the current logical security tool

- Dispensation: No dispense possible
- Triggers: (generic)

**NFR-6504a** - The owner of a writing access service must confirm access service assignations

- Dispensation: No dispense possible
- Triggers: I34,SOX

**NFR-6504b** - The owner of a reading access service must confirm access service assignations

- Dispensation: No dispense possible
- Triggers: C34

**NFR-6504c** - The owner of a functional or technical administrator access service must confirm access service assignations

- Dispensation: No dispense possible
- Triggers: D34,I34,C34,SOX

**NFR-6505a** - The owner of a functional or technical administrator access service limits the number of administrators to the just necessary

- Dispensation: No dispense possible
- Triggers: D34,I3,C3,SOX

**NFR-6505b** - The owner of a functional or technical administrator access service limits number of administrators to the strictly necessary

- Dispensation: No dispense possible
- Triggers: I4,C4

**NFR-6505c** - The allocation of technical administrators roles is temporary limited and subject to validation

- Dispensation: No dispense possible
- Triggers: D4,I4,C4

**NFR-6506** - The number of users having access to an information asset must be less than 150

- Detail: Must be reviewed once at the end of the BUILD phase.
- Dispensation: No dispense possible
- Triggers: C4

**NFR-6507a** - The system authenticates users for writing

- Dispensation: No dispense possible
- Triggers: D23,I12,T12

**NFR-6507b** - The system uses “Strong” method to authenticate users for writing

- Dispensation: No dispense possible
- Triggers: D4,I34,T34

**NFR-6507c** - The system authenticates functional or technical administrators

- Dispensation: No dispense possible
- Triggers: D12,I12,C12,T12

**NFR-6507d** - The system uses “Strong” method to authenticate functional or technical administrators

- Dispensation: No dispense possible
- Triggers: D34,I34,C34,T34

**NFR-6507f** - The system authenticates users

- Dispensation: No dispense possible
- Triggers: C2,T2

**NFR-6507h** - The system uses “Strong” method to authenticate users

- Dispensation: Mandatory for all profiles for which it is useful
- Triggers: C34,T34

**NFR-6507i** - The system uses at least "Strong" method for all access from an environment not under PSA control

- Dispensation: No dispense possible
- Triggers: D234,I234,C234

**NFR-6508** - SOX logs must be properly generated and retention included

- Detail: All accounts are in TAM with justified owners and readers. Description is clear and password respect security rules.
- Dispensation: No dispense possible
- Triggers: SOX

**NFR-6509** - SOX Access right and segregation of duties are properly implemented

- Detail: Access to the application is following Stellantis security policies and password policies. Segregation of duties between developers and run team is ensure via proper control of accesses to Production.
- Dispensation: No dispense possible
- Triggers: SOX

## 7 Maintainability

### 7.0 Overall maintainability requirements

**NFR-7001** - The source code is under control (the SCM tool should be under PSA ownership)

- Dispensation: No dispense possible
- Triggers: D1234,I1234,C1234,T1234

**NFR-7002** - The PSA continuous integration and qualimetric platforms (CIQ) should be used for all supported development languages

- Dispensation: IT-PM can set the status to "Not relevant" if the used language is not supported
- Triggers: (generic)

**NFR-7003** - The development quality acceptance criteria (evaluated by the qualimetric platform) must be respected

- Dispensation: IT-PM can set the status to "Not relevant" if the global quality approach is not available for the used language (ex: Cobol)
- Triggers: (generic)

**NFR-7004** - The Cloud-Native principle must be implemented

- Dispensation: IT-PM can set the status to "Not relevant" if the system is not hosted in the cloud
- Triggers: (generic)

**NFR-7005** - The FINOPS principles must be implemented

- Dispensation: IT-PM can set the status to "Not relevant" if the system is not hosted in the cloud
- Triggers: (generic)

### 7.1 Modularity

**NFR-7101** - The batchs must be designed and developed in modular way in consistent functional subset

- Dispensation: IT-PM can set the status to "Not relevant" if there is no business batchs
- Triggers: (generic)

### 7.2 Reusability

### 7.3 Analyzability

**NFR-7301** - The system must easily enable the users to indicate its reference name as it is written in applications repository to Help Desk

- Dispensation: B-PM can set the status to "Not relevant" if there is no Help Desk available for the system
- Triggers: (generic)

### 7.4 Modifiability

### 7.5 Testability

## 8 Portability

### 8.1 Adaptability

### 8.2 Installability

**NFR-8201** - The system must be designed to be installed on any environment corresponding to the defined technical architecture

- Dispensation: No dispense possible
- Triggers: (generic)

### 8.3 Replaceability

