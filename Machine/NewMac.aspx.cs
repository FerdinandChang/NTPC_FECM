using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.Machine
{
    public partial class NewMac : Page
    {
        private JavaScriptSerializer json;

        public NewMac()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";
                try
                {
                    HandleAjaxAction(action);
                }
                catch (Exception ex)
                {
                    Response.Write(json.Serialize(new
                    {
                        Success = false,
                        Message = "系統處理錯誤：" + ex.Message
                    }));
                }
                Response.End();
                return;
            }
        }

        private string GetCurrentUser()
        {
            if (Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                return Session["LoginUser"].ToString().Trim();
            }
            if (User != null && User.Identity != null && !string.IsNullOrEmpty(User.Identity.Name))
            {
                return User.Identity.Name;
            }
            return "查核人員";
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "getinit":
                    GetInitData();
                    break;
                case "getmac":
                    GetMacData();
                    break;
                case "save":
                    SaveData();
                    break;
                case "deletephoto":
                    DeletePhoto();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的指令：" + action }));
                    break;
            }
        }

        // 1. 初始化頁面基本選項與公私場所資訊
        private void GetInitData()
        {
            string facId = Request["id"] != null ? Request["id"].ToString().Trim() : "";
            string mode = Request["mode"] != null ? Request["mode"].ToString().Trim().ToLower() : "new";

            object facInfo = null;
            if (!string.IsNullOrEmpty(facId))
            {
                try
                {
                    string sqlFac = "SELECT TOP 1 FAC_ID, C_NO, FAC_NAME, FAC_Type1, Use_Area, Use_Area_Unit FROM FAC_Main WHERE FAC_ID = @facId";
                    DataTable dtFac = DbHelper.ExecuteDataTable(sqlFac, new SqlParameter("@facId", facId));
                    if (dtFac.Rows.Count > 0)
                    {
                        DataRow r = dtFac.Rows[0];
                        string facType = r["FAC_Type1"] != DBNull.Value ? r["FAC_Type1"].ToString().Trim() : "";
                        string useArea = r["Use_Area"] != DBNull.Value ? r["Use_Area"].ToString().Trim() : "";
                        string useAreaUnit = r["Use_Area_Unit"] != DBNull.Value ? r["Use_Area_Unit"].ToString().Trim() : "平方公尺";

                        // 檢查是否有最新 FAC_EditHis
                        try
                        {
                            string sqlHis = "SELECT TOP 1 FAC_Type, Use_Area, Use_Area_Unit FROM FAC_EditHis WHERE FAC_ID = @facId ORDER BY Edit_Date DESC";
                            DataTable dtHis = DbHelper.ExecuteDataTable(sqlHis, new SqlParameter("@facId", facId));
                            if (dtHis.Rows.Count > 0)
                            {
                                if (dtHis.Rows[0]["FAC_Type"] != DBNull.Value && !string.IsNullOrEmpty(dtHis.Rows[0]["FAC_Type"].ToString()))
                                {
                                    facType = dtHis.Rows[0]["FAC_Type"].ToString().Trim();
                                }
                                if (dtHis.Rows[0]["Use_Area"] != DBNull.Value && !string.IsNullOrEmpty(dtHis.Rows[0]["Use_Area"].ToString()))
                                {
                                    useArea = dtHis.Rows[0]["Use_Area"].ToString().Trim();
                                }
                                if (dtHis.Rows[0]["Use_Area_Unit"] != DBNull.Value && !string.IsNullOrEmpty(dtHis.Rows[0]["Use_Area_Unit"].ToString()))
                                {
                                    useAreaUnit = dtHis.Rows[0]["Use_Area_Unit"].ToString().Trim();
                                }
                            }
                        }
                        catch
                        {
                        }

                        facInfo = new
                        {
                            FAC_ID = r["FAC_ID"].ToString().Trim(),
                            C_NO = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : "",
                            FAC_NAME = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "",
                            FAC_Type1 = facType,
                            Use_Area = useArea,
                            Use_Area_Unit = string.IsNullOrEmpty(useAreaUnit) ? "平方公尺" : useAreaUnit
                        };
                    }
                }
                catch
                {
                }
            }

            if (facInfo == null)
            {
                facInfo = new
                {
                    FAC_ID = facId,
                    C_NO = facId,
                    FAC_NAME = "公私場所 (" + facId + ")",
                    FAC_Type1 = "",
                    Use_Area = "",
                    Use_Area_Unit = "平方公尺"
                };
            }

            // 產生出產年份清單 (無資料, 現年 - 40 年)
            var yearList = new List<string>();
            yearList.Add("無資料");
            int currentRocYear = DateTime.Now.Year - 1911;
            for (int i = 0; i <= 40; i++)
            {
                yearList.Add((currentRocYear - i).ToString());
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = new
                {
                    CurrentUser = GetCurrentUser(),
                    FacInfo = facInfo,
                    YearList = yearList,
                    DefaultCheckDate = DateTime.Today.ToString("yyyy-MM-dd"),
                    DefaultDeadline = DateTime.Today.AddYears(1).ToString("yyyy-MM-dd")
                }
            }));
        }

        // 2. 取得既有施工機具資料 (編輯模式)
        private void GetMacData()
        {
            string facId = Request["id"] != null ? Request["id"].ToString().Trim() : "";
            string macId = Request["id2"] != null ? Request["id2"].ToString().Trim() : "";

            if (string.IsNullOrEmpty(facId) || string.IsNullOrEmpty(macId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少公私場所編號或機具序號" }));
                return;
            }

            string sql = "SELECT * FROM Machine_Main WHERE FAC_ID = @facId AND mac_ID = @macId";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@facId", facId), new SqlParameter("@macId", macId));
            if (dt.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無該機具申報資料" }));
                return;
            }

            DataRow r = dt.Rows[0];
            var mac = new Dictionary<string, object>();
            foreach (DataColumn col in dt.Columns)
            {
                object val = r[col.ColumnName];
                if (val == DBNull.Value)
                {
                    mac[col.ColumnName] = null;
                }
                else if (val is DateTime)
                {
                    mac[col.ColumnName] = ((DateTime)val).ToString("yyyy-MM-dd");
                }
                else
                {
                    mac[col.ColumnName] = val.ToString().Trim();
                }
            }

            // 讀取既有 6 類照片資訊
            var photoCategories = new string[] { "檢測結果", "檢測過程", "機具全貌", "機身編號、引擎編號", "核發標章", "其他佐證" };
            var photos = new Dictionary<string, object>();
            string dirPath = Server.MapPath("~/Upload/MAC/" + facId + "/" + macId);
            if (Directory.Exists(dirPath))
            {
                DirectoryInfo dir = new DirectoryInfo(dirPath);
                foreach (string cat in photoCategories)
                {
                    FileInfo[] files = dir.GetFiles(cat + ".*");
                    if (files.Length > 0)
                    {
                        photos[cat] = new
                        {
                            Exists = true,
                            FileName = files[0].Name,
                            Url = "../Upload/MAC/" + facId + "/" + macId + "/" + HttpUtility.UrlEncode(files[0].Name) + "?t=" + DateTime.Now.Ticks
                        };
                    }
                    else
                    {
                        photos[cat] = new { Exists = false, FileName = "", Url = "" };
                    }
                }
            }
            else
            {
                foreach (string cat in photoCategories)
                {
                    photos[cat] = new { Exists = false, FileName = "", Url = "" };
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = mac,
                Photos = photos
            }));
        }

        // 3. 儲存機具申報資料 (新增 / 編輯)
        private void SaveData()
        {
            string reqBody = "";
            using (var reader = new StreamReader(Request.InputStream, System.Text.Encoding.UTF8))
            {
                reqBody = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(reqBody))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未接收到儲存內容" }));
                return;
            }

            var dict = json.Deserialize<Dictionary<string, object>>(reqBody);
            if (dict == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "資料格式解析失敗" }));
                return;
            }

            string mode = dict.ContainsKey("Mode") && dict["Mode"] != null ? dict["Mode"].ToString().Trim().ToLower() : "new";
            string facId = dict.ContainsKey("FAC_ID") && dict["FAC_ID"] != null ? dict["FAC_ID"].ToString().Trim() : "";

            if (string.IsNullOrEmpty(facId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少公私場所代碼 (FAC_ID)" }));
                return;
            }

            // 數值與日期安全轉換輔助
            DateTime checkDate = DateTime.Today;
            if (dict.ContainsKey("Check_date") && dict["Check_date"] != null)
            {
                DateTime.TryParse(dict["Check_date"].ToString(), out checkDate);
            }

            object markDeadline = DBNull.Value;
            if (dict.ContainsKey("Mark_Deadline") && dict["Mark_Deadline"] != null)
            {
                DateTime dtDeadline;
                if (DateTime.TryParse(dict["Mark_Deadline"].ToString(), out dtDeadline))
                {
                    markDeadline = dtDeadline;
                }
            }

            float weight = ParseFloat(dict, "Weight");
            float exhaustVolume = ParseFloat(dict, "Exhaust_volume");
            float power = ParseFloat(dict, "Power");
            float speed = ParseFloat(dict, "Rotating_speed");
            float machinePrice = ParseFloat(dict, "MachinePrice");

            float opaqueStart1 = ParseFloat(dict, "opaque_Start1");
            float opaqueStart2 = ParseFloat(dict, "opaque_Start2");
            float opaqueStart3 = ParseFloat(dict, "opaque_Start3");
            float opaqueRun1 = ParseFloat(dict, "opaque_Run1");
            float opaqueRun2 = ParseFloat(dict, "opaque_Run2");
            float opaqueRun3 = ParseFloat(dict, "opaque_Run3");
            float tempStart = ParseFloat(dict, "Tempeture_Start");
            float tempRun = ParseFloat(dict, "Tempeture_Run");

            string currentUser = GetCurrentUser();
            int macId = 0;

            if (mode == "new")
            {
                // 取最大 mac_ID
                string sqlMax = "SELECT ISNULL(MAX(mac_ID), 0) FROM Machine_Main WHERE FAC_ID = @facId";
                object scalar = DbHelper.ExecuteScalar(sqlMax, new SqlParameter("@facId", facId));
                if (scalar != null && scalar != DBNull.Value)
                {
                    int.TryParse(scalar.ToString(), out macId);
                }
                macId++;

                string sqlInsert = @"INSERT INTO Machine_Main (
                    FAC_ID, mac_ID, mac_Type, Always_Here, Move_Mode, When_To_Use,
                    mac_boss1, mac_boss2, mac_boss_tel, Brand, model, PIN,
                    OUT_YEAR, Engine_NO, Weight, Exhaust_volume, Power, Power_Unit, Rotating_speed,
                    one_Driver, Black_Smoke, accelerator, Exhaust_Side, Oil_From, Report_Black_Smoke,
                    Maintenance_Place, Maintenance_PlaceName, Maintenance_Frequency, Maintenance_Frequency_Unit,
                    Maintenance_Type, Maintenance_Price, Control_equipment, Check_date,
                    opaque_Start1, opaque_Start2, opaque_Start3, opaque_Run1, opaque_Run2, opaque_Run3,
                    Tempeture_Start, Tempeture_Run, MachinePrice, Smoke_Start, Smoke_Warn, Smoke_Test,
                    Light_Item1, Light_Item2, Light_Item3, Light_Item4, Light_Item5, Light_Item6, Light_Item7, Light_Item8,
                    Mark_NO, Mark_Deadline, Driver_Name, Driver_Tel,
                    Mac_State, Create_User, Create_Date
                ) VALUES (
                    @FAC_ID, @mac_ID, @mac_Type, @Always_Here, @Move_Mode, @When_To_Use,
                    @mac_boss1, @mac_boss2, @mac_boss_tel, @Brand, @model, @PIN,
                    @OUT_YEAR, @Engine_NO, @Weight, @Exhaust_volume, @Power, @Power_Unit, @Rotating_speed,
                    @one_Driver, @Black_Smoke, @accelerator, @Exhaust_Side, @Oil_From, @Report_Black_Smoke,
                    @Maintenance_Place, @Maintenance_PlaceName, @Maintenance_Frequency, @Maintenance_Frequency_Unit,
                    @Maintenance_Type, @Maintenance_Price, @Control_equipment, @Check_date,
                    @opaque_Start1, @opaque_Start2, @opaque_Start3, @opaque_Run1, @opaque_Run2, @opaque_Run3,
                    @Tempeture_Start, @Tempeture_Run, @MachinePrice, @Smoke_Start, @Smoke_Warn, @Smoke_Test,
                    @Light_Item1, @Light_Item2, @Light_Item3, @Light_Item4, @Light_Item5, @Light_Item6, @Light_Item7, @Light_Item8,
                    @Mark_NO, @Mark_Deadline, @Driver_Name, @Driver_Tel,
                    'A00a', @Create_User, GETDATE()
                )";

                SqlParameter[] pars = CreateParams(dict, facId, macId, checkDate, markDeadline, weight, exhaustVolume, power, speed, machinePrice,
                    opaqueStart1, opaqueStart2, opaqueStart3, opaqueRun1, opaqueRun2, opaqueRun3, tempStart, tempRun, currentUser);

                DbHelper.ExecuteNonQuery(sqlInsert, pars);
            }
            else
            {
                // 編輯更新
                if (dict.ContainsKey("mac_ID") && dict["mac_ID"] != null)
                {
                    int.TryParse(dict["mac_ID"].ToString(), out macId);
                }
                if (macId <= 0 && Request["id2"] != null)
                {
                    int.TryParse(Request["id2"].ToString(), out macId);
                }

                if (macId <= 0)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "編輯模式缺少機具編號 (mac_ID)" }));
                    return;
                }

                string sqlUpdate = @"UPDATE Machine_Main SET
                    mac_Type = @mac_Type,
                    Always_Here = @Always_Here,
                    Move_Mode = @Move_Mode,
                    When_To_Use = @When_To_Use,
                    mac_boss1 = @mac_boss1,
                    mac_boss2 = @mac_boss2,
                    mac_boss_tel = @mac_boss_tel,
                    Brand = @Brand,
                    model = @model,
                    PIN = @PIN,
                    OUT_YEAR = @OUT_YEAR,
                    Engine_NO = @Engine_NO,
                    Weight = @Weight,
                    Exhaust_volume = @Exhaust_volume,
                    Power = @Power,
                    Power_Unit = @Power_Unit,
                    Rotating_speed = @Rotating_speed,
                    one_Driver = @one_Driver,
                    Black_Smoke = @Black_Smoke,
                    accelerator = @accelerator,
                    Exhaust_Side = @Exhaust_Side,
                    Oil_From = @Oil_From,
                    Report_Black_Smoke = @Report_Black_Smoke,
                    Maintenance_Place = @Maintenance_Place,
                    Maintenance_PlaceName = @Maintenance_PlaceName,
                    Maintenance_Frequency = @Maintenance_Frequency,
                    Maintenance_Frequency_Unit = @Maintenance_Frequency_Unit,
                    Maintenance_Type = @Maintenance_Type,
                    Maintenance_Price = @Maintenance_Price,
                    Control_equipment = @Control_equipment,
                    Check_date = @Check_date,
                    opaque_Start1 = @opaque_Start1,
                    opaque_Start2 = @opaque_Start2,
                    opaque_Start3 = @opaque_Start3,
                    opaque_Run1 = @opaque_Run1,
                    opaque_Run2 = @opaque_Run2,
                    opaque_Run3 = @opaque_Run3,
                    Tempeture_Start = @Tempeture_Start,
                    Tempeture_Run = @Tempeture_Run,
                    MachinePrice = @MachinePrice,
                    Smoke_Start = @Smoke_Start,
                    Smoke_Warn = @Smoke_Warn,
                    Smoke_Test = @Smoke_Test,
                    Light_Item1 = @Light_Item1,
                    Light_Item2 = @Light_Item2,
                    Light_Item3 = @Light_Item3,
                    Light_Item4 = @Light_Item4,
                    Light_Item5 = @Light_Item5,
                    Light_Item6 = @Light_Item6,
                    Light_Item7 = @Light_Item7,
                    Light_Item8 = @Light_Item8,
                    Mark_NO = @Mark_NO,
                    Mark_Deadline = @Mark_Deadline,
                    Driver_Name = @Driver_Name,
                    Driver_Tel = @Driver_Tel
                    WHERE FAC_ID = @FAC_ID AND mac_ID = @mac_ID";

                SqlParameter[] pars = CreateParams(dict, facId, macId, checkDate, markDeadline, weight, exhaustVolume, power, speed, machinePrice,
                    opaqueStart1, opaqueStart2, opaqueStart3, opaqueRun1, opaqueRun2, opaqueRun3, tempStart, tempRun, currentUser);

                DbHelper.ExecuteNonQuery(sqlUpdate, pars);
            }

            // 更新場所性質與面積 (若有填寫)
            string facType1 = GetStr(dict, "FAC_Type1");
            string useAreaStr = GetStr(dict, "Use_Area");
            string useAreaUnit = GetStr(dict, "Use_Area_Unit");
            if (!string.IsNullOrEmpty(facType1) || !string.IsNullOrEmpty(useAreaStr))
            {
                try
                {
                    string sqlHis = @"INSERT INTO FAC_EditHis (FAC_ID, Edit_User, Edit_Date, FAC_Type, Use_Area, Use_Area_Unit)
                                      VALUES (@facId, @user, GETDATE(), @facType, @useArea, @unit)";
                    float ua = 0f;
                    float.TryParse(useAreaStr, out ua);
                    DbHelper.ExecuteNonQuery(sqlHis,
                        new SqlParameter("@facId", facId),
                        new SqlParameter("@user", currentUser),
                        new SqlParameter("@facType", string.IsNullOrEmpty(facType1) ? (object)DBNull.Value : facType1),
                        new SqlParameter("@useArea", ua > 0 ? (object)ua : DBNull.Value),
                        new SqlParameter("@unit", string.IsNullOrEmpty(useAreaUnit) ? "平方公尺" : useAreaUnit)
                    );
                    // 同步更新 FAC_Main
                    try
                    {
                        string sqlUpdateFac = @"UPDATE FAC_Main SET 
                            FAC_Type1 = CASE WHEN @facType IS NOT NULL THEN @facType ELSE FAC_Type1 END,
                            Use_Area = CASE WHEN @useArea IS NOT NULL THEN @useArea ELSE Use_Area END,
                            Use_Area_Unit = CASE WHEN @unit IS NOT NULL THEN @unit ELSE Use_Area_Unit END
                            WHERE FAC_ID = @facId";
                        DbHelper.ExecuteNonQuery(sqlUpdateFac,
                            new SqlParameter("@facId", facId),
                            new SqlParameter("@facType", string.IsNullOrEmpty(facType1) ? (object)DBNull.Value : facType1),
                            new SqlParameter("@useArea", ua > 0 ? (object)ua : DBNull.Value),
                            new SqlParameter("@unit", string.IsNullOrEmpty(useAreaUnit) ? (object)DBNull.Value : useAreaUnit)
                        );
                    }
                    catch
                    {
                    }
                }
                catch
                {
                }
            }

            // 儲存上傳照片
            if (dict.ContainsKey("Photos") && dict["Photos"] is Dictionary<string, object>)
            {
                var photos = (Dictionary<string, object>)dict["Photos"];
                string targetDir = Server.MapPath("~/Upload/MAC/" + facId + "/" + macId);
                if (!Directory.Exists(targetDir))
                {
                    Directory.CreateDirectory(targetDir);
                }

                foreach (KeyValuePair<string, object> entry in photos)
                {
                    string cat = entry.Key;
                    if (entry.Value is Dictionary<string, object>)
                    {
                        var pData = (Dictionary<string, object>)entry.Value;
                        if (pData.ContainsKey("Base64") && pData["Base64"] != null)
                        {
                            string b64 = pData["Base64"].ToString();
                            if (!string.IsNullOrEmpty(b64))
                            {
                                string cleanBase64 = Regex.Replace(b64, @"^data:image\/[a-zA-Z]+;base64,", "");
                                byte[] bytes = Convert.FromBase64String(cleanBase64);
                                string savePath = Path.Combine(targetDir, cat + ".jpg");
                                File.WriteAllBytes(savePath, bytes);
                            }
                        }
                    }
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = (mode == "new" ? "施工機具新增成功！" : "施工機具資料更新成功！"),
                FAC_ID = facId,
                mac_ID = macId
            }));
        }

        // 4. 刪除照片
        private void DeletePhoto()
        {
            string facId = Request["id"] != null ? Request["id"].ToString().Trim() : "";
            string macId = Request["id2"] != null ? Request["id2"].ToString().Trim() : "";
            string cat = Request["cat"] != null ? Request["cat"].ToString().Trim() : "";

            if (string.IsNullOrEmpty(facId) || string.IsNullOrEmpty(macId) || string.IsNullOrEmpty(cat))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少必要參數" }));
                return;
            }

            string targetDir = Server.MapPath("~/Upload/MAC/" + facId + "/" + macId);
            if (Directory.Exists(targetDir))
            {
                DirectoryInfo dir = new DirectoryInfo(targetDir);
                FileInfo[] files = dir.GetFiles(cat + ".*");
                foreach (FileInfo f in files)
                {
                    f.Delete();
                }
            }

            Response.Write(json.Serialize(new { Success = true, Message = "照片刪除成功" }));
        }

        // 輔助函式：建立 SqlParameter 陣列
        private SqlParameter[] CreateParams(Dictionary<string, object> d, string facId, int macId, DateTime checkDate, object markDeadline,
            float weight, float exhaustVolume, float power, float speed, float machinePrice,
            float opaqueStart1, float opaqueStart2, float opaqueStart3, float opaqueRun1, float opaqueRun2, float opaqueRun3,
            float tempStart, float tempRun, string currentUser)
        {
            return new SqlParameter[]
            {
                new SqlParameter("@FAC_ID", facId),
                new SqlParameter("@mac_ID", macId),
                new SqlParameter("@mac_Type", GetStr(d, "mac_Type")),
                new SqlParameter("@Always_Here", GetStr(d, "Always_Here")),
                new SqlParameter("@Move_Mode", GetStr(d, "Move_Mode")),
                new SqlParameter("@When_To_Use", GetStr(d, "When_To_Use")),
                new SqlParameter("@mac_boss1", GetStr(d, "mac_boss1")),
                new SqlParameter("@mac_boss2", GetStr(d, "mac_boss2")),
                new SqlParameter("@mac_boss_tel", GetStr(d, "mac_boss_tel")),
                new SqlParameter("@Brand", GetStr(d, "Brand")),
                new SqlParameter("@model", GetStr(d, "model")),
                new SqlParameter("@PIN", GetStr(d, "PIN")),
                new SqlParameter("@OUT_YEAR", GetStr(d, "OUT_YEAR")),
                new SqlParameter("@Engine_NO", GetStr(d, "Engine_NO")),
                new SqlParameter("@Weight", weight),
                new SqlParameter("@Exhaust_volume", exhaustVolume),
                new SqlParameter("@Power", power),
                new SqlParameter("@Power_Unit", GetStr(d, "Power_Unit")),
                new SqlParameter("@Rotating_speed", speed),
                new SqlParameter("@one_Driver", GetStr(d, "one_Driver")),
                new SqlParameter("@Black_Smoke", GetStr(d, "Black_Smoke")),
                new SqlParameter("@accelerator", GetStr(d, "accelerator")),
                new SqlParameter("@Exhaust_Side", GetStr(d, "Exhaust_Side")),
                new SqlParameter("@Oil_From", GetStr(d, "Oil_From")),
                new SqlParameter("@Report_Black_Smoke", GetStr(d, "Report_Black_Smoke")),
                new SqlParameter("@Maintenance_Place", GetStr(d, "Maintenance_Place")),
                new SqlParameter("@Maintenance_PlaceName", GetStr(d, "Maintenance_PlaceName")),
                new SqlParameter("@Maintenance_Frequency", GetStr(d, "Maintenance_Frequency")),
                new SqlParameter("@Maintenance_Frequency_Unit", GetStr(d, "Maintenance_Frequency_Unit")),
                new SqlParameter("@Maintenance_Type", GetStr(d, "Maintenance_Type")),
                new SqlParameter("@Maintenance_Price", GetStr(d, "Maintenance_Price")),
                new SqlParameter("@Control_equipment", GetStr(d, "Control_equipment")),
                new SqlParameter("@Check_date", checkDate),
                new SqlParameter("@opaque_Start1", opaqueStart1.ToString("0.00000")),
                new SqlParameter("@opaque_Start2", opaqueStart2.ToString("0.00000")),
                new SqlParameter("@opaque_Start3", opaqueStart3.ToString("0.00000")),
                new SqlParameter("@opaque_Run1", opaqueRun1.ToString("0.00000")),
                new SqlParameter("@opaque_Run2", opaqueRun2.ToString("0.00000")),
                new SqlParameter("@opaque_Run3", opaqueRun3.ToString("0.00000")),
                new SqlParameter("@Tempeture_Start", tempStart.ToString("0.0")),
                new SqlParameter("@Tempeture_Run", tempRun.ToString("0.0")),
                new SqlParameter("@MachinePrice", machinePrice),
                new SqlParameter("@Smoke_Start", GetStr(d, "Smoke_Start")),
                new SqlParameter("@Smoke_Warn", GetStr(d, "Smoke_Warn")),
                new SqlParameter("@Smoke_Test", GetStr(d, "Smoke_Test")),
                new SqlParameter("@Light_Item1", GetStr(d, "Light_Item1")),
                new SqlParameter("@Light_Item2", GetStr(d, "Light_Item2")),
                new SqlParameter("@Light_Item3", GetStr(d, "Light_Item3")),
                new SqlParameter("@Light_Item4", GetStr(d, "Light_Item4")),
                new SqlParameter("@Light_Item5", GetStr(d, "Light_Item5")),
                new SqlParameter("@Light_Item6", GetStr(d, "Light_Item6")),
                new SqlParameter("@Light_Item7", GetStr(d, "Light_Item7")),
                new SqlParameter("@Light_Item8", GetStr(d, "Light_Item8")),
                new SqlParameter("@Mark_NO", GetStr(d, "Mark_NO")),
                new SqlParameter("@Mark_Deadline", markDeadline),
                new SqlParameter("@Driver_Name", GetStr(d, "Driver_Name")),
                new SqlParameter("@Driver_Tel", GetStr(d, "Driver_Tel")),
                new SqlParameter("@Create_User", currentUser)
            };
        }

        private static string GetStr(Dictionary<string, object> d, string key)
        {
            if (d.ContainsKey(key) && d[key] != null)
            {
                return d[key].ToString().Trim();
            }
            return "";
        }

        private static float ParseFloat(Dictionary<string, object> d, string key)
        {
            if (d.ContainsKey(key) && d[key] != null)
            {
                float res = 0f;
                if (float.TryParse(d[key].ToString().Trim(), out res))
                {
                    return res;
                }
            }
            return 0f;
        }
    }
}
