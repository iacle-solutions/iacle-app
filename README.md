# IAClé

IAClé est l'entreprise individuelle de Christopher Maltais, au Québec. C'est la marque qui livre la pile PistisAI aux PME d'ici.

La pile, c'est le poste de travail bâti autour de Hermes : clavardage, voix, avatar, compétences. Une seule pile, une seule entreprise. [English](README.en.md).

## Local d'abord

L'agent tourne sur un ordinateur chez le client. L'audit gratuit vérifie si son PC actuel peut l'héberger. Sinon, on fournit un mini-PC dédié (standard : Beelink GTi15), en achat ou en location. Du matériel sur mesure, seulement quand l'audit le montre.

Il peut joindre un service infonuagique que le client utilise déjà, seulement si c'est sécuritaire, si le client consent, et si le fournisseur a été évalué selon la Loi 25 (évaluation des facteurs relatifs à la vie privée). On documente les flux qui sortent. On peut les retirer.

Dans le service, l'employé approuve les envois et les décisions importantes.

## Pour qui

Les PME du Québec. D'abord en Estrie, puis plus loin au Québec, surtout les PME réglementées : juridique, santé, finance.

## Le poste

Ce dépôt contient le poste PistisAI, livré sous la marque IAClé.

- Clavardage avec Hermes, OpenClaw, ou une passerelle compatible.
- Voix et avatar.
- Lecture d'écran et OCR, avec la permission de la personne.
- Actions sur le poste, avec une permission à la fois.
- Compétences, sessions, tâches planifiées.
- Maillage privé entre les appareils du client.

Ollama et LM Studio servent à des tâches du poste, comme la mémoire et les embeddings. L'agent principal reste Hermes, ou une passerelle compatible.

## Offre

| Offre | Contenu |
| --- | --- |
| Audit de préparation | Gratuit. Trois colonnes : ce que les outils font déjà, ce qui se fait encore à la main, ce qui reste à automatiser. On vérifie aussi si le PC actuel peut héberger l'agent. |
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

Ce dépôt sera resynchronisé avec pistisai-app (voir [#26](https://github.com/iacle-solutions/iacle-app/issues/26)).

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
