# RGAA Helper – bundle portable

Teste l'analyse d'accessibilité RGAA depuis un tableau de bord web, **sans installer Java ni Node** et sans
accéder au code source. Tout tourne dans Docker, sur ton ordinateur.

## Démarrer

1. Installer et lancer [Docker Desktop](https://www.docker.com/products/docker-desktop/).
2. Télécharger ce dépôt (bouton vert **Code** > **Download ZIP**), puis le dézipper.
3. Double-cliquer sur **`start.bat`** (Windows) ou lancer `./start.sh` (macOS, Linux).
4. Ouvrir **http://localhost:38080** et coller le **jeton** affiché dans la fenêtre.

Le premier démarrage télécharge l'image (environ 1,5 Go) : compter quelques minutes.

## Analyser un site

Dans le tableau de bord : **Nouvelle analyse**, puis :

```yaml
version: 1
baseUrl: https://le-site-a-analyser.fr
pages:
  - /
```

Le site doit d'abord être autorisé : ouvrir le fichier `.env`, ajouter son adresse à
`RGAA_ALLOWED_HOSTS` (sans `https://`, séparées par des virgules, `*.monsite.fr` pour tous les
sous-domaines), puis relancer `start.bat` / `start.sh`.

## Jetons

Le jeton est créé automatiquement au premier lancement et gardé dans `.env`. Pour donner un accès à une autre
personne, générer un jeton avec `openssl rand -hex 32` et l'ajouter dans `RGAA_API_TOKENS`, après une virgule.
Ne jamais partager son `.env`.

## Arrêter, mettre à jour, tout effacer

```bash
docker compose down            # arrêter
docker compose pull            # récupérer la dernière version
docker compose down -v         # arrêter ET effacer l'historique des analyses
```

## Usage responsable

N'analyser que des sites que l'on est autorisé à tester. L'outil ne remplace pas un audit RGAA complet.
Fourni tel quel, sans garantie. Projet indépendant, non officiel, sans lien avec la DINUM.

© ChloeGlbrt, tous droits réservés.
