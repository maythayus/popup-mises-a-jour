# Pop-up de rappel des mises à jour : NVIDIA app, MSI Center / MSI Companion, Cooler Master MasterPlus
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$msiPkg = Get-AppxPackage -Name '*MSICenter*' -ErrorAction SilentlyContinue | Select-Object -First 1

$apps = @(
    @{ Nom = 'NVIDIA app (pilotes GeForce)'; Couleur = '#76B900'
       Chemin = 'C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA App.exe'
       Aide = 'Onglet Pilotes > Rechercher des mises à jour' }
    @{ Nom = 'MSI Center + MSI Companion'; Couleur = '#E4002B'
       Chemin = if ($msiPkg) { "shell:AppsFolder\$($msiPkg.PackageFamilyName)!App" } else { $null }
       Version = if ($msiPkg) { $msiPkg.Version } else { $null }
       Aide = 'Support > Live Update (met aussi à jour Companion)' }
    @{ Nom = 'Cooler Master MasterPlus'; Couleur = '#7A3CFF'
       Chemin = 'C:\Program Files (x86)\CoolerMaster\MasterPlus\MasterPlusApp.exe'
       Aide = 'Paramètres > Mise à jour (logiciel + firmware)' }
)

function Get-AppVersion($app) {
    if ($app.Version) { return "v$($app.Version)" }
    if ($app.Chemin -and (Test-Path $app.Chemin)) {
        $v = (Get-Item $app.Chemin).VersionInfo.ProductVersion
        if ($v) { return "v$v" } else { return 'installé' }
    }
    return 'introuvable'
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

$fond   = [System.Drawing.ColorTranslator]::FromHtml('#1E1F24')
$carte  = [System.Drawing.ColorTranslator]::FromHtml('#2A2C33')
$texte  = [System.Drawing.Color]::WhiteSmoke
$gris   = [System.Drawing.ColorTranslator]::FromHtml('#A0A4AE')

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Mises à jour matériel'
$form.Size = New-Object System.Drawing.Size(520, 430)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.TopMost = $true
$form.BackColor = $fond
$form.ForeColor = $texte
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$titre = New-Object System.Windows.Forms.Label
$titre.Text = 'Pensez à vérifier vos mises à jour'
$titre.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 14)
$titre.Location = New-Object System.Drawing.Point(20, 15)
$titre.AutoSize = $true
$form.Controls.Add($titre)

$y = 60
foreach ($app in $apps) {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(20, $y)
    $panel.Size = New-Object System.Drawing.Size(465, 70)
    $panel.BackColor = $carte

    $barre = New-Object System.Windows.Forms.Panel
    $barre.Size = New-Object System.Drawing.Size(5, 70)
    $barre.BackColor = [System.Drawing.ColorTranslator]::FromHtml($app.Couleur)
    $panel.Controls.Add($barre)

    $nom = New-Object System.Windows.Forms.Label
    $nom.Text = "$($app.Nom)   ($(Get-AppVersion $app))"
    $nom.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 10)
    $nom.Location = New-Object System.Drawing.Point(15, 10)
    $nom.Size = New-Object System.Drawing.Size(330, 22)
    $panel.Controls.Add($nom)

    $aide = New-Object System.Windows.Forms.Label
    $aide.Text = $app.Aide
    $aide.ForeColor = $gris
    $aide.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $aide.Location = New-Object System.Drawing.Point(15, 36)
    $aide.Size = New-Object System.Drawing.Size(330, 22)
    $panel.Controls.Add($aide)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = 'Ouvrir'
    $btn.Location = New-Object System.Drawing.Point(360, 18)
    $btn.Size = New-Object System.Drawing.Size(90, 34)
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml($app.Couleur)
    $btn.BackColor = $fond
    $btn.Tag = $app
    $btn.Enabled = [bool]$app.Chemin -and ($app.Chemin -like 'shell:*' -or (Test-Path $app.Chemin))
    $btn.Add_Click({ Start-App $this.Tag })
    $panel.Controls.Add($btn)

    $form.Controls.Add($panel)
    $y += 80
}

$demarrage = New-Object System.Windows.Forms.CheckBox
$raccourci = Join-Path ([Environment]::GetFolderPath('Startup')) 'Mises a jour materiel.lnk'
$demarrage.Text = 'Afficher au démarrage de Windows'
$demarrage.Location = New-Object System.Drawing.Point(22, ($y + 5))
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

$tout = New-Object System.Windows.Forms.Button
$tout.Text = 'Tout ouvrir'
$tout.Location = New-Object System.Drawing.Point(285, $y)
$tout.Size = New-Object System.Drawing.Size(100, 34)
$tout.FlatStyle = 'Flat'
$tout.BackColor = [System.Drawing.ColorTranslator]::FromHtml('#3A6FF7')
$tout.Add_Click({ foreach ($a in $apps) { if ($a.Chemin) { Start-App $a } }; $form.Close() })
$form.Controls.Add($tout)

$fermer = New-Object System.Windows.Forms.Button
$fermer.Text = 'Plus tard'
$fermer.Location = New-Object System.Drawing.Point(395, $y)
$fermer.Size = New-Object System.Drawing.Size(90, 34)
$fermer.FlatStyle = 'Flat'
$fermer.BackColor = $carte
$fermer.Add_Click({ $form.Close() })
$form.Controls.Add($fermer)
$form.CancelButton = $fermer

[void]$form.ShowDialog()
