using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using WindowsIconToolkit.Services;

namespace WindowsIconToolkit.Controls;

public sealed partial class IconPreview : UserControl
{
    public static readonly DependencyProperty ArrowVisibilityProperty = DependencyProperty.Register(
        nameof(ArrowVisibility), typeof(Visibility), typeof(IconPreview), new PropertyMetadata(Visibility.Visible));
    public static readonly DependencyProperty ShieldVisibilityProperty = DependencyProperty.Register(
        nameof(ShieldVisibility), typeof(Visibility), typeof(IconPreview), new PropertyMetadata(Visibility.Visible));

    public Visibility ArrowVisibility
    {
        get => (Visibility)GetValue(ArrowVisibilityProperty);
        set => SetValue(ArrowVisibilityProperty, value);
    }
    public Visibility ShieldVisibility
    {
        get => (Visibility)GetValue(ShieldVisibilityProperty);
        set => SetValue(ShieldVisibilityProperty, value);
    }

    public IconPreview()
    {
        InitializeComponent();
        Loaded += async (_, _) =>
        {
            try
            {
                var icons = await SystemPreviewIcons.GetAsync();
                ApplicationImage.Source = icons.Application;
                ArrowImage.Source = icons.Arrow;
                ShieldImage.Source = icons.Shield;
                FallbackIcon.Visibility = Visibility.Collapsed;
            }
            catch (Exception ex) { System.Diagnostics.Debug.WriteLine(ex); }
        };
    }
}
