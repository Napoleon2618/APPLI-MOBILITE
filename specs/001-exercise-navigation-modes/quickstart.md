# Quickstart: Navigation par 3 modes vers les séances d'exercices

Guide de validation de bout en bout pour cette fonctionnalité, une fois implémentée.
Référence les contrats (`contracts/`) et le modèle de données (`data-model.md`) plutôt
que de dupliquer leur contenu.

## Prérequis

- Flutter SDK installé, projet `mobile/` récupéré
- Supabase CLI installé, projet local démarré (`supabase start` depuis `backend/supabase/`)
- Migrations appliquées (`supabase db reset` ou équivalent) — crée le schéma de
  `data-model.md` et les policies RLS de `contracts/data-access.md`
- Données de seed chargées (`backend/supabase/seed/`) : au moins un coach, quelques
  `body_zone`, `pain_sign`, `exercise` associés, une `session`, une `daily_formula` pour
  la date du jour, et un compte `client` rattaché à ce coach

## Scénario 1 — Formule du jour (US1, SC-001)

1. Lancer l'application (`flutter run`) et se connecter avec le compte client de seed.
2. **Attendu**: l'écran d'accueil affiche directement une séance sans étape de sélection.
3. Démarrer la séance et dérouler tous les exercices jusqu'à la confirmation de fin.
4. **Attendu**: une ligne `session_log` est créée pour ce client avec `source_mode =
   'daily_formula'` (cf. `data-model.md`).

## Scénario 2 — Gestion de contenu coach + isolation multi-coach (US2)

1. Se connecter avec le compte coach de seed.
2. Créer un exercice, l'associer à une zone corporelle et à un signe de douleur, puis
   l'ajouter à une nouvelle séance.
3. Désigner cette séance comme formule du jour pour une date de test.
4. **Attendu**: le contenu créé est immédiatement lisible par un client rattaché à ce
   coach (revoir le scénario 1 avec la nouvelle date).
5. Créer un second compte coach (données de seed additionnelles) avec son propre contenu.
6. **Attendu**: le client du premier coach ne voit à aucun moment le contenu du second
   coach, dans aucun des trois modes de navigation (vérifie les policies RLS de
   `contracts/data-access.md`).
7. Faire suivre au client de seed la séance créée à l'étape 2-3 (produit un `session_log`),
   puis, en tant que coach, supprimer l'exercice qui y figure (FR-023).
8. **Attendu**: l'exercice disparaît des listes actives du coach et des trois modes de
   navigation client, mais reste visible/consultable dans l'historique de progression du
   client pour la séance déjà suivie (pas de suppression physique — `archived_at` posé,
   cf. `data-model.md`).

## Scénario 3 — Choix par zone corporelle (US3)

1. Depuis l'écran de navigation par zone, sélectionner une zone couverte par le seed.
2. **Attendu**: la liste des exercices associés à cette zone s'affiche.
3. Sélectionner une zone sans exercice associé (à créer dans le seed pour ce test).
4. **Attendu**: message clair d'absence de contenu, pas de liste vide muette (FR-015).

## Scénario 4 — Choix par signe de douleur (US4)

1. Depuis l'écran de navigation par signe, sélectionner un signe de la liste prédéfinie
   (pas de champ de saisie libre — FR-016).
2. **Attendu**: les exercices associés s'affichent ; aucun terme médical/clinique
   n'apparaît dans les libellés proposés (SC-005).

## Scénario 5 — Progression (US5)

1. Après avoir complété plusieurs séances sur plusieurs jours (via le seed ou en rejouant
   le scénario 1 sur plusieurs dates simulées), ouvrir l'écran de progression.
2. **Attendu**: nombre de séances suivies + indicateur de régularité visibles en un seul
   écran (SC-004), sans multiplication d'éléments de gamification (FR-014).

## Scénario 6 — Authentification (FR-019, FR-020, SC-007)

1. Se déconnecter, tenter une connexion avec un mauvais mot de passe.
2. **Attendu**: message d'erreur générique, pas de distinction "email inconnu" vs "mot de
   passe incorrect".
3. Demander une réinitialisation de mot de passe pour l'email du compte client de seed.
4. **Attendu**: email de réinitialisation reçu (boîte de test Supabase locale/Inbucket),
   lien fonctionnel menant à un écran de nouveau mot de passe, reconnexion possible avec
   le nouveau mot de passe.
5. Sur un second appareil/émulateur (ou après désinstallation/réinstallation), se
   connecter avec le compte client de seed qui a déjà des séances suivies.
6. **Attendu**: l'historique de progression (séances suivies, régularité) est identique à
   celui vu sur le premier appareil, sans étape de resynchronisation manuelle (FR-018).

## Scénario 6bis — Rattachement client-coach (FR-022)

1. En tant que coach, générer un code d'invitation.
2. Sur un nouvel appareil/session, s'inscrire avec un nouvel email + mot de passe en
   saisissant ce code.
3. **Attendu**: le nouveau compte client est automatiquement rattaché à ce coach et voit
   son contenu (le code ne peut pas être réutilisé une seconde fois).
4. En tant que coach, créer directement un second compte client (email + mot de passe
   provisoire), sans code.
5. **Attendu**: ce client peut se connecter avec le mot de passe provisoire et voit
   immédiatement le contenu de ce coach.

## Scénario 7 — Mode hors-ligne (Principe IV)

1. Consulter la formule du jour et un exercice détaillé pendant que le réseau est actif.
2. Couper la connectivité réseau de l'appareil/émulateur.
3. **Attendu**: la formule du jour et l'exercice déjà consultés restent affichables ;
   compléter la séance reste possible et crée un `session_log` local en attente de
   synchronisation.
4. Rétablir le réseau.
5. **Attendu**: le `session_log` local se synchronise automatiquement vers Supabase sans
   action manuelle.

## Scénario 8 — Thème clair/sombre (SC-006)

1. Basculer le thème depuis les réglages de l'application.
2. **Attendu**: bascule en une seule action, appliquée immédiatement à tous les écrans.
3. Fermer et rouvrir l'application.
4. **Attendu**: le thème choisi est conservé.
