using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using System.Runtime.InteropServices;
using System.Reflection;
using WindowsIconToolkit.ViewModels;

namespace WindowsIconToolkit;

public sealed partial class MainWindow : Window
{
    public MainViewModel ViewModel { get; } = new();
    public string VersionLabel { get; } = "v" + (Assembly.GetExecutingAssembly()
        .GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion.Split('+')[0] ?? "0.0.0");

    public MainWindow()
    {
        InitializeComponent();
        AppWindow.SetIcon(Path.Combine(AppContext.BaseDirectory, "Assets", "AppIcon.ico"));
        var scale = GetDpiForWindow(WinRT.Interop.WindowNative.GetWindowHandle(this)) / 96d;
        AppWindow.Resize(new Windows.Graphics.SizeInt32((int)(640 * scale), (int)(600 * scale)));
    }

    [DllImport("user32.dll")]
    private static extern uint GetDpiForWindow(nint window);

    private async void Version_Click(object sender, RoutedEventArgs e)
    {
        var panel = new StackPanel { Spacing = 12 };
        panel.Children.Add(new TextBlock { Text = "版本 " + VersionLabel.TrimStart('v'), FontSize = 18 });
        panel.Children.Add(new HyperlinkButton
        {
            Content = "GitHub 项目主页",
            NavigateUri = new Uri("https://github.com/awkj/windows-icon-toolkit"),
            Padding = new Thickness(0)
        });
        await new ContentDialog
        {
            XamlRoot = Content.XamlRoot,
            Title = "Windows Icon Toolkit",
            Content = panel,
            CloseButtonText = "关闭"
        }.ShowAsync();
    }

    private async void RestartExplorer_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new ContentDialog
        {
            XamlRoot = Content.XamlRoot,
            Title = "重启资源管理器？",
            Content = "桌面和任务栏会短暂消失，打开的文件夹窗口可能关闭。其他应用将继续运行。",
            PrimaryButtonText = "重启",
            CloseButtonText = "取消",
            DefaultButton = ContentDialogButton.Close
        };
        if (await dialog.ShowAsync() == ContentDialogResult.Primary)
            await ViewModel.RestartExplorerAsync();
    }
}
