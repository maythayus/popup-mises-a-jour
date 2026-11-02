# Pop-up mises à jour matériel

Petit pop-up Windows (PowerShell + WinForms) qui rappelle de vérifier les mises à jour de :

| Application | Où trouver la mise à jour |
|---|---|
| **NVIDIA app** (pilotes GeForce) | Pilotes > Rechercher des mises à jour |
| **MSI Center** (Microsoft Store) + **MSI Companion** | Support > Live Update |
| **Cooler Master MasterPlus** | Paramètres > Mise à jour (logiciel + firmware) |

Chaque application affiche sa version installée et un bouton **Ouvrir**. Le bouton **Tout ouvrir** lance les trois d'un coup.

## Utilisation

Double-cliquer sur `MisesAJour.bat`.

Cocher **Afficher au démarrage de Windows** pour que le pop-up s'ouvre à chaque démarrage (un raccourci est créé dans le dossier Démarrage ; décocher pour le supprimer). Si le dossier du projet est déplacé, décocher puis recocher la case.

## Chemins utilisés

- `C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA App.exe`
- MSI Center : détecté automatiquement via son paquet Microsoft Store (`Get-AppxPackage *MSICenter*`)
- `C:\Program Files (x86)\CoolerMaster\MasterPlus\MasterPlusApp.exe`

Pour changer un chemin, modifier le tableau `$apps` en haut de `MisesAJour.ps1`.

## Prérequis

Windows 10/11 avec Windows PowerShell 5.1 (inclus dans Windows).
