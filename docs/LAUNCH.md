# IAClé — run the hub from source

> Product description: [README](../README.md) ([English](../README.en.md))
> Repo: [github.com/iacle-solutions/iacle-app](https://github.com/iacle-solutions/iacle-app)

This page is how to run the software in this repository. The offer (Quebec SMBs, Law 25, connection tiers) lives in the README. `pistisai.app` currently returns Cloudflare error 1033, so there is no hosted demo to log into.

---

## What this repository is

The PistisAI desktop hub, delivered by IAClé. It is the layer in front of an agent runtime. Hermes is the primary test path. OpenClaw and compatible gateways are still in the code. Ollama and LM Studio are support providers for memory, embeddings, OCR, and speech. They are not the main runtime.

The software runs on the client's own computer. It does not require special hardware.

---

## Supported runtimes

| Runtime | Status | Notes |
|---------|--------|-------|
| **Hermes** | Primary test path | Sessions, channels, and tools are wired in. |
| **OpenClaw** | Supported | Gateway control and skill management are in the code. |
| Compatible agent gateways | Supported | Any agent exposing the [runtime contract](architecture/AGENT_RUNTIME_CONTRACT.md). |
| Ollama / LM Studio | Support only | Memory, embeddings, OCR, speech. Not the main runtime. |

The setup wizard chooses where the agent lives: this device, another private device, a Tailscale device, or a manual private URL. There is no hardcoded default runtime.

The spec also describes an optional per-user hosted runtime. That path is not the IAClé connection model in the README (free tunnel on `pistisai.app` behind Cloudflare Access; Business and Enterprise on the customer's Tailscale or VPN).

---

## Platforms

CI in this repository builds these targets. No GitHub Release is published on `iacle-solutions/iacle-app` yet, so the way to run it is from source.

| Platform | CI |
|----------|----|
| Linux | `flutter build linux`, AppImage script in `scripts/packaging/build_appimage.sh` |
| Windows | `flutter build windows`, Inno Setup script at `windows/installer/Pistisai.iss` |
| macOS | `flutter build macos` |
| Android | `flutter build apk` via `.github/workflows/build-mobile.yml` |
| Web | `flutter build web --release --no-web-resources-cdn` |

---

## Quick start

```bash
git clone https://github.com/iacle-solutions/iacle-app.git
cd iacle-app

flutter pub get
cd lib/shared && flutter pub get && cd ../..

flutter run -d linux
flutter run -d chrome
```

The app package is `pistisai` (Dart `>=3.5.0 <4.0.0`). `lib/shared` (`pistisai_shared`) targets Dart `>=3.9.0 <4.0.0` and needs its own `flutter pub get`. Flutter is pinned to `3.47.7` in `pubspec.yaml`.

Release builds:

```bash
flutter build linux --release
flutter build web --release --no-web-resources-cdn
flutter build apk --release --split-per-abi
flutter build windows --release
flutter build macos --release
```

Backend services, from the repo root after `npm install`:

```bash
cd services/api-backend && npm install && npm run dev
cd services/streaming-proxy && npm install && npm run dev
```

`backend/auth/` has no `dev` script. Start it with `node handlers.js`. That process still validates Auth0 JWTs. The Flutter web app and desktop cloud mode still use Supabase. Neither matches the offer's sign-in model. See the README section on the current code.

Developer onboarding: [development/DEVELOPER_ONBOARDING.md](development/DEVELOPER_ONBOARDING.md).
Command reference: [AGENTS.md](../AGENTS.md).

---

## Connecting an agent runtime

The setup wizard supports:

- **This device** — Hermes or OpenClaw running locally.
- **Another private device** — a machine on the LAN.
- **Tailscale device** — private path across the client's computers ([Secure Device Mesh](architecture/SECURE_DEVICE_MESH.md)).
- **Manual / private URL** — a private agent gateway endpoint.

Desktop control, vision, and the channel are scoped to a device and permissioned per action.

---

## Self-hosting

- [deployment/DEPLOYMENT_OVERVIEW.md](deployment/DEPLOYMENT_OVERVIEW.md)
- [deployment/SELF_HOSTING.md](deployment/SELF_HOSTING.md)
- [SECURITY.md](../SECURITY.md) — report vulnerabilities privately to `security@pistisai.app` or [this repo's security advisories](https://github.com/iacle-solutions/iacle-app/security/advisories).

---

## Documentation

| Guide | Link |
|-------|------|
| Product description | [README](../README.md) |
| System Architecture | [architecture/SYSTEM_ARCHITECTURE.md](architecture/SYSTEM_ARCHITECTURE.md) |
| Agent Runtime Contract | [architecture/AGENT_RUNTIME_CONTRACT.md](architecture/AGENT_RUNTIME_CONTRACT.md) |
| Secure Device Mesh | [architecture/SECURE_DEVICE_MESH.md](architecture/SECURE_DEVICE_MESH.md) |
| Desktop Control | [architecture/DESKTOP_CONTROL.md](architecture/DESKTOP_CONTROL.md) |
| Vision System | [architecture/VISION_SYSTEM.md](architecture/VISION_SYSTEM.md) |
| User Guide | [user-guide/USER_GUIDE.md](user-guide/USER_GUIDE.md) |
| Setup Guide | [user-guide/SETUP_GUIDE.md](user-guide/SETUP_GUIDE.md) |
| Developer Onboarding | [development/DEVELOPER_ONBOARDING.md](development/DEVELOPER_ONBOARDING.md) |
| Contributing | [CONTRIBUTING.md](../CONTRIBUTING.md) |

Older launch drafts under `docs/marketing/` and `cmo-deliverables/` still point at `pistisai.app` and `pistisAI/pistisai-app`. They are not the current product description.
