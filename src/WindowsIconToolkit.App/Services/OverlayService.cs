using System.Diagnostics;
using Microsoft.Win32;

namespace WindowsIconToolkit.Services;

public enum OverlayAction { HideArrows, HideBoth, Restore }

public sealed class OverlayService
{
    private const string RegistryPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons";
    private static readonly string IconPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData),
        "DesktopIconOverlayBackup", "transparent.ico");

    public string ReadStatus(string name)
    {
        using var registry = RegistryKey.OpenBaseKey(RegistryHive.LocalMachine, RegistryView.Registry64);
        using var key = registry.OpenSubKey(RegistryPath);
        var value = key?.GetValue(name)?.ToString();
        if (value is null) return "当前：Windows 默认设置";
        if (string.Equals(value, IconPath, StringComparison.OrdinalIgnoreCase) ||
            string.Equals(value, IconPath + ",0", StringComparison.OrdinalIgnoreCase))
            return File.Exists(IconPath)
                ? "当前：已配置透明角标，桌面效果待确认"
                : "当前：配置的透明图标文件缺失，请重新应用";
        return "当前：已有其他自定义设置（应用前会备份）";
    }

    public async Task ApplyAsync(OverlayAction action)
    {
        var script = Path.Combine(AppContext.BaseDirectory, "Backend", "Desktop-IconOverlays.ps1");
        if (!File.Exists(script)) throw new FileNotFoundException("缺少角标操作脚本，请重新构建项目。", script);
        // All arguments are selected here; no command text or registry path comes from the UI.
        var arguments = $"-NoProfile -ExecutionPolicy Bypass -File \"{script}\" -Action " +
                        (action == OverlayAction.Restore ? "Restore" : "Hide");
        if (action == OverlayAction.HideBoth) arguments += " -IncludeShield";
        using var process = Process.Start(new ProcessStartInfo
        {
            FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows),
                "System32", "WindowsPowerShell", "v1.0", "powershell.exe"),
            Arguments = arguments,
            UseShellExecute = true,
            Verb = "runas",
            WindowStyle = ProcessWindowStyle.Hidden
        }) ?? throw new InvalidOperationException("无法启动操作进程。");
        await process.WaitForExitAsync();
        if (process.ExitCode != 0)
            throw new InvalidOperationException($"操作失败（退出码 {process.ExitCode}）。可运行仓库中的命令行脚本查看详细错误。");
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
