<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ClientLogin.aspx.cs" Inherits="NTPC_FEC.ClientLogin" %>

<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <title>業者自主申報登入跳轉</title>
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link rel="apple-touch-icon" href="apple-touch-icon.png" />
</head>
<body>
    <form id="form1" runat="server">
        <div style="text-align: center; margin-top: 100px; font-family: '微軟正黑體';">
            <h3>正在驗證業者權限並登入中，請稍候...</h3>
            <p><asp:Literal ID="litMsg" runat="server"></asp:Literal></p>
        </div>
    </form>
</body>
</html>
