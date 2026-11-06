using System.ComponentModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.UI.Xaml;
using WindowsIconToolkit.Services;

namespace WindowsIconToolkit.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly OverlayService service = new();

    [ObservableProperty] public partial string? ArrowStatus { get; set; }
    [ObservableProperty] public partial string? ShieldStatus { get; set; }
    [ObservableProperty] public partial string? StatusMessage { get; set; }
    [ObservableProperty] public partial bool IsBusy { get; set; }
    [ObservableProperty] public partial bool HideArrow { get; set; }
    [ObservableProperty] public partial bool HideShield { get; set; }
    public Visibility PreviewArrowVisibility => HideArrow ? Visibility.Collapsed : Visibility.Visible;
    public Visibility PreviewShieldVisibility => HideShield ? Visibility.Collapsed : Visibility.Visible;
    public string PreviewDescription => $"修改后：记事本，箭头{(HideArrow ? "隐藏" : "显示")}，盾牌{(HideShield ? "隐藏" : "显示")}";
    public bool CanInteract => !IsBusy;
    public Visibility StatusVisibility => string.IsNullOrEmpty(StatusMessage) && !IsBusy ? Visibility.Collapsed : Visibility.Visible;

    public MainViewModel()
    {
        Refresh();
        if (ArrowStatus is not null && ShieldStatus is not null) StatusMessage = null;
    }

    partial void OnIsBusyChanged(bool value)
    {
        OnPropertyChanged(nameof(CanInteract));
        OnPropertyChanged(nameof(StatusVisibility));
    }
    partial void OnStatusMessageChanged(string? value) => OnPropertyChanged(nameof(StatusVisibility));
    partial void OnHideArrowChanged(bool value)
    {
        OnPropertyChanged(nameof(PreviewArrowVisibility));
        OnPropertyChanged(nameof(PreviewDescription));
        StatusMessage = null;
    }
    partial void OnHideShieldChanged(bool value)
    {
        OnPropertyChanged(nameof(PreviewShieldVisibility));
        OnPropertyChanged(nameof(PreviewDescription));
        StatusMessage = null;
    }

    [RelayCommand]
    private void Refresh()
    {
        try
        {
            ArrowStatus = "箭头 · " + service.ReadStatus("29");
            ShieldStatus = "盾牌 · " + service.ReadStatus("77");
            HideArrow = service.IsHiddenConfigured("29");
            HideShield = service.IsHiddenConfigured("77");
            StatusMessage = "已刷新。";
        }
        catch (Exception ex) { StatusMessage = "读取失败：" + ex.Message; }
    }

    [RelayCommand] private Task ApplySelectionAsync() => ApplyAsync(OverlayAction.Apply);
    [RelayCommand] private Task RestoreAsync() => ApplyAsync(OverlayAction.Restore);

    private async Task ApplyAsync(OverlayAction action)
    {
        if (IsBusy) return;
        IsBusy = true;
        StatusMessage = "等待管理员授权并写入设置…";
        try
        {
            await service.ApplyAsync(action, HideArrow, HideShield);
            HideArrow = service.IsHiddenConfigured("29");
            HideShield = service.IsHiddenConfigured("77");
            Refresh();
            StatusMessage = action == OverlayAction.Restore
                ? "已恢复原设置。"
                : "设置已更新。";
        }
        catch (Win32Exception ex) when (ex.NativeErrorCode == 1223)
        { StatusMessage = "已取消管理员授权，未执行本次修改。"; }
        catch (Exception ex) { StatusMessage = ex.Message; }
        finally { IsBusy = false; }
    }

    public async Task RestartExplorerAsync()
    {
        if (IsBusy) return;
        IsBusy = true;
        try
        {
            await service.RestartExplorerAsync();
            Refresh();
            StatusMessage = "资源管理器已重启。";
        }
        catch (Exception ex) { StatusMessage = "重启失败：" + ex.Message; }
        finally { IsBusy = false; }
    }
}
