using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using NTPC_FEC.Services;

namespace NTPC_FEC
{
    /// <summary>
    /// 業者端專屬快速登入入口 - 整合 AuthService 雙軌安全驗證 (相容舊版 Password 與新版 PasswordHash)
    /// </summary>
    public partial class ClientLogin : Page
    {
        protected Literal litMsg;

        protected void Page_Load(object sender, EventArgs e)
        {
            // 安全限制：強制僅允許 HTTP POST 請求，阻斷 GET 請求洩漏密碼於 Log 或瀏覽器歷程
            if (!string.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase))
            {
                Response.Redirect("Default.aspx", true);
                return;
            }

            string reqUser = Request["user"];
            string reqPassword = Request["password"];

            if (string.IsNullOrEmpty(reqUser) || string.IsNullOrEmpty(reqPassword))
            {
                Response.Redirect("Default.aspx", true);
                return;
            }

            var loginRes = AuthService.ValidateClientLogin(reqUser, reqPassword, Context);
            if (loginRes.Success)
            {
                Response.Redirect("MainPage.aspx", false);
                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            if (litMsg != null)
            {
                litMsg.Text = string.Format("<span style='color:red;'>驗證失敗：{0}，3 秒後返回登入頁...</span>", loginRes.Message);
            }
            Response.AddHeader("REFRESH", "3;URL=Default.aspx");
        }
    }
}
