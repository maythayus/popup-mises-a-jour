# Pop-up des mises à jour : pilote NVIDIA, MSI Center, MSI Companion, Cooler Master MasterPlus, Corsair iCUE, Intel Killer
# Chaque carte affiche un indicateur : vert = à jour, rouge = mise à jour disponible, gris = vérification impossible
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$apps = @(
    @{ Id = 'nvidia'; Nom = 'Pilote NVIDIA GeForce'; Couleur = '#76B900'
       Chemin = 'C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA App.exe'
       Aide = 'NVIDIA app > Pilotes > Rechercher des mises à jour' }
    @{ Id = 'msicenter'; Nom = 'MSI Center'; Couleur = '#E4002B'; Paquet = '*MSICenter*'
       Aide = 'Microsoft Store, puis Support > Live Update' }
    @{ Id = 'msicompanion'; Nom = 'MSI Companion (Game Bar)'; Couleur = '#E4002B'; Paquet = '*MSIGameBar*'
       Aide = 'Mise à jour via le Microsoft Store' }
    @{ Id = 'masterplus'; Nom = 'Cooler Master MasterPlus'; Couleur = '#7A3CFF'
       Chemin = 'C:\Program Files (x86)\CoolerMaster\MasterPlus\MasterPlusApp.exe'
       Aide = 'Paramètres > Mise à jour (logiciel + firmware)' }
    @{ Id = 'icue'; Nom = 'Corsair iCUE'; Couleur = '#FFD100'
       Chemin = 'C:\Program Files\Corsair\Corsair iCUE5 Software\iCUE.exe'
       Aide = 'iCUE > Paramètres > Mises à jour (logiciel + firmware)' }
    @{ Id = 'killer'; Nom = 'Intel Killer Performance Suite'; Couleur = '#0071C5'; Paquet = '*KillerControlCenter*'
       Aide = 'Mise à jour via le Microsoft Store' }
)

# Applications du Store : lancement via leur identifiant de paquet et d'application
foreach ($app in $apps | Where-Object { $_.Paquet }) {
    $pkg = Get-AppxPackage -Name $app.Paquet -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pkg) {
        $appId = @((Get-AppxPackageManifest $pkg).Package.Applications.Application)[0].Id
        if (-not $appId) { $appId = 'App' }
        $app.Chemin = "shell:AppsFolder\$($pkg.PackageFamilyName)!$appId"
    }
}

# Vérifications (exécutées en arrière-plan pour ne pas figer la fenêtre)
$verifications = {
    param($app)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $res = @{ Etat = 'inconnu'; Installe = $null; Dernier = $null; Detail = '' }
    try {
        switch ($app.Id) {
            'nvidia' {
                $gpu = Get-CimInstance Win32_VideoController | Where-Object PNPDeviceID -match 'VEN_10DE' | Select-Object -First 1
                if (-not $gpu) { throw 'Aucune carte NVIDIA détectée' }
                $d = $gpu.DriverVersion -replace '\.', ''
                $res.Installe = $d.Substring($d.Length - 5).Insert(3, '.')
                if ($gpu.PNPDeviceID -notmatch 'VEN_(\w{4})&DEV_(\w{4})&SUBSYS_(\w{4})(\w{4})') { throw 'Identifiant GPU illisible' }
                $q = @{ dIDa = @("$($Matches[2])_$($Matches[1])_$($Matches[3])_$($Matches[4])_0"); osC = '10.0'
                        osB = [string][Environment]::OSVersion.Version.Build; is6 = '1'; lg = '1036'; iLp = '0'
                        prvMd = '0'; dch = '1'; upCRD = '0'; isCRD = '0' } | ConvertTo-Json -Compress
                $url = 'https://gfwsl.geforce.com/nvidia_web_services/controller.gfeclientcontent.NG.php/com.nvidia.services.GFEClientContent_NG.getDispDrvrByDevid/' + [uri]::EscapeDataString($q)
                $r = Invoke-RestMethod $url -TimeoutSec 20
                $res.Dernier = $r.criteria.IsDispDriverNewer.latestDispDriverVersion
            }
            { $_ -in 'msicenter', 'msicompanion', 'killer' } {
                $pkg = Get-AppxPackage -Name $app.Paquet | Select-Object -First 1
                if (-not $pkg) { throw 'Application non installée' }
                $res.Installe = [string]$pkg.Version
                $url = "https://displaycatalog.mp.microsoft.com/v7.0/products/lookup?alternateId=PackageFamilyName&Value=$($pkg.PackageFamilyName)&market=FR&languages=fr-fr&fieldsTemplate=details"
                $r = Invoke-RestMethod $url -TimeoutSec 20
                $versions = $r.Products.DisplaySkuAvailabilities.Sku.Properties.Packages.PackageFullName |
                    ForEach-Object { if ($_ -match '_(\d+\.\d+\.\d+\.\d+)_') { [version]$Matches[1] } }
                $res.Dernier = [string]($versions | Sort-Object -Descending | Select-Object -First 1)
            }
            'masterplus' {
                if (-not (Test-Path $app.Chemin)) { throw 'Application non installée' }
                $cle = Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
                    Where-Object DisplayName -like 'MasterPlus*' | Select-Object -First 1
                $res.Installe = if ($cle.DisplayVersion) { $cle.DisplayVersion } else { (Get-Item $app.Chemin).VersionInfo.ProductVersion }
                $page = Invoke-WebRequest 'https://masterplus.coolermaster.com/' -UseBasicParsing -TimeoutSec 20 -UserAgent 'Mozilla/5.0'
                if ($page.Content -match 'MASTERPLUS\+?\s*V\s*(\d+(?:\.\d+)+)') { $res.Dernier = $Matches[1] }
            }
            'icue' {
                if (-not (Test-Path $app.Chemin)) { throw 'Application non installée' }
                $cle = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
                    Where-Object DisplayName -eq 'Corsair iCUE5 Software' | Select-Object -First 1
                $res.Installe = if ($cle.DisplayVersion) { $cle.DisplayVersion } else { (Get-Item $app.Chemin).VersionInfo.ProductVersion }
                # Catalogue officiel winget (Corsair.iCUE.5), lu sur GitHub
                $r = Invoke-RestMethod 'https://api.github.com/repos/microsoft/winget-pkgs/contents/manifests/c/Corsair/iCUE/5' -TimeoutSec 20 -UserAgent 'popup-mises-a-jour'
                $versions = $r | Where-Object type -eq 'dir' | ForEach-Object { try { [version]$_.name } catch {} }
                $res.Dernier = [string]($versions | Sort-Object -Descending | Select-Object -First 1)
            }
        }
        if (-not $res.Dernier) { throw 'Dernière version introuvable' }
        $res.Etat = if ([version]$res.Installe -ge [version]$res.Dernier) { 'ok' } else { 'maj' }
    } catch {
        $res.Detail = $_.Exception.Message
    }
    $res
}

$fond   = [System.Drawing.ColorTranslator]::FromHtml('#1E1F24')
$carte  = [System.Drawing.ColorTranslator]::FromHtml('#2A2C33')
$texte  = [System.Drawing.Color]::WhiteSmoke
$gris   = [System.Drawing.ColorTranslator]::FromHtml('#A0A4AE')
$etats  = @{
    attente = @{ Couleur = '#A0A4AE'; Texte = 'Vérification…' }
    ok      = @{ Couleur = '#2ECC71'; Texte = 'À jour' }
    maj     = @{ Couleur = '#E74C3C'; Texte = 'Mise à jour disponible' }
    inconnu = @{ Couleur = '#F39C12'; Texte = 'Vérification impossible' }
}

function Start-App($app) {
    try {
        if (-not $app.Chemin) { throw 'Application introuvable' }
        if ($app.Chemin -like 'shell:*') { Start-Process explorer.exe $app.Chemin }
        else { Start-Process -FilePath $app.Chemin }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Impossible d'ouvrir $($app.Nom) :`n$($_.Exception.Message)", 'Erreur', 'OK', 'Error') | Out-Null
    }
}

function Set-Etat($app, $etat, $detail) {
    $e = $etats[$etat]
    $app.Pastille.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($e.Couleur)
    $app.Statut.ForeColor = $app.Pastille.ForeColor
    $app.Statut.Text = if ($detail) { "$($e.Texte) · $detail" } else { $e.Texte }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Mises à jour matériel'
$form.ClientSize = New-Object System.Drawing.Size(560, 700)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.TopMost = $true
$form.BackColor = $fond
$form.ForeColor = $texte
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$titre = New-Object System.Windows.Forms.Label
$titre.Text = 'Mises à jour matériel'
$titre.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 14)
$titre.Location = New-Object System.Drawing.Point(20, 15)
$titre.AutoSize = $true
$form.Controls.Add($titre)

$resume = New-Object System.Windows.Forms.Label
$resume.Text = 'Vérification en cours…'
$resume.ForeColor = $gris
$resume.Location = New-Object System.Drawing.Point(22, 48)
$resume.Size = New-Object System.Drawing.Size(510, 22)
$form.Controls.Add($resume)

$y = 80
foreach ($app in $apps) {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(20, $y)
    $panel.Size = New-Object System.Drawing.Size(520, 84)
    $panel.BackColor = $carte

    $barre = New-Object System.Windows.Forms.Panel
    $barre.Size = New-Object System.Drawing.Size(5, 84)
    $barre.BackColor = [System.Drawing.ColorTranslator]::FromHtml($app.Couleur)
    $panel.Controls.Add($barre)

    $app.Pastille = New-Object System.Windows.Forms.Label
    $app.Pastille.Text = '●'
    $app.Pastille.Font = New-Object System.Drawing.Font('Segoe UI', 16)
    $app.Pastille.Location = New-Object System.Drawing.Point(14, 22)
    $app.Pastille.Size = New-Object System.Drawing.Size(30, 34)
    $panel.Controls.Add($app.Pastille)

    $nom = New-Object System.Windows.Forms.Label
    $nom.Text = $app.Nom
    $nom.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 10)
    $nom.Location = New-Object System.Drawing.Point(48, 8)
    $nom.Size = New-Object System.Drawing.Size(355, 22)
    $panel.Controls.Add($nom)

    $app.Statut = New-Object System.Windows.Forms.Label
    $app.Statut.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $app.Statut.Location = New-Object System.Drawing.Point(48, 32)
    $app.Statut.Size = New-Object System.Drawing.Size(355, 20)
    $panel.Controls.Add($app.Statut)

    $aide = New-Object System.Windows.Forms.Label
    $aide.Text = $app.Aide
    $aide.ForeColor = $gris
    $aide.Font = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $aide.Location = New-Object System.Drawing.Point(48, 55)
    $aide.Size = New-Object System.Drawing.Size(355, 20)
    $panel.Controls.Add($aide)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = 'Ouvrir'
    $btn.Location = New-Object System.Drawing.Point(415, 25)
    $btn.Size = New-Object System.Drawing.Size(90, 34)
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml($app.Couleur)
    $btn.BackColor = $fond
    $btn.Tag = $app
    $btn.Enabled = [bool]$app.Chemin -and ($app.Chemin -like 'shell:*' -or (Test-Path $app.Chemin))
    $btn.Add_Click({ Start-App $this.Tag })
    $panel.Controls.Add($btn)

    $form.Controls.Add($panel)
    $y += 94
}

# Lance les vérifications en parallèle et met à jour les pastilles quand elles se terminent
$taches = New-Object System.Collections.ArrayList
function Start-Verifications {
    $resume.Text = 'Vérification en cours…'
    $resume.ForeColor = $gris
    $revoir.Enabled = $false
    foreach ($app in $apps) {
        Set-Etat $app 'attente'
        $ps = [powershell]::Create().AddScript($verifications).AddArgument(@{ Id = $app.Id; Paquet = $app.Paquet; Chemin = $app.Chemin })
        [void]$taches.Add(@{ App = $app; PS = $ps; Handle = $ps.BeginInvoke() })
    }
    $minuteur.Start()
}

$minuteur = New-Object System.Windows.Forms.Timer
$minuteur.Interval = 300
$minuteur.Add_Tick({
    foreach ($t in @($taches)) {
        if (-not $t.Handle.IsCompleted) { continue }
        $r = $t.PS.EndInvoke($t.Handle) | Select-Object -Last 1
        $t.PS.Dispose()
        $taches.Remove($t)
        $app = $t.App
        $app.Resultat = $r
        switch ($r.Etat) {
            'ok'    { Set-Etat $app 'ok' "v$($r.Installe)" }
            'maj'   { Set-Etat $app 'maj' "v$($r.Installe) → v$($r.Dernier)" }
            default { Set-Etat $app 'inconnu' $r.Detail }
        }
    }
    if ($taches.Count -eq 0) {
        $minuteur.Stop()
        $revoir.Enabled = $true
        $nbMaj = @($apps | Where-Object { $_.Resultat.Etat -eq 'maj' }).Count
        $nbInconnu = @($apps | Where-Object { $_.Resultat.Etat -eq 'inconnu' }).Count
        if ($nbMaj) {
            $resume.Text = "$nbMaj mise(s) à jour à faire"
            $resume.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($etats.maj.Couleur)
        } elseif ($nbInconnu) {
            $resume.Text = "$nbInconnu application(s) non vérifiée(s), le reste est à jour"
            $resume.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($etats.inconnu.Couleur)
        } else {
            $resume.Text = 'Tout est à jour'
            $resume.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($etats.ok.Couleur)
        }
    }
})

$demarrage = New-Object System.Windows.Forms.CheckBox
$raccourci = Join-Path ([Environment]::GetFolderPath('Startup')) 'Mises a jour materiel.lnk'
$demarrage.Text = 'Afficher au démarrage de Windows'
$demarrage.Location = New-Object System.Drawing.Point(22, ($y + 12))
$demarrage.AutoSize = $true
$demarrage.Checked = Test-Path $raccourci
$demarrage.Add_CheckedChanged({
    if ($this.Checked) {
        $wsh = New-Object -ComObject WScript.Shell
        $lnk = $wsh.CreateShortcut($raccourci)
        $lnk.TargetPath = 'powershell.exe'
        $lnk.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        $lnk.IconLocation = 'shell32.dll,238'
        $lnk.Save()
    } elseif (Test-Path $raccourci) {
        Remove-Item $raccourci -Force
    }
})
$form.Controls.Add($demarrage)

$revoir = New-Object System.Windows.Forms.Button
$revoir.Text = 'Revérifier'
$revoir.Location = New-Object System.Drawing.Point(240, ($y + 6))
$revoir.Size = New-Object System.Drawing.Size(95, 34)
$revoir.FlatStyle = 'Flat'
$revoir.BackColor = $carte
$revoir.Add_Click({ Start-Verifications })
$form.Controls.Add($revoir)

$tout = New-Object System.Windows.Forms.Button
$tout.Text = 'Tout ouvrir'
$tout.Location = New-Object System.Drawing.Point(345, ($y + 6))
$tout.Size = New-Object System.Drawing.Size(100, 34)
$tout.FlatStyle = 'Flat'
$tout.BackColor = [System.Drawing.ColorTranslator]::FromHtml('#3A6FF7')
$tout.Add_Click({ foreach ($a in $apps) { if ($a.Chemin) { Start-App $a } }; $form.Close() })
$form.Controls.Add($tout)

$fermer = New-Object System.Windows.Forms.Button
$fermer.Text = 'Plus tard'
$fermer.Location = New-Object System.Drawing.Point(455, ($y + 6))
$fermer.Size = New-Object System.Drawing.Size(85, 34)
$fermer.FlatStyle = 'Flat'
$fermer.BackColor = $carte
$fermer.Add_Click({ $form.Close() })
$form.Controls.Add($fermer)
$form.CancelButton = $fermer

$form.Add_Shown({ Start-Verifications })
[void]$form.ShowDialog()
