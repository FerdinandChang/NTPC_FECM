using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;

namespace NTPC_FEC.BareGround
{
    public partial class Bare_List : Page
    {
        private JavaScriptSerializer json;

        public Bare_List()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SearchFilterModel
        {
            public string Mode { get; set; }
            public string BareGroundNo { get; set; }
            public string Addr { get; set; }
            public string LandUse { get; set; }
            public string DateS { get; set; }
            public string DateE { get; set; }
            public string StateFilter { get; set; }
            public int PageIndex { get; set; }
            public int PageSize { get; set; }

            public SearchFilterModel()
            {
                Mode = "all";
                BareGroundNo = "";
                Addr = "";
                LandUse = "";
                DateS = "";
                DateE = "";
                StateFilter = "";
                PageIndex = 1;
                PageSize = 15;
            }
        }

        public class BatchUploadModel
        {
            public List<int> InvNos { get; set; }
            public BatchUploadModel()
            {
                InvNos = new List<int>();
            }
        }

        protected override void Render(HtmlTextWriter writer)
        {
            // 若為 AJAX 請求則完全阻斷 ASP.NET Render 流程，避免 HTML 追加於 JSON 後方造成前端解析失敗
            if (!string.IsNullOrEmpty(Request["action"]))
            {
                return;
            }
            base.Render(writer);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();
                if (action.ToLower() == "exportexcel")
                {
                    HandleExportExcel();
                    return;
                }
                Response.ContentType = "application/json; charset=utf-8";
                try
                {
                    HandleAjaxAction(action);
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                catch (Exception ex)
                {
                    Response.Clear();
                    Response.ContentType = "application/json; charset=utf-8";
                    Response.Write(json.Serialize(new
                    {
                        Success = false,
                        Message = "系統處理失敗：" + ex.Message
                    }));
                }

                try
                {
                    Response.End();
                }
                catch (System.Threading.ThreadAbortException)
                {
                    return;
                }
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "getcounts":
                    GetCounts();
                    break;
                case "getlist":
                    GetList();
                    break;
                case "getinvlist":
                    GetInvList();
                    break;
                case "uploadcheck":
                    UploadCheck();
                    break;
                case "batchuploadcheck":
                    BatchUploadCheck();
                    break;
                case "delinv":
                    DeleteInv();
                    break;
                case "getmapdata":
                    GetMapData();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的指令：" + action }));
                    break;
            }
        }

        #region 1. 取得各業務模式案件數量 (KPI 統計)
        private void GetCounts()
        {
            // 計算各業務狀態案件總數
            // A00a: 暫存草稿 / 退回待修正
            // A00b: 退回待重辦
            // A00, A01, A02: 審核中
            // A03 / 其他已通過: 調查成果
            string sql = @"
                SELECT 
                    ISNULL(SUM(CASE WHEN bi.INV_State = 'A00a' THEN 1 ELSE 0 END), 0) AS CountDraft,
                    ISNULL(SUM(CASE WHEN bi.INV_State = 'A00b' THEN 1 ELSE 0 END), 0) AS CountBack,
                    ISNULL(SUM(CASE WHEN bi.INV_State IN ('A00', 'A01', 'A02') THEN 1 ELSE 0 END), 0) AS CountExamine,
                    ISNULL(SUM(CASE WHEN bi.INV_State NOT IN ('A00a', 'A00b', 'Z00', 'A00', 'A01', 'A02') THEN 1 ELSE 0 END), 0) AS CountDone,
                    (SELECT COUNT(*) FROM Bare_Main) AS CountSites,
                    ISNULL(SUM(CASE WHEN bi.INV_State != 'Z00' THEN 1 ELSE 0 END), 0) AS CountTotalInv
                FROM Bare_INV bi";

            DataTable dt = DbHelper.ExecuteDataTable(sql);
            int countDraft = 0;
            int countBack = 0;
            int countExamine = 0;
            int countDone = 0;
            int countSites = 0;
            int countTotalInv = 0;

            if (dt.Rows.Count > 0)
            {
                DataRow r = dt.Rows[0];
                if (r["CountDraft"] != DBNull.Value) countDraft = Convert.ToInt32(r["CountDraft"]);
                if (r["CountBack"] != DBNull.Value) countBack = Convert.ToInt32(r["CountBack"]);
                if (r["CountExamine"] != DBNull.Value) countExamine = Convert.ToInt32(r["CountExamine"]);
                if (r["CountDone"] != DBNull.Value) countDone = Convert.ToInt32(r["CountDone"]);
                if (r["CountSites"] != DBNull.Value) countSites = Convert.ToInt32(r["CountSites"]);
                if (r["CountTotalInv"] != DBNull.Value) countTotalInv = Convert.ToInt32(r["CountTotalInv"]);
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Counts = new
                {
                    Draft = countDraft,
                    Back = countBack,
                    Examine = countExamine,
                    Done = countDone,
                    Sites = countSites,
                    TotalInv = countTotalInv
                }
            }));
        }
        #endregion

        #region 2. 取得裸露地查核案件清單 (依業務模式精確篩選)
        private void GetList()
        {
            string postData = GetPostRawData();
            SearchFilterModel filter = null;
            if (!string.IsNullOrEmpty(postData))
            {
                try
                {
                    filter = json.Deserialize<SearchFilterModel>(postData);
                }
                catch
                {
                    filter = new SearchFilterModel();
                }
            }
            if (filter == null) filter = new SearchFilterModel();

            List<SqlParameter> pList = new List<SqlParameter>();
            StringBuilder sbWhere = new StringBuilder(" WHERE bi.INV_State != 'Z00' ");

            // 業務模式過濾 (精確對齊各模式之查核案件)
            string mode = string.IsNullOrEmpty(filter.Mode) ? "all" : filter.Mode.ToLower();
            if (mode == "reject")
            {
                sbWhere.Append(" AND bi.INV_State = 'A00a' ");
            }
            else if (mode == "back")
            {
                sbWhere.Append(" AND bi.INV_State = 'A00b' ");
            }
            else if (mode == "examine")
            {
                sbWhere.Append(" AND bi.INV_State IN ('A00', 'A01', 'A02') ");
            }
            else if (mode == "identify" || mode == "search")
            {
                sbWhere.Append(" AND bi.INV_State NOT IN ('A00a', 'A00b', 'Z00', 'A00', 'A01', 'A02') ");
            }

            // 裸露地編號過濾
            if (!string.IsNullOrEmpty(filter.BareGroundNo))
            {
                sbWhere.Append(" AND bm.BareGroundNo LIKE '%' + @BareGroundNo + '%' ");
                pList.Add(new SqlParameter("@BareGroundNo", filter.BareGroundNo.Trim()));
            }

            // 場址地址過濾
            if (!string.IsNullOrEmpty(filter.Addr))
            {
                sbWhere.Append(" AND bm.ADDR LIKE '%' + @ADDR + '%' ");
                pList.Add(new SqlParameter("@ADDR", filter.Addr.Trim()));
            }

            // 地目過濾
            if (!string.IsNullOrEmpty(filter.LandUse))
            {
                sbWhere.Append(" AND bm.LAND_USE LIKE '%' + @LAND_USE + '%' ");
                pList.Add(new SqlParameter("@LAND_USE", filter.LandUse.Trim()));
            }

            // 查核日期區間過濾
            if (!string.IsNullOrEmpty(filter.DateS))
            {
                DateTime dtS;
                if (DateTime.TryParse(filter.DateS, out dtS))
                {
                    sbWhere.Append(" AND bi.Check_DATE >= @DateS ");
                    pList.Add(new SqlParameter("@DateS", dtS.Date));
                }
            }
            if (!string.IsNullOrEmpty(filter.DateE))
            {
                DateTime dtE;
                if (DateTime.TryParse(filter.DateE, out dtE))
                {
                    sbWhere.Append(" AND bi.Check_DATE <= @DateE ");
                    pList.Add(new SqlParameter("@DateE", dtE.Date.AddDays(1).AddSeconds(-1)));
                }
            }

            // 明確狀態代碼過濾
            if (!string.IsNullOrEmpty(filter.StateFilter))
            {
                sbWhere.Append(" AND bi.INV_State = @StateFilter ");
                pList.Add(new SqlParameter("@StateFilter", filter.StateFilter.Trim()));
            }

            // 查詢符合條件的總筆數 (以 Bare_INV 查核案件為主軸)
            string countSql = "SELECT COUNT(*) FROM Bare_INV bi INNER JOIN Bare_Main bm ON bi.Bare_ID = bm.Bare_ID " + sbWhere.ToString();
            int totalCount = Convert.ToInt32(DbHelper.ExecuteScalar(countSql, pList.ToArray()));

            // 分頁計算
            int pageIndex = filter.PageIndex < 1 ? 1 : filter.PageIndex;
            int pageSize = filter.PageSize < 1 ? 15 : filter.PageSize;
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            int startRow = (pageIndex - 1) * pageSize + 1;
            int endRow = pageIndex * pageSize;

            // 查詢分頁資料 (使用 ROW_NUMBER() 符合 SQL Server 與 C# 5.0 最佳相容性)
            string dataSql = string.Format(@"
                WITH PagedData AS (
                    SELECT 
                        bi.INV_NO,
                        bi.Bare_ID,
                        ISNULL(bm.BareGroundNo, '--') AS BareGroundNo,
                        ISNULL(bm.ADDR, '--') AS ADDR,
                        ISNULL(bm.LAND_USE, '--') AS LAND_USE,
                        bm.latitude,
                        bm.longtitude,
                        bi.Check_DATE,
                        ISNULL(bi.Around_Memo, '') AS Around_Memo,
                        ISNULL(bi.Waste_Type, '') AS Waste_Type,
                        bi.pLength,
                        bi.pWidth,
                        bi.pHeight,
                        bi.pVolume,
                        bi.pArea,
                        ISNULL(bi.surroundings, '') AS surroundings,
                        bi.INV_State,
                        ISNULL(bs.State_Name, bi.INV_State) AS State_Name,
                        (SELECT COUNT(*) FROM Bare_INV bi2 WHERE bi2.Bare_ID = bi.Bare_ID AND bi2.INV_State != 'Z00') AS InvCount,
                        ROW_NUMBER() OVER (ORDER BY bi.Check_DATE DESC, bi.INV_NO DESC) AS RowNum
                    FROM Bare_INV bi
                    INNER JOIN Bare_Main bm ON bi.Bare_ID = bm.Bare_ID
                    LEFT JOIN Bare_State_List bs ON bs.State_ID = bi.INV_State
                    {0}
                )
                SELECT * FROM PagedData WHERE RowNum BETWEEN {1} AND {2} ORDER BY RowNum ASC",
                sbWhere.ToString(), startRow, endRow);

            DataTable dtData = DbHelper.ExecuteDataTable(dataSql, pList.ToArray());
            List<object> items = new List<object>();

            foreach (DataRow r in dtData.Rows)
            {
                string bareId = r["Bare_ID"].ToString();
                int invNo = Convert.ToInt32(r["INV_NO"]);
                string token = GenerateToken(bareId);
                string state = r["INV_State"] != DBNull.Value ? r["INV_State"].ToString() : "";
                string stateName = r["State_Name"] != DBNull.Value ? r["State_Name"].ToString() : "";
                if (string.IsNullOrEmpty(stateName) && !string.IsNullOrEmpty(state))
                {
                    stateName = GetDefaultStateName(state);
                }

                // 經緯度座標規範化
                double lat = 0;
                double lng = 0;
                if (r["latitude"] != DBNull.Value) double.TryParse(r["latitude"].ToString(), out lat);
                if (r["longtitude"] != DBNull.Value) double.TryParse(r["longtitude"].ToString(), out lng);

                if (lat > 1000 && lng > 1000)
                {
                    double wLat, wLon;
                    Twd97ToWgs84(lat, lng, out wLat, out wLon);
                    lat = wLat;
                    lng = wLon;
                }

                string checkDateStr = "";
                if (r["Check_DATE"] != DBNull.Value)
                {
                    DateTime cdt = Convert.ToDateTime(r["Check_DATE"]);
                    checkDateStr = cdt.ToString("yyyy/MM/dd HH:mm");
                }

                // 堆置面積與體積說明
                string pLen = r["pLength"] != DBNull.Value ? r["pLength"].ToString() : "-";
                string pWid = r["pWidth"] != DBNull.Value ? r["pWidth"].ToString() : "-";
                string pHei = r["pHeight"] != DBNull.Value ? r["pHeight"].ToString() : "-";
                string pVol = r["pVolume"] != DBNull.Value ? r["pVolume"].ToString() : "-";
                string pAr = r["pArea"] != DBNull.Value ? r["pArea"].ToString() : "-";
                string areaDetail = string.Format("長:{0}m / 寬:{1}m / 高:{2}m (體積約 {3}m³，場址面積約 {4}m²)", pLen, pWid, pHei, pVol, pAr);

                bool canEdit = (state == "A00a" || state == "A00b");
                bool canUpload = (state == "A00a" || state == "A00b");
                bool canDelete = (state == "A00a" || state == "A00b");
                bool canExamine = (state == "A00" || state == "A01" || state == "A02");

                items.Add(new
                {
                    INV_NO = invNo,
                    Bare_ID = bareId,
                    BareGroundNo = r["BareGroundNo"].ToString(),
                    ADDR = r["ADDR"].ToString(),
                    LAND_USE = r["LAND_USE"].ToString(),
                    Lat = lat,
                    Lng = lng,
                    CoodText = (lat > 0 && lng > 0) ? string.Format("{0:F5}, {1:F5}", lat, lng) : "--",
                    InvCount = Convert.ToInt32(r["InvCount"]),
                    Last_INV_NO = invNo,
                    Last_Check_Date = checkDateStr,
                    Last_INV_State = state,
                    Last_State_Name = stateName,
                    Check_DATE = checkDateStr,
                    Around_Memo = r["Around_Memo"].ToString(),
                    Waste_Type = r["Waste_Type"].ToString(),
                    AreaDetail = areaDetail,
                    surroundings = r["surroundings"].ToString(),
                    INV_State = state,
                    State_Name = stateName,
                    Token = token,
                    CanEdit = canEdit,
                    CanUpload = canUpload,
                    CanDelete = canDelete,
                    CanExamine = canExamine,
                    Selected = false
                });
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Data = items,
                Pagination = new
                {
                    TotalCount = totalCount,
                    TotalPages = totalPages,
                    PageIndex = pageIndex,
                    PageSize = pageSize
                }
            }));
        }
        #endregion

        #region 3. 取得指定裸露地場址的歷次查核紀錄 (Inspection History)
        private void GetInvList()
        {
            string bareId = Request["bareId"];
            if (string.IsNullOrEmpty(bareId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "遺失裸露地場址代碼 Bare_ID" }));
                return;
            }

            string sql = @"
                SELECT 
                    bi.INV_NO,
                    bi.Bare_ID,
                    bi.Check_DATE,
                    ISNULL(bi.Around_Memo, '') AS Around_Memo,
                    ISNULL(bi.Waste_Type, '') AS Waste_Type,
                    bi.pLength,
                    bi.pWidth,
                    bi.pHeight,
                    bi.pVolume,
                    bi.pArea,
                    ISNULL(bi.surroundings, '') AS surroundings,
                    bi.INV_State,
                    ISNULL(bs.State_Name, bi.INV_State) AS State_Name,
                    ISNULL(bi.InputUser, '') AS InputUser, ISNULL(bi.InputUser, '') AS User_ID
                FROM Bare_INV bi
                LEFT JOIN Bare_State_List bs ON bs.State_ID = bi.INV_State
                WHERE bi.Bare_ID = @Bare_ID AND bi.INV_State != 'Z00'
                ORDER BY bi.Check_DATE DESC, bi.INV_NO DESC";

            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@Bare_ID", bareId));
            List<object> invList = new List<object>();
            string token = GenerateToken(bareId);

            foreach (DataRow r in dt.Rows)
            {
                int invNo = Convert.ToInt32(r["INV_NO"]);
                string state = r["INV_State"] != DBNull.Value ? r["INV_State"].ToString() : "";
                string stateName = r["State_Name"] != DBNull.Value ? r["State_Name"].ToString() : "";
                if (string.IsNullOrEmpty(stateName))
                {
                    stateName = GetDefaultStateName(state);
                }

                string checkDateStr = "";
                if (r["Check_DATE"] != DBNull.Value)
                {
                    checkDateStr = Convert.ToDateTime(r["Check_DATE"]).ToString("yyyy/MM/dd HH:mm");
                }

                // 組合堆置體積與面積說明字串
                string pLen = r["pLength"] != DBNull.Value ? r["pLength"].ToString() : "-";
                string pWid = r["pWidth"] != DBNull.Value ? r["pWidth"].ToString() : "-";
                string pHei = r["pHeight"] != DBNull.Value ? r["pHeight"].ToString() : "-";
                string pVol = r["pVolume"] != DBNull.Value ? r["pVolume"].ToString() : "-";
                string pAr = r["pArea"] != DBNull.Value ? r["pArea"].ToString() : "-";
                string areaDetail = string.Format("長:{0}m / 寬:{1}m / 高:{2}m (體積約 {3}m³，場址面積約 {4}m²)", pLen, pWid, pHei, pVol, pAr);

                bool canEdit = (state == "A00a" || state == "A00b");
                bool canUpload = (state == "A00a" || state == "A00b");
                bool canDelete = (state == "A00a" || state == "A00b");

                invList.Add(new
                {
                    INV_NO = invNo,
                    Bare_ID = bareId,
                    Check_DATE = checkDateStr,
                    Around_Memo = r["Around_Memo"].ToString(),
                    Waste_Type = r["Waste_Type"].ToString(),
                    pLength = pLen,
                    pWidth = pWid,
                    pHeight = pHei,
                    pVolume = pVol,
                    pArea = pAr,
                    AreaDetail = areaDetail,
                    surroundings = r["surroundings"].ToString(),
                    INV_State = state,
                    State_Name = stateName,
                    User_ID = r["User_ID"].ToString(),
                    InputUser = r["InputUser"].ToString(),
                    Token = token,
                    CanEdit = canEdit,
                    CanUpload = canUpload,
                    CanDelete = canDelete
                });
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Bare_ID = bareId,
                Data = invList
            }));
        }
        #endregion

        #region 4. 單筆查核案件送審 (A00a/A00b -> A00)
        private void UploadCheck()
        {
            string bareId = Request["bareId"];
            string invNoStr = Request["invNo"];
            int invNo;

            if (string.IsNullOrEmpty(bareId) || !int.TryParse(invNoStr, out invNo))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "參數不完整" }));
                return;
            }

            string sql = "UPDATE Bare_INV SET INV_State = 'A00' WHERE Bare_ID = @Bare_ID AND INV_NO = @INV_NO AND INV_State IN ('A00a', 'A00b')";
            int rows = DbHelper.ExecuteNonQuery(sql,
                new SqlParameter("@Bare_ID", bareId),
                new SqlParameter("@INV_NO", invNo));

            if (rows > 0)
            {
                Response.Write(json.Serialize(new { Success = true, Message = "案件已成功送出審核！" }));
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "案件狀態已變更或無法送審" }));
            }
        }
        #endregion

        #region 5. 批次送出審查 (Batch Upload Check)
        private void BatchUploadCheck()
        {
            string postData = GetPostRawData();
            BatchUploadModel model = null;
            if (!string.IsNullOrEmpty(postData))
            {
                try
                {
                    model = json.Deserialize<BatchUploadModel>(postData);
                }
                catch
                {
                }
            }

            if (model == null || model.InvNos == null || model.InvNos.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未選取任何待送審案件" }));
                return;
            }

            StringBuilder sbSql = new StringBuilder();
            List<SqlParameter> pList = new List<SqlParameter>();
            for (int i = 0; i < model.InvNos.Count; i++)
            {
                string pName = "@InvNo" + i;
                if (i > 0) sbSql.Append(",");
                sbSql.Append(pName);
                pList.Add(new SqlParameter(pName, model.InvNos[i]));
            }

            string sql = string.Format("UPDATE Bare_INV SET INV_State = 'A00' WHERE INV_NO IN ({0}) AND INV_State IN ('A00a', 'A00b')", sbSql.ToString());
            int affected = DbHelper.ExecuteNonQuery(sql, pList.ToArray());

            Response.Write(json.Serialize(new
            {
                Success = true,
                Message = string.Format("批次送審完成，共更新 {0} 筆案件！", affected),
                AffectedCount = affected
            }));
        }
        #endregion

        #region 6. 刪除查核紀錄 (軟刪除，狀態變更為 Z00)
        private void DeleteInv()
        {
            string bareId = Request["bareId"];
            string invNoStr = Request["invNo"];
            int invNo;

            if (string.IsNullOrEmpty(bareId) || !int.TryParse(invNoStr, out invNo))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "參數不完整" }));
                return;
            }

            string sql = "UPDATE Bare_INV SET INV_State = 'Z00' WHERE Bare_ID = @Bare_ID AND INV_NO = @INV_NO";
            int rows = DbHelper.ExecuteNonQuery(sql,
                new SqlParameter("@Bare_ID", bareId),
                new SqlParameter("@INV_NO", invNo));

            if (rows > 0)
            {
                Response.Write(json.Serialize(new { Success = true, Message = "該筆查核資料已成功刪除！" }));
            }
            else
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無該筆資料或已被刪除" }));
            }
        }
        #endregion

        #region 7. 取得智慧地圖點位坐標資料 (Leaflet Map Data)
        private void GetMapData()
        {
            string sql = @"
                SELECT TOP 500
                    bm.Bare_ID,
                    ISNULL(bm.BareGroundNo, '--') AS BareGroundNo,
                    ISNULL(bm.ADDR, '--') AS ADDR,
                    ISNULL(bm.LAND_USE, '--') AS LAND_USE,
                    bm.latitude,
                    bm.longtitude,
                    (SELECT TOP 1 bi.Check_DATE FROM Bare_INV bi WHERE bi.Bare_ID = bm.Bare_ID AND bi.INV_State != 'Z00' ORDER BY bi.Check_DATE DESC, bi.INV_NO DESC) AS Last_Check_Date,
                    (SELECT TOP 1 bi.INV_State FROM Bare_INV bi WHERE bi.Bare_ID = bm.Bare_ID AND bi.INV_State != 'Z00' ORDER BY bi.Check_DATE DESC, bi.INV_NO DESC) AS Last_INV_State
                FROM Bare_Main bm
                WHERE bm.latitude IS NOT NULL AND bm.longtitude IS NOT NULL";

            DataTable dt = DbHelper.ExecuteDataTable(sql);
            List<object> markers = new List<object>();

            foreach (DataRow r in dt.Rows)
            {
                double lat = 0;
                double lng = 0;
                if (r["latitude"] != DBNull.Value) double.TryParse(r["latitude"].ToString(), out lat);
                if (r["longtitude"] != DBNull.Value) double.TryParse(r["longtitude"].ToString(), out lng);

                if (lat <= 0 || lng <= 0) continue;

                if (lat > 1000 && lng > 1000)
                {
                    double wLat, wLon;
                    Twd97ToWgs84(lat, lng, out wLat, out wLon);
                    lat = wLat;
                    lng = wLon;
                }

                if (lat < 21.0 || lat > 26.0 || lng < 119.0 || lng > 123.0) continue;

                string bareId = r["Bare_ID"].ToString();
                string state = r["Last_INV_State"] != DBNull.Value ? r["Last_INV_State"].ToString() : "";
                string cdate = r["Last_Check_Date"] != DBNull.Value ? Convert.ToDateTime(r["Last_Check_Date"]).ToString("yyyy/MM/dd HH:mm") : "--";

                markers.Add(new
                {
                    Bare_ID = bareId,
                    BareGroundNo = r["BareGroundNo"].ToString(),
                    ADDR = r["ADDR"].ToString(),
                    LAND_USE = r["LAND_USE"].ToString(),
                    Lat = lat,
                    Lng = lng,
                    LastDate = cdate,
                    State = state,
                    StateName = GetDefaultStateName(state)
                });
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Markers = markers
            }));
        }
        #endregion

        #region 通用輔助函式 (MD5 Token, TWD97 轉換, Post Stream 讀取)
        private string GenerateToken(string bareId)
        {
            string raw = "MD5:" + bareId + DateTime.Now.ToString("yyyyMMddHH");
            using (MD5 md5 = MD5.Create())
            {
                byte[] bytes = md5.ComputeHash(Encoding.UTF8.GetBytes(raw));
                StringBuilder sb = new StringBuilder();
                for (int i = 0; i < bytes.Length; i++)
                {
                    sb.Append(bytes[i].ToString("X2"));
                }
                return sb.ToString();
            }
        }

        private string GetDefaultStateName(string stateId)
        {
            if (string.IsNullOrEmpty(stateId)) return "未查核";
            switch (stateId)
            {
                case "A00a":
                    return "暫存草稿 / 待修正";
                case "A00b":
                    return "退件待重辦";
                case "A00":
                    return "案件待初審";
                case "A01":
                    return "案件待複審";
                case "A02":
                    return "案件待三審";
                case "A03":
                    return "調查成果已核定";
                case "Z00":
                    return "已刪除作廢";
                default:
                    return stateId;
            }
        }

        private string GetPostRawData()
        {
            try
            {
                if (Request.InputStream != null && Request.InputStream.Length > 0)
                {
                    Request.InputStream.Position = 0;
                    using (StreamReader reader = new StreamReader(Request.InputStream, Encoding.UTF8))
                    {
                        return reader.ReadToEnd();
                    }
                }
            }
            catch
            {
            }
            return "";
        }

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
    
        #region 匯出 Excel 報表
        private void HandleExportExcel()
        {
            try
            {
                string mode = Request["mode"] != null ? Request["mode"].Trim().ToLower() : "all";
                string bareNo = Request["bareGroundNo"] != null ? Request["bareGroundNo"].Trim() : "";
                string addr = Request["addr"] != null ? Request["addr"].Trim() : "";
                string landUse = Request["landUse"] != null ? Request["landUse"].Trim() : "";
                string dateS = Request["dateS"] != null ? Request["dateS"].Trim() : "";
                string dateE = Request["dateE"] != null ? Request["dateE"].Trim() : "";
                string stateFilter = Request["stateFilter"] != null ? Request["stateFilter"].Trim() : "";

                List<SqlParameter> pList = new List<SqlParameter>();
                StringBuilder sbWhere = new StringBuilder(" WHERE bi.INV_State != 'Z00' ");

                if (mode == "reject")
                {
                    sbWhere.Append(" AND bi.INV_State = 'A00a' ");
                }
                else if (mode == "back")
                {
                    sbWhere.Append(" AND bi.INV_State = 'A00b' ");
                }
                else if (mode == "examine")
                {
                    sbWhere.Append(" AND bi.INV_State IN ('A00', 'A01', 'A02') ");
                }
                else if (mode == "identify" || mode == "search")
                {
                    sbWhere.Append(" AND bi.INV_State NOT IN ('A00a', 'A00b', 'Z00', 'A00', 'A01', 'A02') ");
                }

                if (!string.IsNullOrEmpty(bareNo))
                {
                    sbWhere.Append(" AND bm.BareGroundNo LIKE '%' + @BareNo + '%' ");
                    pList.Add(new SqlParameter("@BareNo", bareNo));
                }
                if (!string.IsNullOrEmpty(addr))
                {
                    sbWhere.Append(" AND bm.ADDR LIKE '%' + @Addr + '%' ");
                    pList.Add(new SqlParameter("@Addr", addr));
                }
                if (!string.IsNullOrEmpty(landUse))
                {
                    sbWhere.Append(" AND bm.LAND_USE LIKE '%' + @LandUse + '%' ");
                    pList.Add(new SqlParameter("@LandUse", landUse));
                }
                DateTime dtS;
                if (DateTime.TryParse(dateS, out dtS))
                {
                    sbWhere.Append(" AND bi.Check_DATE >= @DateS ");
                    pList.Add(new SqlParameter("@DateS", dtS.Date));
                }
                DateTime dtE;
                if (DateTime.TryParse(dateE, out dtE))
                {
                    sbWhere.Append(" AND bi.Check_DATE <= @DateE ");
                    pList.Add(new SqlParameter("@DateE", dtE.Date.AddDays(1).AddSeconds(-1)));
                }
                if (!string.IsNullOrEmpty(stateFilter))
                {
                    sbWhere.Append(" AND bi.INV_State = @StateFilter ");
                    pList.Add(new SqlParameter("@StateFilter", stateFilter));
                }

                StringBuilder sbSql = new StringBuilder();
                sbSql.Append("SELECT ");
                sbSql.Append("    bi.INV_NO, ");
                sbSql.Append("    ISNULL(bm.BareGroundNo, '--') AS BareGroundNo, ");
                sbSql.Append("    ISNULL(bs.State_Name, bi.INV_State) AS State_Name, ");
                sbSql.Append("    bi.INV_State, ");
                sbSql.Append("    bi.Check_DATE, ");
                sbSql.Append("    ISNULL(bm.ADDR, '--') AS ADDR, ");
                sbSql.Append("    ISNULL(bm.LAND_USE, '--') AS LAND_USE, ");
                sbSql.Append("    bi.pArea, ");
                sbSql.Append("    bi.pLength, ");
                sbSql.Append("    bi.pWidth, ");
                sbSql.Append("    bi.pHeight, ");
                sbSql.Append("    bi.pVolume, ");
                sbSql.Append("    ISNULL(bi.Waste_Type, '') AS Waste_Type, ");
                sbSql.Append("    ISNULL(bi.surroundings, '') AS surroundings, ");
                sbSql.Append("    ISNULL(bi.Around_Memo, '') AS Around_Memo, ");
                sbSql.Append("    ISNULL(bi.InputUser, '') AS InputUser, ISNULL(bi.InputUser, '') AS User_ID, ");
                sbSql.Append("    bm.latitude, ");
                sbSql.Append("    bm.longtitude ");
                sbSql.Append("FROM Bare_INV bi ");
                sbSql.Append("INNER JOIN Bare_Main bm ON bi.Bare_ID = bm.Bare_ID ");
                sbSql.Append("LEFT JOIN Bare_State_List bs ON bs.State_ID = bi.INV_State ");
                sbSql.Append(sbWhere.ToString());
                sbSql.Append(" ORDER BY bi.Check_DATE DESC, bi.INV_NO DESC");

                DataTable dt = DbHelper.ExecuteDataTable(sbSql.ToString(), pList.ToArray());

                HSSFWorkbook workbook = new HSSFWorkbook();
                ISheet sheet = workbook.CreateSheet("裸露地查核清單");

                // 標題樣式
                ICellStyle headerStyle = workbook.CreateCellStyle();
                IFont headerFont = workbook.CreateFont();
                headerFont.FontName = "微軟正黑體";
                headerFont.FontHeightInPoints = 11.0;
                headerFont.IsBold = true;
                headerStyle.SetFont(headerFont);
                headerStyle.Alignment = HorizontalAlignment.Center;
                headerStyle.VerticalAlignment = VerticalAlignment.Center;
                headerStyle.FillForegroundColor = NPOI.HSSF.Util.HSSFColor.Grey25Percent.Index;
                headerStyle.FillPattern = FillPattern.SolidForeground;
                headerStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
                headerStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

                // 內容樣式
                ICellStyle dataStyle = workbook.CreateCellStyle();
                IFont dataFont = workbook.CreateFont();
                dataFont.FontName = "微軟正黑體";
                dataFont.FontHeightInPoints = 10.0;
                dataStyle.SetFont(dataFont);
                dataStyle.VerticalAlignment = VerticalAlignment.Center;
                dataStyle.BorderBottom = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderTop = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderLeft = NPOI.SS.UserModel.BorderStyle.Thin;
                dataStyle.BorderRight = NPOI.SS.UserModel.BorderStyle.Thin;

                // 置中樣式
                ICellStyle centerStyle = workbook.CreateCellStyle();
                centerStyle.CloneStyleFrom(dataStyle);
                centerStyle.Alignment = HorizontalAlignment.Center;

                string[] headers = new string[]
                {
                    "序號", "查核案號", "裸露地編號", "案件狀態", "查核日期",
                    "場址地址", "地目", "場址面積 (m²)", "堆置長 (m)", "寬 (m)", "高 (m)", "體積 (m³)",
                    "堆置廢棄物類型", "周邊環境說明", "現況備註", "查核人員", "緯度 (Lat)", "經度 (Lng)"
                };

                IRow rowHeader = sheet.CreateRow(0);
                rowHeader.HeightInPoints = 26;
                for (int h = 0; h < headers.Length; h++)
                {
                    ICell c = rowHeader.CreateCell(h);
                    c.SetCellValue(headers[h]);
                    c.CellStyle = headerStyle;
                }

                if (dt != null && dt.Rows.Count > 0)
                {
                    for (int r = 0; r < dt.Rows.Count; r++)
                    {
                        DataRow dr = dt.Rows[r];
                        IRow row = sheet.CreateRow(r + 1);
                        row.HeightInPoints = 20;

                        string seq = (r + 1).ToString();
                        string invNo = dr["INV_NO"] != DBNull.Value ? dr["INV_NO"].ToString().Trim() : "";
                        string bareNoVal = dr["BareGroundNo"] != DBNull.Value ? dr["BareGroundNo"].ToString().Trim() : "";
                        
                        string stateVal = dr["INV_State"] != DBNull.Value ? dr["INV_State"].ToString().Trim() : "";
                        string stateName = dr["State_Name"] != DBNull.Value ? dr["State_Name"].ToString().Trim() : "";
                        if (string.IsNullOrEmpty(stateName))
                        {
                            stateName = GetDefaultStateName(stateVal);
                        }

                        string dateVal = dr["Check_DATE"] != DBNull.Value ? string.Format("{0:yyyy/MM/dd HH:mm}", dr["Check_DATE"]) : "";
                        string addrVal = dr["ADDR"] != DBNull.Value ? dr["ADDR"].ToString().Trim() : "";
                        string landVal = dr["LAND_USE"] != DBNull.Value ? dr["LAND_USE"].ToString().Trim() : "";
                        string areaVal = dr["pArea"] != DBNull.Value ? dr["pArea"].ToString().Trim() : "";
                        string pLen = dr["pLength"] != DBNull.Value ? dr["pLength"].ToString().Trim() : "";
                        string pWid = dr["pWidth"] != DBNull.Value ? dr["pWidth"].ToString().Trim() : "";
                        string pHei = dr["pHeight"] != DBNull.Value ? dr["pHeight"].ToString().Trim() : "";
                        string pVol = dr["pVolume"] != DBNull.Value ? dr["pVolume"].ToString().Trim() : "";
                        string wasteVal = dr["Waste_Type"] != DBNull.Value ? dr["Waste_Type"].ToString().Trim() : "";
                        string surrVal = dr["surroundings"] != DBNull.Value ? dr["surroundings"].ToString().Trim() : "";
                        string memoVal = dr["Around_Memo"] != DBNull.Value ? dr["Around_Memo"].ToString().Trim() : "";
                        string userVal = dr["InputUser"] != DBNull.Value ? dr["InputUser"].ToString().Trim() : "";

                        string latVal = "";
                        string lngVal = "";
                        if (dr["latitude"] != DBNull.Value && dr["longtitude"] != DBNull.Value)
                        {
                            double lat = 0, lng = 0;
                            double.TryParse(dr["latitude"].ToString(), out lat);
                            double.TryParse(dr["longtitude"].ToString(), out lng);
                            if (lat > 1000 && lng > 1000)
                            {
                                double wLat, wLon;
                                Twd97ToWgs84(lat, lng, out wLat, out wLon);
                                lat = wLat;
                                lng = wLon;
                            }
                            if (lat > 0 && lng > 0)
                            {
                                latVal = lat.ToString("F6");
                                lngVal = lng.ToString("F6");
                            }
                        }

                        string[] vals = new string[]
                        {
                            seq, invNo, bareNoVal, stateName, dateVal,
                            addrVal, landVal, areaVal, pLen, pWid, pHei, pVol,
                            wasteVal, surrVal, memoVal, userVal, latVal, lngVal
                        };

                        for (int cIdx = 0; cIdx < vals.Length; cIdx++)
                        {
                            ICell cell = row.CreateCell(cIdx);
                            cell.SetCellValue(vals[cIdx]);
                            if (cIdx == 0 || cIdx == 1 || cIdx == 2 || cIdx == 3 || cIdx == 4 || cIdx == 6 || cIdx == 15)
                            {
                                cell.CellStyle = centerStyle;
                            }
                            else
                            {
                                cell.CellStyle = dataStyle;
                            }
                        }
                    }
                }

                for (int i = 0; i < headers.Length; i++)
                {
                    sheet.SetColumnWidth(i, 16 * 256);
                }
                sheet.SetColumnWidth(0, 8 * 256);   // 序號
                sheet.SetColumnWidth(1, 12 * 256);  // 查核案號
                sheet.SetColumnWidth(2, 16 * 256);  // 裸露地編號
                sheet.SetColumnWidth(3, 16 * 256);  // 案件狀態
                sheet.SetColumnWidth(4, 18 * 256);  // 查核日期
                sheet.SetColumnWidth(5, 34 * 256);  // 場址地址
                sheet.SetColumnWidth(14, 30 * 256); // 現況備註

                Response.Clear();
                Response.ContentType = "application/vnd.ms-excel";
                string filename = "裸露地查核清單_" + DateTime.Now.ToString("yyyyMMddHHmmss") + ".xls";
                Response.AddHeader("Content-Disposition", "attachment;filename=" + HttpUtility.UrlEncode(filename, Encoding.UTF8));

                using (MemoryStream ms = new MemoryStream())
                {
                    workbook.Write(ms);
                    Response.BinaryWrite(ms.ToArray());
                }

                try
                {
                    Response.End();
                }
                catch (System.Threading.ThreadAbortException)
                {
                }
            }
            catch (Exception ex)
            {
                Response.Clear();
                Response.ContentType = "text/plain; charset=utf-8";
                Response.Write("匯出 Excel 失敗：" + ex.Message);
            }
        }
        #endregion


}
}
