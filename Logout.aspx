<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="NTPC_FEC.Services" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        string loginMode = Session["LoginMode"]?.ToString();
        
        // 執行安全登出 (清空 Session、清除憑證 Cookie)
        AuthService.Logout(Context);

        // 判斷重導向目的地
        if (string.Equals(loginMode, "client", StringComparison.OrdinalIgnoreCase))
        {
            Response.Redirect("/NTPC_Cloud", true);
        }
        else
        {
            // 動態取得當前站台的 Default.aspx (相容 NTPC_FEC 與 NTPC_FECM 等任何自訂別名)
            string targetUrl = ResolveUrl("~/Default.aspx");
            Response.Redirect(targetUrl, true);
        }
    }
</script>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <title>正在安全登出...</title>
    <meta http-equiv="refresh" content="1;url=Default.aspx" />
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "微軟正黑體", sans-serif;
            background-color: #f4f6f9;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            margin: 0;
            color: #374151;
        }
        .logout-box {
            background: #ffffff;
            padding: 30px 40px;
            border-radius: 12px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="logout-box">
        <h3>已為您安全登出系統</h3>
        <p style="color: #6b7280; font-size: 14px;">正在為您跳轉回登入首頁，請稍候...</p>
    </div>
</body>
</html>
