using System.ComponentModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using WindowsIconToolkit.Services;

namespace WindowsIconToolkit.ViewModels;

public partial class MainViewModel : ObservableObject
{
    private readonly OverlayService service = new();

    [ObservableProperty] public partial string? ArrowStatus { get; set; }
    [ObservableProperty] public partial string? ShieldStatus { get; set; }
    [ObservableProperty] public partial string? StatusMessage { get; set; }
    [ObservableProperty] public partial bool IsBusy { get; set; }
    public bool CanInteract => !IsBusy;

    public MainViewModel()
    {
        StatusMessage = "修改时请求管理员权限；原设置将自动备份。";
        Refresh();
    }

    partial void OnIsBusyChanged(bool value) => OnPropertyChanged(nameof(CanInteract));

    [RelayCommand]
    private void Refresh()
    {
        try
        {
            ArrowStatus = service.ReadStatus("29");
            ShieldStatus = service.ReadStatus("77");
        }
        catch (Exception ex) { StatusMessage = "读取失败：" + ex.Message; }
    }

    [RelayCommand] private Task HideArrowsAsync() => ApplyAsync(OverlayAction.HideArrows);
    [RelayCommand] private Task HideBothAsync() => ApplyAsync(OverlayAction.HideBoth);
    [RelayCommand] private Task RestoreAsync() => ApplyAsync(OverlayAction.Restore);

    private async Task ApplyAsync(OverlayAction action)
    {
        if (IsBusy) return;
        IsBusy = true;
        StatusMessage = "等待管理员授权并写入设置…";
        try
        {
            await service.ApplyAsync(action);
            Refresh();
            StatusMessage = action == OverlayAction.Restore
                ? "已执行恢复。可重启资源管理器刷新图标。"
                : "设置已写入。可重启资源管理器，随后观察桌面效果。";
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
            StatusMessage = "资源管理器已重启。请观察桌面角标，盾牌效果仍需实际确认。";
        }
        catch (Exception ex) { StatusMessage = "重启失败：" + ex.Message; }
        finally { IsBusy = false; }
    }
}
