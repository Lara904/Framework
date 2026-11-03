# Guide d'utilisation — Framework Kiro ARB Readiness (MVP exploratoire)

Ce guide couvre la mise en route et l'exécution du framework tel qu'il se trouve dans ce dépôt
à l'issue de la Phase 1 (MVP exploratoire, run complet sur le TCC réel "Forensic tooling"). Il
s'adresse à quiconque reprend ce travail : toi-même plus tard, un relecteur, ou l'équipe qui
industrialisera le module en Phase 3.

---

## 1. Ce que le framework fait

Le framework est un ensemble de **skills Kiro** (dossiers `.kiro/skills/<nom>/`, chacun avec son
`SKILL.md`, ses scripts PowerShell et ses gabarits) qui, à partir des documents bruts d'un projet
(diagrammes, notes d'architecture, backlog...), produisent les livrables attendus à l'Architecture
Review Board (ARB) SIBS/SFS : architecture fonctionnelle et technique, NFR, DICT, matrice de
droits d'accès, pré-remplissage du threat modeling, estimation de coûts, et le deck "Architecture
Gates" final qui les assemble — plus un questionnaire consolidé de tout ce qui reste à faire
valider par un humain (PGA, MOA, DPO, Sécurité, Finance, Cloud-Infra, EA).

Le principe directeur, répété dans chaque `SKILL.md` : **ne jamais inventer une valeur inconnue**.
Une information manquante reste un placeholder visible (`TBC`/`TBD`) et remonte dans le
questionnaire consolidé — jamais comblée par une hypothèse silencieuse.

## 2. Prérequis

| Composant | Requis pour | Statut |
|---|---|---|
| **PowerShell 7+** (`pwsh`), multiplateforme | Tous les skills | Obligatoire. Testé avec 7.4.6 sur Linux. |
| **xvfb** + **draw.io Desktop** (`.deb`, [releases GitHub](https://github.com/jgraph/drawio-desktop/releases)) | Rendu des diagrammes `.drawio` en PNG (`presentation-gates/assets/scripts/build-diagrams.ps1`) | Optionnel mais recommandé — sans lui, les slides de diagramme gardent une référence textuelle vers le `.drawio`, jamais une image inventée. Voir §5. |
| **Microsoft Excel** (COM) | `nfr-requirements` — uniquement pour exécuter la macro officielle `RequirementsFilter` du classeur de référence | **Non requis** depuis la Phase 1 : un chemin headless (sans Excel) reproduit le calcul de la macro. Voir §5. |
| LibreOffice (`soffice`, `pdftoppm`) | Vérification visuelle du deck avant livraison (pas un prérequis du pipeline lui-même) | Recommandé pour la relecture finale uniquement. |

Aucun de ces prérequis n'est spécifique à Windows : tout le pipeline (hors Excel, désormais
contourné) tourne identiquement sous Linux/macOS/Windows avec `pwsh`.

## 3. Mise en route

```bash
# Depuis la racine du dépôt
pwsh -NoProfile    # vérifier que PowerShell 7+ répond

# Chaque skill s'invoque indépendamment, voir §4. Convention commune :
#   - lire le SKILL.md du skill avant de l'utiliser (il référence ses propres guides "on demand")
#   - les sorties vont dans output/${project_name}/ (jamais dans sources/ ni dans le skill lui-même)
#   - sources/ contient la matière brute du projet (confidentielle, jamais commise au dépôt)
```

## 4. Pipeline — ordre d'exécution

```
1. deliverable-detection        (scanne sources/, mappe chaque fichier vers le skill concerné)
2. functional-architecture       (FAD : .docx + .drawio)
3. technical-architecture        (DAT : .docx + 3 .drawio + dataflow_mapping.xlsx)
4. dict-assessment                (DICT : D/I/C/T, RTO/RPO)
5. nfr-requirements               (NFR : .xlsm)
6. access-right-matrix            (ARM : .xlsx)
7. cost-estimation                (coûts : .json + README)
8. threat-modeling-prefill        (TM : .xlsx, scénarios STRIDE-LM)
9. presentation-gates             (assemble tout dans le deck Architecture Gates .pptx)
10. open-questions-consolidation  (scanne tous les README et produit LE questionnaire unique)
```

Les étapes 2-8 peuvent tourner dans n'importe quel ordre relatif entre elles (chacune lit ses
propres sources), mais doivent précéder l'étape 9 (le deck référence leurs livrables) et l'étape
10 doit toujours être la dernière (elle scanne les README que les étapes précédentes ont écrits).
**Rejouer l'étape 10 après toute modification manuelle d'un README** — c'est elle qui donne le
compte d'items ouverts à citer dans un rapport d'avancement.

### Commandes types

```bash
# Génération du deck (après que toutes les étapes 2-8 ont produit leurs livrables)
pwsh -File .kiro/skills/presentation-gates/assets/scripts/find-missing.ps1 `
  -Pptx "output/<projet>/<projet>_Architecture_Gates_G2.pptx" -Gate all `
  -Out "output/<projet>/<projet>_Architecture_Gates_README.md"

pwsh -File .kiro/skills/presentation-gates/assets/scripts/validate-deck.ps1 `
  -Pptx "output/<projet>/<projet>_Architecture_Gates_G2.pptx" -Gate 2

# Questionnaire consolidé (toujours en dernier)
pwsh -File .kiro/skills/open-questions-consolidation/assets/scripts/build-questionnaire.ps1 `
  -ProjectDir "output/<projet>" -Project "<projet>" `
  -Out "output/<projet>/<projet>_Open_Questions_Questionnaire.md"
```

## 5. Les 3 blocages techniques levés en Phase 1

### 5.1 NFR sans Excel (chemin headless)
**Symptôme avant correction** : `new-nfr-workbook.ps1` échouait sur tout hôte sans Excel installé
(y compris le bac à sable Kiro lui-même) et ne produisait qu'un classeur à moitié rempli
(paramètres seuls, Relevant/Status/Comments vides).

**Résolu** : le script détecte automatiquement l'absence de COM Excel
(`Test-ExcelComAvailable`) et bascule sur un chemin headless
(`New-NfrWorkbookHeadless`) qui recalcule la pertinence de chaque NFR directement depuis le XML
du classeur (`Test-NfrRelevant`, qui reproduit la logique de la macro officielle
`RequirementsFilter`), sans jamais ouvrir Excel. Vérifié de bout en bout sur les 102 décisions
réelles du projet Forensic-tooling : 131/133 NFR correspondent exactement au calcul de la macro
du modèle ; les 2 exceptions connues (références à suffixe lettre portant plusieurs déclencheurs
DICT à la fois, ex. `NFR-6004a`) sont documentées dans le code et signalées dans le message
affiché à l'exécution — jamais silencieusement données pour "0 écart".

```bash
pwsh -File .kiro/skills/nfr-requirements/assets/scripts/new-nfr-workbook.ps1 `
  -Out "output/<projet>/<projet>_NFR.xlsm" `
  -Dict 3333 -Rto 1 -Sox No -DataPrivacy D -AppName "<nom projet>" `
  -Decisions "decisions.tsv"
# Relecture (fonctionne aussi sans Excel depuis ce correctif) :
pwsh -File .kiro/skills/nfr-requirements/assets/scripts/export-nfr.ps1 `
  -Workbook "output/<projet>/<projet>_NFR.xlsm" -Out "dump.tsv"
```

Si Excel est disponible plus tard, relancer une fois avec `-ForceCom` pour confirmer via le
chemin officiel (macro) — ce n'est pas une obligation, c'est une option de double-vérification.

### 5.2 Rendu des diagrammes `.drawio`
**Symptôme avant correction** : les slides de diagramme du deck ne recevaient que la référence
textuelle du `.drawio`, jamais l'image — `Add-PptxImageToSlide` existait déjà mais rien ne savait
convertir `.drawio` en `.png`.

**Résolu** — recette validée en conditions réelles (pas seulement documentée) :

```bash
apt-get install -y xvfb
curl -fsSL -o drawio.deb "https://github.com/jgraph/drawio-desktop/releases/download/v26.2.2/drawio-amd64-26.2.2.deb"
apt-get install -y ./drawio.deb
```

Deux pièges non documentés ailleurs, trouvés en testant pour de vrai :
- `ELECTRON_DISABLE_SANDBOX=1` est obligatoire en root (conteneur/CI), sinon `drawio` refuse de
  démarrer (`Running as root without --no-sandbox is not supported`).
- `--page-index 1` est obligatoire : chaque `.drawio` produit par ce framework a une page
  "Versions" en première page — sans ce flag, l'export produit silencieusement cette page de
  version au lieu du diagramme.
- Le paquet npm `drawio` (`npx drawio`) n'a **aucun rapport** : c'est un générateur de graphiques
  CSV qui partage juste le nom.

```bash
pwsh -File .kiro/skills/presentation-gates/assets/scripts/build-diagrams.ps1 `
  -ProjectDir "output/<projet>" -Project "<projet>"
```

Exécuté et vérifié de bout en bout sur les vrais diagrammes et le vrai deck du projet
Forensic-tooling : PNG rendus correctement, insérés sans chevauchement résiduel
(`validate-deck.ps1` confirme), rendu visuel LibreOffice confirmé à l'œil.

### 5.3 Décision `businessProfiles` (access-right-matrix)
Ce n'est pas un blocage technique mais une décision projet **volontairement bloquante** (rule 3b
du `SKILL.md`) : le champ `businessProfiles` du modèle JSON doit être explicitement `"none"` ou
`"defined"` avant toute génération, pour ne jamais livrer une feuille "Matrix of BUSINESS rights"
silencieusement vide. Sur Forensic-tooling la réponse est `"none"` (pas de profil métier, seuls
des analystes CISO/DFIR-EXT techniques) — documentée comme telle dans le README et le modèle.

Le build et la validation (`build-rightmatrix.ps1`, `validate-rightmatrix.ps1`) ont été testés de
bout en bout sur cet hôte sans qu'aucun blocage technique ne se reproduise, pour les deux cas
(`"none"` et `"defined"`). Si un blocage apparaît sur un autre poste, c'est probablement
spécifique à cet environnement d'exécution (version PowerShell, DLL système) — collecter le
message d'erreur exact avant d'investiguer plus loin, le code lui-même n'a rien montré de cassé.

## 6. Limites connues (honnêtes, pas à masquer)

- **Vérification visuelle non automatisée** : `validate-deck.ps1` et les heuristiques de scan
  (mots-clés, diff contre le gabarit, chevauchement géométrique image/texte) couvrent beaucoup,
  mais seul un rendu réel (LibreOffice → PDF → image) confirme la lisibilité effective. À faire
  avant toute livraison finale, pas seulement en cours de développement.
- **`AWS NG - TECHNICAL rights`** (feuille de `access-right-matrix`) reste le contenu générique du
  gabarit tant qu'aucun mécanisme de personnalisation par profil technique n'existe dans le
  modèle — décision produit en attente (champ `technicalProfilesList` à ajouter ou non).
- **Le pré-remplissage NFR dépend de la qualité du décisions.tsv fourni** : le calcul de pertinence
  est fiable (macro reproduite), mais la justification de chaque statut reste un travail humain ou
  LLM en amont, à écrire par bloc thématique (ISO 25010) plutôt que ligne à ligne pour rester
  économique en tokens — voir `nfr-requirements/references/workflow.md` §5bis.
- **Threat modeling et coûts restent, par construction, un pré-remplissage à valider** — jamais une
  analyse de risque ou un chiffrage acquis (rappelé explicitement sur chaque classeur produit).

## 7. Où regarder en cas de problème

- `SKILL.md` de chaque skill : règles et workflow.
- `references/` de chaque skill : guides détaillés chargés à la demande.
- `output/<projet>/<projet>_Open_Questions_Questionnaire.md` : LA liste unique de ce qui reste à
  faire valider par un humain, par rôle — jamais les 7-8 README individuels.
- `validate-*.ps1` de chaque skill : toujours exécuter avant de considérer un livrable terminé.
