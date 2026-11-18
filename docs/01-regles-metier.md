# Règles métier — OLA STATION

Ce document fixe **comment le système décide**. Les apps (client, pompiste, back-office) ne font qu'afficher et envoyer : tous les calculs et contrôles ci-dessous sont faits **par le serveur**.

Les valeurs entre crochets `[2 000 F]` sont des **paramètres par défaut**, modifiables par l'administrateur de l'enseigne dans `LoyaltySettings`. Elles restent à valider avec la gérance.

---

## 1. Identification du client

| Cas | Ce que fait le pompiste | Ce que le serveur reçoit |
|---|---|---|
| Client avec smartphone | Scanne le QR code de l'app client | `qrToken` (jeton opaque, jamais le numéro) |
| Client sans smartphone | Tape le numéro de téléphone | `phone` au format `+225XXXXXXXXXX` |
| Carte OLA imprimée (option) | Scanne le QR de la carte | `qrToken` |

- Le **numéro de téléphone** est l'identifiant unique d'un client au sein d'une enseigne.
- Le QR code contient un jeton aléatoire. Si un client perd sa carte, on régénère le jeton et l'ancien QR ne marche plus.
- Le pompiste ne voit que : prénom, initiale du nom, niveau, solde de points, type de véhicule, numéro masqué (`07 08 •• •• 12`).

## 2. Inscription

**Depuis l'app client** : numéro → code SMS (OTP) → prénom → choix du PIN à 4 chiffres → acceptation des conditions → QR code généré.

**Inscription express à la pompe** (client sans smartphone) :
1. Le pompiste saisit le numéro et le prénom, et le type de véhicule.
2. Si `requireOtpOnAssistedSignup` `[oui]` : un SMS est envoyé au client, qui lit le code au pompiste. Cela prouve que le numéro existe et appartient au client présent.
3. Le client tape lui-même son PIN sur l'appareil (deux fois).
4. SMS de bienvenue.

Règles :
- PIN : 4 chiffres, refus des PIN trop simples (`0000`, `1234`, `1111`…, et les 4 derniers chiffres du numéro).
- Le PIN est stocké haché (argon2), jamais en clair, jamais visible par personne.
- PIN oublié : réinitialisation par OTP SMS (depuis l'app client, ou à la pompe avec le pompiste).

## 3. Saisie d'un passage

### 3.1 Le pompiste saisit la somme, les litres sont calculés

En Côte d'Ivoire, le client demande une **somme** (« Gasoil 10 000 », « Super 2 500 »), pas un nombre de litres. L'app suit cet usage :

- Le pompiste **tape au clavier la somme donnée par le client**, en FCFA entiers. Il n'y a ni saisie en litres, ni boutons de montants préréglés.
- Le serveur prend le **prix du jour** de la station (dernier `ProductPrice` dont `validFrom` ≤ heure du passage) et calcule les litres : `litres = montant ÷ prix`, arrondi à **2 décimales**.
- Les litres sont affichés à titre d'information (« = 13,99 L ») et servent **uniquement** au rapprochement avec les index des pompes (section 9) et aux plafonds par véhicule. Ils n'entrent jamais dans le calcul des points.

Le prix appliqué est **recopié dans le passage**. Un changement de prix ultérieur ne modifie jamais l'historique.

Exemples (prix d'exemple, à remplacer par les vrais) :

| Demande du client | Prix du jour | Litres calculés |
|---|---|---|
| Gasoil 10 000 | 715 F/L | 13,99 L |
| Super 5 000 | 875 F/L | 5,71 L |
| Gasoil 2 500 | 715 F/L | 3,50 L |

Pour la boutique et les services : même saisie de la somme, sans litres.

### 3.2 Confirmation par le client

Chaque passage saisi depuis l'app pompiste **doit** être confirmé par le **PIN du client**, tapé par le client lui-même sur l'appareil du pompiste, après avoir vu le récapitulatif (produit, quantité, montant, points).

- PIN faux : le pompiste peut refaire saisir. Après `[3]` échecs, le compte est verrouillé `[15 min]` et une alerte `PIN_FAILED_REPEATED` est envoyée au gérant.
- Aucun passage n'est possible sans PIN depuis l'app pompiste. Les passages sans PIN viennent uniquement d'un import ou d'une régularisation du gérant (journalisée).

### 3.3 Contrôles automatiques

Dans cet ordre. Un contrôle **bloquant** refuse le passage (aucun point), un contrôle **non bloquant** enregistre le passage avec une mention.

| # | Contrôle | Résultat | Alerte |
|---|---|---|---|
| 1 | Client actif (ni bloqué ni supprimé) | Bloquant `CUSTOMER_INACTIVE` | — |
| 2 | Le numéro du client n'est pas un numéro bloqué du pompiste (le sien ou un proche déclaré) | Bloquant `SELF_CREDIT_FORBIDDEN` | `SELF_CREDIT_ATTEMPT` (critique) |
| 3 | PIN client correct | Bloquant `PIN_INVALID` / `PIN_LOCKED` | après N échecs |
| 4 | Litres calculés ≤ plafond du véhicule `[moto 15 L, voiture/taxi 80 L, gbaka 150 L, camion 600 L]` | Bloquant `VEHICLE_CAP_EXCEEDED` | oui |
| 5 | Litres calculés du jour pour ce client ≤ `[300 L]` | Bloquant `DAILY_CAP_EXCEEDED` | oui |
| 6 | Un prix du jour existe pour ce produit dans cette station | Bloquant `PRICE_MISSING` | — |
| 7 | Passage compté comme visite ? (voir 3.4) | Non bloquant | — |
| 8 | Synchronisé plus de `[30 min]` après le passage | Non bloquant, marqué `syncedLate` | `LATE_SYNC` (info) |

### 3.4 Qu'est-ce qu'un « passage » (visite) ?

Un passage rapporte toujours ses points, mais il ne compte comme **visite** que si :
- le montant est ≥ `[2 000 F]`, **et**
- la dernière visite comptée de ce client remonte à plus de `[4 h]`.

Pourquoi : un pompiste pourrait découper un passage de 10 000 F en quatre saisies de 2 500 F pour gonfler le compteur de visites. Les points, eux, restent identiques (4 × 2 pts = 8 pts contre 10 pts d'un coup : découper fait même perdre des points à cause de l'arrondi), donc découper ne rapporte rien.

### 3.5 Mode hors ligne

Si le réseau coupe, l'app pompiste **enregistre le passage dans le téléphone** (avec le PIN chiffré) et l'envoie dès le retour du réseau.

- L'identifiant du passage est généré par le téléphone : un renvoi ne crée jamais de doublon.
- Le PIN ne peut pas être vérifié hors ligne. Il est vérifié à la synchronisation. S'il est faux, le passage est **rejeté**, sans points, et une alerte `OFFLINE_PIN_INVALID` est créée.
- L'écran du pompiste affiche le nombre de passages en attente d'envoi.

## 4. Points

### 4.1 Gain

**Les points se calculent toujours sur la somme en FCFA, jamais sur les litres.** C'est la somme que le client donne et qu'il connaît : « j'ai mis 10 000, j'ai gagné 10 points » est facile à comprendre.

Règles provisoires (valeurs réelles à fournir par la gérance, voir `04-valeurs-a-confirmer.md`) :

| Produit | Règle | Exemple |
|---|---|---|
| Carburant | `[1 pt]` par tranche de `[1 000 F]` | Gasoil 10 000 F → 10 pts |
| Boutique | `[1 pt]` par tranche de `[500 F]` | 3 200 F → 6 pts |
| Services (lavage…) | `[1 pt]` par tranche de `[500 F]` | |

- Formule : `points = arrondi inférieur(montant ÷ tranche) × points par tranche`. Exemple : 2 500 F de carburant → 2 pts.
- Si plusieurs règles s'appliquent, la plus précise gagne : produit > catégorie, station > enseigne.
- La gérance peut donner une tranche plus avantageuse à la boutique pour y attirer les clients.

### 4.2 Registre de points

- Chaque mouvement est une ligne : `EARN`, `REDEEM`, `REVERSAL`, `ADJUST`, `EXPIRE`, `BONUS`.
- **On n'efface et on ne modifie jamais une ligne.** Une erreur se corrige par une ligne inverse.
- Le solde affiché = somme des lignes (un cache `pointsBalance` est mis à jour dans la même transaction SQL).
- Contrainte en base : un passage ne peut produire qu'**un seul** `EARN` et qu'**un seul** `REVERSAL`. C'est ce qui garantit qu'une récompense n'est jamais attribuée deux fois.
- Le solde ne peut pas devenir négatif.

### 4.3 Annulation d'un passage

Réservée au gérant, avec motif obligatoire. Le passage passe en `CANCELLED`, une ligne `REVERSAL` retire les points, et l'opération est inscrite au journal d'audit.

### 4.4 Expiration

Désactivée par défaut (`pointsExpiryMonths = null`). Si activée : les points gagnés expirent N mois après leur gain, avec un rappel au client 15 jours avant.

## 5. Niveaux

- Calculés sur les **points gagnés** (`EARN`) pendant les `[3]` derniers mois glissants. Les points dépensés ne font pas baisser le niveau.
- Par défaut : **Bronze** dès l'inscription, **Silver** à `[500]` pts, **Gold** à `[1 500]` pts.
- Le niveau sert au ciblage des offres et événements, et peut réserver certains cadeaux.
- Recalcul chaque nuit, et immédiatement après un gain (pour la montée de niveau).

## 6. Cadeaux

Retrait à la station :
1. Le pompiste identifie le client et choisit le cadeau.
2. Le serveur vérifie : solde suffisant, stock, limite par client, niveau minimum, période de validité.
3. Le client confirme avec son **PIN**.
4. Ligne `REDEEM` dans le registre, stock décrémenté, notification au client.

## 7. Avis

- Possible pour un passage validé, dans les `[72 h]`, **un seul avis par passage**.
- Note de 1 à 5, étiquettes (`accueil`, `rapidité`, `propreté`, `prix`, `boutique`), commentaire facultatif.
- Lié automatiquement à la station et au pompiste du passage.
- **Privé** : visible seulement dans le back-office, jamais publié.
- Note ≤ `[2]` → alerte immédiate au gérant.
- Suivi : `NEW` → `IN_PROGRESS` → `RESOLVED` (ou `DISMISSED` si abusif).

## 8. Offres et événements

- Types : offre, événement, information.
- Ciblage : stations et/ou niveaux. Vide = tout le monde.
- Envoi à la publication : notification push si le client a l'app, sinon SMS **uniquement s'il a accepté les communications marketing**.
- Cadeau d'événement : le client présente son numéro, le pompiste l'enregistre. **Une seule fois par client et par événement** (contrainte en base). Permet de mesurer la participation.

## 9. Fin de service et rapprochement

1. **Début de service** : le pompiste ouvre son service et saisit l'index de chaque pistolet (photo du compteur).
2. Tous ses passages sont rattachés à ce service.
3. **Fin de service** : il saisit les index de fin (photo).
4. Le serveur calcule par produit :
   - `litres pompés` = Σ (index fin − index début)
   - `litres fidélité` = Σ litres des passages validés
   - `taux de capture` = litres fidélité ÷ litres pompés
5. Si `litres fidélité > litres pompés + [0,5 %]` → alerte **critique** `RECONCILIATION_GAP`.
6. Le gérant relit et valide le service.

## 10. Alertes de surveillance (calcul nocturne)

- `CUSTOMER_CONCENTRATION` : sur 30 jours, plus de `[40 %]` des passages d'un pompiste vont aux mêmes 5 clients.
- Un même client crédité dans deux stations différentes à moins de 30 minutes d'intervalle.
- Taux de PIN faux anormal pour un pompiste.

## 11. Données personnelles

- Consentement aux conditions obligatoire à l'inscription, consentement marketing séparé et révocable.
- Suppression de compte : prénom, nom, e-mail, véhicule et numéro sont anonymisés. Les passages et le registre de points sont conservés de façon anonyme pour les statistiques.
- Déclaration du traitement auprès de l'**ARTCI** (loi ivoirienne n°2013-450) : à faire par l'exploitant, à valider avec un juriste.
