# Phase 0 Research: Navigation par 3 modes vers les séances d'exercices

## 1. Framework mobile cross-platform

**Decision**: Flutter (Dart) comme base de code unique pour iOS et Android.

**Rationale**: La constitution (v1.1.0, Additional Constraints) impose une approche
cross-platform par défaut, justifiée par les Principes I (maintenabilité — éviter deux
codebases natives dupliquées) et III (une identité UI unique). Flutter dessine ses propres
widgets avec son propre moteur de rendu plutôt que de s'appuyer sur les composants natifs
de chaque plateforme : l'identité visuelle personnalisée demandée ("sport intense" x
"nature organique", thèmes clair/sombre) rendra donc de façon strictement identique sur
iOS et Android, sans divergences de rendu spécifiques à la plateforme. Le support du mode
hors-ligne (Principe IV) est également mature dans l'écosystème Flutter (SQLite via
`drift`/`sqflite`).

**Alternatives considered**:
- **React Native** : cross-platform également, écosystème plus large, mais s'appuie
  davantage sur des composants natifs par plateforme pour un rendu "idiomatique" — plus
  de risque de divergence visuelle fine entre iOS et Android pour une identité graphique
  personnalisée poussée. Rejeté pour privilégier la cohérence UI stricte exigée par le
  Principe III.
- **Natif séparé (Swift/Kotlin)** : écarté d'emblée par la contrainte constitutionnelle
  cross-platform-par-défaut ; aurait doublé l'effort de maintenance sans bénéfice
  identifié pour cette fonctionnalité (aucune capacité native spécifique requise par le
  spec : pas de traitement temps réel poussé, pas d'accès matériel avancé).

## 2. Backend & authentification

**Decision**: Supabase (PostgreSQL managé + Auth) comme backend-as-a-service. Les vidéos
de démonstration des exercices sont hébergées sur YouTube (URL stockée en base) plutôt
que dans Supabase Storage — décision détaillée dans `data-model.md` (entité `exercise`).

**Rationale**: Le besoin (comptes coach/client avec mot de passe + réinitialisation par
email, données relationnelles multi-coach avec relations plusieurs-à-plusieurs
exercice↔zone↔signe, stockage de médias d'exercice, synchronisation de progression) est
bien couvert par une base relationnelle avec authentification intégrée. Supabase fournit :
Auth email/mot de passe avec flux de réinitialisation par email prêt à l'emploi (couvre
FR-019/FR-020 sans développement custom), PostgreSQL avec Row Level Security pour
l'isolation par coach (FR-017/FR-021) directement au niveau des policies plutôt qu'en
code applicatif. Cela évite de construire et
d'opérer un service API custom pour une V1 à périmètre encore modeste (Principe I —
ne pas complexifier au-delà du nécessaire).

**Alternatives considered**:
- **Firebase (Firestore)** : Auth équivalente disponible, mais modèle de données NoSQL
  moins naturel pour les relations plusieurs-à-plusieurs du domaine (exercice↔zone↔signe,
  séance↔exercice) et pour l'isolation multi-coach, qui demanderait davantage de
  dénormalisation et de logique applicative manuelle pour rester cohérente. Rejeté au
  profit du modèle relationnel + RLS, plus direct pour ce cas.
- **Backend custom (ex. Node/NestJS + PostgreSQL, hébergé séparément)** : offre un
  contrôle total, mais ajoute un service à concevoir, tester, déployer et opérer pour un
  gain non justifié à ce stade (aucune règle métier ne dépasse ce qu'une policy RLS ou une
  fonction Postgres peut exprimer). À reconsidérer si une logique serveur significative
  apparaît plus tard (ex. calcul de recommandations complexe) — pas un choix figé de façon
  irréversible, simplement le point de départ le plus simple qui couvre le besoin actuel.

## 3. Isolation des données multi-coach

**Decision**: Isolation appliquée par Row Level Security (RLS) PostgreSQL, avec une
colonne `coach_id` sur chaque table de contenu (exercices, séances, zones, signes de
douleur, formule du jour) et une policy limitant chaque lecture/écriture au `coach_id`
du compte authentifié (coach) ou au `coach_id` associé au compte client authentifié.

**Rationale**: Répond directement à FR-017 (support multi-coach dès la conception sans
refonte) et FR-021 (client limité au contenu de son coach). Appliquer l'isolation au
niveau base de données plutôt qu'uniquement côté client mobile est requis par le Principe
V (moindre privilège) : un client mal intentionné ne doit pas pouvoir contourner un simple
filtre d'interface pour lire le contenu d'un autre coach.

**Alternatives considered**:
- **Isolation uniquement côté application (filtrage dans le code mobile)** : rejetée,
  car elle ne constitue pas une garantie de sécurité réelle (un client peut interroger
  l'API sous-jacente directement) et violerait le Principe V.
- **Une base de données séparée par coach** : offrirait une isolation physique plus
  forte, mais complexifierait significativement les migrations, le provisioning et les
  requêtes agrégées futures pour un bénéfice non justifié tant qu'un seul coach est
  opérationnel (Principe I — YAGNI). Reconsidérable si le nombre de coachs et les
  exigences d'isolation croissent fortement.

## 4. Mode hors-ligne et synchronisation

**Decision**: Cache local SQLite (`drift`) sur l'appareil pour le contenu déjà consulté
(exercices, séances, formule du jour du jour courant) et pour les séances suivies
enregistrées hors-ligne, avec synchronisation vers Supabase dès le retour de la
connectivité réseau.

**Rationale**: Le Principe IV impose que le contenu déjà chargé et la progression déjà
enregistrée restent utilisables hors-ligne. Un cache local avec file de synchronisation
différée est le patron standard pour ce besoin sur mobile et reste simple à raisonner
(pas de résolution de conflits complexe attendue : la progression est un flux d'ajout,
pas une donnée éditée concurremment).

**Alternatives considered**:
- **Aucun cache, tout dépendant du réseau** : rejeté, viole directement le Principe IV et
  l'edge case déjà identifié dans la spec sur la perte de réseau.
- **Synchronisation bidirectionnelle complète avec résolution de conflits (CRDT, etc.)** :
  écarté comme sur-ingénierie pour ce périmètre — la progression est ajoutée par un seul
  client à la fois, aucun scénario multi-appareil simultané n'est dans la spec.

## Résumé — NEEDS CLARIFICATION résolus

Aucun `NEEDS CLARIFICATION` ne subsiste dans le Technical Context du plan : les quatre
décisions ci-dessus couvrent le langage/framework, le stockage, l'authentification et la
stratégie hors-ligne requis pour passer à la Phase 1.
