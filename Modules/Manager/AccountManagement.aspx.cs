using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using NTPC_FEC.Helpers;
using NTPC_FEC.Services;

namespace NTPC_FEC.Modules.Manager
{
    public partial class AccountManagement : Page
    {
        protected ScriptManager sm1;
        protected Panel pnlAlert;
        protected Literal litAlertMsg;
        protected Button btnOpenNewAcc;
        protected LinkButton btnFilterAll;
        protected Repeater repPUnitTabs;
        protected TextBox txtKeyword;
        protected Button btnSearch;
        protected Literal litTotalCount;
        protected Repeater repUserList;

        // 權限設定 Modal 控制項
        protected Panel pnlSetLicModal;
        protected LinkButton btnCloseLicModalX;
        protected Literal litEditingUserID;
        protected Literal litEditingName;
        protected Literal litEditingPUnit;
        protected TextBox txtEditingPUnit;
        protected Repeater repPermGroups;
        protected CheckBoxList cblTowns;
        protected Button btnCloseLicModal;
        protected Button btnSaveLic;

        // 新增帳號 Modal 控制項
        protected Panel pnlNewAccModal;
        protected LinkButton btnCloseNewAccX;
        protected TextBox txtNewUserId;
        protected TextBox txtNewPassword;
        protected TextBox txtNewName;
        protected TextBox txtNewPUnit;
        protected Button btnCancelNewAcc;
        protected Button btnConfirmNewAcc;

        // Request 級別快取，避免列表渲染時產生 N+1 查詢
        private List<AuthItem> _cachedAuthItems;
        private Dictionary<string, List<string>> _cachedAllUserTowns;

        public string CurrentPUnit
        {
            get { return (ViewState["CurrentPUnit"] as string) ?? "ALL"; }
            set { ViewState["CurrentPUnit"] = value; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["LoginUser"] == null)
            {
                Response.Redirect("~/Default.aspx", true);
                return;
            }

            // 權限檢查：僅管理員能進此頁
            var currentUser = AuthService.GetCurrentUser(Context);
            string userId = (currentUser != null && currentUser.UserID != null) ? currentUser.UserID : (Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "");
            bool isAdmin = (userId.ToLower() == "admin")
                           || MenuService.CheckLicense((currentUser != null ? currentUser.Lic : 0L), 63)
                           || MenuService.CheckLicense((currentUser != null ? currentUser.Lic : 0L), 41);

            if (!isAdmin)
            {
                Response.Write("<script>alert('您無權限存取系統維運管理頁面！'); window.location.href='" + ResolveUrl("~/MainPage.aspx") + "';</script>");
                Response.End();
                return;
            }

            if (!IsPostBack)
            {
                LoadPUnitTabs();
                LoadUsers();
            }
        }

        // 載入單位分類標籤 (康廷、空噪、空品等)
        private void LoadPUnitTabs()
        {
            try
            {
                string sql = "SELECT ISNULL(NULLIF(LTRIM(RTRIM(PUnit)), ''), '未指定') AS PUnit, COUNT(*) AS UserCount FROM UserAcc GROUP BY ISNULL(NULLIF(LTRIM(RTRIM(PUnit)), ''), '未指定') ORDER BY UserCount DESC";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                repPUnitTabs.DataSource = dt;
                repPUnitTabs.DataBind();
            }
            catch { }
        }

        // 預先載入所有帳號之行政區對應，大幅加速列表呈現
        private void PreloadUserTowns()
        {
            _cachedAllUserTowns = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
            try
            {
                string sql = "SELECT u.User_ID, u.TOWN_NO, c.TOWN_NA FROM UserFilterTown u LEFT JOIN C_TOWN c ON u.TOWN_NO = c.TOWN_NO ORDER BY u.TOWN_NO";
                DataTable dt = DbHelper.ExecuteDataTable(sql);
                if (dt != null)
                {
                    foreach (DataRow row in dt.Rows)
                    {
                        string uid = (row["User_ID"] != null && row["User_ID"] != DBNull.Value) ? row["User_ID"].ToString().Trim() : "";
                        if (string.IsNullOrEmpty(uid)) continue;

                        string townName = (row["TOWN_NA"] != null && row["TOWN_NA"] != DBNull.Value) ? row["TOWN_NA"].ToString().Trim() : "";
                        if (string.IsNullOrEmpty(townName))
                        {
                            townName = (row["TOWN_NO"] != null && row["TOWN_NO"] != DBNull.Value) ? row["TOWN_NO"].ToString().Trim() : "";
                        }

                        if (!string.IsNullOrEmpty(townName))
                        {
                            if (!_cachedAllUserTowns.ContainsKey(uid))
                            {
                                _cachedAllUserTowns[uid] = new List<string>();
                            }
                            if (!_cachedAllUserTowns[uid].Contains(townName))
                            {
                                _cachedAllUserTowns[uid].Add(townName);
                            }
                        }
                    }
                }
            }
            catch { }
        }

        // 載入使用者清單
        private void LoadUsers()
        {
            string keyword = txtKeyword.Text.Trim();
            string sql = "SELECT UID, UserID, Name, PUnit, Acc_State, LIC, LIC2, FAC_ID, LastLogin FROM UserAcc WHERE 1=1 ";
            var parameters = new List<SqlParameter>();

            // 單位過濾
            if (!string.IsNullOrEmpty(CurrentPUnit) && CurrentPUnit != "ALL")
            {
                if (CurrentPUnit == "未指定")
                {
                    sql += " AND (PUnit IS NULL OR LTRIM(RTRIM(PUnit)) = '') ";
                }
                else
                {
                    sql += " AND LTRIM(RTRIM(PUnit)) = @PUnit ";
                    parameters.Add(new SqlParameter("@PUnit", SqlDbType.NVarChar) { Value = CurrentPUnit });
                }
            }

            // 關鍵字搜尋
            if (!string.IsNullOrEmpty(keyword))
            {
                sql += " AND (UserID LIKE @Keyword OR Name LIKE @Keyword OR FAC_ID LIKE @Keyword OR PUnit LIKE @Keyword) ";
                parameters.Add(new SqlParameter("@Keyword", SqlDbType.NVarChar) { Value = "%" + keyword + "%" });
            }

            sql += " ORDER BY UID DESC";

            try
            {
                _cachedAuthItems = PermissionService.GetAuthItems();
                PreloadUserTowns();

                DataTable dt = DbHelper.ExecuteDataTable(sql, parameters.ToArray());
                if (litTotalCount != null)
                {
                    litTotalCount.Text = (dt != null ? dt.Rows.Count : 0).ToString();
                }
                repUserList.DataSource = dt;
                repUserList.DataBind();
            }
            catch (Exception ex)
            {
                ShowAlert("載入使用者失敗：" + ex.Message, "alert-danger");
            }
        }

        // 點擊單位標籤篩選
        protected void FilterPUnit_Click(object sender, EventArgs e)
        {
            var btn = sender as LinkButton;
            if (btn != null)
            {
                CurrentPUnit = btn.CommandArgument;
                btnFilterAll.CssClass = CurrentPUnit == "ALL" ? "punit-pill active" : "punit-pill";
                LoadPUnitTabs();
                LoadUsers();
            }
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            LoadUsers();
        }

        // 格式化輸出已配置之權限字串 (多欄緊湊卡片網格)
        public string RenderUserPermissions(object licObj, object lic2Obj)
        {
            long lic = 0, lic2 = 0;
            if (licObj != null && licObj != DBNull.Value) long.TryParse(licObj.ToString(), out lic);
            if (lic2Obj != null && lic2Obj != DBNull.Value) long.TryParse(lic2Obj.ToString(), out lic2);

            if (_cachedAuthItems == null)
            {
                _cachedAuthItems = PermissionService.GetAuthItems();
            }

            var groups = new Dictionary<string, List<string>>();
            foreach (var item in _cachedAuthItems)
            {
                bool hasPermission = false;
                if (item.FieldName.Equals("LIC2", StringComparison.OrdinalIgnoreCase))
                {
                    if (item.LicID >= 0 && item.LicID < 64)
                    {
                        hasPermission = (lic2 & (1L << item.LicID)) != 0;
                    }
                }
                else
                {
                    if (item.LicID >= 0 && item.LicID < 64)
                    {
                        hasPermission = (lic & (1L << item.LicID)) != 0;
                    }
                }

                if (hasPermission)
                {
                    if (!groups.ContainsKey(item.Group))
                    {
                        groups[item.Group] = new List<string>();
                    }
                    groups[item.Group].Add(item.LicName);
                }
            }

            if (groups.Count == 0)
            {
                return "<span class='text-muted small'><i class='fas fa-info-circle mr-1'></i>尚未配置任何業務權限</span>";
            }

            var sb = new System.Text.StringBuilder();
            sb.Append("<div class='perm-summary-grid'>");
            foreach (var kvp in groups)
            {
                sb.Append("<div class='perm-group-chip'>");
                sb.AppendFormat("<div class='perm-group-title'>{0}</div>", kvp.Key);
                sb.Append("<div class='perm-items-wrap'>");
                foreach (var item in kvp.Value)
                {
                    sb.AppendFormat("<span class='perm-item-text'>{0}</span>", item);
                }
                sb.Append("</div></div>");
            }
            sb.Append("</div>");
            return sb.ToString();
        }

        // 格式化輸出限定行政區 (智慧判斷全區 / 3欄緊湊網格)
        public string RenderUserTowns(string userId)
        {
            List<string> towns = null;
            string cleanId = userId != null ? userId.Trim() : "";
            if (_cachedAllUserTowns != null && !string.IsNullOrEmpty(cleanId))
            {
                _cachedAllUserTowns.TryGetValue(cleanId, out towns);
            }
            else
            {
                towns = PermissionService.GetUserTowns(cleanId);
            }

            if (towns == null || towns.Count == 0)
            {
                return "<span class='town-all-badge'><i class='fas fa-globe-asia mr-1'></i>不限制 (全區)</span>";
            }

            if (towns.Count >= 29)
            {
                return "<span class='town-full29-badge' title='已勾選新北市全部 29 個行政區'><i class='fas fa-map-marked-alt mr-1'></i>新北市全區 (29區)</span>";
            }

            var sb = new System.Text.StringBuilder();
            sb.Append("<div class='user-town-grid'>");
            foreach (var town in towns)
            {
                sb.AppendFormat("<span class='town-mini-badge'>{0}</span>", town);
            }
            sb.Append("</div>");
            return sb.ToString();
        }

        // 清單項目操作事件 (設定權限 / 啟用停用)
        protected void repUserList_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            string cmd = e.CommandName;
            if (cmd == "ToggleState")
            {
                // 切換狀態 OK <=> CL
                string[] parts = e.CommandArgument.ToString().Split('|');
                string targetUserId = parts[0];
                string currentState = parts.Length > 1 ? parts[1] : "OK";
                string newState = currentState == "OK" ? "CL" : "OK";

                try
                {
                    string sql = "UPDATE UserAcc SET Acc_State = @State WHERE UserID = @UserID";
                    var parameters = new SqlParameter[]
                    {
                        new SqlParameter("@State", SqlDbType.VarChar) { Value = newState },
                        new SqlParameter("@UserID", SqlDbType.VarChar) { Value = targetUserId }
                    };
                    DbHelper.ExecuteNonQuery(sql, parameters);
                    ShowAlert(string.Format("帳號 [{0}] 狀態已更新為：{1}", targetUserId, (newState == "OK" ? "正常啟用" : "停用")), "alert-success");
                    LoadUsers();
                }
                catch (Exception ex)
                {
                    ShowAlert("狀態變更失敗：" + ex.Message, "alert-danger");
                }
            }
            else if (cmd == "SetLic")
            {
                string targetUserId = e.CommandArgument.ToString();
                OpenSetLicModal(targetUserId);
            }
        }

        // 開啟權限設定 Modal
        private void OpenSetLicModal(string targetUserId)
        {
            string sql = "SELECT UserID, Name, PUnit, LIC, LIC2 FROM UserAcc WHERE UserID = @UserID";
            var parameters = new SqlParameter[]
            {
                new SqlParameter("@UserID", SqlDbType.VarChar) { Value = targetUserId }
            };
            DataTable dt = DbHelper.ExecuteDataTable(sql, parameters);
            if (dt.Rows.Count == 0) return;

            var row = dt.Rows[0];
            string currentPUnit = (row["PUnit"] != null && row["PUnit"] != DBNull.Value) ? row["PUnit"].ToString().Trim() : "";
            litEditingUserID.Text = row["UserID"].ToString();
            litEditingName.Text = row["Name"].ToString();
            litEditingPUnit.Text = string.IsNullOrEmpty(currentPUnit) ? "未指定單位" : currentPUnit;
            if (txtEditingPUnit != null)
            {
                txtEditingPUnit.Text = currentPUnit;
            }

            long lic = 0, lic2 = 0;
            long.TryParse((row["LIC"] != null ? row["LIC"].ToString() : ""), out lic);
            long.TryParse((row["LIC2"] != null ? row["LIC2"].ToString() : ""), out lic2);
            ViewState["EditingLic"] = lic;
            ViewState["EditingLic2"] = lic2;

            // 綁定權限群組 Repeater
            var allAuth = PermissionService.GetAuthItems();
            var groupedAuth = allAuth.GroupBy(a => a.Group).ToDictionary(g => g.Key, g => g.ToList());
            repPermGroups.DataSource = groupedAuth;
            repPermGroups.DataBind();

            // 綁定行政區清單
            var allTowns = PermissionService.GetTownList();
            var userTownNos = PermissionService.GetUserTownNos(targetUserId);
            cblTowns.Items.Clear();
            foreach (var town in allTowns)
            {
                var li = new ListItem(town.TownName, town.TownNo);
                li.Selected = userTownNos.Contains(town.TownNo);
                cblTowns.Items.Add(li);
            }

            pnlSetLicModal.Visible = true;
        }

        // 群組權限項目內部綁定
        protected void repPermGroups_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                var kvp = (KeyValuePair<string, List<AuthItem>>)e.Item.DataItem;
                var cbl = e.Item.FindControl("cblGroupItems") as CheckBoxList;
                if (cbl != null)
                {
                    long lic = ViewState["EditingLic"] != null ? (long)ViewState["EditingLic"] : 0L;
                    long lic2 = ViewState["EditingLic2"] != null ? (long)ViewState["EditingLic2"] : 0L;

                    cbl.Items.Clear();
                    foreach (var item in kvp.Value)
                    {
                        var li = new ListItem(item.LicName, item.LicID + "|" + item.FieldName);
                        bool isChecked = false;
                        if (item.FieldName.Equals("LIC2", StringComparison.OrdinalIgnoreCase))
                        {
                            isChecked = (lic2 & (1L << item.LicID)) != 0;
                        }
                        else
                        {
                            isChecked = (lic & (1L << item.LicID)) != 0;
                        }
                        li.Selected = isChecked;
                        cbl.Items.Add(li);
                    }
                }
            }
        }

        // 儲存權限、所屬單位與轄區設定
        protected void btnSaveLic_Click(object sender, EventArgs e)
        {
            string editUserId = litEditingUserID.Text.Trim();
            if (string.IsNullOrEmpty(editUserId)) return;

            string newPUnit = (txtEditingPUnit != null && txtEditingPUnit.Text != null) ? txtEditingPUnit.Text.Trim() : "";
            long newLic = 0L;
            long newLic2 = 0L;

            // 遍歷所有群組勾選項
            foreach (RepeaterItem item in repPermGroups.Items)
            {
                var cbl = item.FindControl("cblGroupItems") as CheckBoxList;
                if (cbl != null)
                {
                    foreach (ListItem li in cbl.Items)
                    {
                        if (li.Selected)
                        {
                            string[] valParts = li.Value.Split('|');
                            if (valParts.Length >= 2)
                            {
                                int licId = 0;
                                int.TryParse(valParts[0], out licId);
                                string field = valParts[1];

                                if (field.Equals("LIC2", StringComparison.OrdinalIgnoreCase))
                                {
                                    if (licId >= 0 && licId < 64) newLic2 |= (1L << licId);
                                }
                                else
                                {
                                    if (licId >= 0 && licId < 64) newLic |= (1L << licId);
                                }
                            }
                        }
                    }
                }
            }

            try
            {
                // 1. 更新 UserAcc 的 PUnit (所屬單位)、LIC 與 LIC2
                string sql = "UPDATE UserAcc SET PUnit = @PUnit, LIC = @LIC, LIC2 = @LIC2 WHERE UserID = @UserID";
                var parameters = new SqlParameter[]
                {
                    new SqlParameter("@PUnit", SqlDbType.NVarChar) { Value = newPUnit },
                    new SqlParameter("@LIC", SqlDbType.BigInt) { Value = newLic },
                    new SqlParameter("@LIC2", SqlDbType.BigInt) { Value = newLic2 },
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = editUserId }
                };
                DbHelper.ExecuteNonQuery(sql, parameters);

                // 2. 更新 UserFilterTown 行政區限制
                string delSql = "DELETE FROM UserFilterTown WHERE User_ID = @UserID";
                DbHelper.ExecuteNonQuery(delSql, new SqlParameter[] { new SqlParameter("@UserID", SqlDbType.VarChar) { Value = editUserId } });

                foreach (ListItem townItem in cblTowns.Items)
                {
                    if (townItem.Selected)
                    {
                        string insSql = "INSERT INTO UserFilterTown (User_ID, TOWN_NO) VALUES (@UserID, @TownNo)";
                        var townParams = new SqlParameter[]
                        {
                            new SqlParameter("@UserID", SqlDbType.VarChar) { Value = editUserId },
                            new SqlParameter("@TownNo", SqlDbType.VarChar) { Value = townItem.Value }
                        };
                        DbHelper.ExecuteNonQuery(insSql, townParams);
                    }
                }

                pnlSetLicModal.Visible = false;
                string unitLabel = string.IsNullOrEmpty(newPUnit) ? "未指定" : newPUnit;
                ShowAlert(string.Format("帳號 [{0}] 的所屬單位（{1}）、業務權限與轄區配置已儲存成功！", editUserId, unitLabel), "alert-success");
                LoadPUnitTabs();
                LoadUsers();
            }
            catch (Exception ex)
            {
                ShowAlert("儲存權限失敗：" + ex.Message, "alert-danger");
            }
        }

        // 開啟新增帳號 Modal
        protected void btnOpenNewAcc_Click(object sender, EventArgs e)
        {
            txtNewUserId.Text = "";
            txtNewPassword.Text = "";
            txtNewName.Text = "";
            txtNewPUnit.Text = CurrentPUnit != "ALL" && CurrentPUnit != "未指定" ? CurrentPUnit : "康廷";
            pnlNewAccModal.Visible = true;
        }

        // 確認新增帳號
        protected void btnConfirmNewAcc_Click(object sender, EventArgs e)
        {
            string newId = txtNewUserId.Text.Trim();
            string newPwd = txtNewPassword.Text.Trim();
            string newName = txtNewName.Text.Trim();
            string newPUnit = txtNewPUnit.Text.Trim();

            if (string.IsNullOrEmpty(newId) || string.IsNullOrEmpty(newPwd) || string.IsNullOrEmpty(newName))
            {
                ShowAlert("請輸入完整的帳號、密碼與姓名！", "alert-warning");
                return;
            }

            string pwdErr;
            if (!AuthService.CheckStrongPassword(newPwd, out pwdErr))
            {
                ShowAlert(pwdErr, "alert-danger");
                return;
            }

            try
            {
                string chkSql = "SELECT COUNT(*) FROM UserAcc WHERE UserID = @UserID";
                var chkParams = new SqlParameter[] { new SqlParameter("@UserID", SqlDbType.VarChar) { Value = newId } };
                DataTable dt = DbHelper.ExecuteDataTable(chkSql, chkParams);
                if (dt.Rows.Count > 0 && Convert.ToInt32(dt.Rows[0][0]) > 0)
                {
                    ShowAlert(string.Format("帳號 [{0}] 已存在，請更換帳號名稱！", newId), "alert-danger");
                    return;
                }

                string insSql = "INSERT INTO UserAcc (UserID, Password, Name, PUnit, LIC, LIC2, Acc_State, LastPwdChangeDate) VALUES (@UserID, @Password, @Name, @PUnit, 0, 0, 'OK', GETDATE())";
                var insParams = new SqlParameter[]
                {
                    new SqlParameter("@UserID", SqlDbType.VarChar) { Value = newId },
                    new SqlParameter("@Password", SqlDbType.VarChar) { Value = newPwd },
                    new SqlParameter("@Name", SqlDbType.NVarChar) { Value = newName },
                    new SqlParameter("@PUnit", SqlDbType.NVarChar) { Value = newPUnit }
                };

                DbHelper.ExecuteNonQuery(insSql, insParams);
                pnlNewAccModal.Visible = false;
                ShowAlert(string.Format("帳號 [{0}] 已成功建立！請立即點選【權限設定】為其配置業務模組權限。", newId), "alert-success");
                LoadPUnitTabs();
                LoadUsers();
            }
            catch (Exception ex)
            {
                ShowAlert("新增帳號失敗：" + ex.Message, "alert-danger");
            }
        }

        // 關閉任何彈出視窗
        protected void btnCloseModal_Click(object sender, EventArgs e)
        {
            pnlSetLicModal.Visible = false;
            pnlNewAccModal.Visible = false;
        }

        private void ShowAlert(string msg, string cssClass)
        {
            pnlAlert.Visible = true;
            pnlAlert.CssClass = string.Format("alert {0} alert-dismissible fade show mb-4", cssClass);
            litAlertMsg.Text = msg;
        }
    }
}
