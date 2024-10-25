# Projet 2 - Gestion Automatisée des Utilisateurs et des Groupes pour une PME

Ce projet a été réalisé dans le cadre de la gestion des utilisateurs et des groupes au sein d'une PME, avec des fonctionnalités étendues pour la gestion des droits d'accès.

## Résumé

Le script Bash développé automatise plusieurs tâches essentielles de gestion des utilisateurs et des groupes :
- **Ajout, modification et suppression d'utilisateurs**
- **Gestion des permissions via ACL sur des répertoires partagés**
- **Création et gestion de groupes fonctionnels**
- **Détection des utilisateurs inactifs et suppression ou verrouillage de leurs comptes**

## Fonctionnalités

### 1. Ajout et Modification des Utilisateurs
- Le script lit une liste d'utilisateurs depuis un fichier `.txt` et les ajoute au système avec leurs informations (groupe, shell, répertoire).
- Les utilisateurs existants peuvent être modifiés (changement de groupe, répertoire, etc.).
- Un mot de passe par défaut est attribué à chaque utilisateur avec expiration automatique.
  
Commandes utilisées : `useradd`, `usermod`, `chpasswd`.

### 2. Gestion des Utilisateurs Inactifs
- Détection des utilisateurs inactifs depuis une période spécifiée (90 jours par défaut).
- Alerte et proposition de verrouillage ou suppression des comptes inactifs avec sauvegarde des données utilisateur.
  
Commandes utilisées : `lastlog`, `userdel`, `chage`.

### 3. Gestion des Groupes
- Création de groupes fonctionnels (ex : "Marketing", "RH").
- Ajout automatique des utilisateurs aux groupes lors de leur création ou modification.
- Suppression des groupes vides.

Commandes utilisées : `groupadd`, `groupmod`, `groupdel`.

### 4. Attribution des Permissions via ACL
- Configuration des permissions avancées via ACL pour les répertoires partagés selon les rôles (ex : accès lecture pour "RH", lecture et écriture pour "Direction").
- Application des ACL aux nouveaux fichiers dans les répertoires partagés.

Commandes utilisées : `setfacl`, `getfacl`.


## Exécution
Pour exécuter le script, assurez-vous de disposer des droits d'administration et lancez-le comme suit :
```bash
sudo ./gestion_utilisateurs.sh
