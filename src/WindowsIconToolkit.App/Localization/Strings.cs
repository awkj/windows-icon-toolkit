using System.Globalization;
using Microsoft.Windows.ApplicationModel.Resources;
using Microsoft.Windows.Globalization;

namespace WindowsIconToolkit.Localization;

public static class Strings
{
    private static ResourceLoader? loader;

    public static void Initialize()
    {
        // Re-evaluate the Windows UI language on each launch. The SDK rejects an
        // empty override in unpackaged apps, so pass the Windows language tag.
        var arguments = Environment.GetCommandLineArgs();
        var index = Array.IndexOf(arguments, "--language");
        var language = index >= 0 && index + 1 < arguments.Length
            ? arguments[index + 1] : CultureInfo.CurrentUICulture.Name;
        if (string.IsNullOrEmpty(language)) language = "en-US";
        _ = CultureInfo.GetCultureInfo(language);
        ApplicationLanguages.PrimaryLanguageOverride = language;

        // Unpackaged and single-file apps need the actual extracted PRI path.
        var pri = Path.Combine(AppContext.BaseDirectory, "WindowsIconToolkit.App.pri");
        if (!File.Exists(pri)) pri = Path.Combine(AppContext.BaseDirectory, "resources.pri");
        loader = new ResourceLoader(pri, "Resources");
    }

    public static string Get(string key)
    {
        var value = (loader ?? throw new InvalidOperationException("Localization is not initialized.")).GetString(key);
        if (string.IsNullOrEmpty(value)) throw new InvalidOperationException($"Missing resource: {key}");
        return value;
    }

    public static string Format(string key, params object[] values) =>
        string.Format(CultureInfo.CurrentCulture, Get(key), values);
}
