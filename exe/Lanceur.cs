// Lanceur .exe : contient MisesAJour.ps1 et l'exécute sans fenêtre de console
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("Mises à jour matériel")]
[assembly: AssemblyProduct("Mises à jour matériel")]
[assembly: AssemblyDescription("Vérifie les mises à jour NVIDIA, MSI, Cooler Master, Corsair et Intel Killer")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

static class Lanceur
{
    [STAThread]
    static void Main()
    {
        try
        {
            string dossier = Path.Combine(Path.GetTempPath(), "MisesAJourMateriel");
            Directory.CreateDirectory(dossier);
            string script = Path.Combine(dossier, "MisesAJour.ps1");
            using (Stream source = Assembly.GetExecutingAssembly().GetManifestResourceStream("MisesAJour.ps1"))
            using (FileStream cible = File.Create(script))
            {
                source.CopyTo(cible);
            }

            var psi = new ProcessStartInfo("powershell.exe",
                "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + script + "\"");
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            // Permet au script de créer le raccourci de démarrage vers cet .exe
            psi.EnvironmentVariables["MISES_A_JOUR_EXE"] = Assembly.GetExecutingAssembly().Location;
            Process.Start(psi);
        }
        catch (Exception e)
        {
            MessageBox.Show("Impossible de lancer le pop-up :\n" + e.Message, "Mises à jour matériel",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
