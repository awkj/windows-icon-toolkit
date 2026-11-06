using System.ComponentModel;
using System.Runtime.InteropServices;
using Microsoft.UI.Xaml.Media.Imaging;
using Windows.Graphics.Imaging;
using Windows.Storage.Streams;

namespace WindowsIconToolkit.Services;

public sealed record PreviewIconImages(BitmapImage Application, BitmapImage Arrow, BitmapImage Shield);

// Read the computer's own resources at runtime; no copied Windows artwork is shipped.
public static class SystemPreviewIcons
{
    private static Task<PreviewIconImages>? cached;
    public static Task<PreviewIconImages> GetAsync() => cached ??= LoadAsync();

    private static async Task<PreviewIconImages> LoadAsync()
    {
        var system = Environment.GetFolderPath(Environment.SpecialFolder.System);
        var application = await ExtractAsync(Path.Combine(system, "notepad.exe"), 0, 256, false);
        // Read default resources directly so Shell Icons overrides do not hide the preview.
        var arrow = await ExtractAsync(Path.Combine(system, "shell32.dll"), 29, 64, true);
        var shield = await ExtractAsync(Path.Combine(system, "imageres.dll"), -78, 64, true);
        return new(application, arrow, shield);
    }

    private static async Task<BitmapImage> ExtractAsync(string path, int index, int size, bool trim)
    {
        Marshal.ThrowExceptionForHR(SHDefExtractIcon(path, index, 0, out var icon, 0, (uint)size));
        if (icon == 0) throw new InvalidOperationException("System icon could not be loaded.");
        byte[] pixels;
        try { pixels = RenderIcon(icon, size); }
        finally { DestroyIcon(icon); }

        int width = size, height = size;
        if (trim) (pixels, width, height) = TrimTransparentPixels(pixels, size);
        using var stream = new InMemoryRandomAccessStream();
        var encoder = await BitmapEncoder.CreateAsync(BitmapEncoder.PngEncoderId, stream);
        encoder.SetPixelData(BitmapPixelFormat.Bgra8, BitmapAlphaMode.Premultiplied,
            (uint)width, (uint)height, 96, 96, pixels);
        await encoder.FlushAsync();
        stream.Seek(0);
        var image = new BitmapImage();
        await image.SetSourceAsync(stream);
        return image;
    }

    private static byte[] RenderIcon(nint icon, int size)
    {
        var dc = CreateCompatibleDC(0);
        if (dc == 0) throw new Win32Exception(Marshal.GetLastWin32Error());
        nint bitmap = 0, previous = 0;
        try
        {
            var header = new BitmapHeader
            {
                Size = (uint)Marshal.SizeOf<BitmapHeader>(), Width = size, Height = -size,
                Planes = 1, BitCount = 32, SizeImage = (uint)(size * size * 4)
            };
            bitmap = CreateDIBSection(dc, ref header, 0, out var address, 0, 0);
            if (bitmap == 0) throw new Win32Exception(Marshal.GetLastWin32Error());
            var pixels = new byte[size * size * 4];
            Marshal.Copy(pixels, 0, address, pixels.Length);
            previous = SelectObject(dc, bitmap);
            if (!DrawIconEx(dc, 0, 0, icon, size, size, 0, 0, 3))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            Marshal.Copy(address, pixels, 0, pixels.Length);
            return pixels;
        }
        finally
        {
            if (previous != 0) SelectObject(dc, previous);
            if (bitmap != 0) DeleteObject(bitmap);
            DeleteDC(dc);
        }
    }

    private static (byte[], int, int) TrimTransparentPixels(byte[] pixels, int size)
    {
        int left = size, top = size, right = -1, bottom = -1;
        for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
                if (pixels[(y * size + x) * 4 + 3] != 0)
                {
                    left = Math.Min(left, x); top = Math.Min(top, y);
                    right = Math.Max(right, x); bottom = Math.Max(bottom, y);
                }
        if (right < left) throw new InvalidOperationException("System overlay resource is empty.");
        int width = right - left + 1, height = bottom - top + 1;
        var cropped = new byte[width * height * 4];
        for (var y = 0; y < height; y++)
            System.Buffer.BlockCopy(pixels, ((top + y) * size + left) * 4, cropped, y * width * 4, width * 4);
        return (cropped, width, height);
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct BitmapHeader
    {
        public uint Size;
        public int Width, Height;
        public ushort Planes, BitCount;
        public uint Compression, SizeImage;
        public int XPelsPerMeter, YPelsPerMeter;
        public uint ClrUsed, ClrImportant;
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern int SHDefExtractIcon(string file, int index, uint flags, out nint large, nint small, uint size);
    [DllImport("user32.dll")] private static extern bool DestroyIcon(nint icon);
    [DllImport("gdi32.dll", SetLastError = true)] private static extern nint CreateCompatibleDC(nint dc);
    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern nint CreateDIBSection(nint dc, ref BitmapHeader header, uint usage, out nint bits, nint section, uint offset);
    [DllImport("gdi32.dll")] private static extern nint SelectObject(nint dc, nint item);
    [DllImport("gdi32.dll")] private static extern bool DeleteObject(nint item);
    [DllImport("gdi32.dll")] private static extern bool DeleteDC(nint dc);
    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DrawIconEx(nint dc, int x, int y, nint icon, int width, int height, uint step, nint brush, uint flags);
}
