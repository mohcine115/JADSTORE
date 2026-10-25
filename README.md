# JADSTORE — boutique + back-office Supabase

Ce projet contient :
- `index.html` : landing page publique, catalogue connecté, tailles/couleurs, panier et commande WhatsApp.
- `admin.html` : connexion administrateur, ajout/modification/suppression, import de photos, stock et publication.
- `config.js` : URL Supabase, clé publique et numéro WhatsApp.
- `supabase_setup.sql` : tables, règles de sécurité (RLS), stockage photos et produit d'exemple.

## Important avant de commencer
Le projet n'est pas connecté tant que tu n'as pas créé ton projet Supabase et remplacé les valeurs de `config.js`.
N'insère JAMAIS une clé `service_role` ou une clé secrète dans les fichiers HTML/JS. Seule la clé publique `anon`/`publishable` est utilisée dans le navigateur. La sécurité repose sur les règles SQL RLS et le compte admin autorisé.

## Étape 1 — Créer le projet Supabase gratuitement
1. Ouvre https://supabase.com/ et crée un compte.
2. Crée un projet nommé `jadstore` et conserve bien le mot de passe de la base de données.
3. Dans le tableau de bord du projet, ouvre Project Settings / API (ou Connect selon l'interface).
4. Copie l'URL du projet et la clé publique `anon`/`publishable`.

## Étape 2 — Créer la base et le stockage
1. Dans Supabase, ouvre SQL Editor.
2. Crée une nouvelle requête, colle tout le contenu de `supabase_setup.sql` et exécute-le.
3. Le script crée les tables, les politiques de sécurité, le bucket de photos et un produit d'exemple « Costume classique » à 899 DH.
4. Si le SQL signale une erreur, arrête-toi et vérifie le message avant de poursuivre.

## Étape 3 — Créer le compte administrateur
1. Dans Supabase, ouvre Authentication → Users → Add user / Create new user.
2. Crée ton utilisateur avec ton propre e-mail et un mot de passe fort. Si l'option de confirmation d'e-mail est activée, confirme l'adresse.
3. Copie l'UUID / ID de cet utilisateur depuis la liste Users.
4. Retourne dans SQL Editor et exécute cette requête en remplaçant l'UUID :

```sql
insert into public.store_admins (user_id)
values ('COLLE_ICI_UUID_DE_L_ADMIN')
on conflict (user_id) do nothing;
```

N'ajoute dans `store_admins` que les comptes qui doivent administrer la boutique. Les visiteurs publics n'ont pas accès aux fonctions d'écriture.

## Étape 4 — Configurer le site
Ouvre `config.js` et remplace :
- `COLLE_ICI_URL_PROJET_SUPABASE` par l'URL de ton projet.
- `COLLE_ICI_CLE_PUBLISHABLE_OU_ANON` par la clé publique anon/publishable.
- `212600000000` par le numéro WhatsApp de la boutique au format international, sans `+`, espaces ni tirets. Pour le Maroc, commence généralement par `212` et enlève le premier `0` du numéro local.

La clé publique peut être visible dans le navigateur ; c'est normal. Ne copie pas la clé `service_role`, une clé secrète, ni le mot de passe de la base.

## Étape 5 — Publier gratuitement
Option simple : GitHub Pages.
1. Crée un dépôt GitHub public nommé par exemple `jadstore`.
2. Téléverse `index.html`, `admin.html` et `config.js` à la racine du dépôt. Tu peux aussi ajouter README.md.
3. Dans Settings → Pages, active le déploiement depuis la branche principale (`main`) et le dossier `/ (root)`.
4. Attends la publication, puis ouvre l'URL indiquée par GitHub Pages.
5. La landing page sera à la racine du site ; le back-office sera à `.../admin.html`.

Le SQL ne doit pas être téléversé comme une page web. Garde le fichier pour la documentation, mais il ne contient pas de secrets.

## Étape 6 — Test initial
1. Ouvre la landing page : le produit « Costume classique » devrait apparaître sans photo, avec son prix de 899 DH.
2. Ouvre `admin.html`, connecte-toi avec l'utilisateur admin.
3. Modifie le costume, importe une photo JPG/PNG/WebP de moins de 5 Mo, puis enregistre.
4. Coche « Publier ce produit » et vérifie que la photo, la description et le prix apparaissent sur la page publique.
5. Teste la commande WhatsApp après avoir configuré le vrai numéro.

## Notes
- Le code utilise le CDN Supabase JS v2, donc une connexion Internet est nécessaire.
- Les offres gratuites ont des limites et peuvent évoluer. Vérifie les quotas actuels Supabase et GitHub Pages avant une utilisation commerciale importante.
- Le champ stock est affiché et sert à limiter la quantité commandée dans l'interface, mais il ne décrémente pas automatiquement le stock après une commande WhatsApp. La commande n'est pas enregistrée en base et aucun paiement en ligne n'est traité.
- Les photos sont publiques afin que les visiteurs voient les produits ; seuls les administrateurs autorisés peuvent téléverser/modifier/supprimer les fichiers.
- Si tu modifies un produit sans nouvelle photo, l'ancienne photo est conservée. La suppression d'un produit ne supprime pas automatiquement son fichier photo du stockage ; tu peux le supprimer dans Storage plus tard pour éviter les fichiers inutilisés.
- Si tu as déjà publié l'ancienne landing page, remplace son `index.html` par celui-ci.
