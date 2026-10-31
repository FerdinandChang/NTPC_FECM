using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;

namespace NTPC_FEC.MoenvEquip
{
    public partial class MoenvEquipment_Upload : Page
    {
        private JavaScriptSerializer json;

        public MoenvEquipment_Upload()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!string.IsNullOrEmpty(Request["action"]))
            {
                return;
            }
            base.Render(writer);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["LoginUser"] == null && Session["User"] == null)
            {
                string action0 = Request["action"];
                if (!string.IsNullOrEmpty(action0))
                {
                    Dictionary<string, object> err = new Dictionary<string, object>();
                    err["success"] = false;
                    err["message"] = "登入已逾時，請重新登入！";
                    SendJsonResponse(err);
                    return;
                }
                Response.Redirect("~/Default.aspx", true);
                return;
            }

            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                if (action.Equals("upload", StringComparison.OrdinalIgnoreCase))
                {
                    ProcessUpload();
                }
                return;
            }
        }

        private void ProcessUpload()
        {
            Dictionary<string, object> responseData = new Dictionary<string, object>();
            responseData["success"] = false;
            responseData["message"] = "";

            try
            {
                if (Request.Files == null || Request.Files.Count == 0)
                {
                    responseData["message"] = "未偵測到上傳檔案，請重新選擇 (.xlsx) 檔案。";
                    SendJsonResponse(responseData);
                    return;
                }

                HttpPostedFile file = Request.Files[0];
                if (file == null || file.ContentLength <= 0)
                {
                    responseData["message"] = "上傳的檔案內容為空，請確認檔案是否有效。";
                    SendJsonResponse(responseData);
                    return;
                }

                string fileName = file.FileName != null ? file.FileName.ToLower() : "";
                if (!fileName.EndsWith(".xlsx"))
                {
                    responseData["message"] = "格式不符！僅支援環境部下載之 .xlsx 格式 Excel 檔案。";
                    SendJsonResponse(responseData);
                    return;
                }

                string defaultPlanType = Request.Form["defaultPlanType"];
                if (string.IsNullOrEmpty(defaultPlanType))
                {
                    defaultPlanType = "營建";
                }

                Dictionary<string, object> importResult = MoenvEquipment_Helper.ImportExcel(file.InputStream, defaultPlanType);
                SendJsonResponse(importResult);
            }
            catch (System.Threading.ThreadAbortException)
            {
                return;
            }
            catch (Exception ex)
            {
                responseData["message"] = "系統處理錯誤：" + ex.Message;
                SendJsonResponse(responseData);
            }
        }

        private void SendJsonResponse(object data)
        {
            Response.Clear();
            Response.ContentType = "application/json; charset=utf-8";
            Response.ContentEncoding = new UTF8Encoding(true);
            Response.Write(json.Serialize(data));
            AjaxResponseHelper.CompleteRequest(Response, Context);
        }
    }

    /// <summary>
    /// 環境部施工機具匯入與資料庫自動化維護輔助元件 (C# 5.0 規範相容)
    /// </summary>
    public class MoenvEquipment_Helper
    {
        public static string GetConnStr()
        {
            ConnectionStringSettings setting = WebConfigurationManager.ConnectionStrings["EPDConnectionString"];
            if (setting != null && !string.IsNullOrEmpty(setting.ConnectionString))
            {
                return setting.ConnectionString;
            }
            ConnectionStringSettings mainSetting = WebConfigurationManager.ConnectionStrings["MainConnectionString"];
            if (mainSetting != null && !string.IsNullOrEmpty(mainSetting.ConnectionString))
            {
                return mainSetting.ConnectionString;
            }
            return "";
        }

        public static string GetCellValue(ICell cell)
        {
            if (cell == null) return "";
            try
            {
                switch (cell.CellType)
                {
                    case CellType.String:
                        return cell.StringCellValue != null ? cell.StringCellValue.Trim() : "";
                    case CellType.Numeric:
                        if (DateUtil.IsCellDateFormatted(cell))
                        {
                            return cell.DateCellValue.ToString("yyyy/MM/dd");
                        }
                        return cell.NumericCellValue.ToString().Trim();
                    case CellType.Boolean:
                        return cell.BooleanCellValue.ToString();
                    case CellType.Formula:
                        try
                        {
                            return cell.StringCellValue != null ? cell.StringCellValue.Trim() : "";
                        }
                        catch
                        {
                            try
                            {
                                return cell.NumericCellValue.ToString().Trim();
                            }
                            catch
                            {
                                return cell.CellFormula != null ? cell.CellFormula : "";
                            }
                        }
                    case CellType.Blank:
                        return "";
                    default:
                        return cell.ToString().Trim();
                }
            }
            catch
            {
                return "";
            }
        }

        public static object SqlVal(string val)
        {
            if (string.IsNullOrEmpty(val))
            {
                return DBNull.Value;
            }
            string trimmed = val.Trim();
            if (trimmed == "" || trimmed == "無")
            {
                return DBNull.Value;
            }
            return trimmed;
        }

        public static bool IsEmptyVal(string val)
        {
            if (val == null) return true;
            string s = val.Trim();
            return s == "" || s == "無" || s == "無資料";
        }

        public static string NormalizeDateStr(string val)
        {
            if (IsEmptyVal(val)) return "";
            string s = val.Trim().Replace("/", "-");
            if (s.IndexOf(' ') >= 0)
            {
                s = s.Split(' ')[0];
            }
            string[] parts = s.Split('-');
            if (parts.Length == 3)
            {
                string y = parts[0];
                string m = parts[1].PadLeft(2, '0');
                string d = parts[2].PadLeft(2, '0');
                return y + "-" + m + "-" + d;
            }
            return s;
        }

        public static string NormalizeForCompare(string val, string colName)
        {
            if (IsEmptyVal(val)) return "";

            if (colName.Equals("TestDate", StringComparison.OrdinalIgnoreCase) ||
                colName.Equals("IssueDate", StringComparison.OrdinalIgnoreCase))
            {
                return NormalizeDateStr(val);
            }

            if (colName.Equals("Displacement", StringComparison.OrdinalIgnoreCase) ||
                colName.Equals("MaxHorsePower", StringComparison.OrdinalIgnoreCase) ||
                colName.Equals("MaxPowerSpeed", StringComparison.OrdinalIgnoreCase) ||
                colName.Equals("TestValue", StringComparison.OrdinalIgnoreCase) ||
                colName.Equals("RetestValue", StringComparison.OrdinalIgnoreCase))
            {
                double d;
                if (double.TryParse(val.Trim(), out d))
                {
                    return d.ToString("G");
                }
            }

            return val.Trim();
        }

        public static bool IsCheckMark(string val)
        {
            if (string.IsNullOrEmpty(val)) return false;
            string s = val.Trim();
            return s.Equals("V", StringComparison.OrdinalIgnoreCase) ||
                   s.Equals("Y", StringComparison.OrdinalIgnoreCase) ||
                   s == "✓" || s == "✔" || s == "1" || s == "有" || s == "是" ||
                   s == "Ｖ" || s == "ｖ";
        }

        public static bool CalculateIsQualified(Dictionary<string, string> rowVals)
        {
            string[] fields = new string[]
            {
                "Brand", "EquipType", "EquipYear", "Model", "EngineNumber", "MaxHorsePower", "MaxPowerSpeed"
            };

            int nonNullCount = 0;
            for (int i = 0; i < fields.Length; i++)
            {
                string f = fields[i];
                if (rowVals.ContainsKey(f) && !IsEmptyVal(rowVals[f]))
                {
                    nonNullCount++;
                }
            }
            bool cond1 = (nonNullCount >= 5);

            bool cond2 = false;
            string applyType = (rowVals.ContainsKey("ApplyType") && rowVals["ApplyType"] != null) ? rowVals["ApplyType"].Trim() : "";

            if (applyType == "新機具")
            {
                string buyDoc = (rowVals.ContainsKey("BuyDoc") && rowVals["BuyDoc"] != null) ? rowVals["BuyDoc"].Trim() : "";
                string emissionDoc = (rowVals.ContainsKey("EmissionDoc") && rowVals["EmissionDoc"] != null) ? rowVals["EmissionDoc"].Trim() : "";
                cond2 = (IsCheckMark(buyDoc) && IsCheckMark(emissionDoc));
            }
            else if (applyType == "使用中機具")
            {
                string badgePhoto = (rowVals.ContainsKey("BadgePhoto") && rowVals["BadgePhoto"] != null) ? rowVals["BadgePhoto"].Trim() : "";
                string recordDoc = (rowVals.ContainsKey("RecordDoc") && rowVals["RecordDoc"] != null) ? rowVals["RecordDoc"].Trim() : "";
                cond2 = (IsCheckMark(badgePhoto) && IsCheckMark(recordDoc));
            }

            return cond1 && cond2;
        }

        public static void EnsureDatabaseSchema()
        {
            CheckAndCreateMainAndPhotoTables();
            CheckAndCreateProjectTypeColumn();
            CheckAndCreateIsQualifiedColumn();
            CheckAndCreateUnqualifiedTable();
            FixLegacyPhotoPaths();
        }

        public static void FixLegacyPhotoPaths()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();
                    string updateSql = @"
                        UPDATE [dbo].[MoenvEquipment_Photo] 
                        SET [PhotoPath] = '/NTPCEPD_New/MoenvEquip/' + SUBSTRING([PhotoPath], CHARINDEX('Uploads/', [PhotoPath]), LEN([PhotoPath]))
                        WHERE [PhotoPath] LIKE '%Uploads/%' 
                          AND [PhotoPath] NOT LIKE '/NTPCEPD_New/MoenvEquip/Uploads/%';";
                    using (SqlCommand cmd = new SqlCommand(updateSql, conn))
                    {
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch
            {
            }
        }

        public static void CheckAndCreateMainAndPhotoTables()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();

                    string checkMainSql = "SELECT COUNT(*) FROM sys.objects WHERE object_id = OBJECT_ID('[dbo].[MoenvEquipment]') AND type = 'U'";
                    int mainCount = 0;
                    using (SqlCommand cmd = new SqlCommand(checkMainSql, conn))
                    {
                        mainCount = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    if (mainCount == 0)
                    {
                        string createMainSql =
                            "CREATE TABLE [dbo].[MoenvEquipment] (" +
                            "[Id] INT IDENTITY(1,1) NOT NULL," +
                            "[IssuingUnit] NVARCHAR(100) NULL," +
                            "[TestCounty] NVARCHAR(100) NULL," +
                            "[OwnerName] NVARCHAR(200) NULL," +
                            "[ApplyType] NVARCHAR(100) NULL," +
                            "[TaxId] NVARCHAR(50) NULL," +
                            "[Brand] NVARCHAR(150) NULL," +
                            "[EquipType] NVARCHAR(150) NULL," +
                            "[PlateNumber] NVARCHAR(100) NULL," +
                            "[EquipYear] NVARCHAR(100) NULL," +
                            "[Model] NVARCHAR(150) NULL," +
                            "[EngineNumber] NVARCHAR(150) NULL," +
                            "[Displacement] NVARCHAR(100) NULL," +
                            "[MaxHorsePower] NVARCHAR(100) NULL," +
                            "[MaxPowerSpeed] NVARCHAR(100) NULL," +
                            "[TestMethod] NVARCHAR(100) NULL," +
                            "[BadgeNumber] NVARCHAR(150) NULL," +
                            "[TestValue] NVARCHAR(100) NULL," +
                            "[RetestValue] NVARCHAR(100) NULL," +
                            "[TestDate] NVARCHAR(100) NULL," +
                            "[IssueDate] NVARCHAR(100) NULL," +
                            "[BadgeLevel] NVARCHAR(100) NULL," +
                            "[BadgeStatus] NVARCHAR(100) NULL," +
                            "[BuyDoc] NVARCHAR(100) NULL," +
                            "[EmissionDoc] NVARCHAR(100) NULL," +
                            "[BadgePhoto] NVARCHAR(100) NULL," +
                            "[RecordDoc] NVARCHAR(100) NULL," +
                            "[ProjectType] NVARCHAR(50) NULL DEFAULT '營建'," +
                            "[IsQualified] BIT NULL," +
                            "[CreateDate] DATETIME NULL DEFAULT GETDATE()," +
                            "[ModifyDate] DATETIME NULL DEFAULT GETDATE()," +
                            "CONSTRAINT [PK_MoenvEquipment] PRIMARY KEY CLUSTERED ([Id] ASC)" +
                            ");";
                        using (SqlCommand cmd = new SqlCommand(createMainSql, conn))
                        {
                            cmd.ExecuteNonQuery();
                        }
                    }

                    string checkPhotoSql = "SELECT COUNT(*) FROM sys.objects WHERE object_id = OBJECT_ID('[dbo].[MoenvEquipment_Photo]') AND type = 'U'";
                    int photoCount = 0;
                    using (SqlCommand cmd = new SqlCommand(checkPhotoSql, conn))
                    {
                        photoCount = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    if (photoCount == 0)
                    {
                        string createPhotoSql =
                            "CREATE TABLE [dbo].[MoenvEquipment_Photo] (" +
                            "[Id] INT IDENTITY(1,1) NOT NULL," +
                            "[EquipmentId] INT NOT NULL," +
                            "[PhotoPath] NVARCHAR(500) NOT NULL," +
                            "[CreateDate] DATETIME NULL DEFAULT GETDATE()," +
                            "CONSTRAINT [PK_MoenvEquipment_Photo] PRIMARY KEY CLUSTERED ([Id] ASC)" +
                            ");";
                        using (SqlCommand cmd = new SqlCommand(createPhotoSql, conn))
                        {
                            cmd.ExecuteNonQuery();
                        }
                    }
                }
            }
            catch
            {
            }
        }

        public static void CheckAndCreateProjectTypeColumn()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();
                    string checkSql = "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('[dbo].[MoenvEquipment]') AND name = 'ProjectType'";
                    int count = 0;
                    using (SqlCommand cmd = new SqlCommand(checkSql, conn))
                    {
                        count = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    if (count == 0)
                    {
                        string alterSql = "ALTER TABLE [dbo].[MoenvEquipment] ADD [ProjectType] NVARCHAR(50) NULL CONSTRAINT DF_MoenvEquipment_ProjectType DEFAULT '營建';";
                        using (SqlCommand cmd = new SqlCommand(alterSql, conn))
                        {
                            cmd.ExecuteNonQuery();
                        }

                        string updateSql = "UPDATE [dbo].[MoenvEquipment] SET [ProjectType] = '營建' WHERE [ProjectType] IS NULL;";
                        using (SqlCommand cmd = new SqlCommand(updateSql, conn))
                        {
                            cmd.ExecuteNonQuery();
                        }
                    }
                }
            }
            catch
            {
            }
        }

        public static void CheckAndCreateIsQualifiedColumn()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();
                    string checkSql = "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('[dbo].[MoenvEquipment]') AND name = 'IsQualified'";
                    int count = 0;
                    using (SqlCommand cmd = new SqlCommand(checkSql, conn))
                    {
                        count = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    if (count == 0)
                    {
                        string alterSql = "ALTER TABLE [dbo].[MoenvEquipment] ADD [IsQualified] BIT NULL;";
                        using (SqlCommand cmd = new SqlCommand(alterSql, conn))
                        {
                            cmd.ExecuteNonQuery();
                        }
                    }

                    // 全量批次重算 IsQualified（含歷史資料），UPPER() 確保大小寫不敏感
                    string updateSql =
                        "UPDATE [dbo].[MoenvEquipment] SET [IsQualified] = CASE WHEN " +
                        "((CASE WHEN ISNULL([Brand],'') <> '' AND ISNULL([Brand],'') <> '無' AND ISNULL([Brand],'') <> '無資料' THEN 1 ELSE 0 END + " +
                        "CASE WHEN ISNULL([EquipType],'') <> '' AND ISNULL([EquipType],'') <> '無' AND ISNULL([EquipType],'') <> '無資料' THEN 1 ELSE 0 END + " +
                        "CASE WHEN ISNULL([EquipYear],'') <> '' AND ISNULL([EquipYear],'') <> '無' AND ISNULL([EquipYear],'') <> '無資料' THEN 1 ELSE 0 END + " +
                        "CASE WHEN ISNULL([Model],'') <> '' AND ISNULL([Model],'') <> '無' AND ISNULL([Model],'') <> '無資料' THEN 1 ELSE 0 END + " +
                        "CASE WHEN ISNULL([EngineNumber],'') <> '' AND ISNULL([EngineNumber],'') <> '無' AND ISNULL([EngineNumber],'') <> '無資料' THEN 1 ELSE 0 END + " +
                        "CASE WHEN ISNULL([MaxHorsePower],'') <> '' AND ISNULL([MaxHorsePower],'') <> '無' AND ISNULL([MaxHorsePower],'') <> '無資料' THEN 1 ELSE 0 END + " +
                        "CASE WHEN ISNULL([MaxPowerSpeed],'') <> '' AND ISNULL([MaxPowerSpeed],'') <> '無' AND ISNULL([MaxPowerSpeed],'') <> '無資料' THEN 1 ELSE 0 END) >= 5) AND " +
                        "(CASE " +
                        "  WHEN [ApplyType] = '新機具' AND UPPER(LTRIM(RTRIM(ISNULL([BuyDoc],'')))) = 'V' AND UPPER(LTRIM(RTRIM(ISNULL([EmissionDoc],'')))) = 'V' THEN 1 " +
                        "  WHEN [ApplyType] = '使用中機具' AND UPPER(LTRIM(RTRIM(ISNULL([BadgePhoto],'')))) = 'V' AND UPPER(LTRIM(RTRIM(ISNULL([RecordDoc],'')))) = 'V' THEN 1 " +
                        "  ELSE 0 " +
                        "END = 1) " +
                        "THEN 1 ELSE 0 END;";

                    using (SqlCommand cmd = new SqlCommand(updateSql, conn))
                    {
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch
            {
            }
        }

        public static void CheckAndCreateUnqualifiedTable()
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(GetConnStr()))
                {
                    conn.Open();
                    string checkSql = "SELECT COUNT(*) FROM sys.objects WHERE object_id = OBJECT_ID('[dbo].[MoenvEquipment_Unqualified]') AND type = 'U'";
                    int count = 0;
                    using (SqlCommand cmd = new SqlCommand(checkSql, conn))
                    {
                        count = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    if (count == 0)
                    {
                        string createSql =
                            "CREATE TABLE [dbo].[MoenvEquipment_Unqualified] (" +
                            "[Id] INT IDENTITY(1,1) NOT NULL," +
                            "[IssuingUnit] NVARCHAR(100) NULL," +
                            "[TestCounty] NVARCHAR(100) NULL," +
                            "[OwnerName] NVARCHAR(200) NULL," +
                            "[ApplyType] NVARCHAR(100) NULL," +
                            "[TaxId] NVARCHAR(50) NULL," +
                            "[Brand] NVARCHAR(150) NULL," +
                            "[EquipType] NVARCHAR(150) NULL," +
                            "[PlateNumber] NVARCHAR(100) NULL," +
                            "[EquipYear] NVARCHAR(100) NULL," +
                            "[Model] NVARCHAR(150) NULL," +
                            "[EngineNumber] NVARCHAR(150) NULL," +
                            "[Displacement] NVARCHAR(100) NULL," +
                            "[MaxHorsePower] NVARCHAR(100) NULL," +
                            "[MaxPowerSpeed] NVARCHAR(100) NULL," +
                            "[TestMethod] NVARCHAR(100) NULL," +
                            "[BadgeNumber] NVARCHAR(150) NULL," +
                            "[TestValue] NVARCHAR(100) NULL," +
                            "[RetestValue] NVARCHAR(100) NULL," +
                            "[TestDate] NVARCHAR(100) NULL," +
                            "[IssueDate] NVARCHAR(100) NULL," +
                            "[BadgeLevel] NVARCHAR(100) NULL," +
                            "[BadgeStatus] NVARCHAR(100) NULL," +
                            "[BuyDoc] NVARCHAR(100) NULL," +
                            "[EmissionDoc] NVARCHAR(100) NULL," +
                            "[BadgePhoto] NVARCHAR(100) NULL," +
                            "[RecordDoc] NVARCHAR(100) NULL," +
                            "[ProjectType] NVARCHAR(50) NULL DEFAULT '營建'," +
                            "[IsQualified] BIT NULL," +
                            "[CreateDate] DATETIME NULL DEFAULT GETDATE()," +
                            "[ModifyDate] DATETIME NULL DEFAULT GETDATE()," +
                            "CONSTRAINT [PK_MoenvEquipment_Unqualified] PRIMARY KEY CLUSTERED ([Id] ASC)" +
                            ");";
                        using (SqlCommand cmd = new SqlCommand(createSql, conn))
                        {
                            cmd.ExecuteNonQuery();
                        }

                        string idxSql =
                            "CREATE NONCLUSTERED INDEX [IX_MoenvEquipment_Unqualified_Filters] ON [dbo].[MoenvEquipment_Unqualified] ([TestDate], [EquipType], [Brand], [BadgeLevel], [ProjectType]);" +
                            "CREATE NONCLUSTERED INDEX [IX_MoenvEquipment_Unqualified_Keys] ON [dbo].[MoenvEquipment_Unqualified] ([TaxId], [Brand], [Model], [EngineNumber], [PlateNumber]);";
                        using (SqlCommand cmd = new SqlCommand(idxSql, conn))
                        {
                            cmd.ExecuteNonQuery();
                        }
                    }
                }
            }
            catch
            {
            }
        }

        public static Dictionary<string, object> ImportExcel(Stream stream, string defaultPlanType)
        {
            if (string.IsNullOrEmpty(defaultPlanType))
            {
                defaultPlanType = "營建";
            }

            Dictionary<string, object> result = new Dictionary<string, object>();
            result["success"] = false;
            result["message"] = "";

            try
            {
                EnsureDatabaseSchema();

                XSSFWorkbook workbook = new XSSFWorkbook(stream);
                ISheet sheet = workbook.GetSheetAt(0);
                if (sheet == null || sheet.LastRowNum < 1)
                {
                    result["message"] = "Excel 檔案無有效資料列";
                    return result;
                }

                IRow headerRow = sheet.GetRow(0);
                if (headerRow == null)
                {
                    result["message"] = "Excel 標題列無資料";
                    return result;
                }

                Dictionary<string, int> headerMap = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                for (int col = 0; col < headerRow.LastCellNum; col++)
                {
                    ICell cell = headerRow.GetCell(col);
                    if (cell != null)
                    {
                        string hName = cell.ToString().Trim();
                        if (!string.IsNullOrEmpty(hName))
                        {
                            headerMap[hName] = col;
                        }
                    }
                }

                Dictionary<string, string> colMappings = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                colMappings["核發單位"] = "IssuingUnit";
                colMappings["檢測縣市"] = "TestCounty";
                colMappings["機具所有者或公私場所名稱"] = "OwnerName";
                colMappings["所有者名稱"] = "OwnerName";
                colMappings["機具所有者"] = "OwnerName";
                colMappings["申請類型"] = "ApplyType";
                colMappings["統一編號"] = "TaxId";
                colMappings["機具廠牌"] = "Brand";
                colMappings["機具種類"] = "EquipType";
                colMappings["機械牌號碼"] = "PlateNumber";
                colMappings["機械牌照號碼"] = "PlateNumber";
                colMappings["牌照號碼"] = "PlateNumber";
                colMappings["機具年份"] = "EquipYear";
                colMappings["機具型式"] = "Model";
                colMappings["機具型號"] = "Model";
                colMappings["機具引擎編號"] = "EngineNumber";
                colMappings["引擎編號"] = "EngineNumber";
                colMappings["排氣量(c.c)"] = "Displacement";
                colMappings["排氣量"] = "Displacement";
                colMappings["最大額定馬力(hp)"] = "MaxHorsePower";
                colMappings["最大額定馬力"] = "MaxHorsePower";
                colMappings["最大馬力"] = "MaxHorsePower";
                colMappings["最大額定功率轉速"] = "MaxPowerSpeed";
                colMappings["最大功率轉速"] = "MaxPowerSpeed";
                colMappings["檢測方式"] = "TestMethod";
                colMappings["標章編號"] = "BadgeNumber";
                colMappings["檢測值(m-1)"] = "TestValue";
                colMappings["檢測值"] = "TestValue";
                colMappings["複測值(m-1)"] = "RetestValue";
                colMappings["複測值"] = "RetestValue";
                colMappings["檢測日期"] = "TestDate";
                colMappings["核發日期"] = "IssueDate";
                colMappings["標章等級"] = "BadgeLevel";
                colMappings["標章狀態"] = "BadgeStatus";

                // 證明文件欄位對照（相容環境部原始匯出名稱與各類變體）
                colMappings["買受證明文件"] = "BuyDoc";
                colMappings["買受證明"] = "BuyDoc";
                colMappings["購買證明文件"] = "BuyDoc";
                colMappings["購買證明"] = "BuyDoc";

                colMappings["符合排放標準證明"] = "EmissionDoc";
                colMappings["出廠排放標準證明"] = "EmissionDoc";
                colMappings["排放標準證明"] = "EmissionDoc";

                colMappings["機具張貼標章照片"] = "BadgePhoto";
                colMappings["機具標章照片"] = "BadgePhoto";
                colMappings["標章照片"] = "BadgePhoto";

                colMappings["機關檢測紀錄文件或證明"] = "RecordDoc";
                colMappings["機具檢測紀錄文件證明"] = "RecordDoc";
                colMappings["檢測紀錄文件"] = "RecordDoc";

                colMappings["計畫類型"] = "ProjectType";

                string connStr = GetConnStr();
                int totalCount = 0;
                int mainInsertCount = 0;
                int mainUpdateCount = 0;
                int unqInsertCount = 0;
                int unqUpdateCount = 0;

                int maxIdBeforeImport = 0;
                int maxIdBeforeImportUnqualified = 0;

                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    using (SqlCommand cmdMax = new SqlCommand("SELECT ISNULL(MAX([Id]), 0) FROM [MoenvEquipment]", conn))
                    {
                        maxIdBeforeImport = Convert.ToInt32(cmdMax.ExecuteScalar());
                    }
                    using (SqlCommand cmdMaxUnq = new SqlCommand("SELECT ISNULL(MAX([Id]), 0) FROM [MoenvEquipment_Unqualified]", conn))
                    {
                        maxIdBeforeImportUnqualified = Convert.ToInt32(cmdMaxUnq.ExecuteScalar());
                    }

                    for (int r = 1; r <= sheet.LastRowNum; r++)
                    {
                        IRow row = sheet.GetRow(r);
                        if (row == null) continue;

                        Dictionary<string, string> rowVals = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                        foreach (string dbCol in colMappings.Values)
                        {
                            rowVals[dbCol] = "";
                        }

                        bool hasData = false;
                        foreach (KeyValuePair<string, string> kvp in colMappings)
                        {
                            string excelHeader = kvp.Key;
                            string dbColName = kvp.Value;

                            if (headerMap.ContainsKey(excelHeader))
                            {
                                int colIdx = headerMap[excelHeader];
                                string cellVal = GetCellValue(row.GetCell(colIdx));
                                if (!string.IsNullOrEmpty(cellVal))
                                {
                                    if (dbColName == "BuyDoc" || dbColName == "EmissionDoc" || dbColName == "BadgePhoto" || dbColName == "RecordDoc")
                                    {
                                        rowVals[dbColName] = IsCheckMark(cellVal) ? "V" : cellVal.Trim();
                                    }
                                    else
                                    {
                                        rowVals[dbColName] = cellVal;
                                    }
                                    hasData = true;
                                }
                            }
                        }

                        if (!hasData) continue;
                        totalCount++;

                        bool hasExcelProjectType = headerMap.ContainsKey("計畫類型");
                        string finalProjectType = rowVals["ProjectType"];
                        bool isQualified = CalculateIsQualified(rowVals);

                        string normTaxId = (rowVals.ContainsKey("TaxId") && !IsEmptyVal(rowVals["TaxId"])) ? rowVals["TaxId"].Trim() : "";
                        string normBrand = (rowVals.ContainsKey("Brand") && !IsEmptyVal(rowVals["Brand"])) ? rowVals["Brand"].Trim() : "";
                        string normModel = (rowVals.ContainsKey("Model") && !IsEmptyVal(rowVals["Model"])) ? rowVals["Model"].Trim() : "";
                        string normEngineNumber = (rowVals.ContainsKey("EngineNumber") && !IsEmptyVal(rowVals["EngineNumber"])) ? rowVals["EngineNumber"].Trim() : "";
                        string normPlateNumber = (rowVals.ContainsKey("PlateNumber") && !IsEmptyVal(rowVals["PlateNumber"])) ? rowVals["PlateNumber"].Trim() : "";
                        string excelTestDateStr = NormalizeDateStr(rowVals["TestDate"]);
                        string excelBadgeNumStr = rowVals.ContainsKey("BadgeNumber") ? rowVals["BadgeNumber"].Trim() : "";
                        string excelBadgeLevelStr = rowVals.ContainsKey("BadgeLevel") ? rowVals["BadgeLevel"].Trim() : "";

                        bool isUnqualifiedRecord = (excelBadgeLevelStr.Equals("未通過") || IsEmptyVal(excelBadgeNumStr));
                        string targetTable = isUnqualifiedRecord ? "MoenvEquipment_Unqualified" : "MoenvEquipment";
                        int currentMaxId = isUnqualifiedRecord ? maxIdBeforeImportUnqualified : maxIdBeforeImport;

                        int matchId = 0;

                        if (isUnqualifiedRecord)
                        {
                            string matchSql =
                                "SELECT TOP 1 [Id] FROM [MoenvEquipment_Unqualified] WHERE [Id] <= @MaxId AND " +
                                "(LTRIM(RTRIM(ISNULL([TaxId], ''))) = @TaxId OR (LTRIM(RTRIM(ISNULL([TaxId], ''))) IN ('', '無', '無資料') AND @TaxId = '')) AND " +
                                "(LTRIM(RTRIM(ISNULL([Brand], ''))) = @Brand OR (LTRIM(RTRIM(ISNULL([Brand], ''))) IN ('', '無', '無資料') AND @Brand = '')) AND " +
                                "(LTRIM(RTRIM(ISNULL([Model], ''))) = @Model OR (LTRIM(RTRIM(ISNULL([Model], ''))) IN ('', '無', '無資料') AND @Model = '')) AND " +
                                "(LTRIM(RTRIM(ISNULL([EngineNumber], ''))) = @EngineNumber OR (LTRIM(RTRIM(ISNULL([EngineNumber], ''))) IN ('', '無', '無資料') AND @EngineNumber = '')) AND " +
                                "(LTRIM(RTRIM(ISNULL([PlateNumber], ''))) = @PlateNumber OR (LTRIM(RTRIM(ISNULL([PlateNumber], ''))) IN ('', '無', '無資料') AND @PlateNumber = '')) AND " +
                                "LEFT(REPLACE(ISNULL(CONVERT(NVARCHAR(50), [TestDate], 120), ''), '/', '-'), 10) = @TestDateNorm";

                            using (SqlCommand matchCmd = new SqlCommand(matchSql, conn))
                            {
                                matchCmd.Parameters.AddWithValue("@MaxId", currentMaxId);
                                matchCmd.Parameters.AddWithValue("@TaxId", normTaxId);
                                matchCmd.Parameters.AddWithValue("@Brand", normBrand);
                                matchCmd.Parameters.AddWithValue("@Model", normModel);
                                matchCmd.Parameters.AddWithValue("@EngineNumber", normEngineNumber);
                                matchCmd.Parameters.AddWithValue("@PlateNumber", normPlateNumber);
                                matchCmd.Parameters.AddWithValue("@TestDateNorm", excelTestDateStr);

                                object scalarResult = matchCmd.ExecuteScalar();
                                if (scalarResult != null && scalarResult != DBNull.Value)
                                {
                                    matchId = Convert.ToInt32(scalarResult);
                                }
                            }
                        }
                        else
                        {
                            string matchSql =
                                "SELECT TOP 1 [Id] FROM [MoenvEquipment] WHERE [Id] <= @MaxId AND " +
                                "LTRIM(RTRIM(ISNULL([BadgeNumber], ''))) = @BadgeNumber AND " +
                                "LEFT(REPLACE(ISNULL(CONVERT(NVARCHAR(50), [TestDate], 120), ''), '/', '-'), 10) = @TestDateNorm";

                            using (SqlCommand matchCmd = new SqlCommand(matchSql, conn))
                            {
                                matchCmd.Parameters.AddWithValue("@MaxId", currentMaxId);
                                matchCmd.Parameters.AddWithValue("@BadgeNumber", excelBadgeNumStr);
                                matchCmd.Parameters.AddWithValue("@TestDateNorm", excelTestDateStr);

                                object scalarResult = matchCmd.ExecuteScalar();
                                if (scalarResult != null && scalarResult != DBNull.Value)
                                {
                                    matchId = Convert.ToInt32(scalarResult);
                                }
                            }
                        }

                        string insertProjectType = finalProjectType;
                        if (string.IsNullOrEmpty(insertProjectType))
                        {
                            insertProjectType = defaultPlanType;
                        }

                        if (matchId > 0)
                        {
                            bool needsUpdate = false;
                            string readSql = "SELECT * FROM [" + targetTable + "] WHERE [Id] = @Id";
                            using (SqlCommand readCmd = new SqlCommand(readSql, conn))
                            {
                                readCmd.Parameters.AddWithValue("@Id", matchId);
                                using (SqlDataReader reader = readCmd.ExecuteReader())
                                {
                                    if (reader.Read())
                                    {
                                        foreach (string dbCol in colMappings.Values)
                                        {
                                            if (isUnqualifiedRecord)
                                            {
                                                if (dbCol.Equals("TaxId", StringComparison.OrdinalIgnoreCase) ||
                                                    dbCol.Equals("Brand", StringComparison.OrdinalIgnoreCase) ||
                                                    dbCol.Equals("Model", StringComparison.OrdinalIgnoreCase) ||
                                                    dbCol.Equals("EngineNumber", StringComparison.OrdinalIgnoreCase) ||
                                                    dbCol.Equals("PlateNumber", StringComparison.OrdinalIgnoreCase) ||
                                                    dbCol.Equals("TestDate", StringComparison.OrdinalIgnoreCase))
                                                {
                                                    continue;
                                                }
                                            }
                                            else
                                            {
                                                if (dbCol.Equals("BadgeNumber", StringComparison.OrdinalIgnoreCase) ||
                                                    dbCol.Equals("TestDate", StringComparison.OrdinalIgnoreCase))
                                                {
                                                    continue;
                                                }
                                            }

                                            if (dbCol.Equals("ProjectType", StringComparison.OrdinalIgnoreCase))
                                            {
                                                if (hasExcelProjectType)
                                                {
                                                    string ep = rowVals.ContainsKey("ProjectType") ? rowVals["ProjectType"].Trim() : "";
                                                    int ordIdx = -1;
                                                    for (int ci = 0; ci < reader.FieldCount; ci++)
                                                    {
                                                        if (reader.GetName(ci).Equals("ProjectType", StringComparison.OrdinalIgnoreCase))
                                                        {
                                                            ordIdx = ci;
                                                            break;
                                                        }
                                                    }
                                                    string dp = (ordIdx >= 0 && !reader.IsDBNull(ordIdx)) ? reader[ordIdx].ToString().Trim() : "";
                                                    if (ep != "" && !ep.Equals(dp, StringComparison.OrdinalIgnoreCase))
                                                    {
                                                        needsUpdate = true;
                                                        break;
                                                    }
                                                }
                                                continue;
                                            }

                                            string excelVal = rowVals.ContainsKey(dbCol) ? rowVals[dbCol].Trim() : "";
                                            string dbVal = "";
                                            int colOrd = -1;
                                            for (int ci = 0; ci < reader.FieldCount; ci++)
                                            {
                                                if (reader.GetName(ci).Equals(dbCol, StringComparison.OrdinalIgnoreCase))
                                                {
                                                    colOrd = ci;
                                                    break;
                                                }
                                            }
                                            if (colOrd >= 0 && !reader.IsDBNull(colOrd))
                                            {
                                                if (reader.GetFieldType(colOrd) == typeof(DateTime))
                                                {
                                                    dbVal = Convert.ToDateTime(reader[colOrd]).ToString("yyyy-MM-dd");
                                                }
                                                else
                                                {
                                                    dbVal = reader[colOrd].ToString().Trim();
                                                }
                                            }

                                            string normExcel = NormalizeForCompare(excelVal, dbCol);
                                            string normDb = NormalizeForCompare(dbVal, dbCol);
                                            if (!normExcel.Equals(normDb, StringComparison.OrdinalIgnoreCase))
                                            {
                                                needsUpdate = true;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }

                            if (needsUpdate)
                            {
                                string updateSql =
                                    "UPDATE [" + targetTable + "] SET " +
                                    "[IssuingUnit] = @IssuingUnit, [TestCounty] = @TestCounty, [OwnerName] = @OwnerName, " +
                                    "[ApplyType] = @ApplyType, [TaxId] = @TaxId, [Brand] = @Brand, [EquipType] = @EquipType, " +
                                    "[PlateNumber] = @PlateNumber, [EquipYear] = @EquipYear, [Model] = @Model, [EngineNumber] = @EngineNumber, " +
                                    "[Displacement] = @Displacement, [MaxHorsePower] = @MaxHorsePower, [MaxPowerSpeed] = @MaxPowerSpeed, " +
                                    "[TestMethod] = @TestMethod, [BadgeNumber] = @BadgeNumber, [TestValue] = @TestValue, " +
                                    "[RetestValue] = @RetestValue, [TestDate] = @TestDate, [IssueDate] = @IssueDate, " +
                                    "[BadgeLevel] = @BadgeLevel, [BadgeStatus] = @BadgeStatus, [BuyDoc] = @BuyDoc, " +
                                    "[EmissionDoc] = @EmissionDoc, [BadgePhoto] = @BadgePhoto, [RecordDoc] = @RecordDoc, " +
                                    "[ProjectType] = @ProjectType, [IsQualified] = @IsQualified, [ModifyDate] = GETDATE() " +
                                    "WHERE [Id] = @Id";

                                using (SqlCommand updCmd = new SqlCommand(updateSql, conn))
                                {
                                    updCmd.Parameters.AddWithValue("@Id", matchId);
                                    BindAllRowParameters(updCmd, rowVals, insertProjectType, isQualified);
                                    updCmd.ExecuteNonQuery();

                                    if (isUnqualifiedRecord)
                                    {
                                        unqUpdateCount++;
                                    }
                                    else
                                    {
                                        mainUpdateCount++;
                                    }
                                }
                            }
                        }
                        else
                        {
                            string insertSql =
                                "INSERT INTO [" + targetTable + "] (" +
                                "[IssuingUnit],[TestCounty],[OwnerName],[ApplyType],[TaxId]," +
                                "[Brand],[EquipType],[PlateNumber],[EquipYear],[Model]," +
                                "[EngineNumber],[Displacement],[MaxHorsePower],[MaxPowerSpeed]," +
                                "[TestMethod],[BadgeNumber],[TestValue],[RetestValue],[TestDate]," +
                                "[IssueDate],[BadgeLevel],[BadgeStatus],[BuyDoc],[EmissionDoc]," +
                                "[BadgePhoto],[RecordDoc],[ProjectType],[IsQualified],[CreateDate],[ModifyDate]) " +
                                "VALUES (" +
                                "@IssuingUnit,@TestCounty,@OwnerName,@ApplyType,@TaxId," +
                                "@Brand,@EquipType,@PlateNumber,@EquipYear,@Model," +
                                "@EngineNumber,@Displacement,@MaxHorsePower,@MaxPowerSpeed," +
                                "@TestMethod,@BadgeNumber,@TestValue,@RetestValue,@TestDate," +
                                "@IssueDate,@BadgeLevel,@BadgeStatus,@BuyDoc,@EmissionDoc," +
                                "@BadgePhoto,@RecordDoc,@ProjectType,@IsQualified,GETDATE(),GETDATE())";

                            using (SqlCommand insCmd = new SqlCommand(insertSql, conn))
                            {
                                BindAllRowParameters(insCmd, rowVals, insertProjectType, isQualified);
                                insCmd.ExecuteNonQuery();

                                if (isUnqualifiedRecord)
                                {
                                    unqInsertCount++;
                                }
                                else
                                {
                                    mainInsertCount++;
                                }
                            }
                        }
                    }
                }

                result["success"] = true;
                result["message"] = string.Format(
                    "Excel 檔案匯入成功！共解析 {0} 筆資料。\r\n【合格主要清冊】：新增 {1} 筆，覆蓋更新 {2} 筆。\r\n【未通過清冊】：新增 {3} 筆，覆蓋更新 {4} 筆。",
                    totalCount, mainInsertCount, mainUpdateCount, unqInsertCount, unqUpdateCount);
                result["total"] = totalCount;
                result["mainInserted"] = mainInsertCount;
                result["mainUpdated"] = mainUpdateCount;
                result["unqInserted"] = unqInsertCount;
                result["unqUpdated"] = unqUpdateCount;
                result["failed"] = 0;
            }
            catch (Exception ex)
            {
                result["message"] = "匯入 Excel 失敗：" + ex.Message;
            }

            return result;
        }

        private static void BindAllRowParameters(SqlCommand cmd, Dictionary<string, string> rowVals, string insertProjectType, bool isQualified)
        {
            cmd.Parameters.AddWithValue("@IssuingUnit", SqlVal(rowVals["IssuingUnit"]));
            cmd.Parameters.AddWithValue("@TestCounty", SqlVal(rowVals["TestCounty"]));
            cmd.Parameters.AddWithValue("@OwnerName", SqlVal(rowVals["OwnerName"]));
            cmd.Parameters.AddWithValue("@ApplyType", SqlVal(rowVals["ApplyType"]));
            cmd.Parameters.AddWithValue("@TaxId", SqlVal(rowVals["TaxId"]));
            cmd.Parameters.AddWithValue("@Brand", SqlVal(rowVals["Brand"]));
            cmd.Parameters.AddWithValue("@EquipType", SqlVal(rowVals["EquipType"]));
            cmd.Parameters.AddWithValue("@PlateNumber", SqlVal(rowVals["PlateNumber"]));
            cmd.Parameters.AddWithValue("@EquipYear", SqlVal(rowVals["EquipYear"]));
            cmd.Parameters.AddWithValue("@Model", SqlVal(rowVals["Model"]));
            cmd.Parameters.AddWithValue("@EngineNumber", SqlVal(rowVals["EngineNumber"]));
            cmd.Parameters.AddWithValue("@Displacement", SqlVal(rowVals["Displacement"]));
            cmd.Parameters.AddWithValue("@MaxHorsePower", SqlVal(rowVals["MaxHorsePower"]));
            cmd.Parameters.AddWithValue("@MaxPowerSpeed", SqlVal(rowVals["MaxPowerSpeed"]));
            cmd.Parameters.AddWithValue("@TestMethod", SqlVal(rowVals["TestMethod"]));
            cmd.Parameters.AddWithValue("@BadgeNumber", SqlVal(rowVals["BadgeNumber"]));
            cmd.Parameters.AddWithValue("@TestValue", SqlVal(rowVals["TestValue"]));
            cmd.Parameters.AddWithValue("@RetestValue", SqlVal(rowVals["RetestValue"]));
            cmd.Parameters.AddWithValue("@TestDate", SqlVal(rowVals["TestDate"]));
            cmd.Parameters.AddWithValue("@IssueDate", SqlVal(rowVals["IssueDate"]));
            cmd.Parameters.AddWithValue("@BadgeLevel", SqlVal(rowVals["BadgeLevel"]));
            cmd.Parameters.AddWithValue("@BadgeStatus", SqlVal(rowVals["BadgeStatus"]));
            cmd.Parameters.AddWithValue("@BuyDoc", SqlVal(rowVals["BuyDoc"]));
            cmd.Parameters.AddWithValue("@EmissionDoc", SqlVal(rowVals["EmissionDoc"]));
            cmd.Parameters.AddWithValue("@BadgePhoto", SqlVal(rowVals["BadgePhoto"]));
            cmd.Parameters.AddWithValue("@RecordDoc", SqlVal(rowVals["RecordDoc"]));
            cmd.Parameters.AddWithValue("@ProjectType", SqlVal(insertProjectType));
            cmd.Parameters.AddWithValue("@IsQualified", isQualified);
        }
    }
}

