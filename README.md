# IAClé

IAClé est l'entreprise individuelle de Christopher Maltais, au Québec. C'est la marque qui livre la pile PistisAI aux PME d'ici.

La pile, c'est le poste de travail bâti autour de Hermes : clavardage, voix, avatar, compétences. Une seule pile, une seule entreprise. [English](README.en.md).

## Local d'abord

Le logiciel tourne sur l'ordinateur du client. Il n'exige pas de matériel spécial.

Il peut joindre un service infonuagique que le client utilise déjà, seulement si c'est sécuritaire, si le client consent, et si le fournisseur a été évalué selon la Loi 25 (évaluation des facteurs relatifs à la vie privée). On documente les flux qui sortent. On peut les retirer.

Dans le service, l'employé approuve les envois et les décisions importantes.

## Pour qui

Les PME du Québec. D'abord en Estrie, puis plus loin au Québec, surtout les PME réglementées : juridique, santé, finance.

## Le poste

Ce dépôt contient le poste PistisAI, livré sous la marque IAClé.

- Clavardage avec Hermes. OpenClaw et les passerelles compatibles sont encore dans le code.
- Voix et avatar.
- Lecture d'écran et OCR, avec la permission de la personne.
- Actions sur le poste, avec une permission à la fois.
- Compétences, sessions, tâches planifiées.
- Maillage privé entre les appareils du client.

Ollama et LM Studio servent à des tâches du poste, comme la mémoire et les embeddings. L'agent principal reste Hermes, ou une passerelle compatible.

## Offre

| Offre | Contenu |
| --- | --- |
| Audit de préparation | Gratuit. Trois colonnes : ce que les outils font déjà, ce qui se fait encore à la main, ce qui reste à automatiser. |
| Implantation | Un parcours opérationnel. Exemples : tri des courriels, factures, réceptionniste bilingue, rapports, comptabilité. |
| Services gérés | Suivi du système, aide pour la Loi 25, reprise des données. |

## Connexion

La connexion sert au tunnel et à la synchro.

| Palier | Réseau |
| --- | --- |
| Gratuit | Tunnel `pistisai.app`, derrière Cloudflare Access |
| Affaires | Tailscale ou le VPN du client |
| Entreprise | Tailscale ou le VPN du client |

Ce modèle ne passe pas par Supabase.

Au moment de cette page, `pistisai.app` ne répond pas (erreur Cloudflare 1033). Ce n'est pas une démo ouverte. `docs.pistisai.app` ne résout pas.

Le code de ce dépôt ne suit pas encore ce modèle. La section suivante dit ce qu'il fait vraiment.

## Ce dépôt aujourd'hui

Le reclonage de marque, à partir de pistisai-app, viendra plus tard. Ici, le code s'appelle encore Pistisai.

- Sur le bureau, sans nuage : pas de compte. L'auth est locale.
- Sur le web, et sur le bureau avec `CLOUD_ENABLED` : connexion Google via Supabase.
- Les paliers dans le code s'appellent `free`, `premium` et `enterprise`. Il n'y a pas de palier Affaires, et pas de Cloudflare Access dans le dépôt.
- `backend/auth/` valide encore des JWT Auth0.
- Aucune version n'est publiée sur [iacle-solutions/iacle-app](https://github.com/iacle-solutions/iacle-app). La CI de ce dépôt construit Linux, Windows, macOS et Android.

## Développement

Flutter `3.47.7`, indiqué dans `pubspec.yaml`. Node `26`, indiqué dans `.nvmrc`. Les services acceptent Node `>=22 <27` (le SDK, `>=18`).

```bash
git clone https://github.com/iacle-solutions/iacle-app.git
cd iacle-app
flutter pub get
cd lib/shared && flutter pub get && cd ../..
flutter run -d linux
flutter run -d chrome
```

```bash
flutter build linux --release
flutter build web --release --no-web-resources-cdn
flutter build apk --release --split-per-abi
flutter build windows --release
flutter build macos --release
```

```bash
cd services/api-backend && npm install && npm run dev
cd services/streaming-proxy && npm install && npm run dev
```

`backend/auth/` n'a pas de script `dev`. On le lance avec `node handlers.js`.

Détails : [AGENTS.md](AGENTS.md), [prise en main](docs/development/DEVELOPER_ONBOARDING.md), [contribuer](CONTRIBUTING.md).

## Documentation

| Document | Contenu |
| --- | --- |
| [English](README.en.md) | La même page en anglais |
| [Vue d'ensemble](docs/index.md) | Définition du logiciel |
| [Démarrage](docs/LAUNCH.md) | Lancer depuis le code source |
| [Installation](docs/user-guide/SETUP_GUIDE.md) | Installer le poste |
| [Utilisation](docs/user-guide/USER_GUIDE.md) | S'en servir |
| [Architecture](docs/architecture/SYSTEM_ARCHITECTURE.md) | Comment c'est fait |
| [Spécification](SPEC.md) | Spec du logiciel |
| [Sécurité](SECURITY.md) | Signaler une faille |

## Licence

MIT. Voir [LICENSE](LICENSE).
