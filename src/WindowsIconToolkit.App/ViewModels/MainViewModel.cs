using System.ComponentModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Microsoft.UI.Xaml;
using WindowsIconToolkit.Services;
using WindowsIconToolkit.Localization;

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
    public string PreviewDescription => Strings.Format("PreviewDescription", Strings.Get(HideArrow ? "Hidden" : "Visible"), Strings.Get(HideShield ? "Hidden" : "Visible"));
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
            ArrowStatus = Strings.Format("ArrowStatusFormat", service.ReadStatus("29"));
            ShieldStatus = Strings.Format("ShieldStatusFormat", service.ReadStatus("77"));
            HideArrow = service.IsHiddenConfigured("29");
            HideShield = service.IsHiddenConfigured("77");
            StatusMessage = Strings.Get("Refreshed");
        }
        catch (Exception ex) { StatusMessage = Strings.Format("ReadFailedFormat", ex.Message); }
    }

    [RelayCommand] private Task ApplySelectionAsync() => ApplyAsync(OverlayAction.Apply);
    [RelayCommand] private Task RestoreAsync() => ApplyAsync(OverlayAction.Restore);

    private async Task ApplyAsync(OverlayAction action)
    {
        if (IsBusy) return;
        IsBusy = true;
        StatusMessage = Strings.Get("WaitingForAdmin");
        try
        {
            await service.ApplyAsync(action, HideArrow, HideShield);
            HideArrow = service.IsHiddenConfigured("29");
            HideShield = service.IsHiddenConfigured("77");
            Refresh();
            StatusMessage = action == OverlayAction.Restore
                ? Strings.Get("Restored")
                : Strings.Get("Applied");
        }
        catch (Win32Exception ex) when (ex.NativeErrorCode == 1223)
        { StatusMessage = Strings.Get("AdminCancelled"); }
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
            StatusMessage = Strings.Get("ExplorerRestarted");
        }
        catch (Exception ex) { StatusMessage = Strings.Format("RestartFailedFormat", ex.Message); }
        finally { IsBusy = false; }
    }
}
