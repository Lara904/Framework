---
inclusion: always
---

# Exécution des commandes shell (timeout & retry)

Sur cette machine (Windows / PowerShell / cmd), certaines commandes — souvent
PowerShell, l'automatisation COM Office, ou des outils réseau — **cessent de
répondre** et laissent l'agent bloqué indéfiniment. Les règles ci-dessous
évitent ces blocages.

## Règle d'emplacement : tout le transitoire dans `.temp_ai/`
**Tous** les fichiers temporaires générés par les agents — scripts `.ps1`, logs,
sondes, sorties intermédiaires, fichiers de travail jetables — doivent vivre
**exclusivement** sous un dossier `.temp_ai/` à la racine du projet. **La racine
du projet reste propre** : aucun `_run.ps1`, `_script.ps1`, `_tpl*.txt`,
`*_probe.*` ni log ne doit y être créé.

- **Un sous-dossier de travail par agent.** Chaque agent écrit uniquement dans
  `.temp_ai/<agent>/` (nom d'agent en kebab-case, ex. `.temp_ai/office-word/`,
  `.temp_ai/functional-architecture/`, `.temp_ai/general/` pour un agent
  générique). Un agent ne touche pas au sous-dossier d'un autre.
- Le dossier `.temp_ai/` est **jetable** : son contenu peut être supprimé à tout
  moment. Il ne doit contenir aucun livrable. Les livrables restent écrits **à la
  racine du projet** (ou là où le skill concerné les attend), jamais dans
  `.temp_ai/`.
- Créer `.temp_ai/<agent>/` s'il n'existe pas avant d'y écrire (l'outil
  d'écriture de fichier crée les dossiers manquants).

## Règle d'or : toujours prévoir un timeout
- **Ne jamais lancer une commande sans borne de temps.** Fournir systématiquement
  le paramètre `timeout` (en millisecondes) à l'outil d'exécution de commandes.
- Valeurs indicatives :
  - Commandes rapides (lecture, `dir`, `git status`, petits scripts) : **30 000 ms**.
  - Commandes moyennes (build court, automatisation Office/COM, génération de
    fichiers) : **120 000 ms**.
  - Commandes longues connues (gros build, export volumineux) : **300 000 ms** max,
    et prévenir l'utilisateur avant.
- Si aucune durée n'est raisonnable, **découper la tâche** plutôt que d'attendre
  sans limite.

## Détecter un process bloqué
Considérer une commande comme bloquée si :
- Le `timeout` est atteint sans sortie finale.
- La sortie n'évolue plus alors qu'une progression était attendue (aucune
  nouvelle ligne, aucun prompt rendu).
- Une commande interactive attend une entrée (prompt `Y/N`, éditeur, pager). Ces
  commandes doivent être lancées en mode **non interactif** (`-NoProfile`,
  `-NonInteractive`, `--yes`, `| cat`, etc.).

## Stratégie de retry
1. **Tentative 1** : lancer la commande avec le timeout adapté.
2. **En cas de timeout** : arrêter proprement le process (utiliser l'action
   `stop` du gestionnaire de process en arrière-plan si lancé ainsi) afin de ne
   pas laisser d'`EXCEL.EXE`, `pwsh.exe` ou autre process orphelin.
3. **Tentative 2 (retry)** : relancer **une seule fois** avec un timeout
   augmenté (environ ×2) et, si possible, une variante plus sûre :
   - Ajouter `-NoProfile -NonInteractive` aux commandes PowerShell.
   - Écrire la logique multi-lignes dans un `.ps1` temporaire sous
     `.temp_ai/<agent>/` et l'exécuter via
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\.temp_ai\<agent>\_run.ps1`
     plutôt qu'en `-Command` inline.
   - Réduire le périmètre (traiter un sous-ensemble, ajouter des logs de
     progression).
4. **Après 2 échecs** : **arrêter d'insister.** Ne pas boucler sur la même
   approche. Diagnostiquer la cause racine (interactivité, verrou de fichier,
   dépendance manquante, ressource réseau injoignable) et proposer à
   l'utilisateur une approche différente ou une exécution manuelle.

## Stabilité des commandes (éviter la ré-autorisation par l'IDE)
L'IDE mémorise les commandes autorisées d'après le **texte de la commande**. Dès
qu'un détail change — nom de variable, **chemin**, valeur d'argument, guillemets,
ordre des options —, l'IDE ne reconnaît plus la commande, **bloque l'exécution**
et redemande une autorisation. La cause la plus fréquente n'est pas le nom des
variables mais **les arguments qui varient** (chemins de fichiers, valeurs). La
règle prioritaire est donc : **la commande vue par l'IDE doit être strictement
identique à chaque appel, sans aucun argument variable.**

### Règle n°1 (à appliquer par défaut) : une seule commande canonique, figée
Router **toute** logique PowerShell non triviale par un script temporaire à
**chemin fixe** dans le sous-dossier de l'agent, **sans passer d'arguments**, et
l'invoquer **toujours avec exactement la même ligne de commande**. Le chemin est
fixe par agent, donc il ne varie pas d'un appel à l'autre :

```
powershell -NoProfile -ExecutionPolicy Bypass -File .\.temp_ai\<agent>\_run.ps1
```

- Le chemin du script ne change **jamais** pour un agent donné
  (`.temp_ai/<agent>/_run.ps1`). Comme il est constant, l'IDE ne redemande pas
  d'autorisation entre deux appels du même agent.
- **Aucun paramètre** n'est passé sur la ligne de commande : tout ce qui varie
  (chemins, valeurs, options) est écrit **à l'intérieur** de `_run.ps1` via
  l'outil d'écriture de fichier. L'IDE ne voit pas le contenu du script, donc la
  commande reste identique d'une exécution à l'autre.
- Workflow type : (1) écrire/écraser `.temp_ai/<agent>/_run.ps1` avec la logique
  du moment, (2) lancer la commande canonique ci-dessus, (3) supprimer le script
  (ou tout `.temp_ai/<agent>/`) après usage.
- Écrire les logs et sorties intermédiaires du script **dans le même
  `.temp_ai/<agent>/`**, jamais à la racine.
- **Ne jamais** mettre un chemin ou une valeur variable directement sur la ligne
  de commande (ni en `-Command "..."`, ni en argument de `-File`). C'est ce qui
  déclenche la ré-autorisation.

### Exception a la Regle n°1 : les generateurs/validateurs fournis par un skill
Quand un skill Kiro (`.kiro/skills/<skill>/assets/scripts/`) fournit deja ses
propres scripts `build-*.ps1` / `validate-*.ps1`, il faut les **appeler
directement** avec `-File` et leurs parametres documentes :

```
powershell -NoProfile -ExecutionPolicy Bypass -File ".kiro\skills\<skill>\assets\scripts\build-xxx.ps1" -Model "<project>_....model.json" -Out "<project>_....docx"
powershell -NoProfile -ExecutionPolicy Bypass -File ".kiro\skills\<skill>\assets\scripts\validate-xxx.ps1" -Docx "<project>_....docx"
```

- **NE PAS** les enrober dans un `_run.ps1` : un wrapper qui reimporte le module
  du skill via un chemin relatif (`Join-Path`, `Import-Module .\...`) peut
  **echouer silencieusement** (exit 0, aucun fichier produit) parce que la
  resolution du `.psm1` depuis l'interieur du wrapper ne pointe pas au bon
  endroit. C'est exactement le piege a eviter.
- Ces scripts sont deja stables (nom fixe, `-NoProfile -ExecutionPolicy Bypass
  -File`) ; seuls les arguments `-Model` / `-Out` / `-Docx` changent. C'est
  acceptable ici : la priorite est que le livrable soit reellement genere et
  valide, et l'auto-approbation peut etre accordee une fois a ces commandes.
- Toujours enchainer par le `validate-*.ps1` du skill et **verifier sa sortie**
  (doit finir par `... VALIDATION OK` et exit 0). Un exit 0 sans ligne de
  confirmation = suspecter un echec silencieux et relancer en direct.

### Règle n°2 : proscrire l'inline `-Command`
Éviter `powershell -Command "<corps qui change>"` : le corps fait partie du texte
de la commande, donc il change à chaque fois et provoque systématiquement une
nouvelle demande d'autorisation. Préférer toujours la Règle n°1.

### Règle n°3 : pour les commandes simples, garder des noms/chemins stables
Pour les commandes courtes qu'on ne peut pas mettre dans un script (`dir`,
`git status`, etc.) :
- Réutiliser les **mêmes noms de variables** génériques et stables :
  - `$src` : chemin source / entrée.
  - `$dst` : chemin destination / sortie.
  - `$app` : objet COM d'application Office (Excel, Word, PowerPoint).
  - `$doc` : document / classeur / présentation ouvert.
  - `$items` : collection en cours de traitement.
  - `$i` : index de boucle.
  - `$result` : valeur de retour / résultat intermédiaire.
- Ne pas renommer ces variables entre deux commandes similaires (même casse, même
  orthographe).
- Garder un **préfixe identique** en tête de commande et ne faire varier que le
  strict nécessaire.

### Si les demandes persistent malgré tout
- Vérifier qu'aucun caractère invisible ou variation de guillemets/casse ne
  s'introduit entre deux appels ; copier-coller la même ligne canonique.
- Proposer à l'utilisateur d'ajouter la commande canonique de l'agent
  (`powershell -NoProfile -ExecutionPolicy Bypass -File .\.temp_ai\<agent>\_run.ps1`)
  à la **liste des commandes de confiance / auto-approuvées** de l'IDE (réglages
  d'autorisation des commandes), pour qu'elle ne soit demandée qu'une seule fois.

## Process longs (serveurs, watchers)
- Ne **jamais** lancer un serveur de dev, un watcher ou une commande interactive
  via l'exécution synchrone : cela bloque l'agent.
- Utiliser le gestionnaire de process en arrière-plan (`start`), puis lire la
  sortie séparément, et `stop` pour nettoyer.

## Nettoyage
- Toujours libérer les objets COM et fermer les applications Office ouvertes par
  automatisation, même en cas d'échec ou de timeout, pour éviter les process
  orphelins qui verrouillent les fichiers.
- Supprimer les scripts `.ps1` temporaires une fois exécutés. En fin de tâche,
  nettoyer le sous-dossier `.temp_ai/<agent>/` de l'agent ; la racine du projet
  ne doit jamais conserver de fichier temporaire.
