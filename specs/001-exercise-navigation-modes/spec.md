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
5. **Given** deux coachs distincts ayant chacun créé leur propre contenu, **When** un client rattaché au coach A consulte l'application, **Then** il ne voit que le contenu du coach A (exercices, séances, formule du jour, zones, signes de douleur), jamais celui d'un autre coach.

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
- Comment le système gère-t-il un exercice supprimé par le coach alors qu'il fait déjà partie d'une séance en cours de suivi côté client, ou d'une séance passée dans l'historique de progression d'un client ? **Résolu** : l'exercice est archivé plutôt que supprimé définitivement tant qu'il est référencé par un historique de progression (FR-023).
- Comment l'application se comporte-t-elle en l'absence de connexion réseau pour un client qui a déjà consulté du contenu précédemment (formule du jour, séance en cours) ?
- Que se passe-t-il si un coach modifie ou supprime une séance pendant qu'un client est en train de la suivre activement ? **Hors périmètre V1** (voir Assumptions) : ce comportement n'est pas garanti dans cette itération.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT proposer à chaque client, sans action de sélection de sa part, une séance du jour prête à être suivie (mode "Formule journalière").
- **FR-002**: Le système DOIT permettre au coach de créer, modifier et supprimer des exercices (contenu descriptif de l'exercice) — voir FR-023 pour la politique de suppression d'un exercice déjà référencé par un historique de progression.
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
- **FR-017**: Le système DOIT être conçu pour supporter plusieurs coachs distincts dès la conception des données, chacun avec son propre contenu (exercices, séances, associations zone/signe, formule du jour) non partagé par défaut avec les autres coachs. Un seul coach sera opérationnellement actif en V1, mais le modèle de données NE DOIT PAS nécessiter de refonte pour qu'un second coach rejoigne l'application par la suite.
- **FR-018**: Un client DOIT disposer d'un compte utilisateur pour accéder à l'application ; son historique de progression DOIT être associé à ce compte et rester accessible depuis un nouvel appareil après connexion.
- **FR-019**: Le système DOIT authentifier les comptes utilisateur (coach comme client) via un identifiant (email) et un mot de passe classique — pas de lien de connexion sans mot de passe ("magic link") en V1.
- **FR-020**: Le système DOIT permettre à un utilisateur ayant oublié son mot de passe de le réinitialiser via un lien de réinitialisation envoyé par email.
- **FR-021**: Le système DOIT rattacher chaque client à un unique coach, et DOIT limiter le contenu visible par ce client (exercices, séances, formule du jour, zones corporelles, signes de douleur) à celui créé par son coach.
- **FR-022**: Le système DOIT permettre le rattachement d'un client à un coach par deux mécanismes possibles : (a) un code d'invitation généré par le coach, que le client saisit lors de son inscription pour rejoindre ce coach ; (b) une création directe du compte client par le coach (email + mot de passe provisoire), sans passage par un code. Les deux mécanismes DOIVENT rester disponibles simultanément (pas d'exclusivité de l'un par rapport à l'autre).
- **FR-023**: Lorsqu'un coach supprime un exercice référencé par au moins une séance déjà suivie par un client (présente dans son historique de progression), le système DOIT conserver cet exercice consultable dans cet historique (archivage) plutôt que de le supprimer définitivement. Un exercice archivé DOIT disparaître des listes actives proposées au coach (création/édition de séances, associations zone/signe) et des trois modes de navigation client, sans altérer les séances déjà suivies qui le référencent.

### Key Entities

- **Coach**: Compte au rôle admin/contenu, propriétaire d'un espace de contenu qui lui est propre (exercices, séances, zones corporelles éventuellement personnalisées, signes de douleur, formule du jour). Plusieurs coachs peuvent coexister dans le système ; leurs contenus respectifs ne sont pas partagés entre eux. Un seul coach est opérationnellement actif en V1.
- **Exercice**: Unité de contenu de mobilité/assouplissement créée par un coach donné et rattachée à celui-ci (nom, description, instructions d'exécution). Peut être associé à plusieurs zones corporelles et plusieurs signes de douleur du même coach, et peut appartenir à plusieurs séances du même coach. Un exercice référencé par l'historique de progression d'un client est archivé plutôt que supprimé définitivement lorsqu'un coach le retire (FR-023).
- **Séance**: Ensemble ordonné d'exercices, créé par un coach et rattaché à celui-ci. Peut être désignée comme formule du jour pour une ou plusieurs dates.
- **Formule du jour**: Association entre une date et une séance d'un coach donné, déterminant ce qui est proposé aux clients de ce coach dans le mode "Formule journalière" pour cette date.
- **Zone corporelle**: Catégorie de localisation anatomique (ex. dos, épaules, hanches, genoux, chevilles), rattachée à un coach, utilisée pour cibler des exercices dans le mode "Choix par zone corporelle".
- **Signe de douleur**: Formulation en langage courant décrivant une gêne ou douleur (ex. "douleur au coude", "tiraillement dans le bas du dos"), définie et gérée par un coach dans une liste prédéfinie qui lui est propre, utilisée pour cibler des exercices dans le mode "Choix par signe de douleur".
- **Séance suivie (historique)**: Enregistrement qu'un client donné a suivi une séance donnée (de son coach) à une date donnée, utilisé pour calculer la progression et la régularité.
- **Compte utilisateur**: Identité authentifiée (email + mot de passe) d'un coach ou d'un client, associée à son rôle. Pour un client, associée aussi à son coach unique et à son historique de progression (retrouvable après connexion depuis un nouvel appareil). Supporte la réinitialisation de mot de passe par email. Un compte client est créé soit par le client lui-même via un code d'invitation, soit directement par le coach avec un mot de passe provisoire (FR-022).
- **Code d'invitation**: Jeton généré par un coach, associé à celui-ci, permettant à un client de s'inscrire et d'être automatiquement rattaché à ce coach lors de l'inscription (FR-022, mécanisme a).
- **Utilisateur**: Personne utilisant l'application, avec un rôle coach (gestion de contenu propre à ce coach) ou client (consultation et suivi du contenu d'un unique coach rattaché).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un client peut démarrer une séance depuis l'ouverture de l'application en moins de 10 secondes via la formule du jour, sans étape de sélection intermédiaire.
- **SC-002**: Au moins 90 % des tentatives de recherche par zone corporelle ou par signe de douleur renvoient au moins un exercice associé par le coach, lorsque le coach a couvert cette zone/ce signe dans son contenu.
- **SC-003**: Un coach peut créer un exercice, l'associer à une zone corporelle et à un signe de douleur, et l'intégrer à une séance en moins de 5 minutes au total.
- **SC-004**: Un client peut consulter son nombre de séances suivies et un indicateur de régularité en un seul écran, sans navigation supplémentaire.
- **SC-005**: Aucun terme médical/clinique n'apparaît dans les libellés du parcours "Choix par signe de douleur", vérifié par relecture du contenu proposé aux clients.
- **SC-006**: Un utilisateur peut basculer entre mode clair et mode sombre en une seule action, et ce choix est conservé lors des ouvertures suivantes de l'application.
- **SC-007**: Un utilisateur ayant oublié son mot de passe peut en demander la réinitialisation et retrouver l'accès à son compte via l'email reçu, sans intervention manuelle du coach ou d'un support.

## Assumptions

- L'application est utilisée par un public grand public non médical côté client ; le contenu n'est ni un diagnostic ni un avis médical, seulement des propositions d'exercices de mobilité/assouplissement.
- Les zones corporelles proposées couvrent un ensemble standard de zones courantes en mobilité/assouplissement (ex. nuque, épaules, dos, hanches, genoux, chevilles, poignets) ; la liste exacte est définie et modifiable par le coach via la gestion de contenu, non figée dans cette spécification.
- Un exercice, une zone corporelle et un signe de douleur peuvent avoir des relations plusieurs-à-plusieurs (un exercice peut couvrir plusieurs zones/signes, une zone/un signe peut être couvert par plusieurs exercices).
- La formule du jour est définie par le coach à l'avance (elle n'est pas générée automatiquement par un algorithme de recommandation dans le périmètre de cette spécification) ; comment le coach la programme précisément (ex. calendrier manuel ou rotation) reste un détail de gestion de contenu ouvert.
- Le mode clair/sombre et l'identité visuelle "sport intense" x "nature organique" s'appliquent uniformément à travers les trois modes de navigation, l'espace coach et l'espace client.
- La gamification modérée se limite à un décompte de séances et un indicateur de régularité (ex. série de jours) ; aucun système de points, niveaux ou classement entre clients n'est dans le périmètre de cette spécification, sauf demande contraire.
- Un client est rattaché à un unique coach (pas d'abonnement d'un même client à plusieurs coachs dans le périmètre de cette spécification) ; le rattachement se fait par code d'invitation ou par création directe du compte par le coach (FR-022) — les deux mécanismes sont actés, ce n'est plus un point ouvert.
- En V1, un seul coach est réellement créé et opérationnel ; le support de plusieurs coachs est une exigence de conception des données (FR-017) pour éviter une refonte future, pas une fonctionnalité de gestion multi-coach (ex. back-office de supervision inter-coachs) livrée dès cette itération.
- L'authentification par email + mot de passe (avec réinitialisation par email) s'applique aux comptes coach comme aux comptes client ; l'inscription initiale d'un coach (ex. création manuelle, validation) reste un détail d'implémentation ouvert.
- Le comportement de l'application lorsqu'un coach modifie ou supprime une séance pendant qu'un client la suit activement n'est pas garanti en V1 (hors périmètre) ; ce cas pourra être traité dans une itération ultérieure si besoin.
