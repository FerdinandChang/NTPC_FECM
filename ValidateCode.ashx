<%@ WebHandler Language="VB" Class="ValidateCode" %>

Imports System
Imports System.Web
Imports System.Drawing
Imports System.Drawing.Drawing2D
Imports System.Web.SessionState
Imports System.IO

Public Class ValidateCode : Implements IHttpHandler, IRequiresSessionState

    Public Sub ProcessRequest(ByVal context As HttpContext) Implements IHttpHandler.ProcessRequest
        ' 產生 5 位數隨機碼
        Dim code As String = GenerateRandomCode(5)
        context.Session("ValidateCode") = code
        
        ' 產生高畫質 PNG 驗證碼圖片 (比照 NTPCEPD_NEW 現代設計)
        Dim ms As MemoryStream = CreateCaptchaImage(code)
        
        context.Response.Clear()
        context.Response.ContentType = "image/png"
        context.Response.BinaryWrite(ms.ToArray())
    End Sub

    Public ReadOnly Property IsReusable() As Boolean Implements IHttpHandler.IsReusable
        Get
            Return False
        End Get
    End Property

    Private Function GenerateRandomCode(length As Integer) As String
        Dim r As New Random()
        Dim code As String = ""
        For i As Integer = 0 To length - 1
            code &= r.Next(0, 10).ToString()
        Next
        Return code
    End Function

    Private Function CreateCaptchaImage(code As String) As MemoryStream
        ' === 設定區 ===
        Dim width As Integer = 135   ' 加寬，確保 5 位數清晰不被切邊
        Dim height As Integer = 45   ' 配合輸入框高度
        Dim fontSize As Integer = 22 ' 現代清晰 Verdana 字體
        ' =============

        Dim bmp As New Bitmap(width, height)
        Dim g As Graphics = Graphics.FromImage(bmp)
        Dim rand As New Random()

        Try
            ' 1. 背景處理 (純白乾淨背景)
            g.Clear(Color.White)
            g.SmoothingMode = SmoothingMode.AntiAlias

            ' 2. 繪製微量淡雅干擾線 (避免視覺疲勞)
            For i As Integer = 0 To 5 
                Dim x1 As Integer = rand.Next(width)
                Dim y1 As Integer = rand.Next(height)
                Dim x2 As Integer = rand.Next(width)
                Dim y2 As Integer = rand.Next(height)
                Dim penColor As Color = Color.FromArgb(rand.Next(160, 210), rand.Next(160, 210), rand.Next(160, 210))
                g.DrawLine(New Pen(penColor, 1), x1, y1, x2, y2)
            Next

            ' 3. 繪製驗證碼文字 (深藍到深紅線性漸層)
            Dim font As New Font("Verdana", fontSize, FontStyle.Bold)
            Dim brush As New LinearGradientBrush(New Rectangle(0, 0, width, height), Color.FromArgb(0, 60, 120), Color.FromArgb(120, 30, 30), 1.2F, True)
            
            Dim format As New StringFormat()
            format.Alignment = StringAlignment.Center
            format.LineAlignment = StringAlignment.Center

            g.DrawString(code, font, brush, New Rectangle(0, 0, width, height), format)

            ' 4. 繪製隨機細微噪點
            For i As Integer = 0 To 30
                Dim x As Integer = rand.Next(width)
                Dim y As Integer = rand.Next(height)
                bmp.SetPixel(x, y, Color.FromArgb(rand.Next(120, 210), rand.Next(120, 210), rand.Next(120, 210)))
            Next
            
            ' 5. 外邊框 (淡灰色質感)
            g.DrawRectangle(New Pen(Color.FromArgb(220, 220, 220)), 0, 0, width - 1, height - 1)

            Dim ms As New MemoryStream()
            bmp.Save(ms, System.Drawing.Imaging.ImageFormat.Png)
            Return ms
        Finally
            g.Dispose()
            bmp.Dispose()
        End Try
    End Function

End Class
