# CovoiturageESMT - Frontend

Application mobile/web de covoiturage universitaire pour la communauté ESMT, développée avec Flutter. Ce dépôt contient uniquement le frontend ; le backend Spring Boot est disponible dans un dépôt séparé.

## Description

CovoiturageESMT permet aux étudiants et au personnel de l'ESMT de publier des trajets en tant que conducteur, rechercher et réserver des trajets en tant que passager, suivre en temps réel un trajet réservé grâce à la géolocalisation, évaluer un conducteur après un trajet, gérer son profil et son historique, et administrer les comptes utilisateurs.

Le rôle Conducteur/Passager n'est pas un champ figé : il est déterminé automatiquement selon que l'utilisateur possède ou non un véhicule enregistré.

## Prérequis

- Flutter SDK (^3.11.5)
- Chrome (pour lancer en mode web, utilisé pendant tout le développement)
- Le backend Spring Boot doit tourner en local sur http://localhost:8080 (voir le dépôt backend pour les instructions)
- Sur Windows, le Mode développeur doit être activé (Paramètres > Confidentialité et sécurité > Pour les développeurs > Mode développeur), nécessaire pour certains plugins Flutter utilisant des liens symboliques

## Installation

```bash
git clone https://github.com/habibfl/covoiturage_esmt_frontend.git
cd covoiturage_esmt_frontend
flutter pub get
```

## Configuration de l'URL du backend

L'URL de base de l'API est définie dans lib/constants/api_constants.dart :

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api';
}
```

Adapter cette valeur si le backend tourne sur une autre adresse, par exemple une IP locale pour tester sur un téléphone physique.

## Firebase et Google Maps

Le fichier lib/firebase_options.dart est déjà présent dans ce dépôt et pointe vers un projet Firebase déjà configuré (Realtime Database, utilisée pour le suivi GPS en temps réel). Aucune configuration supplémentaire n'est nécessaire, tout fonctionne directement après un flutter pub get. Ce projet Firebase est utilisé uniquement côté frontend, le backend gère ses propres données via PostgreSQL.

La clé API Google Maps est déjà intégrée dans web/index.html, elle aussi prête à l'emploi.

Si vous préférez utiliser vos propres projets, il faudra créer un projet sur console.firebase.google.com, activer Realtime Database, installer FlutterFire CLI avec dart pub global activate flutterfire_cli puis lancer flutterfire configure à la racine du projet, et remplacer la clé Google Maps dans web/index.html par la vôtre.

## Lancer le projet

Toujours lancer avec un port fixe, pour que la session de connexion (token JWT stocké en local storage) persiste entre les redémarrages :

```bash
flutter run -d chrome --web-port=5000
```

Puis ouvrir http://localhost:5000 si le navigateur ne s'ouvre pas automatiquement.

## Comptes de test

Aucun compte de test n'est fourni dans ce dépôt. Chaque développeur doit créer son propre compte via l'écran d'inscription, avec une adresse email @esmt.sn valide qu'il peut consulter pour recevoir le code de validation.

Pour tester le rôle Conducteur, il faut ajouter un véhicule depuis l'écran Profil après inscription. Pour tester le rôle Passager, il suffit de ne pas ajouter de véhicule.

La connexion nécessite une validation par code reçu par email (2FA). Le code est envoyé à l'adresse utilisée à l'inscription.

Pour tester le rôle Administrateur, le compte doit avoir le champ role positionné à ROLE_ADMIN directement en base de données, aucune interface ne permet de le faire depuis l'app.

Astuce pour tester plusieurs comptes avec une seule boîte mail : si votre fournisseur email le supporte, comme Gmail ou Outlook, utilisez un alias avec le signe plus. Par exemple votre.email+conducteur@esmt.sn et votre.email+passager@esmt.sn arrivent tous les deux dans votre boîte principale, mais sont traités comme deux comptes distincts par le backend.

## Règles de validation

Email : doit se terminer par @esmt.sn

Mot de passe : minimum 8 caractères, au moins une majuscule, une minuscule, un chiffre et un caractère spécial parmi @#$%^&+=!

## Dépannage

Si la connexion échoue avec une erreur CORS visible dans la console du navigateur, vérifiez que le backend tourne bien et que sa configuration CORS autorise votre port actuel. Le plus simple est de toujours lancer avec flutter run -d chrome --web-port=5000 pour garder un port fixe et éviter ce genre de souci, plutôt que de laisser Flutter choisir un port aléatoire à chaque redémarrage.

Le code de vérification par email peut parfois prendre une minute ou deux avant d'arriver, pensez à vérifier aussi le dossier des courriers indésirables.

Un conducteur ne peut pas réserver son propre trajet, c'est un comportement normal et volontaire du backend, pas un bug.

Si une tentative de réservation échoue avec le message "Vous avez déjà réservé ce trajet", cela signifie qu'une réservation existe déjà pour ce trajet et cet utilisateur, même si elle a été annulée depuis. Ce comportement dépend de la version du backend utilisée à un instant donné.

Si l'app redémarre et que vous êtes déconnecté alors que vous étiez bien connecté juste avant, c'est probablement parce que le port a changé entre deux lancements de flutter run, ce qui invalide la session stockée localement dans le navigateur. Reconnectez-vous simplement.

## Parcours de test recommandé

Pour valider rapidement que tout fonctionne, voici un parcours simple à suivre avec deux comptes distincts créés via l'astuce de l'alias email :

1. Créer un premier compte, ajouter un véhicule pour devenir Conducteur, puis publier un trajet
2. Créer un second compte, rechercher ce trajet et le réserver
3. Se reconnecter avec le premier compte, aller dans les demandes de réservation et confirmer la demande
4. Se reconnecter avec le second compte, aller sur le suivi du trajet et vérifier que le statut affiche bien Confirmée
5. Depuis le premier compte, démarrer le trajet pour activer le suivi GPS, puis vérifier depuis le second compte que la position s'affiche sur la carte en temps réel
6. Une fois le trajet terminé côté conducteur, le second compte peut laisser un avis sur le conducteur depuis l'historique des trajets

## Fonctionnalités implémentées

- Inscription avec upload de carte étudiante
- Connexion avec validation 2FA par email
- Mot de passe oublié et réinitialisation
- Ajout de véhicule, devient Conducteur
- Publication de trajet
- Recherche de trajets avec filtrage en temps réel
- Réservation de place
- Gestion des demandes de réservation côté conducteur, accepter ou refuser
- Suivi de trajet réservé avec détection automatique de la réservation active
- Suivi GPS en temps réel via Firebase et Google Maps
- Annulation de réservation
- Système d'évaluation avec note moyenne du conducteur
- Historique des trajets pour le passager et le conducteur
- Notifications
- Espace Administrateur avec liste des utilisateurs, blocage et déblocage de comptes
- Mode sombre

## Limitations connues

Un conducteur ne peut pas encore laisser d'avis sur un passager, le backend n'expose pas encore l'identifiant du passager dans les réponses de réservation.

Le suivi local des avis déjà laissés est stocké par appareil dans SharedPreferences, le backend reste la source de vérité en cas de doublon.

Le bouton Contact n'est pas encore fonctionnel, le backend n'expose pas le numéro de téléphone dans les réponses de trajet ou de réservation.

## Architecture du projet

lib/constants contient les couleurs et constantes API. lib/screens contient les écrans de l'application. lib/services contient les appels API pour l'authentification, les véhicules, les trajets, les réservations et les avis. lib/theme contient le thème clair et sombre. lib/widgets contient les composants réutilisables comme les boutons, les champs et les cartes.

## Stack technique

Flutter et Dart, go_router pour la navigation, http pour les requêtes API, shared_preferences pour le stockage local du token JWT, google_fonts pour la police Inter, google_maps_flutter, geolocator pour la géolocalisation en continu, firebase_core, firebase_database et firebase_storage, image_picker et file_picker.