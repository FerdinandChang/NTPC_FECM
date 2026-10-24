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

namespace NTPC_FEC.BareGround
{
    public partial class BareResult : Page
    {
        private JavaScriptSerializer jsonSerializer;

        public BareResult()
        {
            jsonSerializer = new JavaScriptSerializer();
            jsonSerializer.MaxJsonLength = int.MaxValue;
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
                    Response.Write(jsonSerializer.Serialize(new
                    {
                        Success = false,
                        Message = "伺服器處理失敗：" + ex.Message
                    }));
                }
                Response.End();
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            string bareId = Request["id"];
            string token = Request["id1"];
            string invNo = Request["id2"];
            string mode = Request["mode"];

            switch (action.ToLower())
            {
                case "getcase":
                    GetCaseData(bareId, token, invNo, mode);
                    break;
                case "savesignature":
                    SaveSignature();
                    break;
                default:
                    Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "未知的操作指令：" + action }));
                    break;
            }
        }

        private bool ValidateToken(string bareId, string token)
        {
            if (string.IsNullOrEmpty(bareId)) return false;

            // 1. 若已有登入工作階段，直接通過
            if (Session["LoginUser"] != null && !string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                return true;
            }
            if (User != null && User.Identity != null && User.Identity.IsAuthenticated)
            {
                return true;
            }

            // 2. Token 比對 (容錯當前小時與前一小時)
            if (string.IsNullOrEmpty(token)) return false;

            string nowToken = GenerateToken(bareId, DateTime.Now);
            if (string.Equals(token, nowToken, StringComparison.OrdinalIgnoreCase)) return true;

            string prevToken = GenerateToken(bareId, DateTime.Now.AddHours(-1));
            if (string.Equals(token, prevToken, StringComparison.OrdinalIgnoreCase)) return true;

            string nextToken = GenerateToken(bareId, DateTime.Now.AddHours(1));
            if (string.Equals(token, nextToken, StringComparison.OrdinalIgnoreCase)) return true;

            return false;
        }

        private string GenerateToken(string bareId, DateTime dt)
        {
            string raw = "MD5:" + bareId + dt.ToString("yyyyMMddHH");
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

        private void GetCaseData(string bareId, string token, string invNoStr, string mode)
        {
            if (string.IsNullOrEmpty(bareId))
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "缺少場址代碼 (id)" }));
                return;
            }

            // 安全性驗證
            if (!ValidateToken(bareId, token))
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "安全驗證憑證已失效或不相符，請重新由清單進入。" }));
                return;
            }

            int invNo = 0;
            int.TryParse(invNoStr, out invNo);

            // 1. 讀取場址主檔 Bare_Main
            string sqlMain = "SELECT * FROM Bare_Main WHERE Bare_ID = @Bare_ID";
            DataTable dtMain = DbHelper.ExecuteDataTable(sqlMain, new SqlParameter("@Bare_ID", bareId.Trim()));
            if (dtMain.Rows.Count == 0)
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "查無此裸露地場址資料 (ID: " + bareId + ")" }));
                return;
            }

            DataRow rMain = dtMain.Rows[0];

            // 2. 讀取巡查明細 Bare_INV
            DataRow rInv = null;
            if (invNo > 0)
            {
                string sqlInv = "SELECT * FROM Bare_INV WHERE Bare_ID = @Bare_ID AND INV_NO = @INV_NO";
                DataTable dtInv = DbHelper.ExecuteDataTable(sqlInv,
                    new SqlParameter("@Bare_ID", bareId.Trim()),
                    new SqlParameter("@INV_NO", invNo));
                if (dtInv.Rows.Count > 0)
                {
                    rInv = dtInv.Rows[0];
                }
            }
            else
            {
                string sqlLatest = "SELECT TOP 1 * FROM Bare_INV WHERE Bare_ID = @Bare_ID ORDER BY INV_NO DESC";
                DataTable dtLatest = DbHelper.ExecuteDataTable(sqlLatest, new SqlParameter("@Bare_ID", bareId.Trim()));
                if (dtLatest.Rows.Count > 0)
                {
                    rInv = dtLatest.Rows[0];
                    if (rInv["INV_NO"] != DBNull.Value)
                    {
                        int.TryParse(rInv["INV_NO"].ToString(), out invNo);
                    }
                }
            }

            // 經緯度處理 (檢查是否為 TWD97 二度分帶座標)
            double lat = 0;
            double lng = 0;
            if (rMain["Latitude"] != DBNull.Value)
            {
                double.TryParse(rMain["Latitude"].ToString(), out lat);
            }
            if (rMain["Longtitude"] != DBNull.Value)
            {
                double.TryParse(rMain["Longtitude"].ToString(), out lng);
            }

            // 若經緯度反轉或為 TWD97 (X > 100000)
            if (lng > 100000 && lat > 1000000)
            {
                double wgsLat, wgsLon;
                Twd97ToWgs84(lng, lat, out wgsLat, out wgsLon);
                lat = wgsLat;
                lng = wgsLon;
            }
            else if (lat > 100000 && lng > 1000000)
            {
                double wgsLat, wgsLon;
                Twd97ToWgs84(lat, lng, out wgsLat, out wgsLon);
                lat = wgsLat;
                lng = wgsLon;
            }

            // 數值資料解析
            string checkDateStr = "";
            string aroundMemo = "";
            string wasteType = "";
            string surroundings = "";
            string pLength = "0.0";
            string pWidth = "0.0";
            string pHeight = "0.0";
            string pVolume = "0.0";
            string pArea = "0.0";
            string inputUser = "";
            string invState = "";
            string invStateName = "未查核";

            if (rInv != null)
            {
                if (rInv["Check_Date"] != DBNull.Value)
                {
                    DateTime dtCheck;
                    if (DateTime.TryParse(rInv["Check_Date"].ToString(), out dtCheck))
                    {
                        checkDateStr = dtCheck.ToString("yyyy-MM-dd HH:mm");
                    }
                }

                aroundMemo = rInv["Around_Memo"] != DBNull.Value ? rInv["Around_Memo"].ToString().Replace("<br />", "\r\n").Replace("<br>", "\r\n") : "";
                wasteType = rInv["Waste_Type"] != DBNull.Value ? rInv["Waste_Type"].ToString().Replace("<br />", "\r\n").Replace("<br>", "\r\n") : "";
                surroundings = rInv["surroundings"] != DBNull.Value ? rInv["surroundings"].ToString().Replace("<br />", "\r\n").Replace("<br>", "\r\n") : "";

                float flen = 0f, fwid = 0f, fhei = 0f, fvol = 0f, farea = 0f;
                if (rInv["pLength"] != DBNull.Value) float.TryParse(rInv["pLength"].ToString(), out flen);
                if (rInv["pWidth"] != DBNull.Value) float.TryParse(rInv["pWidth"].ToString(), out fwid);
                if (rInv["pHeight"] != DBNull.Value) float.TryParse(rInv["pHeight"].ToString(), out fhei);
                if (rInv["pVolume"] != DBNull.Value) float.TryParse(rInv["pVolume"].ToString(), out fvol);
                if (rInv["pArea"] != DBNull.Value) float.TryParse(rInv["pArea"].ToString(), out farea);

                pLength = flen.ToString("0.0");
                pWidth = fwid.ToString("0.0");
                pHeight = fhei.ToString("0.0");
                pVolume = fvol.ToString("0.0");
                pArea = farea.ToString("0.0");

                inputUser = rInv["InputUser"] != DBNull.Value ? rInv["InputUser"].ToString().Trim() : "";
                invState = rInv["INV_State"] != DBNull.Value ? rInv["INV_State"].ToString().Trim() : "";
                invStateName = GetStateName(invState);
            }

            // 讀取現場照片 (一) ~ (四)
            var photos = new List<object>();
            string targetDir = Server.MapPath(string.Format("~/Upload/BareGround/{0}/{1}", bareId.Trim(), invNo));
            string[] photoTitles = new string[] { "裸露地現場照片(一)", "裸露地現場照片(二)", "裸露地現場照片(三)", "裸露地現場照片(四)" };

            for (int i = 0; i < 4; i++)
            {
                string title = photoTitles[i];
                string fileUrl = "";
                bool hasFile = false;
                string fileSizeText = "";
                string updateTimeText = "";

                if (Directory.Exists(targetDir))
                {
                    string[] matched = Directory.GetFiles(targetDir, title + ".*");
                    if (matched.Length > 0 && File.Exists(matched[0]))
                    {
                        FileInfo fi = new FileInfo(matched[0]);
                        fileUrl = string.Format("../Upload/BareGround/{0}/{1}/{2}?t={3}",
                            bareId.Trim(), invNo, fi.Name, fi.LastWriteTime.Ticks);
                        hasFile = true;
                        fileSizeText = (fi.Length / 1024).ToString("N0") + " KB";
                        updateTimeText = fi.LastWriteTime.ToString("yyyy-MM-dd HH:mm");
                    }
                }

                photos.Add(new
                {
                    Index = i + 1,
                    Title = title,
                    HasFile = hasFile,
                    Url = fileUrl,
                    FileSize = fileSizeText,
                    UpdateTime = updateTimeText
                });
            }

            // 讀取稽查人員簽名
            string sigUrl = "";
            string sigBase64 = "";
            bool hasSig = false;
            string sigUpdateTime = "";

            if (Directory.Exists(targetDir))
            {
                string sigPath = Path.Combine(targetDir, "Sig1.png");
                if (File.Exists(sigPath))
                {
                    try
                    {
                        byte[] bytes = File.ReadAllBytes(sigPath);
                        sigBase64 = "data:image/png;base64," + Convert.ToBase64String(bytes);
                        sigUrl = string.Format("../Upload/BareGround/{0}/{1}/Sig1.png?t={2}",
                            bareId.Trim(), invNo, File.GetLastWriteTime(sigPath).Ticks);
                        hasSig = true;
                        sigUpdateTime = File.GetLastWriteTime(sigPath).ToString("yyyy-MM-dd HH:mm");
                    }
                    catch
                    {
                    }
                }
            }

            Response.Write(jsonSerializer.Serialize(new
            {
                Success = true,
                Data = new
                {
                    Bare_ID = rMain["Bare_ID"].ToString().Trim(),
                    BareGroundNo = rMain["BareGroundNo"] != DBNull.Value ? rMain["BareGroundNo"].ToString().Trim() : "",
                    ADDR = rMain["ADDR"] != DBNull.Value ? rMain["ADDR"].ToString().Trim() : "",
                    Land_USE = rMain["Land_USE"] != DBNull.Value ? rMain["Land_USE"].ToString().Trim() : "",
                    Latitude = lat > 0 ? lat.ToString("0.000000") : "",
                    Longtitude = lng > 0 ? lng.ToString("0.000000") : "",
                    INV_NO = invNo,
                    Check_Date = checkDateStr,
                    Around_Memo = aroundMemo,
                    Waste_Type = wasteType,
                    pLength = pLength,
                    pWidth = pWidth,
                    pHeight = pHeight,
                    pVolume = pVolume,
                    pArea = pArea,
                    surroundings = surroundings,
                    InputUser = inputUser,
                    INV_State = invState,
                    INV_StateName = invStateName,
                    Photos = photos,
                    HasSig = hasSig,
                    SigUrl = sigUrl,
                    SigBase64 = sigBase64,
                    SigUpdateTime = sigUpdateTime,
                    CurrentMode = string.IsNullOrEmpty(mode) ? "read" : mode.ToLower()
                }
            }));
        }

        private void SaveSignature()
        {
            string rawJson = GetPostRawData();
            if (string.IsNullOrEmpty(rawJson))
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "未接收到儲存簽章資料" }));
                return;
            }

            Dictionary<string, object> dict = null;
            try
            {
                dict = jsonSerializer.Deserialize<Dictionary<string, object>>(rawJson);
            }
            catch (Exception ex)
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "解析簽章封包錯誤：" + ex.Message }));
                return;
            }

            if (dict == null)
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "簽章資料為空" }));
                return;
            }

            string bareId = dict.ContainsKey("Bare_ID") ? dict["Bare_ID"].ToString().Trim() : "";
            string token = dict.ContainsKey("Token") ? dict["Token"].ToString().Trim() : "";
            string invNoStr = dict.ContainsKey("INV_NO") ? dict["INV_NO"].ToString().Trim() : "";
            string base64Data = dict.ContainsKey("SigBase64") ? dict["SigBase64"].ToString().Trim() : "";

            if (string.IsNullOrEmpty(bareId))
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "缺少場址編號" }));
                return;
            }

            // 安全性驗證
            if (!ValidateToken(bareId, token))
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "安全憑證驗證失敗，無法儲存簽章" }));
                return;
            }

            int invNo = 0;
            int.TryParse(invNoStr, out invNo);
            if (invNo <= 0)
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "無效的巡查紀錄編號" }));
                return;
            }

            if (string.IsNullOrEmpty(base64Data))
            {
                Response.Write(jsonSerializer.Serialize(new { Success = false, Message = "未提供手寫簽名圖檔內容" }));
                return;
            }

            try
            {
                string targetDir = Server.MapPath(string.Format("~/Upload/BareGround/{0}/{1}", bareId, invNo));
                if (!Directory.Exists(targetDir))
                {
                    Directory.CreateDirectory(targetDir);
                }

                string pureBase64 = base64Data;
                int commaIdx = pureBase64.IndexOf(",");
                if (commaIdx >= 0)
                {
                    pureBase64 = pureBase64.Substring(commaIdx + 1);
                }

                byte[] imageBytes = Convert.FromBase64String(pureBase64);
                string sigPath = Path.Combine(targetDir, "Sig1.png");
                File.WriteAllBytes(sigPath, imageBytes);

                string sigUrl = string.Format("../Upload/BareGround/{0}/{1}/Sig1.png?t={2}",
                    bareId, invNo, DateTime.Now.Ticks);

                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = true,
                    Message = "簽章儲存成功！",
                    SigUrl = sigUrl,
                    SigUpdateTime = DateTime.Now.ToString("yyyy-MM-dd HH:mm")
                }));
            }
            catch (Exception ex)
            {
                Response.Write(jsonSerializer.Serialize(new
                {
                    Success = false,
                    Message = "儲存簽章時發生例外：" + ex.Message
                }));
            }
        }

        private string GetStateName(string stateId)
        {
            if (string.IsNullOrEmpty(stateId)) return "未查核";
            switch (stateId)
            {
                case "A00a": return "暫存草稿 / 待修正";
                case "A00b": return "退件待重辦";
                case "A00": return "案件待初審";
                case "A01": return "案件待複審";
                case "A02": return "案件待三審";
                case "A03": return "調查成果已核定";
                case "Z00": return "已刪除作廢";
                default: return stateId;
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

        #region TWD97 轉 WGS84 標準演算法 (C# 5.0 合規)
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
