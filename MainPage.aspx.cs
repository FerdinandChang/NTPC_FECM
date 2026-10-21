using System;
using System.Collections.Generic;
using System.Web.UI;
using Newtonsoft.Json;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC
{
    public partial class MainPage : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["LoginUser"] == null)
            {
                Response.Redirect("Default.aspx", true);
                return;
            }
        }

        public string GetModulesJson()
        {
            var currentUser = AuthService.GetCurrentUser(Context);
            List<MenuModule> modules = MenuService.GetUserModules(currentUser);
            return JsonConvert.SerializeObject(modules);
        }
    }
}
