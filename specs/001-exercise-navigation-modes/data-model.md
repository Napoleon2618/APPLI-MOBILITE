# Phase 1 Data Model: Navigation par 3 modes vers les séances d'exercices

Modèle relationnel (PostgreSQL/Supabase). Toutes les tables de contenu portent un
`coach_id` pour l'isolation multi-coach (FR-017, FR-021), appliquée via policies RLS
(voir `research.md` §3 et `contracts/data-access.md`).

## Entités

### coach
Représente un compte coach (rôle admin/contenu), propriétaire d'un espace de contenu qui
lui est propre.

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | référence l'identité auth Supabase (1-1 avec le compte utilisateur) |
| display_name | text | requis |
| created_at | timestamptz | requis, défaut now() |

### client
Représente un compte client (rôle consultation), rattaché à un unique coach (FR-021).

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | référence l'identité auth Supabase (1-1 avec le compte utilisateur) |
| coach_id | uuid (FK → coach.id) | requis, non modifiable après rattachement initial |
| display_name | text | requis |
| created_at | timestamptz | requis, défaut now() |

**Relation**: un `client` appartient à exactement un `coach` (Assumptions — pas de
rattachement à plusieurs coachs dans ce périmètre).

### invite_code (code d'invitation)
Jeton généré par un coach, permettant à un client de s'inscrire en se rattachant
automatiquement à ce coach (FR-022, mécanisme a).

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | |
| coach_id | uuid (FK → coach.id) | requis |
| code | text (unique) | requis, court identifiant à saisir par le client à l'inscription |
| created_at | timestamptz | requis, défaut now() |
| used_at | timestamptz | nullable ; renseigné à la première utilisation (usage unique) |
| used_by_client_id | uuid (FK → client.id) | nullable ; client créé via ce code |

**Note — deux parcours de rattachement (FR-022)**: le rattachement d'un client à un coach
se fait par l'un des deux mécanismes suivants, tous deux à conserver :

1. **Code d'invitation** : le client crée son propre compte (email + mot de passe, via
   l'inscription standard Supabase Auth, un appel non authentifié classique), puis, une
   fois sa session ouverte, appelle une fonction Postgres dédiée (`redeem_invite_code`,
   `SECURITY DEFINER`) qui valide le code (existe, non utilisé, coach actif), crée la
   ligne `client` avec le `coach_id` du code, et marque le code utilisé. Ce détour par une
   fonction serveur (plutôt qu'un `INSERT` direct sur `client`) est nécessaire pour valider
   le code de façon fiable sans exposer aux clients la possibilité d'écrire un `coach_id`
   arbitraire.
2. **Création directe par le coach** : un coach ne peut pas créer un autre compte
   utilisateur Supabase Auth depuis l'application mobile (cela nécessite la clé de service
   Supabase, qui ne doit jamais être embarquée dans l'app — Principe V). Ce parcours passe
   donc par une Supabase Edge Function serveur (`create-client-account`), qui vérifie que
   l'appelant authentifié est bien un coach, crée le compte Auth du client avec un mot de
   passe provisoire fourni par le coach, puis crée la ligne `client` avec `coach_id`
   directement égal à celui du coach appelant. La clé de service reste uniquement dans
   l'environnement serveur de la fonction, jamais dans le client mobile.

### body_zone (zone corporelle)
Catégorie de localisation anatomique définie par un coach (ex. dos, épaules, hanches).

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | |
| coach_id | uuid (FK → coach.id) | requis |
| label | text | requis, non médical par nature (nom de zone, pas de terme clinique) |
| created_at | timestamptz | requis, défaut now() |

### pain_sign (signe de douleur)
Formulation en langage courant décrivant une gêne, définie par un coach dans une liste
prédéfinie (FR-016) — pas de saisie libre côté client.

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | |
| coach_id | uuid (FK → coach.id) | requis |
| label | text | requis ; DOIT être en langage courant, non clinique (FR-009) — contrôlé en
revue de contenu coach, pas par une contrainte technique automatisée |
| created_at | timestamptz | requis, défaut now() |

### exercise (exercice)
Unité de contenu de mobilité/assouplissement créée par un coach.

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | |
| coach_id | uuid (FK → coach.id) | requis |
| name | text | requis |
| description | text | requis |
| instructions | text | requis (déroulé d'exécution) |
| youtube_video_url | text | optionnel ; URL d'une vidéo YouTube hébergée sur YouTube (pas
de fichier vidéo stocké dans Supabase Storage — voir note ci-dessous) |
| archived_at | timestamptz | nullable ; renseigné quand le coach "supprime" un exercice
déjà référencé par un historique de progression (FR-023) — voir note ci-dessous |
| created_at | timestamptz | requis, défaut now() |
| updated_at | timestamptz | requis, défaut now(), mis à jour à chaque modification |

**Note — suppression = archivage conditionnel (FR-023)**: quand un coach supprime un
exercice, le système vérifie s'il est référencé par au moins une ligne `session_log` (via
`session_exercise` de la séance suivie). S'il ne l'est pas, la suppression est une
suppression définitive classique (`DELETE`). S'il l'est, la suppression pose
`archived_at = now()` au lieu d'un `DELETE` (pas de suppression physique, pas de cascade
destructive sur `session_log`/`session_exercise`/`exercise_body_zone`/
`exercise_pain_sign`). Un exercice archivé DOIT être exclu de toutes les listes actives
(zones, signes, création/édition de séance, formule du jour, les trois modes de
navigation client) mais reste lisible depuis l'historique de progression d'un client qui
l'a suivi.

**Note — hébergement vidéo**: la démonstration vidéo d'un exercice est hébergée sur
YouTube ; seule l'URL est stockée côté application (`youtube_video_url`), lue par un
lecteur/embed YouTube côté client. Aucun fichier vidéo n'est téléversé dans Supabase
Storage pour ce champ (Storage reste disponible pour d'éventuels autres médias, ex.
images, mais n'est plus dans le périmètre du contenu vidéo d'exercice). Ce choix évite
les coûts de stockage/bande passante vidéo et la mise en place d'un pipeline
d'encodage/streaming, au prix d'une dépendance à la disponibilité de YouTube et à une
connexion réseau active pour la lecture (la vidéo elle-même n'est donc pas disponible
hors-ligne, contrairement au texte de `instructions`, qui reste consultable via le cache
local — cf. Principe IV).

### exercise_body_zone (association N↔N)
| Champ | Type | Règles |
|---|---|---|
| exercise_id | uuid (FK → exercise.id) | requis |
| body_zone_id | uuid (FK → body_zone.id) | requis |

Contrainte : `exercise.coach_id` DOIT être égal à `body_zone.coach_id` (un exercice ne
s'associe qu'à des zones du même coach) — appliquée par policy RLS/contrainte applicative.

### exercise_pain_sign (association N↔N)
| Champ | Type | Règles |
|---|---|---|
| exercise_id | uuid (FK → exercise.id) | requis |
| pain_sign_id | uuid (FK → pain_sign.id) | requis |

Même contrainte de cohérence de `coach_id` que ci-dessus.

### session (séance)
Ensemble ordonné d'exercices, créé par un coach.

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | |
| coach_id | uuid (FK → coach.id) | requis |
| name | text | requis |
| created_at | timestamptz | requis, défaut now() |

### session_exercise (association ordonnée N↔N)
| Champ | Type | Règles |
|---|---|---|
| session_id | uuid (FK → session.id) | requis |
| exercise_id | uuid (FK → exercise.id) | requis |
| position | integer | requis, ordre d'exécution dans la séance |

Contrainte de cohérence de `coach_id` identique aux associations ci-dessus.

### daily_formula (formule du jour)
Association entre une date et une séance d'un coach donné (FR-006).

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | |
| coach_id | uuid (FK → coach.id) | requis |
| session_id | uuid (FK → session.id) | requis, DOIT appartenir au même coach |
| date | date | requis |

Contrainte : unicité de (`coach_id`, `date`) — une seule formule du jour par coach et par
date.

### session_log (séance suivie / historique)
Enregistrement qu'un client a suivi une séance à une date donnée (FR-013), base du calcul
de progression et de régularité.

| Champ | Type | Règles |
|---|---|---|
| id | uuid (PK) | |
| client_id | uuid (FK → client.id) | requis |
| session_id | uuid (FK → session.id) | requis |
| completed_at | timestamptz | requis, défaut now() |
| source_mode | text | requis, un de `daily_formula` / `body_zone` / `pain_sign` — mode
de navigation ayant conduit à cette séance suivie, utile pour analyse produit ultérieure |

## Diagramme des relations (résumé)

```text
coach 1───N client
coach 1───N invite_code
coach 1───N body_zone
coach 1───N pain_sign
coach 1───N exercise
coach 1───N session
coach 1───N daily_formula

exercise N───N body_zone   (via exercise_body_zone)
exercise N───N pain_sign   (via exercise_pain_sign)
session  N───N exercise    (via session_exercise, avec position)
daily_formula N───1 session

client 1───N session_log
session 1───N session_log
invite_code 0───1 client   (used_by_client_id, une fois utilisé)
```

## Règles de validation issues des exigences

- Un `client` ne DOIT voir (lecture) que les lignes `body_zone`, `pain_sign`, `exercise`,
  `session`, `daily_formula` dont `coach_id` correspond à son propre `coach_id` (FR-021).
- Un `coach` ne DOIT voir/modifier que ses propres lignes de contenu (FR-002 à FR-006,
  FR-017) — jamais celles d'un autre coach.
- `pain_sign.label` DOIT rester un texte non clinique (FR-009) — géré par une consigne de
  contenu côté coach plutôt qu'une validation technique (le langage courant n'est pas
  formellement vérifiable côté système).
- Une tentative de recherche par `body_zone` ou `pain_sign` sans exercice associé DOIT
  renvoyer un résultat vide explicite (pas d'erreur) pour permettre l'état "message clair"
  requis par FR-015/US3/US4.
- Toute lecture d'`exercise` dans un contexte de liste active (zones, signes, création de
  séance, formule du jour, navigation client) DOIT exclure les lignes où
  `archived_at IS NOT NULL` (FR-023).
- Un code d'`invite_code` DOIT être rejeté par `redeem_invite_code` s'il est déjà utilisé
  (`used_at IS NOT NULL`) ou inexistant.

## État / transitions

Les entités de contenu (session, body_zone, pain_sign) suivent un cycle de vie CRUD simple
(créé → modifié → supprimé) piloté par le coach, sans machine à états. `exercise` a un
état supplémentaire lié à sa suppression : actif (`archived_at IS NULL`) → soit supprimé
définitivement (si non référencé par un historique), soit archivé (`archived_at` renseigné,
si référencé) — l'archivage est terminal, un exercice archivé n'est pas
désarchivable dans le périmètre de cette spécification. `session_log` est en écriture
seule après création (une séance suivie n'est pas modifiée rétroactivement). `invite_code`
passe de non-utilisé (`used_at IS NULL`) à utilisé (`used_at` renseigné) une seule fois,
de façon irréversible.
