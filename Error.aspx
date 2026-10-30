<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />
    <title>新北市固定逸散源管理平台 - 系統異常提示</title>
    <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
    <link rel="stylesheet" href="Content/bootstrap.min.css" />
    <link rel="stylesheet" href="Content/fontawesome/css/all.min.css" />
    <style>
        body {
            background-color: #f1f5f9;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans TC", "微軟正黑體", sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
            padding: 20px;
        }
        .error-card {
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
            max-width: 520px;
            width: 100%;
            padding: 40px 32px;
            text-align: center;
            border-top: 5px solid #ef4444;
        }
        .error-icon {
            font-size: 3.5rem;
            color: #ef4444;
            margin-bottom: 20px;
        }
        .error-title {
            font-size: 1.4rem;
            font-weight: 700;
            color: #0f172a;
            margin-bottom: 12px;
        }
        .error-desc {
            color: #64748b;
            font-size: 0.95rem;
            line-height: 1.6;
            margin-bottom: 24px;
        }
        .trace-box {
            background: #f8fafc;
            border: 1px dashed #cbd5e1;
            border-radius: 8px;
            padding: 12px;
            font-family: Consolas, monospace;
            font-size: 0.85rem;
            color: #475569;
            margin-bottom: 28px;
        }
        .trace-box strong {
            color: #0f172a;
        }
        .btn-action {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            padding: 10px 22px;
            border-radius: 6px;
            font-weight: 600;
            font-size: 0.95rem;
            transition: all 0.2s ease;
            text-decoration: none;
        }
        .btn-action-primary {
            background: #0284c7;
            color: #ffffff;
            border: 1px solid #0284c7;
        }
        .btn-action-primary:hover {
            background: #0369a1;
            color: #ffffff;
            text-decoration: none;
        }
        .btn-action-outline {
            background: #ffffff;
            color: #64748b;
            border: 1px solid #cbd5e1;
        }
        .btn-action-outline:hover {
            background: #f1f5f9;
            color: #334155;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="error-card">
        <div class="error-icon">
            <i class="fas fa-exclamation-triangle"></i>
        </div>
        <h1 class="error-title">系統暫時無法處理您的請求</h1>
        <p class="error-desc">
            抱歉，伺服器在執行此項作業時發生暫時性異常。<br />
            為保障系統資安，詳細錯誤已被安全封存至內部日誌。若問題持續發生，請提供下方追蹤碼洽詢系統維運人員。
        </p>

        <%
            string traceId = HttpContext.Current.Items["CurrentErrorTraceId"] as string;
            if (string.IsNullOrEmpty(traceId))
            {
                traceId = DateTime.Now.ToString("yyyyMMdd-HHmmss");
            }
        %>
        <div class="trace-box">
            <span>問題追蹤識別碼 (Trace ID)：</span><br />
            <strong><%= traceId %></strong>
        </div>

        <div class="d-flex justify-content-center gap-2">
            <a href="javascript:location.reload();" class="btn-action btn-action-outline mr-2">
                <i class="fas fa-redo"></i> 重新載入
            </a>
            <a href="<%= ResolveUrl("~/MainPage.aspx") %>" class="btn-action btn-action-primary">
                <i class="fas fa-home"></i> 返回系統首頁
            </a>
        </div>
    </div>
</body>
</html>
