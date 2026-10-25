using System;
using System.Web;
using System.Web.UI;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.BufferAnalysis
{
    /// <summary>
    /// 環域空間分析與 360 環景導覽地圖頁面 (CodeBehind)
    /// 符合 C# 5.0 語法規範
    /// </summary>
    public partial class BufferMap : Page
    {
        public string CurrentUserName { get; set; }
        public string CurrentUserId { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            // 權限檢查 (Session 或 FormsAuthentication)
            UserAccount user = Session["LoginUser"] as UserAccount;
            if (user == null)
            {
                // 嘗試從 AuthService 或 Ticket 取回
                user = AuthService.GetCurrentUser(Context);
            }

            if (user != null)
            {
                CurrentUserName = user.Name ?? "";
                CurrentUserId = user.UserID ?? "";
            }
            else
            {
                CurrentUserName = "訪客";
                CurrentUserId = "";
            }
        }
    }
}
