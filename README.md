# Pop-up mises à jour matériel

Petit pop-up Windows (PowerShell + WinForms) qui vérifie si vos logiciels matériels sont à jour :

| Application | Comment la dernière version est vérifiée |
|---|---|
| **Pilote NVIDIA GeForce** | Service web officiel de NVIDIA (celui qu'utilise la NVIDIA app), pour votre carte exacte |
| **MSI Center** (Microsoft Store) | Catalogue public du Microsoft Store |
| **MSI Companion** (MSI Game Bar, Microsoft Store) | Catalogue public du Microsoft Store |
| **Cooler Master MasterPlus** | Page officielle masterplus.coolermaster.com |

Chaque carte affiche un indicateur :

- 🟢 **À jour** : la version installée est la dernière
- 🔴 **Mise à jour disponible** : avec la version installée → la nouvelle version
- 🟠 **Vérification impossible** : pas de connexion, application absente, etc.

Les vérifications ne font que lire : rien n'est téléchargé ni installé automatiquement. Le bouton **Ouvrir** lance l'application pour faire la mise à jour, **Revérifier** relance les contrôles, **Tout ouvrir** lance toutes les applications.

## Utilisation

Double-cliquer sur `MisesAJour.bat`.

Cocher **Afficher au démarrage de Windows** pour que le pop-up s'ouvre à chaque démarrage (un raccourci est créé dans le dossier Démarrage ; décocher pour le supprimer). Si le dossier du projet est déplacé, décocher puis recocher la case.

## Chemins utilisés

- `C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA App.exe`
- MSI Center et MSI Companion : détectés automatiquement via leur paquet Microsoft Store
- `C:\Program Files (x86)\CoolerMaster\MasterPlus\MasterPlusApp.exe`

Pour changer un chemin, modifier le tableau `$apps` en haut de `MisesAJour.ps1`.

## Prérequis

Windows 10/11 avec Windows PowerShell 5.1 (inclus dans Windows) et une connexion Internet pour les vérifications.
