<%@ WebHandler Language="C#" Class="KeepAlive" %>

using System;
using System.Web;
using System.Web.SessionState;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

public class KeepAlive : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json; charset=utf-8";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.Cache.SetNoStore();

        if (context.Session == null)
        {
            context.Response.Write("{\"success\":false,\"authenticated\":false,\"message\":\"Session expired\"}");
            return;
        }

        // 統一透過 AuthService.GetCurrentUser 檢查並自動維持/補齊 Session 登入狀態
        UserAccount currentUser = AuthService.GetCurrentUser(context);
        if (currentUser == null && context.Session["LoginUser"] == null && context.Session["User"] == null)
        {
            context.Response.Write("{\"success\":false,\"authenticated\":false,\"message\":\"Session expired\"}");
            return;
        }

        // 存取並更新 Session 變數，觸發 ASP.NET 滑動過期機制 (Sliding Expiration)，自動展延 Session 有效期限
        context.Session["LastKeepAlive"] = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        context.Session["LastActiveAt"] = DateTime.UtcNow.Ticks;

        context.Response.Write("{\"success\":true,\"authenticated\":true}");
    }

    public bool IsReusable
    {
        get { return false; }
    }
}
