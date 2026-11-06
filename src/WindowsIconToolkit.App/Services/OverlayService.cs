using System.Diagnostics;
using Microsoft.Win32;
using WindowsIconToolkit.Localization;

namespace WindowsIconToolkit.Services;

public enum OverlayAction { Apply, Restore }

public sealed class OverlayService
{
    private const string RegistryPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons";
    private static readonly string IconPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),
        "DesktopIconOverlayBackup", "transparent.ico");

    public bool IsHiddenConfigured(string name)
    {
        using var registry = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);
        using var key = registry.OpenSubKey(RegistryPath);
        var value = key?.GetValue(name)?.ToString();
        return File.Exists(IconPath) && (string.Equals(value, IconPath, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(value, IconPath + ",0", StringComparison.OrdinalIgnoreCase));
    }

    public string ReadStatus(string name)
    {
        using var registry = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);
        using var key = registry.OpenSubKey(RegistryPath);
        var value = key?.GetValue(name)?.ToString();
        if (value is null) return Strings.Get("OverlayDefault");
        if (string.Equals(value, IconPath, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(value, IconPath + ",0", StringComparison.OrdinalIgnoreCase))
            return File.Exists(IconPath)
                ? Strings.Get("OverlayConfigured")
                : Strings.Get("OverlayIconMissing");
        return Strings.Get("OverlayCustom");
    }

    public async Task ApplyAsync(OverlayAction action, bool hideArrow = false, bool hideShield = false)
    {
        var script = Path.Combine(AppContext.BaseDirectory, "Backend", "Desktop-IconOverlays.ps1");
        if (!File.Exists(script)) throw new FileNotFoundException(Strings.Get("BackendMissing"), script);
        // All arguments are selected here; no command text or registry path comes from the UI.
        var arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{script}\" -Action " +
                        (action == OverlayAction.Restore ? "Restore" : "Apply");
        if (action == OverlayAction.Apply && hideArrow) arguments += " -HideArrow";
        if (action == OverlayAction.Apply && hideShield) arguments += " -IncludeShield";
        using var process = Process.Start(new ProcessStartInfo
        {
            FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                "System32", "WindowsPowerShell", "v1.0", "powershell.exe"),
            Arguments = arguments,
            UseShellExecute = true,
            Verb = "runas",
            WindowStyle = ProcessWindowStyle.Hidden
        }) ?? throw new InvalidOperationException(Strings.Get("BackendStartFailed"));
        await process.WaitForExitAsync();
        if (process.ExitCode != 0)
            throw new InvalidOperationException(Strings.Format("BackendFailedFormat", process.ExitCode));
    }

    public async Task RestartExplorerAsync()
    {
        var session = Process.GetCurrentProcess().SessionId;
        foreach (var process in Process.GetProcessesByName("explorer"))
        {
            using (process)
            {
                if (process.SessionId != session) continue;
                process.Kill();
                await process.WaitForExitAsync();
            }
        }
        await Task.Delay(2000);
        var running = Process.GetProcessesByName("explorer");
        bool found;
        try { found = running.Any(p => p.SessionId == session); }
        finally { foreach (var process in running) process.Dispose(); }
        if (!found)
            using (Process.Start(new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "explorer.exe"),
                UseShellExecute = true
            })) { }
    }
}
