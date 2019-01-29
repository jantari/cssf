# cssf
The Chocolatey Silent Switch Finder

Syntax:
```powershell
.\cssf.ps1
    -Softwarename <String>
    [-FindSilentArgs]
    [-LimitResults <Uint>]
    [<CommonParameters>]
```

Use this script to find the silent install switches for software as they are used  
by the popular [Chocolatey](https://chocolatey.org/) software manager for Windows.

The name is a reference to the [Ultimate silent switch finder](https://deployhappiness.com/the-ultimate-exe-silent-switch-finder/) which is great but  
it relies on recognizing what kind of installer your software is using and since it's  
not being updated anymore it might not recognize newer software and their installers.

This script searches the Chocolatey repositories for the silent switches they use,  
which ensures they're always reasonably up to date and "tested" - even for oddball  
software with weird installers.

Example usage and output:
```powershell
.\cssf.ps1 -Softwarename 'nextcloud' -LimitResults 3 -FindSilentArgs
3 results found for 'nextcloud'.

Name                  : Nextcloud Client
Version               : 2.5.1.20190121
Author                : Nextcloud
ChocolateyPackageName : nextcloud-client
SilentArgs            : {silentArgs    = '/S', silentArgs    = '/S', silentArgs    = '/S', silentArgs    = '/S'...}

Name                  : QOwnNotes
Version               : 19.1.1
Author                : Patrizio Bekerle
ChocolateyPackageName : qownnotes
SilentArgs            : {}

Name                  : (unofficial) Choco Package List Backup to Local and Cloud (Script + Task)
Version               : 2019.01.24
Author                : Bill Curran
ChocolateyPackageName : choco-package-list-backup
SilentArgs            : {}
```

Please note that this script uses the Chocolatey, GitHub and/or GitLab APIs. These APIs may be rate-limited
so sending a very excessive amount of requests their way could land your IP in a short timeout until you can request again.
