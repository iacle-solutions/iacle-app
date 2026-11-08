# IAClé

IAClé is Christopher Maltais's Quebec sole proprietorship. It is the brand that delivers the PistisAI stack to Quebec SMBs.

The stack is the desktop hub built around Hermes: chat, voice, avatar, and skills. One stack, one company. [Français](README.md).

## Local-first

The software runs on the client's own computer. It does not need special hardware.

It can reach a cloud service the client already uses only when that is secure, the client consents, and the provider has been assessed under Quebec Law 25 (a privacy impact assessment). Outbound flows are documented. They can be pulled back.

In the service, an employee approves outgoing messages and important decisions.

## Who it is for

Quebec SMBs. First in Estrie, then further into Quebec, especially regulated firms: legal, health, and finance.

## The hub

This repository is the PistisAI desktop hub, delivered under the IAClé brand.

- Chat with Hermes, OpenClaw, or a compatible gateway.
- Voice and avatar.
- Screen reading and OCR, with the person's permission.
- Desktop actions, each one permissioned.
- Skills, sessions, and scheduled tasks.
- A private mesh across the client's computers.

Ollama and LM Studio handle hub tasks such as memory and embeddings. The main agent stays Hermes, or a compatible gateway.

## Offer

| Offer | What it is |
| --- | --- |
| Readiness audit | Free. Three columns: what current tools already do, what is still done by hand, and what is left to automate. |
| Implementation | One operational path. Examples: email triage, invoices, a bilingual AI receptionist, reports, bookkeeping. |
| Managed services | System monitoring, Law 25 support, and a way to take the data back. |

## Sign-in

Sign-in is for the tunnel and for sync.

| Tier | Network |
| --- | --- |
| Free | `pistisai.app` tunnel, behind Cloudflare Access |
| Business | The customer's Tailscale or VPN |
| Enterprise | The customer's Tailscale or VPN |

This model does not use Supabase.

This repository will be resynced with pistisai-app (see [#26](https://github.com/iacle-solutions/iacle-app/issues/26)).

## Development

Flutter `3.47.7`, pinned in `pubspec.yaml`. Node `26`, pinned in `.nvmrc`. Service engines allow Node `>=22 <27` (the SDK allows `>=18`).

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

`backend/auth/` has no `dev` script. Start it with `node handlers.js`.

Details: [AGENTS.md](AGENTS.md), [onboarding](docs/development/DEVELOPER_ONBOARDING.md), [contributing](CONTRIBUTING.md).

## Documentation

| Document | What it is |
| --- | --- |
| [Français](README.md) | The same page in French |
| [Overview](docs/index.md) | What the software is |
| [Getting started](docs/LAUNCH.md) | Run it from source |
| [Setup](docs/user-guide/SETUP_GUIDE.md) | Install the hub |
| [User guide](docs/user-guide/USER_GUIDE.md) | Use the hub |
| [Architecture](docs/architecture/SYSTEM_ARCHITECTURE.md) | How it is built |
| [Specification](SPEC.md) | Software spec |
| [Security](SECURITY.md) | Report a vulnerability |

## License

MIT. See [LICENSE](LICENSE).
