# CovoiturageESMT — Frontend

Application mobile/web de covoiturage universitaire pour la communauté ESMT, développée avec Flutter. Ce dépôt contient uniquement le frontend ; le backend Spring Boot est disponible dans un dépôt séparé.

## Description

CovoiturageESMT permet aux étudiants et au personnel de l'ESMT de :
- Publier des trajets en tant que conducteur (avec véhicule enregistré)
- Rechercher et réserver des trajets en tant que passager
- Suivre en temps réel un trajet réservé
- Gérer son profil, son véhicule et l'historique de ses trajets

Le rôle Conducteur/Passager n'est pas un champ figé : il est déterminé automatiquement selon que l'utilisateur possède ou non un véhicule enregistré.

## Prérequis

- Flutter SDK (^3.11.5)
- Chrome (pour lancer en mode web, utilisé pendant tout le développement)
- Le backend Spring Boot doit tourner en local sur `http://localhost:8080` (voir le dépôt backend pour les instructions)

## Installation

```bash
git clone https://github.com/habibfl/covoiturage_esmt_frontend.git
cd covoiturage_esmt_frontend
flutter pub get
```

## Configuration de l'URL du backend

L'URL de base de l'API est définie dans `lib/constants/api_constants.dart` :

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api';
}
```

Adapter cette valeur si le backend tourne sur une autre adresse (ex: IP locale pour tester sur un téléphone physique).

## Lancer le projet

**Important** : toujours lancer avec un port fixe, pour que la session de connexion (token JWT stocké en local storage) persiste entre les redémarrages :

```bash
flutter run -d chrome --web-port=5000
```

Puis ouvrir `http://localhost:5000` si le navigateur ne s'ouvre pas automatiquement.

## Comptes de test

Aucun compte de test n'est fourni dans ce dépôt. Chaque développeur doit créer son propre compte via l'écran d'inscription, avec une adresse email `@esmt.sn` valide qu'il peut consulter (pour recevoir le code de validation).

Pour tester le rôle Conducteur, ajouter un véhicule depuis l'écran Profil après inscription. Pour tester le rôle Passager, ne pas ajouter de véhicule.

⚠️ La connexion nécessite une validation par code reçu par email (2FA). Le code est envoyé à l'adresse utilisée à l'inscription.

### Astuce pour tester plusieurs comptes avec une seule boîte mail

Si votre fournisseur email le supporte (Gmail, Outlook...), utilisez un alias avec `+` :
`votre.email+conducteur@esmt.sn` et `votre.email+passager@esmt.sn` arrivent tous les deux dans votre boîte principale, mais sont traités comme deux comptes distincts par le backend.

## Règles de validation

- **Email** : doit se terminer par `@esmt.sn`
- **Mot de passe** : minimum 8 caractères, au moins une majuscule, une minuscule, un chiffre et un caractère spécial parmi `@#$%^&+=!`

## Fonctionnalités implémentées

- [x] Inscription avec upload de carte étudiante
- [x] Connexion avec validation 2FA par email
- [x] Mot de passe oublié / réinitialisation
- [x] Ajout de véhicule (devient Conducteur)
- [x] Publication de trajet
- [x] Recherche de trajets
- [x] Réservation de place
- [x] Suivi de trajet réservé (avec détection automatique de la réservation active)
- [x] Annulation de réservation
- [x] Historique des trajets
- [x] Notifications (écran présent, contenu à connecter)
- [x] Mode sombre
- [ ] Gestion des demandes de réservation côté conducteur (accepter/refuser)
- [ ] Suivi GPS en temps réel (position du véhicule)

## Architecture du projet

lib/
├── constants/ # Couleurs, constantes API
├── screens/ # Écrans de l'application
├── services/ # Appels API (auth, véhicule, trajet, réservation)
├── theme/ # Thème clair/sombre
└── widgets/ # Composants réutilisables (boutons, champs, cartes)


## Problèmes connus côté backend

Voir les issues ou contacter l'équipe backend pour :
- Gestion des messages d'erreur métier (certaines exceptions ne renvoient pas de message clair)
- Vérification de doublon de réservation qui ne prend pas en compte les réservations annulées

## Stack technique

- Flutter / Dart
- go_router (navigation)
- http (requêtes API)
- shared_preferences (stockage local du token JWT)
- google_fonts
- google_maps_flutter
- firebase_core / firebase_database / firebase_storage
- image_picker / file_picker