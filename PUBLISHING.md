# Publier ce dépôt

Deux niveaux de publication possibles. `.gitignore` applique déjà le premier par défaut ; le
second est un bloc optionnel à activer à la main (voir son commentaire "PUBLIC-REPO MODE").

## Niveau 1 — dépôt privé/interne (ex. un repo d'entreprise donné par ton employeur)
**Déjà prêt, rien à faire de plus.** `.gitignore` exclut déjà tout ce qui n'est pas réutilisable :
- `sources/` et `output/` (matière et livrables d'un projet réel — jamais le framework)
- `.kiro/.temp_ai/` (scratch d'agent)
- `.kiro/specs/*/` (spécifications décrivant un cas précis, pas le framework générique)
- toute steering locale/personnelle (`*.local.md`, `*.perso.md`, `project-context*.md`)
- les livrables Office laissés par erreur à la racine du dépôt

Les gabarits officiels embarqués dans `.kiro/skills/*/assets/templates/` (gabarit SIBS Architecture
Gates, modèle NFR DP-MD18, matrice de droits SFS) **restent dans le dépôt** à ce niveau : un repo
privé d'entreprise où ces documents sont de toute façon internes n'a pas besoin de les retirer.

Avant de pousser : `git status` doit ne montrer aucun fichier sous `sources/` ou `output/` ; sinon
ils ont été ajoutés avant que `.gitignore` ne les exclue (`git rm -r --cached sources/ output/` si
c'est le cas).

## Niveau 2 — dépôt public (hors de l'entreprise)
Nécessite en plus de retirer les gabarits propriétaires eux-mêmes (ils ne sont pas à nous de
diffuser). Décommenter le bloc "OPTIONAL: PUBLIC-REPO MODE" en bas de `.gitignore`, puis déposer
dans chaque `assets/templates/` concerné un `README.md` expliquant quel fichier officiel récupérer
et où le replacer (le bloc l'exclut déjà de l'ignore, donc ce README reste visible même quand les
binaires sont exclus). Ne pas faire ce niveau sans une décision explicite — c'est un changement de
périmètre de diffusion, pas un nettoyage cosmétique.

## Checklist avant de publier (les deux niveaux)
- [ ] `git status` propre : aucun fichier sous `sources/`, `output/`, `.kiro/.temp_ai/`
- [ ] Aucune steering personnelle (`project-context.md` rempli, pas le `.template.md`)
- [ ] `GUIDE.md` à jour (prérequis, pipeline, blocages connus)
- [ ] Les 9 skills + 1 (`open-questions-consolidation`) chargent sans erreur (`Import-Module` sur
      chaque `.psm1`, voir `GUIDE.md` §3)
