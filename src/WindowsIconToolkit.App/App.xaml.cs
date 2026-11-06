using Microsoft.UI.Xaml;
using WindowsIconToolkit.Localization;

namespace WindowsIconToolkit;

public partial class App : Application
{
    private MainWindow? window;

    public App()
    {
        UnhandledException += (_, args) => WriteFailure(args.Exception, args.Message);
        try { Strings.Initialize(); InitializeComponent(); }
        catch (Exception ex) { WriteFailure(ex, "Application initialization"); throw; }
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        try
        {
            window = new MainWindow();
            window.Activate();
        }
        catch (Exception ex) { WriteFailure(ex, "Window creation"); throw; }
    }

    private static void WriteFailure(Exception exception, string context)
    {
        try
        {
            var folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "WindowsIconToolkit", "Logs");
            Directory.CreateDirectory(folder);
            File.AppendAllText(Path.Combine(folder, "errors.log"),
                $"{DateTimeOffset.Now:o} {context}{Environment.NewLine}{exception}{Environment.NewLine}");
        }
        catch { /* Logging must not replace the original error. */ }
    }
}
