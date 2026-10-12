# NFR index (EN / FR) - code to title

Quick bilingual lookup of every NFR base identifier by code, without opening a card. For full
details (goal, constraints, governance, DocInfo link) open the matching card in
`nfr-cards/NFR-XXXX.md`. Titles are immutable - never paraphrase them in a deliverable.

The repository has 108 base identifiers (some with lettered sub-variants a/b/c...) across the
8 ISO 25010 categories.

## 1 - Functional Suitability / Adequation fonctionnelle
| NFR | Title (EN) | Titre (FR) |
|---|---|---|
| NFR-1101 | The scheduling entities results are produced on time | Les resultats des entites d'ordonnancement sont produits dans les delais |
| NFR-1201 | Programs must use a functional date independent from the machine's date | Les programmes doivent utiliser une date fonctionnelle independante de la date machine |
| NFR-1202 | The system's scheduling entities produce consistent, complete results | Les entites d'ordonnancement produisent des resultats coherents et complets |
| NFR-1203 | The time reference must be guaranteed and checked periodically | La reference de temps doit etre garantie et verifiee periodiquement |
| NFR-1204 | New LCDV codification: new PSA applications developed in 7 digits | Nouvelle codification LCDV : nouvelles applications PSA en 7 chiffres |
| NFR-1401 | High-level description and risk analysis on personal data (prestudy) | Description et analyse de risque de haut niveau sur les donnees personnelles (pre-etude) |
| NFR-1402 | Personal data defined, incl. data minimization and retention period | Donnees personnelles definies, incl. minimisation et duree de conservation |
| NFR-1403 | A complete Privacy Impact Assessment (PIA) has been conducted | Une analyse d'impact (PIA) complete a ete realisee |
| NFR-1404 | System up to date in the record of processing register | Systeme a jour dans le registre des traitements |
| NFR-1405 | Exercise of the rights of the natural person is specified | L'exercice des droits de la personne physique est specifie |
| NFR-1406 | Non-EU supplier must accept the EU legal obligations | Le fournisseur hors UE doit accepter les obligations legales europeennes |
| NFR-1407 | Personal data to a subcontractor is anonymized or pseudonymized | Les donnees personnelles transmises a un sous-traitant sont anonymisees/pseudonymisees |
| NFR-1408 | SOX treatments identified and described (functionally & technically) | Traitements SOX identifies et decrits (fonctionnellement et techniquement) |
| NFR-1409 | The OS configuration respects the SOX compliance rules | La configuration de l'OS respecte les regles de conformite SOX |
| NFR-1410 | The DB configuration respects the SOX compliance rules | La configuration de la BD respecte les regles de conformite SOX |
| NFR-1411 | SOX schedulers properly configured | Les planificateurs SOX correctement configures |

## 2 - Performance Efficiency / Efficacite des performances
| NFR | Title (EN) | Titre (FR) |
|---|---|---|
| NFR-2101 | Target architecture meets performance expectations; monitored in RUN | L'architecture cible repond aux performances ; surveillee en exploitation |
| NFR-2102 | User response-time requirements validated with business and tested | Exigences de temps de reponse validees avec le metier et testees |
| NFR-2201 | Purging procedure for functional data, with archive if required | Procedure d'epuration des donnees fonctionnelles, avec archivage si besoin |
| NFR-2202 | Purging procedures for technical data | Procedures d'epuration des donnees techniques |
| NFR-2203 | Operational procedure to re-organize the database(s) | Procedure operationnelle de reorganisation de la/des base(s) |
| NFR-2204 | Resources regularly monitored, analysed and adequate to needs | Ressources surveillees, analysees et en adequation avec les besoins |
| NFR-2301 | Initial capacity handles starting needs and anticipated increase | La capacite initiale couvre le demarrage et l'augmentation anticipee |
| NFR-2302 | Increase of resource needs anticipated with the business growth | L'augmentation des besoins en ressources est anticipee |

## 3 - Compatibility / Compatibilite
| NFR | Title (EN) | Titre (FR) |
|---|---|---|
| NFR-3101 | The system is able to coexist with others | Le systeme est capable de coexister avec les autres |
| NFR-3102 | Except derogation, uses the up-to-date certified technical stack | Sauf derogation, utilise la stack technique certifiee a jour |
| NFR-3201 | IP services of the system are identified (map of flows) | Les services IP du systeme sont identifies (cartographie des flux) |
| NFR-3202 | Usage through the PSALib environment must be operational | L'utilisation via l'environnement PSALib doit etre operationnelle |

## 4 - Usability / Facilite d'utilisation
| NFR | Title (EN) | Titre (FR) |
|---|---|---|
| NFR-4101 | The system proposes useful languages for the user interface | Le systeme propose les langues utiles pour l'interface |
| NFR-4501 | Meets standard ergonomic rules and business graphic charters | Respecte les regles ergonomiques et chartes graphiques metier |
| NFR-4601 | Meets users specific accessibility needs | Repond aux besoins specifiques d'accessibilite |

## 5 - Reliability / Fiabilite
| NFR | Title (EN) | Titre (FR) |
|---|---|---|
| NFR-5101 | Designed to be operated by Operations with their usual tools | Concu pour etre exploite par l'exploitation avec ses outils habituels |
| NFR-5102 | Hardware outside DDCE: maintenance forecasted, critical HW identified | Materiel hors DDCE : maintenance planifiee, materiel critique identifie |
| NFR-5103 | Process scheduling must be fully automatic | L'ordonnancement des processus doit etre entierement automatique |
| NFR-5104 | Any job submitted by a user under exclusive control of application | Tout job soumis par un utilisateur sous controle exclusif de l'application |
| NFR-5105 | Operational information complete and up to date in CMDB | Informations operationnelles completes et a jour dans la CMDB |
| NFR-5106 | Change templates up to date for each version | Modeles de changement a jour pour chaque version |
| NFR-5107 | Anticipation planning for the CAB up to date | Planification anticipee pour le CAB a jour |
| NFR-5108 | New app / major evolution must use IndusGen tools | Nouvelle app / evolution majeure doit utiliser les outils IndusGen |
| NFR-5201 | Monitored, generates incidents automatically to the right entities | Supervise, genere automatiquement des incidents vers les bonnes entites |
| NFR-5202 | Degraded processes exist and are tested (IT/organizational) | Des procedures degradees existent et sont testees (IT/organisationnelles) |
| NFR-5203 | Needed on-call duties are operational | Les astreintes necessaires sont operationnelles |
| NFR-5204 | Maintenance contracts with repair times tailored to DICT, up to date | Contrats de maintenance avec delais adaptes au DICT, a jour |
| NFR-5205 | Time ranges for users/batch/maintenance validated with users | Plages horaires utilisateurs/batch/maintenance validees avec les utilisateurs |
| NFR-5301 | Batch program generates a return code reflecting its end status | Un programme batch genere un code retour refletant son statut de fin |
| NFR-5302 | All system batches can be restarted | Tous les batchs systeme peuvent etre redemarres |
| NFR-5303 | Technical environment secured with hardware redundancy | Environnement technique securise avec redondance materielle |
| NFR-5304 | IT hardware redundancy (farms, clusters) implemented | Redondance materielle IT (fermes, clusters) mise en oeuvre |
| NFR-5401 | Tested operational back-up and recovery mechanism | Mecanisme operationnel de sauvegarde et restauration teste |
| NFR-5402 | Tested shut-down and restart plans (HW, OS, products, system) | Plans de mise hors service et redemarrage testes (HW, OS, produits, systeme) |
| NFR-5403 | POA has a range of functional tests to apply during a restart | Le POA dispose d'une gamme de tests fonctionnels pour un redemarrage |
| NFR-5404 | System infrastructure class and DRP (PRA) test | Classe d'infrastructure du systeme et test PRA (DRP) |

## 6 - Security / Securite
| NFR | Title (EN) | Titre (FR) |
|---|---|---|
| NFR-6001 | Physical access to computer rooms strictly limited | Acces physique aux salles informatiques strictement limite |
| NFR-6002 | Source code control, vulnerability search and penetration testing | Controle du code source, recherche de vulnerabilites et tests d'intrusion |
| NFR-6003 | Treatment of security vulnerabilities | Traitement des vulnerabilites de securite |
| NFR-6004 | Access rights reviews | Revues des droits d'acces |
| NFR-6006 | Tools for application reporting (dashboards, etc.) | Outils de reporting applicatif (tableaux de bord, etc.) |
| NFR-6007 | Internet-exposed servers/proxies use default-trusted CA certificates | Serveurs/proxies exposes Internet : certificats d'AC reconnues par defaut |
| NFR-6008 | Safety compliance checks of environments compatible with the DICT | Controles de conformite securite des environnements compatibles avec le DICT |
| NFR-6009 | Access closed outside users' working hours | Acces ferme en dehors des horaires de travail |
| NFR-6101 | Exchanges must be encrypted | Les echanges doivent etre chiffres |
| NFR-6104 | Backups and archives with enhanced protection (encryption or safe) | Sauvegardes/archives avec protection renforcee (chiffrement ou coffre) |
| NFR-6105 | Enhanced protection when backups/archives stored by a third party | Protection renforcee quand sauvegardes/archives stockees par un tiers |
| NFR-6106 | Enhanced by strict network/server segmentation or hardened OS | Renforce par segmentation reseau/serveur stricte ou OS durci |
| NFR-6107 | Active network services limited to strictly necessary | Services reseau actifs limites au strict necessaire |
| NFR-6108 | Deployed on a dedicated environment (itself or a group) | Deploye sur un environnement dedie (lui-meme ou un groupe) |
| NFR-6109 | Data protection strengthened (dedicated storage or encryption) | Protection des donnees renforcee (stockage dedie ou chiffrement) |
| NFR-6110 | Physical access to servers/storage follows specific procedures | Acces physique aux serveurs/baies suit des procedures specifiques |
| NFR-6111 | Check differences between reference and actual access rights | Verifier les ecarts entre droits de reference et droits reels |
| NFR-6112 | Test environments use anonymized or pseudonymized data | Les environnements de test utilisent des donnees anonymisees/pseudonymisees |
| NFR-6113 | Third-party app DICT consistent with the system's DICT | Le DICT d'une app tierce est coherent avec le DICT du systeme |
| NFR-6114 | Data erased during the support restitution process | Donnees effacees lors de la restitution des supports |
| NFR-6115 | Data extractions and downloads/uploads controlled | Extractions et telechargements/televersements controles |
| NFR-6116 | Client workstation data unreadable if returned/stolen/lost | Donnees des postes clients illisibles si restitue/vole/perdu |
| NFR-6117 | External-storage hosting compliant with data confidentiality | Hebergement en stockage externe conforme a la confidentialite |
| NFR-6201 | Technical admin actions via the infrastructure admin gateway | Actions d'administration technique via la passerelle d'administration |
| NFR-6202 | Installation under exclusive responsibility of technical integrators | Installation sous responsabilite exclusive des integrateurs techniques |
| NFR-6203 | Technical integrators seal system components after receipt | Les integrateurs techniques scellent les composants apres reception |
| NFR-6204 | Evolutions of system versions registered | Les evolutions de versions du systeme enregistrees |
| NFR-6205 | Technical configuration modifications registered | Les modifications de configuration technique enregistrees |
| NFR-6206 | Means to detect version evolutions implemented | Moyens de detecter les evolutions de versions mis en oeuvre |
| NFR-6207 | The system ensures operational integrity of its data | Le systeme assure l'integrite operationnelle de ses donnees |
| NFR-6208 | The user's session controlled and protected | La session utilisateur controlee et protegee |
| NFR-6209 | Integrity of the code in production controlled | Integrite du code en production controlee |
| NFR-6301 | Tested back-up and recovery for traceability data | Sauvegarde et restauration des donnees de tracabilite testees |
| NFR-6302 | Integration with the Corporate SOC set | Integration avec le SOC Groupe etablie |
| NFR-6303 | SOX logs properly generated with retention | Journaux SOX correctement generes avec conservation |
| NFR-6401 | Control procedures of deviant behaviours defined and implemented | Procedures de controle des comportements deviants definies et mises en oeuvre |
| NFR-6402 | Traceability chart for business traceability requirements defined | Charte de tracabilite pour les exigences metier definie |
| NFR-6403 | Accesses of third-party applications traced | Les acces des applications tierces traces |
| NFR-6404 | Shelf life of activity logs at least 1 year | Duree de conservation des journaux d'au moins 1 an |
| NFR-6501 | Access-right policy defined and managed | Politique des droits d'acces definie et geree |
| NFR-6502 | User rights administration complies with the logical security tool | Administration des droits conforme a l'outil de securite logique |
| NFR-6503 | All users needing authentication use the logical security tool | Tous les utilisateurs a authentifier utilisent l'outil de securite logique |
| NFR-6504 | Access-service owner confirms access service assignations | Le proprietaire d'un service d'acces confirme les attributions |
| NFR-6505 | Admin access-service owner limits admins to strictly necessary | Le proprietaire limite les administrateurs au strict necessaire |
| NFR-6506 | Fewer than 150 users have access to an information asset | Moins de 150 utilisateurs ont acces a un actif informationnel |
| NFR-6507 | The system uses the right method to authenticate users | Le systeme utilise la methode adequate pour authentifier les utilisateurs |
| NFR-6508 | Technical accounts properly set up in TAM | Comptes techniques correctement configures dans TAM |
| NFR-6509 | SOX access rights and segregation of duties implemented | Droits d'acces SOX et separation des taches mis en oeuvre |

## 7 - Maintainability / Maintenabilite
| NFR | Title (EN) | Titre (FR) |
|---|---|---|
| NFR-7001 | Source code under control (SCM tool under PSA ownership) | Code source sous controle (outil SCM sous propriete PSA) |
| NFR-7002 | Use the CIQ continuous-integration/qualimetry platforms | Utiliser les plateformes d'integration continue/qualimetrie (CIQ) |
| NFR-7003 | Development quality acceptance criteria respected | Criteres d'acceptation qualite de developpement respectes |
| NFR-7004 | The Cloud-Native principle must be implemented | Le principe Cloud-Native doit etre mis en oeuvre |
| NFR-7005 | The FINOPS principles must be implemented | Les principes FINOPS doivent etre mis en oeuvre |
| NFR-7101 | Batches designed and developed in a modular way | Les batchs concus et developpes de maniere modulaire |
| NFR-7301 | Users can indicate the system reference name to the Help Desk | Les utilisateurs peuvent indiquer le nom de reference au Help Desk |

## 8 - Portability / Portabilite
| NFR | Title (EN) | Titre (FR) |
|---|---|---|
| NFR-8201 | Designed to be installed on any environment per the tech architecture | Concu pour etre installe sur tout environnement conforme a l'architecture |

Note: `nfr-catalog.md` lists the lettered sub-variants (e.g. NFR-6507a..i) with their exact
dispensation and triggers. The cards in `nfr-cards/` carry the full detail and DocInfo links.
