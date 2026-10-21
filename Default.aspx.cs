using System;
using System.Web.UI;
using Newtonsoft.Json;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC
{
    public partial class Default : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // 處理非同步 AJAX 登入請求
            if (Request.HttpMethod == "POST" && Request["action"] == "login")
            {
                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";

                string userId = Request["userId"] ?? "";
                string password = Request["password"] ?? "";
                string validateCode = Request["validateCode"] ?? "";

                LoginResult result = AuthService.ValidateLogin(userId, password, validateCode, Context);
                Response.Write(JsonConvert.SerializeObject(result));
                Response.End();
                return;
            }

            // 若已登入則直接前往主頁
            if (!IsPostBack)
            {
                if (Session["LoginUser"] != null)
                {
                    Response.Redirect("MainPage.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                }
            }
        }
    }
}
