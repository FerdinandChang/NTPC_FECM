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
                string displayName = user != null ? $"{user.Name} ({user.UserID})" : Session["LoginUser"].ToString();

                if (litUserName != null)
                {
                    litUserName.Text = displayName;
                }
            }
        }
    }
}
