# OLA STATION

Application de fidélisation pour stations-service, pensée pour le terrain ouest-africain : paiement au pompiste, pas de reçu, clients avec ou sans smartphone, réseau instable.

Site pilote : **Ola Latrie, Abidjan**. Architecture multi-stations et multi-enseignes dès le départ.

## Principe

1. Le client est identifié par son **numéro de téléphone** (ou son QR code s'il a un smartphone).
2. Le pompiste saisit le produit et la quantité, l'app calcule le montant et les points.
3. **Le client confirme avec son PIN** sur le téléphone du pompiste.
4. En fin de service, les **index des pompes** sont comparés aux litres saisis : les litres fidélité ne peuvent pas dépasser les litres pompés.

## Organisation du dépôt

| Dossier | Contenu | Techno |
|---|---|---|
| `api/` | Serveur, base de données, règles métier | NestJS + PostgreSQL (Prisma) |
| `admin/` | Back-office du gérant | Next.js |
| `app_pompiste/` | App des pompistes, fonctionne hors ligne | Flutter |
| `app_client/` | App des clients | Flutter |
| `docs/` | Règles métier, modèle de données, contrat d'API | |

## Documents de référence

- [Règles métier](docs/01-regles-metier.md) : comment le système calcule et contrôle.
- [Modèle de données](docs/02-modele-donnees.md) : les tables et les garanties.
- [Contrat d'API](docs/api/openapi.yaml) : les échanges entre les apps et le serveur (OpenAPI 3.1).
- [Schéma Prisma](api/prisma/schema.prisma) : source de vérité de la base.

## Avancement

- [x] **Étape 1** : modèle de données, règles métier, contrat d'API
- [ ] Étape 1 bis : charte visuelle et maquettes des 5 écrans clés
- [ ] **Étape 2** : serveur (inscription, passages, PIN, anti-fraude, points) + app pompiste
- [ ] **Étape 3** : app client + back-office
- [ ] **Étape 4** : test réel à Ola Latrie

## Démarrer (serveur)

```bash
cd api
npm install
npm run prisma:validate
```
