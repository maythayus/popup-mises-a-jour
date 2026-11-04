# Construit MisesAJour.exe à partir de MisesAJour.ps1 avec le compilateur C# fourni par Windows
$racine = Split-Path $PSScriptRoot
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$icone = Join-Path $PSScriptRoot 'icone.ico'
$sortie = Join-Path $racine 'MisesAJour.exe'

# Icône : pastille verte avec une flèche de mise à jour
if (-not (Test-Path $icone)) {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 64, 64
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml('#2ECC71'))), 2, 2, 60, 60)
    $stylo = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 7
    $stylo.StartCap = 'Round'; $stylo.EndCap = 'Round'
    $g.DrawLine($stylo, 32, 16, 32, 44)
    $g.DrawLine($stylo, 20, 32, 32, 45)
    $g.DrawLine($stylo, 44, 32, 32, 45)
    $g.Dispose()
    $fichier = [System.IO.File]::Create($icone)
    [System.Drawing.Icon]::FromHandle($bmp.GetHicon()).Save($fichier)
    $fichier.Close()
}

& $csc /nologo /target:winexe /optimize+ /codepage:65001 "/out:$sortie" "/win32icon:$icone" `
    "/resource:$(Join-Path $racine 'MisesAJour.ps1'),MisesAJour.ps1" `
    /reference:System.Windows.Forms.dll (Join-Path $PSScriptRoot 'Lanceur.cs')
if ($LASTEXITCODE -eq 0) { "Construit : $sortie" } else { throw 'Échec de la compilation' }
