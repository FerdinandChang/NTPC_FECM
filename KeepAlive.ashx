<%@ WebHandler Language="C#" Class="KeepAlive" %>

using System;
using System.Web;
using System.Web.SessionState;

public class KeepAlive : IHttpHandler, IRequiresSessionState
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json; charset=utf-8";
        context.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        context.Response.Cache.SetNoStore();

        // 檢查使用者 Session 是否存在且已登入
        if (context.Session == null || context.Session["LoginUser"] == null)
        {
            context.Response.Write("{\"success\":false,\"authenticated\":false,\"message\":\"Session expired\"}");
            return;
        }

        // 存取並更新 Session 變數，觸發 ASP.NET 滑動過期機制 (Sliding Expiration)，自動展延 Session 有效期限
        context.Session["LastKeepAlive"] = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

        context.Response.Write("{\"success\":true,\"authenticated\":true}");
    }

    public bool IsReusable
    {
        get { return false; }
    }
}
