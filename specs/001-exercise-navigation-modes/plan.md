# Implementation Plan: Navigation par 3 modes vers les séances d'exercices

**Branch**: `001-exercise-navigation-modes` | **Date**: 2026-08-20 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-exercise-navigation-modes/spec.md`

## Summary

Application mobile de mobilité/assouplissement offrant trois modes d'accès aux exercices
(formule du jour sans choix, zone corporelle, signe de douleur en langage non médical),
avec un espace coach (gestion de contenu) et un espace client (consultation + progression).
Approche technique : une application mobile cross-platform unique (Flutter/Dart) pour
iOS et Android, adossée à un backend-as-a-service relationnel (Supabase/PostgreSQL) qui
porte l'authentification par mot de passe, l'isolation multi-coach via Row Level Security,
le stockage du contenu et la synchronisation de la progression, avec un cache local
permettant l'usage hors-ligne du contenu déjà chargé.

## Technical Context

**Language/Version**: Dart 3.x avec Flutter (dernière version stable au démarrage de
l'implémentation)

**Primary Dependencies**: Flutter SDK (UI cross-platform) ; `supabase_flutter` (client
Supabase — auth, base de données, storage) ; `drift` ou `sqflite` (cache local SQLite
pour l'usage hors-ligne) ; `go_router` (navigation/routage écran) ; `flutter_lints`
(qualité de code)

**Storage**: PostgreSQL managé par Supabase (contenu, comptes, historique de progression)
+ cache local SQLite embarqué sur l'appareil pour le contenu déjà consulté et la
progression enregistrée hors-ligne, synchronisés dès le retour du réseau ; Supabase
Storage pour les médias d'exercice (images/vidéos d'instruction)

**Testing**: `flutter_test` (tests unitaires et de widgets) ; `integration_test`
(parcours de bout en bout sur device/émulateur) ; tests des policies Row Level Security
Supabase via requêtes SQL scénarisées (isolation multi-coach, accès client limité à son
coach)

**Target Platform**: iOS 15+ et Android 8+ (API 26+), via une base de code Flutter unique
partagée entre les deux plateformes (pas d'arborescence ios/ et android/ séparées au-delà
du nécessaire packaging natif Flutter)

**Project Type**: mobile-app + backend-as-a-service (pas de service API custom à
développer/héberger : Supabase fournit l'API générée, l'auth et la base de données ;
le "backend" du projet se limite aux migrations SQL, policies RLS et configuration)

**Performance Goals**: démarrage d'une séance depuis l'ouverture de l'app en moins de
10 secondes (SC-001) ; recherche par zone/signe perçue comme instantanée (retour < 1s sur
réseau normal, contenu déjà en cache local le cas échéant)

**Constraints**: hors-ligne-capable pour le contenu déjà chargé et la progression déjà
enregistrée (Principe IV) ; aucune donnée médicale/sensible traitée (Principe V) ;
secrets (clés Supabase) fournis par configuration d'environnement, jamais committés

**Scale/Scope**: un seul coach opérationnel en V1 avec un nombre modeste de clients
rattachés (dizaines à quelques centaines) ; le modèle de données supporte plusieurs
coachs sans refonte (FR-017), mais aucune fonctionnalité de gestion inter-coachs
(back-office de supervision, etc.) n'est dans le périmètre de cette itération

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principe / Contrainte | Évaluation | Statut |
|---|---|---|
| I. Code Quality & Maintainability | Base de code Flutter unique (pas de duplication iOS/Android) ; lint (`flutter_lints`) et revue de code obligatoires ; architecture en features avec repositories partagés | PASS |
| II. Test-First (NON-NEGOTIABLE) | `flutter_test`/`integration_test` couvrent la logique de séance, progression et isolation multi-coach avant merge ; TDD attendu sur ces chemins | PASS |
| III. UX Consistency | Rendu Flutter propre au moteur (pas de composants natifs divergents par plateforme) garantissant une identité visuelle et des thèmes clair/sombre strictement identiques sur iOS et Android | PASS |
| IV. Performance & Reliability | Cache SQLite local + synchronisation différée assurent la disponibilité hors-ligne du contenu déjà chargé et de la progression déjà enregistrée, sans crash en cas de perte réseau | PASS |
| V. Security & Data Privacy | Auth par mot de passe gérée par Supabase Auth (hachage géré par la plateforme) ; isolation des données par coach via Row Level Security (moindre privilège) ; secrets en configuration d'environnement | PASS |
| Additional Constraints — plateformes/cross-platform | iOS + Android via une unique base Flutter, conforme à l'exigence cross-platform par défaut ; aucune exception native envisagée à ce stade | PASS |
| Additional Constraints — conformité | Aucune donnée médicale/sensible ; aucun régime réglementaire connu ; les pratiques de moindre privilège du Principe V restent appliquées | PASS |

Aucune violation identifiée. La section Complexity Tracking reste vide.

## Project Structure

### Documentation (this feature)

```text
specs/001-exercise-navigation-modes/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository root)

```text
mobile/
├── lib/
│   ├── core/
│   │   ├── theme/            # thèmes clair/sombre, identité "sport intense x nature organique"
│   │   ├── router/           # go_router, garde de rôle coach/client
│   │   └── offline/          # cache local, synchronisation
│   ├── features/
│   │   ├── auth/             # connexion, inscription client, réinitialisation mot de passe
│   │   ├── daily_formula/    # mode 1 : formule du jour
│   │   ├── body_zone/        # mode 2 : choix par zone corporelle
│   │   ├── pain_sign/        # mode 3 : choix par signe de douleur
│   │   ├── coach_content/    # espace coach : exercices, séances, associations, formule du jour
│   │   └── progress/         # historique et régularité côté client
│   └── data/
│       ├── models/           # entités (Exercice, Séance, Coach, etc.)
│       └── repositories/     # accès Supabase + cache local, un repository par entité
└── test/
    ├── unit/
    ├── widget/
    └── integration/

backend/
└── supabase/
    ├── migrations/            # schéma SQL : tables + policies RLS d'isolation multi-coach
    ├── seed/                  # données de démonstration pour le développement local
    └── config.toml            # configuration du projet Supabase local (Supabase CLI)
```

**Structure Decision**: Application mobile cross-platform unique (`mobile/`, Flutter) plus
configuration backend-as-a-service versionnée (`backend/supabase/`, migrations et policies
RLS). Pas de service API custom séparé à ce stade : Supabase expose directement les
données au client mobile via des policies RLS scoping chaque requête au coach/client
authentifié, ce qui couvre FR-017/FR-021 (isolation multi-coach) sans code serveur
supplémentaire à maintenir.

## Complexity Tracking

> Aucune violation de la Constitution Check ci-dessus — section laissée vide.
