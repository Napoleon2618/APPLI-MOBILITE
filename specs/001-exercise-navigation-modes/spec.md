# Feature Specification: Navigation par 3 modes vers les séances d'exercices

**Feature Branch**: `001-exercise-navigation-modes`

**Created**: 2026-08-20

**Status**: Draft

**Input**: User description: "Application mobile de mobilité/assouplissement physique avec 3 modes de navigation pour accéder au contenu d'exercices : (1) Formule journalière prête à suivre, (2) Choix par zone corporelle, (3) Choix par signe/localisation de douleur en langage non médical. Deux rôles : le coach (admin/contenu) et les clients/patients (consultation). Design : mode clair/sombre au choix, esthétique entre 'sport intense' et 'nature organique', gamification modérée (progression visible, sans surenchère de badges)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Suivre la formule du jour (Priority: P1)

Un client ouvre l'application et veut s'entraîner tout de suite, sans avoir à réfléchir à quoi que ce soit. L'application lui propose directement une séance du jour, prête à suivre.

**Why this priority**: C'est la promesse centrale du produit — l'effort zéro pour démarrer une séance. C'est le chemin le plus court vers la valeur et la fonctionnalité qui doit fonctionner dès la première version livrable.

**Independent Test**: Peut être testé en ouvrant l'application avec un compte client et du contenu déjà configuré par le coach, puis en vérifiant qu'une séance du jour est affichée et peut être suivie du début à la fin sans étape de sélection intermédiaire.

**Acceptance Scenarios**:

1. **Given** un client ouvre l'application un jour donné, **When** il accède à l'écran d'accueil, **Then** une séance du jour est déjà proposée, sans qu'il ait à faire un choix pour l'obtenir.
2. **Given** une séance du jour affichée, **When** le client démarre la séance, **Then** il peut dérouler tous les exercices de la séance jusqu'à la fin et voir une confirmation de séance terminée.
3. **Given** un client revient un autre jour, **When** il accède à l'écran d'accueil, **Then** la séance proposée peut différer de celle du jour précédent.

---

### User Story 2 - Gérer le contenu en tant que coach (Priority: P2)

Le coach crée et organise les exercices, les séances, les associations zone/signe ↔ exercices, ainsi que la formule du jour, afin que les clients aient toujours du contenu pertinent à suivre.

**Why this priority**: Sans contenu créé par le coach, aucun des trois modes de navigation client n'a de contenu à afficher. C'est un prérequis fonctionnel bloquant pour toute valeur livrée aux clients.

**Independent Test**: Peut être testé en se connectant avec un rôle coach, en créant un exercice, en l'associant à une zone corporelle et à un signe de douleur, en l'incluant dans une séance, puis en désignant cette séance comme formule du jour — sans dépendre d'une action côté client.

**Acceptance Scenarios**:

1. **Given** un coach connecté, **When** il crée un nouvel exercice avec son contenu descriptif, **Then** l'exercice est enregistré et disponible pour être ajouté à une ou plusieurs séances.
2. **Given** un exercice existant, **When** le coach l'associe à une ou plusieurs zones corporelles et à un ou plusieurs signes de douleur, **Then** ces associations sont enregistrées et utilisées par les modes de navigation 2 et 3 côté client.
3. **Given** une séance existante, **When** le coach la désigne comme formule du jour pour une date donnée, **Then** cette séance est celle proposée aux clients à cette date via le mode "Formule journalière".
4. **Given** un client connecté (rôle consultation), **When** il tente d'accéder à un écran de création ou modification de contenu, **Then** l'accès lui est refusé.

---

### User Story 3 - Explorer les exercices par zone corporelle (Priority: P3)

Un client souhaite travailler une zone du corps en particulier (par exemple le dos ou les hanches). Il sélectionne cette zone et l'application lui propose des exercices ciblés.

**Why this priority**: Complète la formule du jour par un accès dirigé, pour les clients qui savent déjà quelle zone travailler. Nécessite le contenu et les associations créées en P2.

**Independent Test**: Peut être testé en sélectionnant une zone corporelle dans la liste proposée et en vérifiant que seuls des exercices associés à cette zone par le coach sont affichés.

**Acceptance Scenarios**:

1. **Given** un client sur l'écran de navigation par zone, **When** il sélectionne une zone corporelle, **Then** la liste des exercices associés à cette zone s'affiche.
2. **Given** une zone corporelle sans exercice associé, **When** le client la sélectionne, **Then** un message clair indique l'absence de contenu pour cette zone plutôt qu'une liste vide sans explication.
3. **Given** une liste d'exercices pour une zone, **When** le client sélectionne un exercice, **Then** il peut consulter son détail et l'exécuter comme dans une séance.

---

### User Story 4 - Explorer les exercices par signe de douleur (Priority: P4)

Un client a une douleur à un endroit précis et souhaite trouver des exercices adaptés. Il choisit, dans une liste de formulations courantes définie par le coach (par exemple "douleur au coude"), celle qui correspond le mieux à sa gêne, sans avoir besoin de connaître un terme médical ni de le saisir lui-même.

**Why this priority**: Répond à un besoin plus spécifique que la navigation par zone, pour des clients en situation de gêne ou de douleur précise. Dépend du même contenu que P3, avec un vocabulaire d'entrée différent et volontairement non clinique.

**Independent Test**: Peut être testé en sélectionnant un signe de douleur dans la liste non médicale proposée et en vérifiant que les exercices affichés correspondent à ceux associés à ce signe par le coach, sans qu'aucun terme médical/clinique n'apparaisse dans le parcours de sélection.

**Acceptance Scenarios**:

1. **Given** un client sur l'écran de navigation par signe de douleur, **When** il sélectionne dans la liste proposée le signe correspondant à sa douleur, **Then** l'application propose des exercices associés à ce signe.
2. **Given** un signe de douleur indiqué par le client, **When** aucun exercice n'y est associé, **Then** un message clair l'indique et suggère une alternative (par exemple explorer par zone corporelle ou consulter la formule du jour).
3. **Given** le parcours de navigation par signe de douleur, **When** un client le consulte, **Then** aucun terme médical/clinique (ex. noms de pathologies) n'apparaît dans les libellés proposés.

---

### User Story 5 - Suivre sa progression (Priority: P5)

Un client veut voir qu'il progresse dans le temps : les séances suivies et sa régularité, sans être submergé par des récompenses ou des badges.

**Why this priority**: Renforce la fidélisation une fois les parcours principaux en place ; n'est pas nécessaire au fonctionnement des trois modes de navigation eux-mêmes.

**Independent Test**: Peut être testé en complétant plusieurs séances sur plusieurs jours puis en vérifiant qu'un résumé de régularité et d'historique des séances suivies est consultable par le client.

**Acceptance Scenarios**:

1. **Given** un client ayant terminé une ou plusieurs séances, **When** il consulte son profil ou son tableau de progression, **Then** il voit le nombre de séances suivies et un indicateur de régularité (par exemple une série de jours consécutifs ou une fréquence récente).
2. **Given** l'affichage de la progression, **When** le client le consulte, **Then** il ne voit pas un nombre excessif d'éléments de gamification (pas de multiplication de badges/récompenses) — la progression reste lisible en un coup d'œil.

---

### Edge Cases

- Que se passe-t-il si le coach n'a pas encore désigné de formule du jour pour la date en cours ? Le client doit voir un état explicite (par exemple une proposition de repli ou un message clair) plutôt qu'un écran vide ou une erreur.
- Comment le système gère-t-il un exercice supprimé par le coach alors qu'il fait déjà partie d'une séance en cours de suivi côté client, ou d'une séance passée dans l'historique de progression d'un client ?
- Que se passe-t-il si un client sélectionne à la fois une zone corporelle et un signe de douleur qui, ensemble, ne renvoient aucun exercice commun ?
- Comment l'application se comporte-t-elle en l'absence de connexion réseau pour un client qui a déjà consulté du contenu précédemment (formule du jour, séance en cours) ?
- Que se passe-t-il si un coach modifie ou supprime une séance pendant qu'un client est en train de la suivre activement ?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT proposer à chaque client, sans action de sélection de sa part, une séance du jour prête à être suivie (mode "Formule journalière").
- **FR-002**: Le système DOIT permettre au coach de créer, modifier et supprimer des exercices (contenu descriptif de l'exercice).
- **FR-003**: Le système DOIT permettre au coach de créer, modifier et supprimer des séances composées d'un ou plusieurs exercices.
- **FR-004**: Le système DOIT permettre au coach d'associer un ou plusieurs exercices à une ou plusieurs zones corporelles.
- **FR-005**: Le système DOIT permettre au coach d'associer un ou plusieurs exercices à un ou plusieurs signes/localisations de douleur exprimés en langage courant, non médical.
- **FR-006**: Le système DOIT permettre au coach de désigner une séance existante comme formule du jour pour une date donnée.
- **FR-007**: Le système DOIT permettre à un client de sélectionner une zone corporelle parmi une liste proposée et d'obtenir en retour les exercices associés à cette zone (mode "Choix par zone corporelle").
- **FR-008**: Le système DOIT permettre à un client d'indiquer un signe de douleur en langage courant et d'obtenir en retour les exercices associés à ce signe (mode "Choix par signe de douleur").
- **FR-009**: Le vocabulaire présenté au client dans le mode "Choix par signe de douleur" DOIT être non médical et compréhensible sans connaissance clinique (par exemple "douleur au coude" plutôt qu'un terme diagnostique).
- **FR-010**: Le système DOIT distinguer deux rôles utilisateur — coach (création/gestion de contenu) et client (consultation et suivi de séances) — et DOIT empêcher un utilisateur au rôle client d'accéder aux fonctions de création/gestion de contenu réservées au coach.
- **FR-011**: Le système DOIT permettre à l'utilisateur de choisir entre un mode d'affichage clair et un mode d'affichage sombre.
- **FR-012**: L'identité visuelle du système DOIT combiner des éléments associés à une esthétique "sport intense" (contrastes marqués, typographie affirmée) et des éléments associés à une esthétique "nature organique" (tons terreux, courbes douces), plutôt que de retenir l'une des deux directions de façon exclusive.
- **FR-013**: Le système DOIT enregistrer, pour chaque client, l'historique des séances suivies afin d'en tirer un indicateur de régularité et un décompte de séances suivies.
- **FR-014**: Le système DOIT présenter la progression du client (séances suivies, régularité) de façon synthétique et lisible en un coup d'œil, sans multiplier les éléments de gamification (pas de système extensif de badges/récompenses).
- **FR-015**: Le système DOIT afficher un état explicite (message clair) lorsqu'un mode de navigation (formule du jour, zone corporelle, signe de douleur) ne peut renvoyer aucun contenu, plutôt que de laisser un écran vide.

- **FR-016**: Le client DOIT indiquer son signe de douleur en sélectionnant une formulation dans une liste prédéfinie de signes courants, non médicaux, gérée par le coach — pas de saisie libre en texte.
- **FR-017**: Le contenu (exercices, séances, associations zone/signe, formule du jour) DOIT être géré par un unique coach et DOIT être visible par l'ensemble des clients de l'application (modèle mono-coach/cabinet ; pas de contenu séparé par coach).
- **FR-018**: Un client DOIT disposer d'un compte utilisateur avec identifiants pour accéder à l'application ; son historique de progression DOIT être associé à ce compte et rester accessible depuis un nouvel appareil après connexion.

### Key Entities

- **Exercice**: Unité de contenu de mobilité/assouplissement créée par un coach (nom, description, instructions d'exécution). Peut être associé à plusieurs zones corporelles et plusieurs signes de douleur, et peut appartenir à plusieurs séances.
- **Séance**: Ensemble ordonné d'exercices, créé par un coach. Peut être désignée comme formule du jour pour une ou plusieurs dates.
- **Formule du jour**: Association entre une date et une séance, déterminant ce qui est proposé aux clients dans le mode "Formule journalière" pour cette date.
- **Zone corporelle**: Catégorie de localisation anatomique (ex. dos, épaules, hanches, genoux, chevilles) utilisée pour cibler des exercices dans le mode "Choix par zone corporelle".
- **Signe de douleur**: Formulation en langage courant décrivant une gêne ou douleur (ex. "douleur au coude", "tiraillement dans le bas du dos"), définie et gérée par le coach dans une liste prédéfinie, utilisée pour cibler des exercices dans le mode "Choix par signe de douleur".
- **Séance suivie (historique)**: Enregistrement qu'un client donné a suivi une séance donnée à une date donnée, utilisé pour calculer la progression et la régularité.
- **Compte utilisateur**: Identité authentifiée d'un coach ou d'un client, associée à son rôle et, pour un client, à son historique de progression (retrouvable après connexion depuis un nouvel appareil).
- **Utilisateur**: Personne utilisant l'application, avec un rôle coach (gestion de contenu) ou client (consultation et suivi).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un client peut démarrer une séance depuis l'ouverture de l'application en moins de 10 secondes via la formule du jour, sans étape de sélection intermédiaire.
- **SC-002**: Au moins 90 % des tentatives de recherche par zone corporelle ou par signe de douleur renvoient au moins un exercice pertinent, lorsque le coach a couvert cette zone/ce signe dans son contenu.
- **SC-003**: Un coach peut créer un exercice, l'associer à une zone corporelle et à un signe de douleur, et l'intégrer à une séance en moins de 5 minutes au total.
- **SC-004**: Un client peut consulter son nombre de séances suivies et un indicateur de régularité en un seul écran, sans navigation supplémentaire.
- **SC-005**: Aucun terme médical/clinique n'apparaît dans les libellés du parcours "Choix par signe de douleur", vérifié par relecture du contenu proposé aux clients.
- **SC-006**: Un utilisateur peut basculer entre mode clair et mode sombre en une seule action, et ce choix est conservé lors des ouvertures suivantes de l'application.

## Assumptions

- L'application est utilisée par un public grand public non médical côté client ; le contenu n'est ni un diagnostic ni un avis médical, seulement des propositions d'exercices de mobilité/assouplissement.
- Les zones corporelles proposées couvrent un ensemble standard de zones courantes en mobilité/assouplissement (ex. nuque, épaules, dos, hanches, genoux, chevilles, poignets) ; la liste exacte est définie et modifiable par le coach via la gestion de contenu, non figée dans cette spécification.
- Un exercice, une zone corporelle et un signe de douleur peuvent avoir des relations plusieurs-à-plusieurs (un exercice peut couvrir plusieurs zones/signes, une zone/un signe peut être couvert par plusieurs exercices).
- La formule du jour est définie par le coach à l'avance (elle n'est pas générée automatiquement par un algorithme de recommandation dans le périmètre de cette spécification) ; comment le coach la programme précisément (ex. calendrier manuel ou rotation) reste un détail de gestion de contenu ouvert.
- Le mode clair/sombre et l'identité visuelle "sport intense" x "nature organique" s'appliquent uniformément à travers les trois modes de navigation, l'espace coach et l'espace client.
- La gamification modérée se limite à un décompte de séances et un indicateur de régularité (ex. série de jours) ; aucun système de points, niveaux ou classement entre clients n'est dans le périmètre de cette spécification, sauf demande contraire.
