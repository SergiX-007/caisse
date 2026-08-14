# Caisse

Suivi des transferts d'argent Maurice → Madagascar et des finances personnelles.
Application d'une seule page (`caisse.html`), sans build ni dépendance à installer :
les données sont lues et écrites dans une base Postgres hébergée sur Supabase.

## Utilisation

Ouvrir `caisse.html` dans un navigateur. La pastille en haut à droite indique l'état :

| État | Signification |
|---|---|
| **Enregistré** (vert) | tout est écrit dans la base |
| **Modification / Enregistrement** (orange) | écriture en cours |
| **Non enregistré / Hors ligne** (rouge) | la base est injoignable, un message détaille la suite |

L'application a besoin du réseau : sans connexion, rien n'est lu ni enregistré.
Les boutons **Exporter / Importer la sauvegarde** restent disponibles pour un
fichier JSON de secours.

Au premier lancement, si d'anciennes données existent dans le `localStorage` du
navigateur, l'application propose de les transférer vers la base. La reprise n'est
proposée que tant que la base est vide.

## Base de données

Projet Supabase `caisse` (région `ap-south-1`, la plus proche de Maurice).
URL et clé publique sont en tête du script, dans `caisse.html` :

```js
const SUPABASE_URL = 'https://vuznzycuiomaedoebvkg.supabase.co';
const SUPABASE_CLE = 'sb_publishable_...';
```

### Tables

| Table | Contenu | Clés |
|---|---|---|
| `clients` | personnes qui déposent de l'argent | `id` (texte, généré côté navigateur) |
| `contacts` | destinataires à Madagascar | `client_id` → `clients` (suppression en cascade) |
| `operations` | dépôt, envoi ou remise | `client_id` → `clients` (cascade), `contact_id` → `contacts` (mis à `null`) |
| `finances` | dépenses et revenus personnels | — |
| `reglages` | ligne unique : `banque`, `liquide`, `ouverture` | `id = 1` |

Les montants sont en `numeric`, les dates en `date`, et `cree` conserve
l'horodatage de création (millisecondes) qui sert à l'ordre d'affichage.

### Enregistrement

L'état complet reste en mémoire dans le navigateur et sert à l'affichage. Après
chaque modification, un instantané du dernier enregistrement réussi est comparé à
l'état courant, et seules les lignes créées, modifiées ou supprimées sont envoyées
(600 ms de temporisation). Les suppressions partent des enfants vers les parents,
les écritures dans l'ordre inverse, pour respecter les clés étrangères. En cas
d'échec, l'instantané n'est pas mis à jour : la tentative suivante renvoie tout ce
qui manquait.

## Accès et confidentialité

**La base est ouverte en lecture et en écriture sans authentification.** Les
policies RLS autorisent le rôle anonyme sur toutes les tables, et ce dépôt est
public : toute personne qui lit ce fichier peut consulter et modifier l'intégralité
des données (noms des clients, montants, numéros des destinataires).

Pour restreindre l'accès, il faut activer Supabase Auth et remplacer les policies
`acces public *` par des policies liées à `auth.uid()`.
