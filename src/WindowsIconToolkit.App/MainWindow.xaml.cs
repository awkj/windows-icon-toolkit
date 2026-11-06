using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using System.Runtime.InteropServices;
using System.Reflection;
using WindowsIconToolkit.ViewModels;
using WindowsIconToolkit.Localization;

namespace WindowsIconToolkit;

public sealed partial class MainWindow : Window
{
    public MainViewModel ViewModel { get; } = new();
    public string VersionLabel { get; } = "v" + (Assembly.GetExecutingAssembly()
        .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion.Split('+')[0] ?? "0.0.0");

    public MainWindow()
    {
        InitializeComponent();
        Title = Strings.Get("AppName");
        AppWindow.SetIcon(Path.Combine(AppContext.BaseDirectory, "Assets", "AppIcon.ico"));
        var scale = GetDpiForWindow(WinRT.Interop.WindowNative.GetWindowHandle(this)) / 96d;
        AppWindow.Resize(new Windows.Graphics.SizeInt32((int)(640 * scale), (int)(600 * scale)));
    }

    [DllImport("user32.dll")]
    private static extern uint GetDpiForWindow(nint window);

    private async void Version_Click(object sender, RoutedEventArgs e)
    {
        var panel = new StackPanel { Spacing = 12 };
        panel.Children.Add(new TextBlock { Text = Strings.Format("VersionFormat", VersionLabel.TrimStart('v')), FontSize = 18 });
        panel.Children.Add(new HyperlinkButton
        {
            Content = Strings.Get("ProjectHome"),
            NavigateUri = new Uri("https://github.com/awkj/windows-icon-toolkit"),
            Padding = new Thickness(0)
        });
        await new ContentDialog
        {
            XamlRoot = Content.XamlRoot,
            Title = Strings.Get("AppName"),
            Content = panel,
            CloseButtonText = Strings.Get("Close")
        }.ShowAsync();
    }

    private async void RestartExplorer_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new ContentDialog
        {
            XamlRoot = Content.XamlRoot,
            Title = Strings.Get("RestartConfirmationTitle"),
            Content = Strings.Get("RestartConfirmationMessage"),
            PrimaryButtonText = Strings.Get("Restart"),
            CloseButtonText = Strings.Get("Cancel"),
            DefaultButton = ContentDialogButton.Close
        };
        if (await dialog.ShowAsync() == ContentDialogResult.Primary)
            await ViewModel.RestartExplorerAsync();
    }
}
