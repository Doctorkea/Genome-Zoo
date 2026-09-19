using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class ConvertParts {
    public static int Main(string[] args) {
        if (args.Length < 2) {
            Console.Error.WriteLine("Usage: ConvertParts <srcDir> <destDir>");
            return 1;
        }
        string srcDir = args[0];
        string destDir = args[1];
        Directory.CreateDirectory(destDir);

        var map = new Dictionary<string, string> {
            { "4kJimmothyBodyReal.jpg", "body_jimmothy.png" },
            { "4kJimmothyHead.jpg", "head_jimmothy.png" },
            { "4KJimmothyFrontLeg.jpg", "front_legs_jimmothy.png" },
            { "4kJimmothyBackLeg.jpg", "back_legs_jimmothy.png" },
            { "4KJimmothyTail.jpg", "tail_jimmothy.png" },
        };

        foreach (var pair in map) {
            string src = Path.Combine(srcDir, pair.Key);
            string dest = Path.Combine(destDir, pair.Value);
            Convert(src, dest);
            Console.WriteLine("wrote " + dest);
        }
        return 0;
    }

    static void Convert(string src, string dest) {
        using (var srcImg = new Bitmap(src)) {
            int size = 400;
            using (var img = new Bitmap(size, size, PixelFormat.Format32bppArgb)) {
                using (var g = Graphics.FromImage(img)) {
                    g.Clear(Color.Transparent);
                    g.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
                    g.DrawImage(srcImg, 0, 0, size, size);
                }

                bool[,] bg = new bool[size, size];
                var q = new Queue<Point>();
                Action<int, int> tryEnqueue = (x, y) => {
                    if (x < 0 || y < 0 || x >= size || y >= size || bg[x, y]) return;
                    Color c = img.GetPixel(x, y);
                    if (IsBackground(c)) {
                        bg[x, y] = true;
                        q.Enqueue(new Point(x, y));
                    }
                };

                for (int x = 0; x < size; x++) {
                    tryEnqueue(x, 0);
                    tryEnqueue(x, size - 1);
                }
                for (int y = 0; y < size; y++) {
                    tryEnqueue(0, y);
                    tryEnqueue(size - 1, y);
                }
                while (q.Count > 0) {
                    Point p = q.Dequeue();
                    tryEnqueue(p.X - 1, p.Y);
                    tryEnqueue(p.X + 1, p.Y);
                    tryEnqueue(p.X, p.Y - 1);
                    tryEnqueue(p.X, p.Y + 1);
                }

                for (int y = 0; y < size; y++) {
                    for (int x = 0; x < size; x++) {
                        if (bg[x, y]) {
                            img.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                            continue;
                        }
                        Color c = img.GetPixel(x, y);
                        if (c.A < 8) {
                            img.SetPixel(x, y, Color.FromArgb(0, 0, 0, 0));
                            continue;
                        }
                        int max = Math.Max(c.R, Math.Max(c.G, c.B));
                        int luma = (int)(0.16 * 255 + (max / 255.0) * 0.68 * 255);
                        luma = Math.Max(28, Math.Min(220, luma));
                        img.SetPixel(x, y, Color.FromArgb(255, luma, luma, luma));
                    }
                }

                img.Save(dest, ImageFormat.Png);
            }
        }
    }

    static bool IsBackground(Color c) {
        return c.R >= 228 && c.G >= 228 && c.B >= 228;
    }
}
