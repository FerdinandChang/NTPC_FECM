using System;
using System.Web.UI;
using System.Web.UI.WebControls;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC
{
    public partial class MainPageMaster : MasterPage
    {
        protected Literal litUserName;
        protected Literal litUserRole;
        protected Literal litFullDisplayName;
        protected PlaceHolder phAdminQuickLink;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["LoginUser"] == null)
            {
                Response.Redirect("~/Default.aspx", true);
                return;
            }

            if (!IsPostBack)
            {
                var user = AuthService.GetCurrentUser(Context);
                string userId = (user != null && user.UserID != null) ? user.UserID : (Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "");
                string userName = (user != null && !string.IsNullOrEmpty(user.Name)) ? user.Name : userId;

                // 判斷是否為系統管理者
                bool isAdmin = (userId.ToLower() == "admin") 
                               || MenuService.CheckLicense((user != null ? user.Lic : 0L), 63)
                               || MenuService.CheckLicense((user != null ? user.Lic : 0L), 41);

                if (litUserName != null)
                {
                    litUserName.Text = userName;
                }

                if (litFullDisplayName != null)
                {
                    litFullDisplayName.Text = string.Format("{0} ({1})", userName, userId);
                }

                if (litUserRole != null)
                {
                    if (isAdmin)
                    {
                        litUserRole.Text = "系統管理者";
                    }
                    else if ((user != null && !string.IsNullOrEmpty(user.FacID)))
                    {
                        litUserRole.Text = "自主申報廠端";
                    }
                    else
                    {
                        litUserRole.Text = "查核稽查員";
                    }
                }

                if (phAdminQuickLink != null)
                {
                    phAdminQuickLink.Visible = isAdmin;
                }
            }
        }
    }
}
