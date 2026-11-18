# Charte graphique — OLA STATION (v0.1)

Maquettes interactives : canvas « OLA STATION Maquettes » (lien partagé dans le suivi du projet).

Principe : **lisible en plein soleil, utilisable d'une main, sur des téléphones Android d'entrée de gamme.**

## Couleurs

| Rôle | Nom | Hex | Usage |
|---|---|---|---|
| Primaire | Vert station | `#0B5D4B` | Actions principales, en-têtes, succès |
| Accent | Ambre | `#F2A516` | Points, cadeaux, écran remis au client (PIN) |
| Texte | Encre | `#13201A` | Tout le texte principal |
| Texte secondaire | Gris vert | `#4A5A52` | Libellés, aides |
| Fond | Fond | `#F4F5F0` | Fond des écrans |
| Surface | Blanc | `#FFFFFF` | Cartes, champs |
| Bordure | | `#DCE1D9` | Champs, boutons non sélectionnés |
| Alerte | Rouge | `#B3261E` | Erreurs, alertes critiques (fond `#FBE9E7`) |
| Info | Bleu | `#2B6CB0` | Hors ligne, passages en attente (fond `#E3EDF8`) |
| Sélection | Vert clair | `#E3F0EB` | Fond d'un choix sélectionné |
| Fond points | Ambre clair | `#FDF3DC` | Carte client, cadeaux |

Niveaux (fond / texte) : Bronze `#F3E3D3` / `#7A4519` · Silver `#E4E8EB` / `#3E4850` · Gold `#F8EAC4` / `#7A5A00`.

Règle : jamais de texte ambre sur blanc (contraste insuffisant). L'ambre est un fond, avec du texte encre dessus.

## Typographie

| Usage | Police | Graisse | Taille |
|---|---|---|---|
| Titres | Bricolage Grotesque | 800 | 28–34 px |
| Sous-titres | Bricolage Grotesque | 600 | 20–22 px |
| Texte | Inter | 400–600 | 16 px minimum dans les apps mobiles |
| Montants, litres, points | Inter | 700–800 | chiffres alignés (`tabular-nums`) |

## Formats

- Montants : FCFA entiers, espace entre les milliers, suffixe `F` : `13 125 F`.
- Litres : 2 décimales maximum, virgule : `11,43 L`.
- Téléphone : `07 08 45 12 12`, masqué côté pompiste : `07 08 •• •• 12`.

## Composants et tailles

| Élément | App pompiste | App client |
|---|---|---|
| Bouton d'action principal | 64 px de haut, rayon 16 | 60 px, rayon 16 |
| Autres boutons, choix produit | 52–56 px | 44–52 px |
| Touches du clavier PIN | 68 px | — |
| Champ de saisie | 60 px, bordure 2 px | 52 px |
| Rayon des cartes | 14–20 px | 18–22 px |

## Règles terrain

1. **Plein soleil** : texte encre sur fond clair, contraste 7:1 minimum pour les infos importantes.
2. **Une main** : l'action principale est toujours en bas de l'écran.
3. **Le téléphone change de main** : l'écran PIN passe en ambre pour signaler « c'est au client ».
4. **Réseau visible** : badge « En ligne » ou « Hors ligne · N » toujours affiché chez le pompiste.

## Les écrans de la v0.1

| Écran | Rôle |
|---|---|
| Pompiste 1 · Identifier | Scanner le QR ou taper le numéro, ou inscrire un nouveau client |
| Pompiste 2 · Saisir | Produit, litres ou FCFA, montants rapides, points calculés |
| Pompiste 3 · PIN | Le client vérifie le récapitulatif et tape son code |
| Pompiste 4 · Confirmé | Points gagnés, nouveau solde, cadeau disponible |
| Client 1 · Ma carte | QR code, solde, niveau, prochain cadeau, événement |
| Client 2 · Avis | Note du pompiste, étiquettes, commentaire privé |
| Back-office · Tableau de bord | Indicateurs, taux de capture, alertes, avis, classement des pompistes |
