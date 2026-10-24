﻿using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NTPC_FEC.Helpers;
using NTPC_FEC.Models;
using NTPC_FEC.Services;

namespace NTPC_FEC.OwnReport
{
    public partial class Report_AirQuality : Page
    {
        private JavaScriptSerializer jsonSerializer;

        public Report_AirQuality()
        {
            jsonSerializer = new JavaScriptSerializer();
            jsonSerializer.MaxJsonLength = int.MaxValue;
        }

        #region 資料傳輸模型 (遵循 C# 5.0，無自動屬性初始化)

        public class ResponseModel
        {
            public bool Success { get; set; }
            public string Message { get; set; }
            public object Data { get; set; }
        }

        public class FacInfoModel
        {
            public string FacId { get; set; }
            public string CNo { get; set; }
            public string FacName { get; set; }
            public string TownName { get; set; }
            public string Addr { get; set; }
            public double Twd97X { get; set; }
            public double Twd97Y { get; set; }
            public double Lat { get; set; }
            public double Lng { get; set; }
        }

        public class ReportDataModel
        {
            public int pIndex { get; set; }
            public string FAC_ID { get; set; }
            public string County { get; set; }
            public string C_NO { get; set; }
            public string CNAM { get; set; }
            public string OverDate { get; set; }
            public string ContentType { get; set; }
            public string Status { get; set; }
            public string Less { get; set; }
            public string LessMe { get; set; }
            public string NoReason { get; set; }
            public string RunTimeStart { get; set; }
            public string RunTimeEnd { get; set; }
            public string TSP { get; set; }
            public string PM10 { get; set; }
            public string PM25 { get; set; }
            public string SOx { get; set; }
            public string NOx { get; set; }
            public string VOCs { get; set; }
            public string InputUser { get; set; }
            public string CreateDate { get; set; }
            public string EditDate { get; set; }
        }

        public class InitDataPackage
        {
            public string Mode { get; set; }
            public bool IsManager { get; set; }
            public bool CanEdit { get; set; }
            public string CurrentUser { get; set; }
            public FacInfoModel FacInfo { get; set; }
            public List<string> DateList { get; set; }
            public ReportDataModel ReportData { get; set; }
            public List<FacInfoModel> FacList { get; set; }

            public InitDataPackage()
            {
                DateList = new List<string>();
                FacList = new List<FacInfoModel>();
            }
        }

        #endregion

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
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "系統處理失敗：" + ex.Message
                    }));
                }
                Response.End();
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower().Trim())
            {
                case "getinitdata":
                    GetInitData();
                    break;
                case "save":
                    SaveReport();
                    break;
                default:
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "未知的 API 指令：" + action
                    }));
                    break;
            }
        }

        #region AJAX: 初始化取得案件與工廠資料 (GetInitData)

        private void GetInitData()
        {
            string mode = Request["mode"];
            if (string.IsNullOrEmpty(mode)) mode = "new";
            mode = mode.ToLower().Trim();

            string facId = Request["fac"];
            if (facId != null) facId = facId.Trim();

            string currentUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString().Trim() : "Guest";

            // 檢查管理員身分
            bool isManager = false;
            try
            {
                UserAccount uAcc = AuthService.GetCurrentUser(Context);
                if (uAcc != null)
                {
                    if ((uAcc.Lic & (1L << 16)) != 0 || (uAcc.Lic & (1L << 63)) != 0 || string.IsNullOrEmpty(uAcc.FacID))
                    {
                        isManager = true;
                    }
                    if (string.IsNullOrEmpty(facId) && !string.IsNullOrEmpty(uAcc.FacID))
                    {
                        facId = uAcc.FacID.Trim();
                    }
                }
            }
            catch
            {
            }

            // 若使用者未指定 fac，嘗試自 Session 提取工廠
            if (string.IsNullOrEmpty(facId))
            {
                if (Session["User_FAC_ID"] != null)
                {
                    facId = Session["User_FAC_ID"].ToString().Trim();
                }
            }

            InitDataPackage pkg = new InitDataPackage();
            pkg.Mode = mode;
            pkg.IsManager = isManager;
            pkg.CanEdit = true;
            pkg.CurrentUser = currentUser;

            // 1. 若為管理員或無指定工廠時，載入工廠選單供前端切換
            if (isManager || string.IsNullOrEmpty(facId))
            {
                try
                {
                    string facSql = "SELECT TOP 100 f.FAC_ID, f.C_NO, f.FAC_NAME, t.TOWN_NA, f.ADDR, f.TWD97_X, f.TWD97_Y FROM FAC_Main f LEFT JOIN C_TOWN t ON f.TOWN_CODE = t.TOWN_NO WHERE f.FAC_ID IS NOT NULL AND f.FAC_NAME IS NOT NULL ORDER BY f.FAC_NAME";
                    DataTable dtFacs = DbHelper.ExecuteDataTable(facSql);
                    if (dtFacs != null)
                    {
                        foreach (DataRow row in dtFacs.Rows)
                        {
                            FacInfoModel fItem = new FacInfoModel();
                            fItem.FacId = row["FAC_ID"] != DBNull.Value ? row["FAC_ID"].ToString().Trim() : "";
                            fItem.CNo = row["C_NO"] != DBNull.Value ? row["C_NO"].ToString().Trim() : "";
                            fItem.FacName = row["FAC_NAME"] != DBNull.Value ? row["FAC_NAME"].ToString().Trim() : "";
                            fItem.TownName = row["TOWN_NA"] != DBNull.Value ? row["TOWN_NA"].ToString().Trim() : "";
                            fItem.Addr = (row.Table.Columns.Contains("ADDR") && row["ADDR"] != DBNull.Value) ? row["ADDR"].ToString().Trim() : ((row.Table.Columns.Contains("FAC_ADDR") && row["FAC_ADDR"] != DBNull.Value) ? row["FAC_ADDR"].ToString().Trim() : "");
                            pkg.FacList.Add(fItem);
                        }
                    }

                    if (string.IsNullOrEmpty(facId) && pkg.FacList.Count > 0)
                    {
                        facId = pkg.FacList[0].FacId;
                    }
                }
                catch
                {
                }
            }

            // 2. 取得工廠詳細資訊
            FacInfoModel facInfo = new FacInfoModel();
            facInfo.FacId = facId ?? "";
            if (!string.IsNullOrEmpty(facId))
            {
                try
                {
                    string facDetailSql = "SELECT TOP 1 f.FAC_ID, f.C_NO, f.FAC_NAME, t.TOWN_NA, f.ADDR, f.TWD97_X, f.TWD97_Y FROM FAC_Main f LEFT JOIN C_TOWN t ON f.TOWN_CODE = t.TOWN_NO WHERE f.FAC_ID = @FAC_ID";
                    SqlParameter[] fParams = new SqlParameter[]
                    {
                        new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId }
                    };
                    DataTable dtF = DbHelper.ExecuteDataTable(facDetailSql, fParams);
                    if (dtF != null && dtF.Rows.Count > 0)
                    {
                        DataRow r = dtF.Rows[0];
                        facInfo.FacId = facId;
                        facInfo.CNo = r["C_NO"] != DBNull.Value ? r["C_NO"].ToString().Trim() : "";
                        facInfo.FacName = r["FAC_NAME"] != DBNull.Value ? r["FAC_NAME"].ToString().Trim() : "";
                        facInfo.TownName = r["TOWN_NA"] != DBNull.Value ? r["TOWN_NA"].ToString().Trim() : "";
                        facInfo.Addr = (r.Table.Columns.Contains("ADDR") && r["ADDR"] != DBNull.Value) ? r["ADDR"].ToString().Trim() : ((r.Table.Columns.Contains("FAC_ADDR") && r["FAC_ADDR"] != DBNull.Value) ? r["FAC_ADDR"].ToString().Trim() : "");

                        double x = 0, y = 0;
                        if (r["TWD97_X"] != DBNull.Value) double.TryParse(r["TWD97_X"].ToString(), out x);
                        if (r["TWD97_Y"] != DBNull.Value) double.TryParse(r["TWD97_Y"].ToString(), out y);
                        facInfo.Twd97X = x;
                        facInfo.Twd97Y = y;

                        if (x > 0 && y > 0)
                        {
                            double lat, lng;
                            Twd97ToWgs84(x, y, out lat, out lng);
                            facInfo.Lat = Math.Round(lat, 6);
                            facInfo.Lng = Math.Round(lng, 6);
                        }
                    }
                }
                catch
                {
                }
            }
            pkg.FacInfo = facInfo;

            // 3. 取得空品不良預警通報日期列表
            pkg.DateList = FetchAirQualityDates();

            // 4. 取得或初始化回報單資料
            ReportDataModel rData = new ReportDataModel();
            int reportIndex = 0;
            int.TryParse(Request["id"], out reportIndex);
            if (reportIndex == 0)
            {
                int.TryParse(Request["index"], out reportIndex);
            }

            if (mode == "edit" && !string.IsNullOrEmpty(facId) && reportIndex > 0)
            {
                try
                {
                    string qSql = "SELECT TOP 1 * FROM OverReport_TypeA_1 WHERE FAC_ID = @FAC_ID AND pIndex = @pIndex";
                    SqlParameter[] qParams = new SqlParameter[]
                    {
                        new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = facId },
                        new SqlParameter("@pIndex", SqlDbType.Int) { Value = reportIndex }
                    };
                    DataTable dtRep = DbHelper.ExecuteDataTable(qSql, qParams);
                    if (dtRep != null && dtRep.Rows.Count > 0)
                    {
                        DataRow repRow = dtRep.Rows[0];
                        rData.pIndex = reportIndex;
                        rData.FAC_ID = facId;
                        rData.County = repRow["County"] != DBNull.Value ? repRow["County"].ToString() : "";
                        rData.C_NO = repRow["C_NO"] != DBNull.Value ? repRow["C_NO"].ToString() : "";
                        rData.CNAM = repRow["CNAM"] != DBNull.Value ? repRow["CNAM"].ToString() : "";

                        if (repRow["OverDate"] != DBNull.Value)
                        {
                            DateTime dtOver;
                            if (DateTime.TryParse(repRow["OverDate"].ToString(), out dtOver))
                            {
                                rData.OverDate = dtOver.ToString("yyyy-MM-dd");
                            }
                        }

                        rData.ContentType = repRow["ContentType"] != DBNull.Value ? repRow["ContentType"].ToString() : "電話";
                        rData.Status = repRow["Status"] != DBNull.Value ? repRow["Status"].ToString() : "操作中";
                        rData.Less = repRow["Less"] != DBNull.Value ? repRow["Less"].ToString() : "是";
                        rData.LessMe = repRow["LessMe"] != DBNull.Value ? repRow["LessMe"].ToString().Replace("<br />", "\r\n") : "";
                        rData.NoReason = repRow["NoReason"] != DBNull.Value ? repRow["NoReason"].ToString() : "";

                        if (repRow["S_DATE"] != DBNull.Value)
                        {
                            DateTime sDt;
                            if (DateTime.TryParse(repRow["S_DATE"].ToString(), out sDt))
                            {
                                rData.RunTimeStart = sDt.ToString("HH:mm");
                            }
                        }
                        if (string.IsNullOrEmpty(rData.RunTimeStart)) rData.RunTimeStart = "08:00";

                        if (repRow["E_DATE"] != DBNull.Value)
                        {
                            DateTime eDt;
                            if (DateTime.TryParse(repRow["E_DATE"].ToString(), out eDt))
                            {
                                rData.RunTimeEnd = eDt.ToString("HH:mm");
                            }
                        }
                        if (string.IsNullOrEmpty(rData.RunTimeEnd)) rData.RunTimeEnd = "17:00";

                        rData.TSP = FormatDoubleString(repRow["TSP"]);
                        rData.PM10 = FormatDoubleString(repRow["PM10"]);
                        rData.PM25 = FormatDoubleString(repRow["PM25"]);
                        rData.SOx = FormatDoubleString(repRow["SOx"]);
                        rData.NOx = FormatDoubleString(repRow["NOx"]);
                        rData.VOCs = FormatDoubleString(repRow["VOCs"]);

                        rData.InputUser = repRow["InputUser"] != DBNull.Value ? repRow["InputUser"].ToString() : "";
                        if (repRow["CreateDate"] != DBNull.Value)
                        {
                            DateTime cd;
                            if (DateTime.TryParse(repRow["CreateDate"].ToString(), out cd))
                            {
                                rData.CreateDate = cd.ToString("yyyy-MM-dd HH:mm");
                            }
                        }
                        if (repRow["EditDate"] != DBNull.Value)
                        {
                            DateTime ed;
                            if (DateTime.TryParse(repRow["EditDate"].ToString(), out ed))
                            {
                                rData.EditDate = ed.ToString("yyyy-MM-dd HH:mm");
                            }
                        }
                    }
                }
                catch
                {
                }
            }
            else
            {
                // 新增模式預設值
                rData.pIndex = 0;
                rData.FAC_ID = facId;
                rData.County = facInfo.TownName;
                rData.C_NO = facInfo.CNo;
                rData.CNAM = facInfo.FacName;
                rData.OverDate = pkg.DateList.Count > 0 ? pkg.DateList[0] : DateTime.Today.ToString("yyyy-MM-dd");
                rData.ContentType = "電話";
                rData.Status = "操作中";
                rData.Less = "是";
                rData.LessMe = "";
                rData.NoReason = "";
                rData.RunTimeStart = "08:00";
                rData.RunTimeEnd = "17:00";
                rData.TSP = "0";
                rData.PM10 = "0";
                rData.PM25 = "0";
                rData.SOx = "0";
                rData.NOx = "0";
                rData.VOCs = "0";
                rData.InputUser = currentUser;
                rData.CreateDate = DateTime.Now.ToString("yyyy-MM-dd HH:mm");
                rData.EditDate = rData.CreateDate;
            }

            // 若既有日期清單不包含這筆案件的 OverDate，動態補入
            if (!string.IsNullOrEmpty(rData.OverDate) && !pkg.DateList.Contains(rData.OverDate))
            {
                pkg.DateList.Insert(0, rData.OverDate);
            }

            pkg.ReportData = rData;

            Response.Write(jsonSerializer.Serialize(new ResponseModel
            {
                Success = true,
                Message = "OK",
                Data = pkg
            }));
        }

        #endregion

        #region AJAX: 儲存應變回報單 (SaveReport)

        private void SaveReport()
        {
            string jsonBody = "";
            using (StreamReader reader = new StreamReader(Request.InputStream, Encoding.UTF8))
            {
                jsonBody = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(jsonBody))
            {
                jsonBody = Request["data"];
            }

            if (string.IsNullOrEmpty(jsonBody))
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "未接收到回報表單資料"
                }));
                return;
            }

            ReportDataModel model = null;
            try
            {
                model = JsonConvert.DeserializeObject<ReportDataModel>(jsonBody);
            }
            catch (Exception ex)
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "表單資料格式錯誤：" + ex.Message
                }));
                return;
            }

            if (model == null || string.IsNullOrEmpty(model.FAC_ID))
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "工廠管制代碼不可為空"
                }));
                return;
            }

            if (string.IsNullOrEmpty(model.OverDate))
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "應變日期不可為空"
                }));
                return;
            }

            // 檢核減排措施邏輯
            if (model.Less == "是" && string.IsNullOrEmpty(model.LessMe != null ? model.LessMe.Trim() : ""))
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "配合執行減排措施為「是」，請填寫具體減排措施"
                }));
                return;
            }

            if (model.Less == "否" && string.IsNullOrEmpty(model.NoReason != null ? model.NoReason.Trim() : ""))
            {
                Response.Write(jsonSerializer.Serialize(new ResponseModel
                {
                    Success = false,
                    Message = "配合執行減排措施為「否」，請填寫未配合原因說明"
                }));
                return;
            }

            DateTime overDate;
            if (!DateTime.TryParse(model.OverDate, out overDate))
            {
                overDate = DateTime.Today;
            }

            // 解析執行起訖時間
            DateTime sDate = overDate;
            if (!string.IsNullOrEmpty(model.RunTimeStart))
            {
                string[] parts = model.RunTimeStart.Split(':');
                int h = 0, m = 0;
                if (parts.Length > 0) int.TryParse(parts[0], out h);
                if (parts.Length > 1) int.TryParse(parts[1], out m);
                sDate = new DateTime(overDate.Year, overDate.Month, overDate.Day, h, m, 0);
            }

            DateTime eDate = overDate;
            if (!string.IsNullOrEmpty(model.RunTimeEnd))
            {
                string[] parts = model.RunTimeEnd.Split(':');
                int h = 0, m = 0;
                if (parts.Length > 0) int.TryParse(parts[0], out h);
                if (parts.Length > 1) int.TryParse(parts[1], out m);
                eDate = new DateTime(overDate.Year, overDate.Month, overDate.Day, h, m, 0);
            }

            string currentUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString().Trim() : "Guest";
            string formattedLessMe = model.LessMe != null ? model.LessMe.Replace("\r\n", "<br />").Replace("\n", "<br />") : "";

            bool isNew = (model.pIndex <= 0);

            if (isNew)
            {
                // 1. 取得新序號
                int newIndex = 1;
                string maxSql = "SELECT ISNULL(MAX(pIndex), 0) FROM OverReport_TypeA_1 WHERE FAC_ID = @FAC_ID";
                SqlParameter[] maxParams = new SqlParameter[]
                {
                    new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = model.FAC_ID }
                };
                object maxObj = DbHelper.ExecuteScalar(maxSql, maxParams);
                if (maxObj != null && maxObj != DBNull.Value)
                {
                    int mIdx;
                    if (int.TryParse(maxObj.ToString(), out mIdx))
                    {
                        newIndex = mIdx + 1;
                    }
                }

                // 2. 寫入新增
                string insertSql = @"INSERT INTO OverReport_TypeA_1
(FAC_ID, pIndex, County, C_NO, CNAM, S_DATE, E_DATE, ContentType, Status, Less, LessMe, NoReason, OverDate, TSP, PM10, PM25, SOx, NOx, VOCs, InputUser, CreateDate, EditDate)
VALUES
(@FAC_ID, @pIndex, @County, @C_NO, @CNAM, @S_DATE, @E_DATE, @ContentType, @Status, @Less, @LessMe, @NoReason, @OverDate, @TSP, @PM10, @PM25, @SOx, @NOx, @VOCs, @InputUser, @CreateDate, @EditDate)";

                SqlParameter[] insertParams = new SqlParameter[]
                {
                    new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = model.FAC_ID },
                    new SqlParameter("@pIndex", SqlDbType.Int) { Value = newIndex },
                    new SqlParameter("@County", SqlDbType.NVarChar) { Value = (object)model.County ?? DBNull.Value },
                    new SqlParameter("@C_NO", SqlDbType.VarChar) { Value = (object)model.C_NO ?? DBNull.Value },
                    new SqlParameter("@CNAM", SqlDbType.NVarChar) { Value = (object)model.CNAM ?? DBNull.Value },
                    new SqlParameter("@S_DATE", SqlDbType.DateTime) { Value = sDate },
                    new SqlParameter("@E_DATE", SqlDbType.DateTime) { Value = eDate },
                    new SqlParameter("@ContentType", SqlDbType.NVarChar) { Value = (object)model.ContentType ?? DBNull.Value },
                    new SqlParameter("@Status", SqlDbType.NVarChar) { Value = (object)model.Status ?? DBNull.Value },
                    new SqlParameter("@Less", SqlDbType.NVarChar) { Value = (object)model.Less ?? DBNull.Value },
                    new SqlParameter("@LessMe", SqlDbType.NVarChar) { Value = (object)formattedLessMe ?? DBNull.Value },
                    new SqlParameter("@NoReason", SqlDbType.NVarChar) { Value = (object)model.NoReason ?? DBNull.Value },
                    new SqlParameter("@OverDate", SqlDbType.DateTime) { Value = overDate },
                    new SqlParameter("@TSP", SqlDbType.Float) { Value = ParseDoubleOrNull(model.TSP) },
                    new SqlParameter("@PM10", SqlDbType.Float) { Value = ParseDoubleOrNull(model.PM10) },
                    new SqlParameter("@PM25", SqlDbType.Float) { Value = ParseDoubleOrNull(model.PM25) },
                    new SqlParameter("@SOx", SqlDbType.Float) { Value = ParseDoubleOrNull(model.SOx) },
                    new SqlParameter("@NOx", SqlDbType.Float) { Value = ParseDoubleOrNull(model.NOx) },
                    new SqlParameter("@VOCs", SqlDbType.Float) { Value = ParseDoubleOrNull(model.VOCs) },
                    new SqlParameter("@InputUser", SqlDbType.VarChar) { Value = currentUser },
                    new SqlParameter("@CreateDate", SqlDbType.DateTime) { Value = DateTime.Now },
                    new SqlParameter("@EditDate", SqlDbType.DateTime) { Value = DateTime.Now }
                };

                int aff = DbHelper.ExecuteNonQuery(insertSql, insertParams);
                if (aff > 0)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = true,
                        Message = "空品應變回報單已成功新增儲存！",
                        Data = new { pIndex = newIndex, facId = model.FAC_ID }
                    }));
                }
                else
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "儲存失敗，未寫入資料庫"
                    }));
                }
            }
            else
            {
                // 更新編輯
                string updateSql = @"UPDATE OverReport_TypeA_1 SET
County = @County,
C_NO = @C_NO,
CNAM = @CNAM,
S_DATE = @S_DATE,
E_DATE = @E_DATE,
ContentType = @ContentType,
Status = @Status,
Less = @Less,
LessMe = @LessMe,
NoReason = @NoReason,
OverDate = @OverDate,
TSP = @TSP,
PM10 = @PM10,
PM25 = @PM25,
SOx = @SOx,
NOx = @NOx,
VOCs = @VOCs,
EditDate = @EditDate
WHERE FAC_ID = @FAC_ID AND pIndex = @pIndex";

                SqlParameter[] updateParams = new SqlParameter[]
                {
                    new SqlParameter("@County", SqlDbType.NVarChar) { Value = (object)model.County ?? DBNull.Value },
                    new SqlParameter("@C_NO", SqlDbType.VarChar) { Value = (object)model.C_NO ?? DBNull.Value },
                    new SqlParameter("@CNAM", SqlDbType.NVarChar) { Value = (object)model.CNAM ?? DBNull.Value },
                    new SqlParameter("@S_DATE", SqlDbType.DateTime) { Value = sDate },
                    new SqlParameter("@E_DATE", SqlDbType.DateTime) { Value = eDate },
                    new SqlParameter("@ContentType", SqlDbType.NVarChar) { Value = (object)model.ContentType ?? DBNull.Value },
                    new SqlParameter("@Status", SqlDbType.NVarChar) { Value = (object)model.Status ?? DBNull.Value },
                    new SqlParameter("@Less", SqlDbType.NVarChar) { Value = (object)model.Less ?? DBNull.Value },
                    new SqlParameter("@LessMe", SqlDbType.NVarChar) { Value = (object)formattedLessMe ?? DBNull.Value },
                    new SqlParameter("@NoReason", SqlDbType.NVarChar) { Value = (object)model.NoReason ?? DBNull.Value },
                    new SqlParameter("@OverDate", SqlDbType.DateTime) { Value = overDate },
                    new SqlParameter("@TSP", SqlDbType.Float) { Value = ParseDoubleOrNull(model.TSP) },
                    new SqlParameter("@PM10", SqlDbType.Float) { Value = ParseDoubleOrNull(model.PM10) },
                    new SqlParameter("@PM25", SqlDbType.Float) { Value = ParseDoubleOrNull(model.PM25) },
                    new SqlParameter("@SOx", SqlDbType.Float) { Value = ParseDoubleOrNull(model.SOx) },
                    new SqlParameter("@NOx", SqlDbType.Float) { Value = ParseDoubleOrNull(model.NOx) },
                    new SqlParameter("@VOCs", SqlDbType.Float) { Value = ParseDoubleOrNull(model.VOCs) },
                    new SqlParameter("@EditDate", SqlDbType.DateTime) { Value = DateTime.Now },
                    new SqlParameter("@FAC_ID", SqlDbType.VarChar) { Value = model.FAC_ID },
                    new SqlParameter("@pIndex", SqlDbType.Int) { Value = model.pIndex }
                };

                int aff = DbHelper.ExecuteNonQuery(updateSql, updateParams);
                if (aff > 0)
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = true,
                        Message = "空品應變回報單已成功更新！",
                        Data = new { pIndex = model.pIndex, facId = model.FAC_ID }
                    }));
                }
                else
                {
                    Response.Write(jsonSerializer.Serialize(new ResponseModel
                    {
                        Success = false,
                        Message = "更新失敗，未找到對應案件或無修改變更"
                    }));
                }
            }
        }

        #endregion

        #region 工具函式

        /// <summary>
        /// 取得空品不良預警通報日期列表 (具備外部 API 呼叫與資料庫備援機制)
        /// </summary>
        private List<string> FetchAirQualityDates()
        {
            List<string> dates = new List<string>();

            // 1. 嘗試呼叫環保局空品預警 API
            try
            {
                string host = HttpContext.Current != null && HttpContext.Current.Request != null ? HttpContext.Current.Request.Url.Host : "";
                string apiUrl = (host == "127.0.0.1") ? "http://192.168.1.91/ntpc_airquality/line/getdate.ashx" : "http://www.content.com.tw/ntpc_airquality/line/getdate.ashx";

                HttpWebRequest req = (HttpWebRequest)WebRequest.Create(apiUrl);
                req.Method = "GET";
                req.Timeout = 3000;
                req.ReadWriteTimeout = 3000;
                using (HttpWebResponse resp = (HttpWebResponse)req.GetResponse())
                {
                    using (StreamReader sr = new StreamReader(resp.GetResponseStream(), Encoding.UTF8))
                    {
                        string respText = sr.ReadToEnd();
                        JArray arr = JsonConvert.DeserializeObject(respText) as JArray;
                        if (arr != null)
                        {
                            for (int i = 0; i < arr.Count; i++)
                            {
                                string dStr = arr[i].Value<string>();
                                if (!string.IsNullOrEmpty(dStr))
                                {
                                    DateTime parsed;
                                    if (DateTime.TryParse(dStr, out parsed))
                                    {
                                        string standardDate = parsed.ToString("yyyy-MM-dd");
                                        if (!dates.Contains(standardDate))
                                        {
                                            dates.Add(standardDate);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch
            {
            }

            // 2. 備援機制：若外部 API 無法連通，從資料庫 OverReport_TypeA_1 查詢近期通報日期
            if (dates.Count == 0)
            {
                try
                {
                    string fallbackSql = "SELECT DISTINCT TOP 10 CONVERT(varchar(10), OverDate, 120) AS Send_Date FROM OverReport_TypeA_1 WHERE OverDate IS NOT NULL ORDER BY Send_Date DESC";
                    DataTable dtBack = DbHelper.ExecuteDataTable(fallbackSql);
                    if (dtBack != null)
                    {
                        foreach (DataRow row in dtBack.Rows)
                        {
                            if (row["Send_Date"] != DBNull.Value)
                            {
                                string d = row["Send_Date"].ToString().Trim();
                                if (!string.IsNullOrEmpty(d) && !dates.Contains(d))
                                {
                                    dates.Add(d);
                                }
                            }
                        }
                    }
                }
                catch
                {
                }
            }

            // 3. 確保至少有今日日期
            string todayStr = DateTime.Today.ToString("yyyy-MM-dd");
            if (!dates.Contains(todayStr))
            {
                dates.Insert(0, todayStr);
            }

            return dates;
        }

        private static object ParseDoubleOrNull(string val)
        {
            if (string.IsNullOrEmpty(val)) return DBNull.Value;
            double d;
            if (double.TryParse(val.Trim(), out d))
            {
                return d;
            }
            return DBNull.Value;
        }

        private static string FormatDoubleString(object obj)
        {
            if (obj == null || obj == DBNull.Value) return "";
            double d;
            if (double.TryParse(obj.ToString(), out d))
            {
                return d.ToString("0.###");
            }
            return obj.ToString();
        }

        /// <summary>
        /// 二度分帶座標轉換 (TWD97 轉 WGS84 經緯度)，遵循 SKILL.md 標準規範
        /// </summary>
        private static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
        {
            if (x <= 0 || y <= 0) { lat = 0; lon = 0; return; }

            double a = 6378137.0;
            double b = 6356752.314245;
            double lon0 = 121.0 * Math.PI / 180.0;
            double k0 = 0.9999;
            double dx = 250000.0;

            double e = Math.Sqrt(1.0 - (b * b) / (a * a));
            double e2 = e * e / (1.0 - e * e);
            x -= dx;

            double M = y / k0;
            double mu = M / (a * (1.0 - Math.Pow(e, 2) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0));
            double e1 = (1.0 - Math.Sqrt(1.0 - Math.Pow(e, 2))) / (1.0 + Math.Sqrt(1.0 - Math.Pow(e, 2)));

            double J1 = (3.0 * e1 / 2.0 - 27.0 * Math.Pow(e1, 3) / 32.0);
            double J2 = (21.0 * Math.Pow(e1, 2) / 16.0 - 55.0 * Math.Pow(e1, 4) / 32.0);
            double J3 = (151.0 * Math.Pow(e1, 3) / 96.0);
            double J4 = (1097.0 * Math.Pow(e1, 4) / 512.0);

            double fp = mu + J1 * Math.Sin(2.0 * mu) + J2 * Math.Sin(4.0 * mu) + J3 * Math.Sin(6.0 * mu) + J4 * Math.Sin(8.0 * mu);

            double C1 = e2 * Math.Pow(Math.Cos(fp), 2);
            double T1 = Math.Pow(Math.Tan(fp), 2);
            double R1 = a * (1.0 - Math.Pow(e, 2)) / Math.Pow(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2), 1.5);
            double N1 = a / Math.Sqrt(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2));
            double D = x / (N1 * k0);

            double latRad = fp - (N1 * Math.Tan(fp) / R1) * (Math.Pow(D, 2) / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.Pow(C1, 2) - 9.0 * e2) * Math.Pow(D, 4) / 24.0 + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.Pow(T1, 2) - 252.0 * e2 - 3.0 * Math.Pow(C1, 2)) * Math.Pow(D, 6) / 720.0);
            double lonRad = lon0 + (D - (1.0 + 2.0 * T1 + C1) * Math.Pow(D, 3) / 6.0 + (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.Pow(C1, 2) + 8.0 * e2 + 24.0 * Math.Pow(T1, 2)) * Math.Pow(D, 5) / 120.0) / Math.Cos(fp);

            lat = latRad * 180.0 / Math.PI;
            lon = lonRad * 180.0 / Math.PI;
        }

        #endregion
    }
}
