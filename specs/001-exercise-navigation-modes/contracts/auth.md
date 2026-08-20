# Contract: Authentification

Fournie par Supabase Auth (email + mot de passe classique — FR-019, pas de magic link).
Le client mobile appelle directement le SDK `supabase_flutter` ; il n'y a pas d'endpoint
custom à développer pour ces flux.

## Inscription (client) — deux parcours (FR-022)

### a) Auto-inscription par code d'invitation

- **Entrée**: email, mot de passe, code d'invitation (`invite_code.code`)
- **Comportement attendu**: 1) le client crée son identité Supabase Auth via l'appel
  standard `signUp` (email + mot de passe) ; 2) une fois la session ouverte, l'app appelle
  la fonction Postgres `redeem_invite_code(code)` (`SECURITY DEFINER`), qui valide le code
  (existe, `used_at IS NULL`, coach actif), crée la ligne `client` avec le `coach_id` du
  code, et marque `invite_code.used_at`/`used_by_client_id`. Voir `data-model.md` (entité
  `invite_code`) pour le détail et la justification de ce détour par une fonction serveur.
- **Erreurs**: email déjà utilisé ; mot de passe ne respectant pas la politique minimale
  Supabase ; code invalide, déjà utilisé, ou inexistant (dans ce cas l'identité Auth a été
  créée mais aucune ligne `client` n'existe — l'app DOIT bloquer l'accès au contenu et
  proposer de ressaisir un code plutôt que de laisser un compte orphelin utilisable).

### b) Création directe par le coach

- **Entrée** (côté coach, authentifié) : email du client, mot de passe provisoire
- **Comportement attendu**: le coach appelle la Supabase Edge Function
  `create-client-account`, qui vérifie que l'appelant est un coach authentifié, crée
  l'identité Supabase Auth du client (via la clé de service, détenue uniquement côté
  serveur de la fonction — jamais dans l'app mobile, Principe V) avec le mot de passe
  provisoire fourni, puis crée la ligne `client` avec `coach_id` égal à celui du coach
  appelant.
- **Erreurs**: email déjà utilisé ; appelant non-coach (refusé) ; échec de création côté
  Auth.
- Le client ainsi créé se connecte ensuite normalement (email + mot de passe provisoire)
  et peut le changer via le flux de réinitialisation standard (FR-020) — aucun flux de
  changement de mot de passe obligatoire au premier login n'est requis par cette spec.

Dans les deux cas, le rattachement `coach_id` DOIT être fixé à la création et non
modifiable ensuite par le client (FR-021).

## Connexion

- **Entrée**: email, mot de passe
- **Sortie**: session authentifiée (jeton), à partir de laquelle le rôle (coach/client) et
  le `coach_id` applicable sont résolus pour scoper toutes les requêtes suivantes (RLS).
- **Erreurs**: identifiants invalides — message générique (ne pas révéler si l'email
  existe, principe de moindre divulgation).

## Réinitialisation de mot de passe (FR-020)

- **Entrée**: email
- **Comportement attendu**: envoi d'un email contenant un lien de réinitialisation
  (flux standard Supabase Auth `resetPasswordForEmail`) ; le lien ouvre un écran de
  saisie du nouveau mot de passe dans l'application.
- **Sortie observable**: confirmation affichée que l'email a été envoyé (que l'adresse
  existe ou non, pour ne pas divulguer l'existence d'un compte) ; SC-007.

## Contrainte transverse

- Toute requête ultérieure sur les tables de contenu (exercise, session, body_zone,
  pain_sign, daily_formula, session_log) DOIT être effectuée dans le contexte de la
  session authentifiée : les policies RLS (voir `data-access.md`) refusent toute requête
  non authentifiée sur ces tables.
