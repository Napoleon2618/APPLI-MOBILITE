# Contract: Authentification

Fournie par Supabase Auth (email + mot de passe classique — FR-019, pas de magic link).
Le client mobile appelle directement le SDK `supabase_flutter` ; il n'y a pas d'endpoint
custom à développer pour ces flux.

## Inscription (client)

- **Entrée**: email, mot de passe, `coach_id` de rattachement (issu d'une invitation ou
  d'un code fourni par le coach — mécanisme précis hors périmètre de cette spec,
  cf. Assumptions)
- **Comportement attendu**: crée l'identité Supabase Auth puis la ligne `client`
  correspondante avec le `coach_id` fourni. Le rattachement `coach_id` DOIT être fixé à la
  création et non modifiable ensuite par le client (FR-021).
- **Erreurs**: email déjà utilisé ; mot de passe ne respectant pas la politique minimale
  Supabase ; `coach_id` invalide/inexistant.

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
