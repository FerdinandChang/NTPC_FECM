using System;
using System.Data;
using System.Data.SqlClient;
using System.Web.UI;
using System.Web.UI.WebControls;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;

namespace NTPC_FEC
{
    public partial class ClientLogin : Page
    {
        protected Literal litMsg;

        protected void Page_Load(object sender, EventArgs e)
        {
            string reqUser = Request["user"];
            string reqPassword = Request["password"];

            if (string.IsNullOrEmpty(reqUser) || string.IsNullOrEmpty(reqPassword))
            {
                Response.Redirect("Default.aspx", true);
                return;
            }

            string sql = "SELECT * FROM UserAcc WHERE UserID = @UserID";
            var parameters = new SqlParameter[]
            {
                new SqlParameter("@UserID", SqlDbType.VarChar) { Value = reqUser.Trim() }
            };

            DataTable dt = DbHelper.ExecuteDataTable(sql, parameters);
            if (dt.Rows.Count > 0)
            {
                var row = dt.Rows[0];
                string dbPassword = row["Password"]?.ToString() ?? "";
                string accState = row["Acc_State"]?.ToString() ?? "";
                string userName = row["Name"]?.ToString() ?? reqUser;

                if (string.Equals(dbPassword, reqPassword) && accState.Equals("OK", StringComparison.OrdinalIgnoreCase))
                {
                    long lic = 0, lic2 = 0;
                    long.TryParse(row["LIC"]?.ToString(), out lic);
                    long.TryParse(row["LIC2"]?.ToString(), out lic2);
                    int uid = 0;
                    int.TryParse(row["UID"]?.ToString(), out uid);

                    var user = new UserAccount
                    {
                        UID = uid,
                        UserID = reqUser,
                        Name = userName,
                        AccState = accState,
                        Lic = lic,
                        Lic2 = lic2,
                        FacID = row["FAC_ID"]?.ToString() ?? ""
                    };

                    Session["LoginUser"] = user.UserID;
                    Session["UserName"] = user.Name;
                    Session["UserAccount"] = user;
                    Session["LoginMode"] = "client";

                    Response.Redirect("MainPage.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                    return;
                }
            }

            if (litMsg != null)
            {
                litMsg.Text = "<span style='color:red;'>驗證失敗：帳號密碼不符或無權限存取，3 秒後返回登入頁...</span>";
            }
            Response.AddHeader("REFRESH", "3;URL=Default.aspx");
        }
    }
}
