using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.Modules.Manager
{
    public partial class PasswordChange : Page
    {
        protected TextBox txtUserId;
        protected TextBox txtOldPwd;
        protected TextBox txtNewPwd;
        protected TextBox txtConfirmPwd;
        protected Button btnSave;
        protected Panel pnlAlert;
        protected Literal litAlertMsg;

        protected void Page_Load(object sender, EventArgs e)
        {
            // 支援頂部 Navbar 遮罩視窗 AJAX 變更密碼
            if (Request.HttpMethod == "POST" && Request["action"] == "changePassword")
            {
                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";

                string uId = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
                string oPwd = Request["oldPwd"] != null ? Request["oldPwd"].Trim() : "";
                string nPwd = Request["newPwd"] != null ? Request["newPwd"].Trim() : "";
                string cPwd = Request["confirmPwd"] != null ? Request["confirmPwd"].Trim() : "";

                OperationResult ajaxRes = AuthService.ChangePassword(uId, oPwd, nPwd, cPwd);
                Response.Write(Newtonsoft.Json.JsonConvert.SerializeObject(ajaxRes));
                Response.End();
                return;
            }

            if (Session["LoginUser"] == null)
            {
                Response.Redirect("~/Default.aspx", true);
                return;
            }

            if (!IsPostBack)
            {
                string userId = Session["LoginUser"].ToString();
                txtUserId.Text = userId;
            }
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            string userId = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "";
            string oldPwd = txtOldPwd.Text.Trim();
            string newPwd = txtNewPwd.Text.Trim();
            string confirmPwd = txtConfirmPwd.Text.Trim();

            OperationResult res = AuthService.ChangePassword(userId, oldPwd, newPwd, confirmPwd);
            if (res.Success)
            {
                ShowAlert(res.Message, "alert-success");
                txtOldPwd.Text = "";
                txtNewPwd.Text = "";
                txtConfirmPwd.Text = "";
            }
            else
            {
                ShowAlert(res.Message, "alert-danger");
            }
        }

        private void ShowAlert(string msg, string cssClass)
        {
            pnlAlert.Visible = true;
            pnlAlert.CssClass = string.Format("alert {0} alert-dismissible fade show mb-4", cssClass);
            litAlertMsg.Text = msg;
        }
    }
}
