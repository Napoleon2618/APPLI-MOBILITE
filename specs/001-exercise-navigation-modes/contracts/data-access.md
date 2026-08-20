# Contract: Accès aux données de contenu (Row Level Security)

Supabase expose une API REST/temps réel générée automatiquement à partir du schéma
PostgreSQL (voir `data-model.md`). Le "contrat" applicatif pour ce projet est donc
principalement porté par les policies RLS ci-dessous, plutôt que par des endpoints
custom : elles définissent ce que chaque rôle authentifié peut lire ou écrire.

## Policies par table

### coach
- Un coach authentifié peut lire/modifier sa propre ligne (`id = auth.uid()`).
- Un client authentifié peut lire uniquement le `display_name` du coach auquel il est
  rattaché (pas d'accès aux autres coachs).

### client
- Un client authentifié peut lire/modifier sa propre ligne (`id = auth.uid()`).
- Un coach authentifié peut lire les lignes `client` dont `coach_id = auth.uid()`
  (ses propres clients uniquement) ; écriture limitée aux champs de gestion de compte
  pertinents (pas de changement de `coach_id` après création — FR-021).

### invite_code
- **Lecture/Écriture (INSERT)** : un coach authentifié peut créer et lire ses propres
  codes (`coach_id = auth.uid()`) uniquement.
- Aucun accès direct en lecture/écriture pour un client authentifié ou un utilisateur non
  authentifié : la validation/consommation d'un code passe exclusivement par la fonction
  `redeem_invite_code` (`SECURITY DEFINER`, voir `data-model.md` et `auth.md`), jamais par
  un `SELECT`/`UPDATE` direct sur la table.

### body_zone, pain_sign, exercise, session, daily_formula
Pour chacune de ces tables (toutes portant `coach_id`) :
- **Lecture (SELECT)** : autorisée si `coach_id = auth.uid()` (coach propriétaire) OU
  `coach_id = (SELECT coach_id FROM client WHERE id = auth.uid())` (client rattaché à ce
  coach). Couvre FR-021 (isolation multi-coach côté client) et US2 scénario 5. Pour
  `exercise` spécifiquement, toute lecture dans un contexte de liste active DOIT en outre
  filtrer `archived_at IS NULL` (FR-023) — seule une consultation d'historique
  (`session_log` → `session_exercise` → `exercise`) peut renvoyer un exercice archivé.
- **Écriture (INSERT/UPDATE/DELETE)** : autorisée uniquement si `coach_id = auth.uid()`
  ET l'utilisateur authentifié a le rôle coach. Couvre FR-010 (un client ne peut pas
  accéder aux fonctions de gestion de contenu). Pour `exercise` spécifiquement, un
  `DELETE` initié par le coach DOIT être intercepté côté application (ou par un trigger) :
  s'il existe une ligne `session_log` référençant cet exercice via `session_exercise`, le
  `DELETE` est remplacé par un `UPDATE ... SET archived_at = now()` (FR-023) plutôt
  qu'exécuté tel quel.

### exercise_body_zone, exercise_pain_sign, session_exercise (tables d'association)
- Mêmes règles que ci-dessus, appliquées via jointure sur le `coach_id` de l'entité
  parente (`exercise.coach_id` ou `session.coach_id`).
- Contrainte de cohérence supplémentaire (vérifiée en écriture) : les deux entités liées
  par une association DOIVENT partager le même `coach_id` — un coach ne peut pas associer
  un de ses exercices à une zone/un signe d'un autre coach.

### session_log
- **Lecture** : un client authentifié ne lit que ses propres lignes
  (`client_id = auth.uid()`). Un coach authentifié peut lire les lignes des clients qui
  lui sont rattachés (`client_id IN (SELECT id FROM client WHERE coach_id = auth.uid())`),
  pour un usage de suivi futur hors périmètre immédiat mais permis par le modèle.
- **Écriture (INSERT)** : un client authentifié ne peut créer une ligne que pour
  lui-même (`client_id = auth.uid()`) et pour une `session` appartenant à son coach.
  Pas d'UPDATE/DELETE côté client (écriture seule après création — cf. data-model.md).

## Recherche "sans résultat" (FR-015)

Les requêtes de navigation par zone (`body_zone` → `exercise` via
`exercise_body_zone`) et par signe de douleur (`pain_sign` → `exercise` via
`exercise_pain_sign`) DOIVENT renvoyer un ensemble vide (pas d'erreur) quand aucun
exercice n'est associé, pour permettre à l'application d'afficher l'état "message clair"
requis par la spec plutôt qu'un état d'erreur.
