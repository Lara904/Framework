---
inclusion: fileMatch
fileMatchPattern: '.kiro/skills/**'
---

# Skill authoring - cadrage des exigences

Ce steering cadre la creation et la maintenance des skills Kiro de ce workspace (dossier
`.kiro/skills/<skill-name>/`). Il vise a garantir des skills **auto-portes**, a la **structure
predictible**, et **coherents** avec les skills existants (`dict-assessment`, `nfr-requirements`,
`presentation-gates`, `functional-architecture`, `technical-architecture`).

Les identifiants techniques (cles de front-matter, chemins, noms de fichiers) restent en anglais.

## 1. Principe directeur : auto-portage (self-contained)

Un skill DOIT pouvoir produire ses livrables **sans dependance externe** au-dela de ce qui est
livre dans son propre dossier.

- **Aucun fichier d'entree obligatoire hors du skill.** Les exemples officiels (ex. un `.docx`,
  un `.xlsx`, un `.pptx` de reference) servent de **provenance uniquement** : leur structure doit
  etre **reproduite dans les references** du skill (colonnes, plan, schema), jamais requise en
  entree a l'execution.
- **Templates et assets embarques.** Tout template, logo, modele de reference, catalogue ou
  standard necessaire est place sous `assets/` du skill et reference par chemin relatif.
- **Pas de dependance a Python ou Microsoft Office.** Pour generer des livrables Office
  (`.docx`, `.xlsx`, `.pptx`), utiliser des generateurs PowerShell auto-portes qui ecrivent des
  paquets OPC valides (voir section 5).
- **Pas de reference reseau** pour un livrable : images en base64 embarquees, pas de chemins
  externes.
- **Test d'auto-portage obligatoire** avant de considerer un skill termine : generer un livrable
  a partir du seul skill + un modele/entree minimal, dans un dossier temporaire, sans aucun
  fichier du projet (`Sources/` etc.). Si cela echoue, le skill n'est pas auto-porte.

## 2. Structure de dossier (predictible)

```
.kiro/skills/<skill-name>/
  SKILL.md                 # obligatoire : front-matter + vue d'ensemble + regles
  references/              # guides charges a la demande (1 sujet par fichier)
  assets/                  # ressources embarquees (non-modifiables a l'execution)
    templates/             # templates de reference (source of truth)
    scripts/               # generateurs + validateurs auto-portes
    logos/ | cards/ | ...  # autres ressources embarquees
```

- `SKILL.md` est le **seul** point d'entree ; il reste court et renvoie vers `references/`.
- Un fichier de `references/` = **un sujet** (questionnaire, output-format, un template de
  document, regles de validation...). Chargement a la demande, pas tout dans `SKILL.md`.
- `assets/templates/` est la **source of truth** ; ne jamais la modifier a l'execution (lecture
  seule). Les livrables sont ecrits dans le **dossier de sortie par projet** `output/${project_name}/`
  (voir le steering `output-convention.md`, source unique de verite de l'emplacement de sortie),
  pas dans le skill ni a la racine nue du projet.

## 3. SKILL.md - front-matter et contenu

Front-matter YAML obligatoire :
- `name` : identifiant en kebab-case, identique au nom du dossier.
- `description` : une a trois phrases a la **troisieme personne**, disant ce que le skill fait,
  sur quel standard/template officiel il s'appuie, et ce qu'il produit. Mentionner "self-contained"
  si des assets sont embarques. Renvoyer vers le skill complementaire s'il existe (ex. "For the
  TECHNICAL view use ... instead").
- `keywords` : liste de termes de declenchement (acronymes, synonymes FR/EN, references de
  standards) - c'est le signal d'activation, etre genereux et precis.

Corps de `SKILL.md`, dans cet ordre :
1. Titre + paragraphe de vue d'ensemble (ce que fait le skill, quels livrables).
2. "When to use this skill" - declencheurs concrets.
3. "Bundled assets" - inventaire de `assets/` (templates, scripts, logos...).
4. "Deliverables (always produce all N)" - liste numerotee, convention de nommage stable
   `${project_name}_<domain>_<kind>`, avec renvoi vers la reference de chaque livrable. Indiquer
   l'emplacement de sortie **`output/${project_name}/`** et renvoyer au steering `output-convention.md`
   (source unique de verite) ; ne jamais coder un emplacement en dur dans le skill.
5. "Ask before generating" - renvoi au questionnaire (voir section 4).
6. "Reference guides (load on demand)" - une ligne par fichier de `references/`.
7. "Core rules (always apply)" - liste numerotee, imperative, chaque regle sur une intention.
8. "Quick workflow" - etapes numerotees de bout en bout (poser questions -> generer ->
   valider -> ecrire).

## 4. Cadrage des exigences (requirements) avant generation

Tout skill qui produit un livrable est **interactif** : il cadre les exigences avant de generer.

- Fournir un `references/questionnaire.md` : questions groupees par theme, a poser **seulement si
  necessaire** (ne pas re-demander ce qui est deja connu du contexte/README/fichiers existants).
- **Ne jamais inventer** un service, un flux, une valeur, un port, un dimensionnement, une
  criticite. Toute inconnue devient :
  - un marqueur visible dans le livrable (`C?`, "TBC", "Not applicable"),
  - une "Open question" dans le README compagnon,
  - puis une question posee a l'utilisateur.
- **Respecter les standards/templates officiels** : quand un livrable suit un template officiel
  (DAT, NFR, gates, flow mapping...), reproduire **fidelement** son plan/ses colonnes/sa
  numerotation. Garder les sections meme legeres (mettre "Not applicable"/"TBC" plutot que
  supprimer un titre).
- **Coherence inter-livrables** : quand plusieurs livrables portent la meme information (diagramme
  + README + document + classeur), ils DOIVENT s'accorder (memes composants, memes flux, memes
  valeurs de classification). Le noter explicitement dans les regles du skill.

## 5. Generation de livrables Office (OPC-safe)

Pour `.docx` / `.xlsx` / `.pptx`, sans Python ni Office :
- Ecrire un **module PowerShell** (`assets/scripts/<Thing>.psm1`) qui construit un paquet OPC
  valide (parties Open XML minimales + rels + content types).
- **Toujours** zipper avec `ZipArchiveMode.Create` (JAMAIS `Update`, qui corrompt le paquet et
  declenche "repair on open"). Ecrire en **UTF-8 sans BOM**. Echapper le texte XML.
- Piloter le contenu par un **modele JSON** (`<project>_..._model.json`) pour rendre la
  regeneration et le versionnement triviaux.
- Fournir un **wrapper** `build-*.ps1` et un **validateur** `validate-*.ps1` qui verifie au
  niveau OPC ("would Word/Excel repair this?") + XML bien forme. Le validateur DOIT sortir en
  code 0 avant livraison.
- Documenter le schema JSON dans un fichier de `references/`.

## 6. Encodage et style des livrables

- UTF-8 sans BOM partout. Pour les `.drawio`, texte de cellule **ASCII uniquement** (eviter tirets
  cadratins, puces, guillemets courbes -> mojibake) ; utiliser des equivalents ASCII.
- Langue des livrables : rester coherent avec l'ecosysteme du skill (les livrables techniques
  existants sont en anglais). Fixer la langue explicitement dans les regles du skill.
- Pages "Versions" / historiques : format tabulaire predictible et stable ; on **ajoute** une
  ligne a chaque modification, on ne reecrit jamais l'historique.

## 7. Checklist de definition of done d'un skill

- [ ] `SKILL.md` avec front-matter (`name`, `description`, `keywords`) conforme section 3.
- [ ] Structure `references/` + `assets/` conforme section 2.
- [ ] Auto-porte : aucun fichier d'entree externe obligatoire ; templates/standards embarques.
- [ ] Test d'auto-portage passe (generation dans un dossier temp, sans fichiers du projet).
- [ ] Questionnaire de cadrage des exigences present ; regle "ne jamais inventer" explicite.
- [ ] Livrables : convention de nommage stable, coherence inter-livrables documentee.
- [ ] Emplacement de sortie `output/${project_name}/` indique, renvoyant a `output-convention.md`
      (pas d'emplacement code en dur).
- [ ] Generateurs Office OPC-safe + validateurs (sortie 0) si livrables Office.
- [ ] Exemples officiels cites comme provenance uniquement (structure reproduite en references).
- [ ] Regles d'encodage/langue explicites.
