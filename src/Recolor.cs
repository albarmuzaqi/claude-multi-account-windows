// Shifts the hue of every pixel in an image; near-white and transparent pixels stay as they are.
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class IconRecolor
{
    public static Bitmap ShiftHue(Bitmap src, double shift)
    {
        var bmp = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) g.DrawImage(src, 0, 0, src.Width, src.Height);
        var data = bmp.LockBits(new Rectangle(0, 0, bmp.Width, bmp.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int n = data.Stride * bmp.Height;
        var px = new byte[n];
        Marshal.Copy(data.Scan0, px, 0, n);
        for (int i = 0; i < n; i += 4)
        {
            double b = px[i] / 255.0, gr = px[i + 1] / 255.0, r = px[i + 2] / 255.0;
            double max = Math.Max(r, Math.Max(gr, b)), min = Math.Min(r, Math.Min(gr, b));
            double l = (max + min) / 2, d = max - min, h = 0, s = 0;
            if (d > 1e-6)
            {
                s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
                if (max == r) h = (gr - b) / d + (gr < b ? 6 : 0);
                else if (max == gr) h = (b - r) / d + 2;
                else h = (r - gr) / d + 4;
                h *= 60;
            }
            h = ((h + shift) % 360 + 360) % 360;
            double q = l < 0.5 ? l * (1 + s) : l + s - l * s, p = 2 * l - q, hk = h / 360;
            px[i + 2] = (byte)Math.Round(255 * Channel(p, q, hk + 1.0 / 3));
            px[i + 1] = (byte)Math.Round(255 * Channel(p, q, hk));
            px[i] = (byte)Math.Round(255 * Channel(p, q, hk - 1.0 / 3));
        }
        Marshal.Copy(px, 0, data.Scan0, n);
        bmp.UnlockBits(data);
        return bmp;
    }

    static double Channel(double p, double q, double t)
    {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1.0 / 6) return p + (q - p) * 6 * t;
        if (t < 0.5) return q;
        if (t < 2.0 / 3) return p + (q - p) * (2.0 / 3 - t) * 6;
        return p;
    }
}
