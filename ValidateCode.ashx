<%@ WebHandler Language="C#" Class="ValidateCode" %>

using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Web;
using System.Web.SessionState;

public class ValidateCode : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest(HttpContext context)
    {
        // 產生 5 位數隨機碼
        string code = GenerateRandomCode(5);
        if (context.Session != null)
        {
            context.Session["ValidateCode"] = code;
        }

        context.Response.Clear();
        context.Response.ContentType = "image/png";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.Cache.SetNoStore();

        // 產生高畫質 PNG 驗證碼圖片並完整釋放 GDI+ 與 MemoryStream 資源
        byte[] imageBytes = CreateCaptchaImageBytes(code);
        context.Response.BinaryWrite(imageBytes);
    }

    public bool IsReusable
    {
        get { return false; }
    }

    private static string GenerateRandomCode(int length)
    {
        Random r = new Random();
        char[] chars = new char[length];
        for (int i = 0; i < length; i++)
        {
            chars[i] = (char)('0' + r.Next(0, 10));
        }
        return new string(chars);
    }

    private static byte[] CreateCaptchaImageBytes(string code)
    {
        int width = 135;
        int height = 45;
        int fontSize = 22;

        Random rand = new Random();

        using (Bitmap bmp = new Bitmap(width, height))
        using (Graphics g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.White);
            g.SmoothingMode = SmoothingMode.AntiAlias;

            // 1. 繪製微量淡雅干擾線
            for (int i = 0; i < 6; i++)
            {
                int x1 = rand.Next(width);
                int y1 = rand.Next(height);
                int x2 = rand.Next(width);
                int y2 = rand.Next(height);
                Color penColor = Color.FromArgb(rand.Next(160, 210), rand.Next(160, 210), rand.Next(160, 210));
                using (Pen pen = new Pen(penColor, 1f))
                {
                    g.DrawLine(pen, x1, y1, x2, y2);
                }
            }

            // 2. 繪製驗證碼文字 (深藍到深紅線性漸層)
            Rectangle textRect = new Rectangle(0, 0, width, height);
            using (Font font = new Font("Verdana", fontSize, FontStyle.Bold))
            using (LinearGradientBrush brush = new LinearGradientBrush(textRect, Color.FromArgb(0, 60, 120), Color.FromArgb(120, 30, 30), 1.2f, true))
            using (StringFormat format = new StringFormat())
            {
                format.Alignment = StringAlignment.Center;
                format.LineAlignment = StringAlignment.Center;
                g.DrawString(code, font, brush, textRect, format);
            }

            // 3. 繪製隨機細微噪點
            for (int i = 0; i < 30; i++)
            {
                int x = rand.Next(width);
                int y = rand.Next(height);
                bmp.SetPixel(x, y, Color.FromArgb(rand.Next(120, 210), rand.Next(120, 210), rand.Next(120, 210)));
            }

            // 4. 外邊框 (淡灰色質感)
            using (Pen borderPen = new Pen(Color.FromArgb(220, 220, 220), 1f))
            {
                g.DrawRectangle(borderPen, 0, 0, width - 1, height - 1);
            }

            using (MemoryStream ms = new MemoryStream())
            {
                bmp.Save(ms, ImageFormat.Png);
                return ms.ToArray();
            }
        }
    }
}
