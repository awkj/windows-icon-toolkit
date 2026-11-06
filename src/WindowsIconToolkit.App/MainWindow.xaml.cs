using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using WindowsIconToolkit.ViewModels;

namespace WindowsIconToolkit;

public sealed partial class MainWindow : Window
{
    public MainViewModel ViewModel { get; } = new();

    public MainWindow()
    {
        InitializeComponent();
        AppWindow.Resize(new Windows.Graphics.SizeInt32(1120, 880));
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
