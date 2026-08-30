using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

internal static class FrameCapture
{
    private delegate bool EnumWindowsProc(IntPtr window, IntPtr parameter);

    [StructLayout(LayoutKind.Sequential)]
    private struct Rect
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    private static extern bool EnumWindows(EnumWindowsProc callback, IntPtr parameter);

    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr window, out uint processId);

    [DllImport("user32.dll")]
    private static extern bool GetWindowRect(IntPtr window, out Rect rectangle);

    [DllImport("user32.dll")]
    private static extern bool IsWindowVisible(IntPtr window);

    private static Dictionary<string, string> ParseArguments(string[] arguments)
    {
        Dictionary<string, string> parsed = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (int index = 0; index < arguments.Length; index++)
        {
            string key = arguments[index];
            if (!key.StartsWith("--", StringComparison.Ordinal) || index + 1 >= arguments.Length)
            {
                throw new ArgumentException("Argument invalide : " + key);
            }
            parsed[key.Substring(2)] = arguments[++index];
        }
        return parsed;
    }

    private static string Required(Dictionary<string, string> arguments, string key)
    {
        string value;
        if (!arguments.TryGetValue(key, out value) || String.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Argument requis : --" + key);
        }
        return value;
    }

    private static IntPtr FindLargestVisibleWindow(int processId, out Rect rectangle)
    {
        IntPtr bestWindow = IntPtr.Zero;
        Rect bestRectangle = new Rect();
        long bestArea = 0;
        EnumWindows(delegate(IntPtr window, IntPtr parameter)
        {
            uint owner;
            GetWindowThreadProcessId(window, out owner);
            if (owner != (uint)processId || !IsWindowVisible(window))
            {
                return true;
            }

            Rect candidate;
            if (!GetWindowRect(window, out candidate))
            {
                return true;
            }
            int width = candidate.Right - candidate.Left;
            int height = candidate.Bottom - candidate.Top;
            long area = (long)width * height;
            if (width > 0 && height > 0 && area > bestArea)
            {
                bestArea = area;
                bestWindow = window;
                bestRectangle = candidate;
            }
            return true;
        }, IntPtr.Zero);
        rectangle = bestRectangle;
        return bestWindow;
    }

    private static ImageCodecInfo GetJpegEncoder()
    {
        foreach (ImageCodecInfo encoder in ImageCodecInfo.GetImageEncoders())
        {
            if (encoder.FormatID == ImageFormat.Jpeg.Guid)
            {
                return encoder;
            }
        }
        throw new InvalidOperationException("Encodeur JPEG introuvable.");
    }

    private static void SaveJpeg(Bitmap bitmap, string path, long quality)
    {
        using (EncoderParameters parameters = new EncoderParameters(1))
        {
            parameters.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
            bitmap.Save(path, GetJpegEncoder(), parameters);
        }
    }

    private static string Csv(string value)
    {
        return "\"" + value.Replace("\"", "\"\"") + "\"";
    }

    private static int Main(string[] arguments)
    {
        try
        {
            Dictionary<string, string> parsed = ParseArguments(arguments);
            int processId = Int32.Parse(Required(parsed, "process-id"), CultureInfo.InvariantCulture);
            string output = Path.GetFullPath(Required(parsed, "output"));
            string stopFile = Path.GetFullPath(Required(parsed, "stop-file"));
            int framesPerSecond = parsed.ContainsKey("fps") ? Int32.Parse(parsed["fps"], CultureInfo.InvariantCulture) : 10;
            long quality = parsed.ContainsKey("quality") ? Int64.Parse(parsed["quality"], CultureInfo.InvariantCulture) : 82;
            if (framesPerSecond < 1 || framesPerSecond > 30)
            {
                throw new ArgumentOutOfRangeException("fps", "La cadence doit etre comprise entre 1 et 30.");
            }
            if (quality < 30 || quality > 100)
            {
                throw new ArgumentOutOfRangeException("quality", "La qualite doit etre comprise entre 30 et 100.");
            }

            Directory.CreateDirectory(output);
            string framesDirectory = Path.Combine(output, "frames");
            Directory.CreateDirectory(framesDirectory);
            Process game = Process.GetProcessById(processId);
            Stopwatch clock = Stopwatch.StartNew();
            long interval = Math.Max(1, 1000 / framesPerSecond);
            int frameIndex = 0;
            IntPtr lastWindow = IntPtr.Zero;

            using (StreamWriter eventsWriter = new StreamWriter(Path.Combine(output, "capture-events.csv"), false, new UTF8Encoding(false)))
            using (StreamWriter framesWriter = new StreamWriter(Path.Combine(output, "frames.csv"), false, new UTF8Encoding(false)))
            {
                eventsWriter.AutoFlush = true;
                framesWriter.AutoFlush = true;
                eventsWriter.WriteLine("utc,elapsed_ms,event,detail");
                framesWriter.WriteLine("utc,elapsed_ms,frame,path,left,top,width,height");
                eventsWriter.WriteLine(Csv(DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture)) + ",0," + Csv("capture_started") + "," + Csv("pid=" + processId));

                while (!File.Exists(stopFile))
                {
                    game.Refresh();
                    if (game.HasExited)
                    {
                        eventsWriter.WriteLine(Csv(DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture)) + "," + clock.ElapsedMilliseconds + "," + Csv("process_exited") + "," + Csv(""));
                        break;
                    }

                    long frameStart = clock.ElapsedMilliseconds;
                    Rect rectangle;
                    IntPtr window = FindLargestVisibleWindow(processId, out rectangle);
                    if (window == IntPtr.Zero)
                    {
                        Thread.Sleep(25);
                        continue;
                    }
                    if (window != lastWindow)
                    {
                        lastWindow = window;
                        eventsWriter.WriteLine(Csv(DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture)) + "," + clock.ElapsedMilliseconds + "," + Csv("window_detected") + "," + Csv("handle=0x" + window.ToInt64().ToString("X", CultureInfo.InvariantCulture)));
                    }

                    int width = rectangle.Right - rectangle.Left;
                    int height = rectangle.Bottom - rectangle.Top;
                    if (width > 0 && height > 0)
                    {
                        string fileName = "frame-" + frameIndex.ToString("D6", CultureInfo.InvariantCulture) + ".jpg";
                        string framePath = Path.Combine(framesDirectory, fileName);
                        try
                        {
                            using (Bitmap bitmap = new Bitmap(width, height, PixelFormat.Format24bppRgb))
                            using (Graphics graphics = Graphics.FromImage(bitmap))
                            {
                                graphics.CopyFromScreen(rectangle.Left, rectangle.Top, 0, 0, new Size(width, height), CopyPixelOperation.SourceCopy | CopyPixelOperation.CaptureBlt);
                                SaveJpeg(bitmap, framePath, quality);
                            }
                            framesWriter.WriteLine(
                                Csv(DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture)) + "," +
                                clock.ElapsedMilliseconds + "," + frameIndex + "," + Csv("frames/" + fileName) + "," +
                                rectangle.Left + "," + rectangle.Top + "," + width + "," + height);
                            frameIndex++;
                        }
                        catch (Exception error)
                        {
                            eventsWriter.WriteLine(Csv(DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture)) + "," + clock.ElapsedMilliseconds + "," + Csv("frame_error") + "," + Csv(error.GetType().Name + ": " + error.Message));
                        }
                    }

                    long delay = interval - (clock.ElapsedMilliseconds - frameStart);
                    if (delay > 0)
                    {
                        Thread.Sleep((int)delay);
                    }
                }
                eventsWriter.WriteLine(Csv(DateTime.UtcNow.ToString("O", CultureInfo.InvariantCulture)) + "," + clock.ElapsedMilliseconds + "," + Csv("capture_stopped") + "," + Csv("frames=" + frameIndex));
            }
            return 0;
        }
        catch (Exception error)
        {
            Console.Error.WriteLine(error.ToString());
            return 1;
        }
    }
}
