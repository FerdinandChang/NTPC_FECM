using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.RoadClean
{
    public partial class NewCleanChk : Page
    {
        private JavaScriptSerializer json = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };

        protected void Page_Load(object sender, EventArgs e)
        {
            // Ajax API 請求處理
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
                    Response.Write(json.Serialize(new { Success = false, Message = ex.Message }));
                }
                Response.End();
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            switch (action.ToLower())
            {
                case "gettowns":
                    GetTowns();
                    break;
                case "getroads":
                    GetRoads(Request["town"]);
                    break;
                case "getroaddetail":
                    GetRoadDetail(Request["rdid"]);
                    break;
                case "getrecord":
                    GetRecord(Request["chkId"]);
                    break;
                case "save":
                    SaveCheckRecord();
                    break;
                case "upload_photo":
                    UploadPhoto();
                    break;
                case "delete_photo":
                    DeletePhoto();
                    break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的操作指令" }));
                    break;
            }
        }

        // 1. 取得新北市行政區列表
        private void GetTowns()
        {
            string sql = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
            DataTable dt = DbHelper.ExecuteDataTable(sql);
            var list = new List<object>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new
                {
                    TownNo = row["TOWN_NO"].ToString().Trim(),
                    TownName = row["TOWN_NA"].ToString().Trim()
                });
            }
            Response.Write(json.Serialize(new { Success = true, Data = list }));
        }

        // 2. 取得行政區對應的巡檢道路
        private void GetRoads(string town)
        {
            if (string.IsNullOrEmpty(town))
            {
                Response.Write(json.Serialize(new { Success = true, Data = new List<object>() }));
                return;
            }

            string sql = "SELECT [RDID], [RoadName], [dis], [wid] FROM [RoadClean_CheckPointMain] WHERE [TOWN] = @town ORDER BY [RoadName]";
            DataTable dt = DbHelper.ExecuteDataTable(sql, new SqlParameter("@town", town));
            var list = new List<object>();
            foreach (DataRow row in dt.Rows)
            {
                list.Add(new
                {
                    Rdid = row["RDID"].ToString().Trim(),
                    RoadName = row["RoadName"].ToString().Trim(),
                    Dis = row["dis"] != DBNull.Value ? Convert.ToDecimal(row["dis"]) : 0m,
                    Wid = row["wid"] != DBNull.Value ? Convert.ToDecimal(row["wid"]) : 0m
                });
            }
            Response.Write(json.Serialize(new { Success = true, Data = list }));
        }

        // 3. 取得道路檢核點與題庫
        private void GetRoadDetail(string rdid)
        {
            if (string.IsNullOrEmpty(rdid) || rdid == "-----")
            {
                Response.Write(json.Serialize(new { Success = false, Message = "無效的道路代碼" }));
                return;
            }

            // 道路基本資料
            string sqlRoad = "SELECT * FROM [RoadClean_CheckPointMain] WHERE [RDID] = @rdid";
            DataTable dtRoad = DbHelper.ExecuteDataTable(sqlRoad, new SqlParameter("@rdid", rdid));
            if (dtRoad.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此道路資料" }));
                return;
            }

            DataRow rRoad = dtRoad.Rows[0];
            string startPlace = rRoad.Table.Columns.Contains("StartPlace") && rRoad["StartPlace"] != DBNull.Value ? rRoad["StartPlace"].ToString().Trim() : "";
            string endPlace = rRoad.Table.Columns.Contains("EndPlace") && rRoad["EndPlace"] != DBNull.Value ? rRoad["EndPlace"].ToString().Trim() : "";

            var roadInfo = new
            {
                Rdid = rRoad["RDID"].ToString().Trim(),
                RoadName = rRoad["RoadName"].ToString().Trim(),
                Town = rRoad["TOWN"].ToString().Trim(),
                Dis = rRoad["dis"] != DBNull.Value ? rRoad["dis"].ToString() : "0",
                Wid = rRoad["wid"] != DBNull.Value ? rRoad["wid"].ToString() : "0",
                StartPlace = startPlace,
                EndPlace = endPlace
            };

            // 檢核點清單
            string sqlPoints = "SELECT * FROM [RoadClean_CheckPointList] WHERE [RDID] = @rdid ORDER BY [pIndex] ASC";
            DataTable dtPoints = DbHelper.ExecuteDataTable(sqlPoints, new SqlParameter("@rdid", rdid));
            var pointList = new List<object>();
            foreach (DataRow row in dtPoints.Rows)
            {
                double px = 0;
                double py = 0;
                if (row.Table.Columns.Contains("Point_X") && row["Point_X"] != DBNull.Value)
                {
                    double.TryParse(row["Point_X"].ToString(), out px);
                }
                if (row.Table.Columns.Contains("Point_Y") && row["Point_Y"] != DBNull.Value)
                {
                    double.TryParse(row["Point_Y"].ToString(), out py);
                }

                double lat = 0;
                double lng = 0;
                if (px > 0 && py > 0)
                {
                    Twd97ToWgs84(px, py, out lat, out lng);
                }

                pointList.Add(new
                {
                    PointId = row["Point_ID"].ToString().Trim(),
                    PIndex = row["pIndex"] != DBNull.Value ? Convert.ToInt32(row["pIndex"]) : 1,
                    PointPlace = row["PointPlace"].ToString().Trim(),
                    Lat = Math.Round(lat, 6),
                    Lng = Math.Round(lng, 6)
                });
            }

            // 題庫 (道路潔淨 RCC% 與 淹水潛勢 FLD%)
            string sqlQuestions = "SELECT * FROM [Def_RoadCleanCheck] ORDER BY [Sort_ID] ASC";
            DataTable dtQ = DbHelper.ExecuteDataTable(sqlQuestions);
            var rccList = new List<object>();
            var fldList = new List<object>();

            foreach (DataRow r in dtQ.Rows)
            {
                string code = r["Chk_Code"].ToString().Trim();
                var qObj = new
                {
                    ChkCode = code,
                    Title = r["Title"].ToString().Trim(),
                    SortId = r["Sort_ID"] != DBNull.Value ? Convert.ToInt32(r["Sort_ID"]) : 0,
                    Options = BuildOptions(r),
                    SubItems = r["Chi_CheckBox_Item1"] != DBNull.Value && !string.IsNullOrEmpty(r["Chi_CheckBox_Item1"].ToString())
                        ? r["Chi_CheckBox_Item1"].ToString().Split(new char[] { ',', '、', ';' }, StringSplitOptions.RemoveEmptyEntries)
                        : new string[0]
                };

                if (code.StartsWith("RCC", StringComparison.OrdinalIgnoreCase))
                {
                    rccList.Add(qObj);
                }
                else if (code.StartsWith("FLD", StringComparison.OrdinalIgnoreCase))
                {
                    fldList.Add(qObj);
                }
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                Road = roadInfo,
                Points = pointList,
                Questions = new
                {
                    RCC = rccList,
                    FLD = fldList
                }
            }));
        }

        private List<object> BuildOptions(DataRow r)
        {
            var options = new List<object>();
            for (int i = 1; i <= 5; i++)
            {
                string textCol = "Text_Item" + i;
                string fracCol = "Fraction_Item" + i;
                if (r.Table.Columns.Contains(textCol) && r[textCol] != DBNull.Value && !string.IsNullOrEmpty(r[textCol].ToString().Trim()))
                {
                    string text = r[textCol].ToString().Trim();
                    int fraction = 0;
                    if (r.Table.Columns.Contains(fracCol) && r[fracCol] != DBNull.Value)
                    {
                        int.TryParse(r[fracCol].ToString().Trim(), out fraction);
                    }
                    options.Add(new { Text = text, Score = fraction });
                }
            }
            return options;
        }

        // 4. 讀取既有紀錄 (mode=edit / mode=read)
        private void GetRecord(string chkId)
        {
            if (string.IsNullOrEmpty(chkId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無單號" }));
                return;
            }

            chkId = chkId.Trim();

            string sqlMain = @"SELECT M.*, R.RoadName, R.TOWN, R.dis, R.wid 
                               FROM RoadClean_ChkRecord_Main M 
                               LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID 
                               WHERE M.ChkID = @chkId";
            DataTable dtMain = DbHelper.ExecuteDataTable(sqlMain, new SqlParameter("@chkId", chkId));
            if (dtMain.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無此查核紀錄" }));
                return;
            }

            DataRow rMain = dtMain.Rows[0];
            string rdid = rMain["ChkRoadID"] != DBNull.Value ? rMain["ChkRoadID"].ToString().Trim() : "";
            string town = rMain["TOWN"] != DBNull.Value ? rMain["TOWN"].ToString().Trim() : "";
            string roadName = rMain["RoadName"] != DBNull.Value ? rMain["RoadName"].ToString().Trim() : "";

            // 簽名檔讀取 (容錯副檔名大小寫與多種格式)
            string sigBase64 = "";
            string sigDir = Server.MapPath("~/Upload/RoadCleanPIC/" + chkId);
            if (Directory.Exists(sigDir))
            {
                string[] sigFiles = Directory.GetFiles(sigDir, "Sig_1.*");
                if (sigFiles.Length > 0 && File.Exists(sigFiles[0]))
                {
                    try
                    {
                        byte[] bytes = File.ReadAllBytes(sigFiles[0]);
                        string ext = Path.GetExtension(sigFiles[0]).ToLower().Replace(".", "");
                        if (ext == "jpg") ext = "jpeg";
                        sigBase64 = "data:image/" + ext + ";base64," + Convert.ToBase64String(bytes);
                    }
                    catch
                    {
                        // 簽名檔讀取容錯
                    }
                }
            }

            // 檢核點現況與照片讀取
            string picDirRel = "~/Upload/RoadCleanPIC/" + chkId;
            string picDir = Server.MapPath(picDirRel);
            bool dirExists = Directory.Exists(picDir);

            string sqlPtMain = "SELECT * FROM RoadClean_ChkRecord_PointMain WHERE ChkID = @chkId ORDER BY pIndex ASC";
            DataTable dtPtMain = DbHelper.ExecuteDataTable(sqlPtMain, new SqlParameter("@chkId", chkId));
            var ptList = new List<object>();
            foreach (DataRow r in dtPtMain.Rows)
            {
                string pId = r["Point_ID"] != DBNull.Value ? r["Point_ID"].ToString().Trim() : "";
                string s0 = "", s1 = "", f0 = "", f1 = "";
                if (dirExists && !string.IsNullOrEmpty(pId))
                {
                    s0 = GetPhotoUrlIfExist(picDir, picDirRel, pId + "_現場照片");
                    s1 = GetPhotoUrlIfExist(picDir, picDirRel, pId + "_現場照片1");
                    f0 = GetPhotoUrlIfExist(picDir, picDirRel, pId + "_淹水潛勢照片");
                    f1 = GetPhotoUrlIfExist(picDir, picDirRel, pId + "_淹水潛勢照片1");
                }

                ptList.Add(new
                {
                    PointId = pId,
                    PIndex = r["pIndex"] != DBNull.Value ? Convert.ToInt32(r["pIndex"]) : 0,
                    STree = r["S_Tree"] != DBNull.Value ? r["S_Tree"].ToString().Trim() : "Y",
                    SIsland = r["S_island"] != DBNull.Value ? r["S_island"].ToString().Trim() : "Y",
                    CivilSide = r["Civil_Side"] != DBNull.Value ? r["Civil_Side"].ToString().Trim() : "N",
                    PLV = r["P_LV"] != DBNull.Value ? r["P_LV"].ToString().Trim() : "",
                    FloodLV = r["Flood_LV"] != DBNull.Value ? r["Flood_LV"].ToString().Trim() : "",
                    Photos = new { site0 = s0, site1 = s1, flood0 = f0, flood1 = f1 }
                });
            }

            // 得分細項
            string sqlScore = "SELECT * FROM RoadClean_ChkRecord_PointScore WHERE ChkID = @chkId";
            DataTable dtScore = DbHelper.ExecuteDataTable(sqlScore, new SqlParameter("@chkId", chkId));
            var scoreList = new List<object>();
            foreach (DataRow r in dtScore.Rows)
            {
                scoreList.Add(new
                {
                    PointId = r["Point_ID"] != DBNull.Value ? r["Point_ID"].ToString().Trim() : "",
                    ChkCode = r["Chk_Code"] != DBNull.Value ? r["Chk_Code"].ToString().Trim() : "",
                    Score = r["Score"] != DBNull.Value ? (object)Convert.ToInt32(r["Score"]) : null,
                    ChiItem1 = r["Chi_Item1"] != DBNull.Value ? r["Chi_Item1"].ToString().Trim() : ""
                });
            }

            // 審核意見
            string sqlExamine = "SELECT TOP 1 ExamineMemo, ExamineDate FROM RoadClean_ExamineData WHERE ChkID = @chkId ORDER BY ExamineDate DESC";
            DataTable dtExamine = DbHelper.ExecuteDataTable(sqlExamine, new SqlParameter("@chkId", chkId));
            string examineMemo = dtExamine.Rows.Count > 0 && dtExamine.Rows[0]["ExamineMemo"] != DBNull.Value ? dtExamine.Rows[0]["ExamineMemo"].ToString().Trim() : "";

            Response.Write(json.Serialize(new
            {
                Success = true,
                ChkId = chkId,
                ChkDate = rMain["ChkDate"] != DBNull.Value ? Convert.ToDateTime(rMain["ChkDate"]).ToString("yyyy-MM-dd HH:mm") : "",
                Rdid = rdid,
                Town = town,
                RoadName = roadName,
                Dis = rMain["dis"] != DBNull.Value ? rMain["dis"].ToString() : "0",
                Wid = rMain["wid"] != DBNull.Value ? rMain["wid"].ToString() : "0",
                CaseState = rMain["Case_State"] != DBNull.Value ? Convert.ToInt32(rMain["Case_State"]) : 1001,
                Signature = sigBase64,
                ExamineMemo = examineMemo,
                PointMain = ptList,
                Scores = scoreList
            }));
        }

        // 5. 儲存查核紀錄 (寫入資料庫與保存簽名)
        private void SaveCheckRecord()
        {
            string jsonBody = "";
            using (var reader = new StreamReader(Request.InputStream))
            {
                jsonBody = reader.ReadToEnd();
            }

            if (string.IsNullOrEmpty(jsonBody))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未接收到資料內容" }));
                return;
            }

            var input = json.Deserialize<CheckSaveModel>(jsonBody);
            if (input == null)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "資料格式無效" }));
                return;
            }

            if (string.IsNullOrEmpty(input.Signature))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "請先進行稽查人員簽名！" }));
                return;
            }

            string loginUser = Session["LoginUser"] != null ? Session["LoginUser"].ToString() : "Guest";
            string mode = input.Mode ?? "new";
            string thisChkId = input.ChkId;

            // 產生自動編號：ClnRD + yyyyMMdd + 5位流水號
            if (mode == "new" || string.IsNullOrEmpty(thisChkId) || thisChkId == "自動編號")
            {
                string keyWord = "ClnRD" + DateTime.Now.ToString("yyyyMMdd");
                string sqlMax = "SELECT TOP 1 ChkID FROM RoadClean_ChkRecord_Main WHERE ChkID LIKE @prefix ORDER BY ChkID DESC";
                DataTable dtMax = DbHelper.ExecuteDataTable(sqlMax, new SqlParameter("@prefix", keyWord + "%"));
                int maxNo = 0;
                if (dtMax.Rows.Count > 0)
                {
                    string oldId = dtMax.Rows[0]["ChkID"].ToString();
                    if (oldId.Length >= 18)
                    {
                        int.TryParse(oldId.Substring(13), out maxNo);
                    }
                }
                maxNo++;
                thisChkId = keyWord + maxNo.ToString("D5");
            }

            // 寫入主檔 RoadClean_ChkRecord_Main
            string sqlCheckExists = "SELECT COUNT(*) FROM RoadClean_ChkRecord_Main WHERE ChkID = @chkId";
            int existsCount = Convert.ToInt32(DbHelper.ExecuteScalar(sqlCheckExists, new SqlParameter("@chkId", thisChkId)));

            if (existsCount > 0)
            {
                string sqlUpdate = @"UPDATE RoadClean_ChkRecord_Main 
                                     SET Update_Date = GETDATE(), Update_User = @user 
                                     WHERE ChkID = @chkId";
                DbHelper.ExecuteNonQuery(sqlUpdate,
                    new SqlParameter("@user", loginUser),
                    new SqlParameter("@chkId", thisChkId));
            }
            else
            {
                string sqlInsert = @"INSERT INTO RoadClean_ChkRecord_Main 
                                     (ChkID, ChkRoadID, ChkDate, Create_Date, Create_User, Case_State) 
                                     VALUES (@chkId, @rdid, GETDATE(), GETDATE(), @user, 1001)";
                DbHelper.ExecuteNonQuery(sqlInsert,
                    new SqlParameter("@chkId", thisChkId),
                    new SqlParameter("@rdid", input.Rdid),
                    new SqlParameter("@user", loginUser));
            }

            // 清除舊檢核點與舊得分
            DbHelper.ExecuteNonQuery("DELETE FROM RoadClean_ChkRecord_PointMain WHERE ChkID = @chkId", new SqlParameter("@chkId", thisChkId));
            DbHelper.ExecuteNonQuery("DELETE FROM RoadClean_ChkRecord_PointScore WHERE ChkID = @chkId", new SqlParameter("@chkId", thisChkId));

            // 批次寫入檢核點
            if (input.Points != null)
            {
                foreach (var pt in input.Points)
                {
                    // 計算評級
                    int rccTotal = 0;
                    int rccCount = 0;
                    int fldTotal = 0;
                    if (pt.Scores != null)
                    {
                        foreach (var sc in pt.Scores)
                        {
                            object scoreObj = DBNull.Value;
                            if (sc.Score.HasValue)
                            {
                                // 判斷特殊題是否不計分
                                if (sc.ChkCode == "RCC004" && pt.SIsland != "Y") scoreObj = DBNull.Value;
                                else if (sc.ChkCode == "RCC005" && pt.STree != "Y") scoreObj = DBNull.Value;
                                else if (sc.ChkCode == "RCC006" && pt.CivilSide != "Y") scoreObj = DBNull.Value;
                                else
                                {
                                    scoreObj = sc.Score.Value;
                                    if (sc.ChkCode.StartsWith("RCC", StringComparison.OrdinalIgnoreCase))
                                    {
                                        rccTotal += sc.Score.Value;
                                        rccCount++;
                                    }
                                    else if (sc.ChkCode.StartsWith("FLD", StringComparison.OrdinalIgnoreCase))
                                    {
                                        fldTotal += sc.Score.Value;
                                    }
                                }
                            }

                            string sqlInsertScore = @"INSERT INTO RoadClean_ChkRecord_PointScore 
                                                      (ChkID, Point_ID, Chk_Code, Score, Chi_Item1) 
                                                      VALUES (@chkId, @pointId, @code, @score, @chi)";
                            DbHelper.ExecuteNonQuery(sqlInsertScore,
                                new SqlParameter("@chkId", thisChkId),
                                new SqlParameter("@pointId", pt.PointId),
                                new SqlParameter("@code", sc.ChkCode),
                                new SqlParameter("@score", scoreObj),
                                new SqlParameter("@chi", string.IsNullOrEmpty(sc.ChiItem1) ? (object)DBNull.Value : sc.ChiItem1));
                        }
                    }

                    // 道路潔淨評級
                    string pLv = "C級";
                    if (rccCount > 0)
                    {
                        float avg = (float)rccTotal / rccCount;
                        if (avg >= 85f) pLv = "A級";
                        else if (avg >= 60f) pLv = "B級";
                    }

                    // 淹水評級 (FLD 滿分 100 分，85 分以上 A 級，60 分以上 B 級，其餘 C 級)
                    string floodLv = "C級";
                    if (fldTotal >= 85)
                    {
                        floodLv = "A級";
                    }
                    else if (fldTotal >= 60)
                    {
                        floodLv = "B級";
                    }

                    string sqlInsertPt = @"INSERT INTO RoadClean_ChkRecord_PointMain 
                                           (ChkID, Point_ID, pIndex, S_Tree, S_island, Civil_Side, P_LV, Flood_LV) 
                                           VALUES (@chkId, @pointId, @pIndex, @tree, @island, @civil, @pLv, @floodLv)";
                    DbHelper.ExecuteNonQuery(sqlInsertPt,
                        new SqlParameter("@chkId", thisChkId),
                        new SqlParameter("@pointId", pt.PointId),
                        new SqlParameter("@pIndex", pt.PIndex),
                        new SqlParameter("@tree", pt.STree ?? "N"),
                        new SqlParameter("@island", pt.SIsland ?? "N"),
                        new SqlParameter("@civil", pt.CivilSide ?? "N"),
                        new SqlParameter("@pLv", pLv),
                        new SqlParameter("@floodLv", floodLv));
                }
            }

            // 保存簽名檔 Base64 轉 PNG
            try
            {
                string targetDir = Server.MapPath("~/Upload/RoadCleanPIC/" + thisChkId);
                if (!Directory.Exists(targetDir))
                {
                    Directory.CreateDirectory(targetDir);
                }

                string sigData = input.Signature;
                if (sigData.Contains(","))
                {
                    sigData = sigData.Substring(sigData.IndexOf(",") + 1);
                }
                byte[] sigBytes = Convert.FromBase64String(sigData);
                File.WriteAllBytes(Path.Combine(targetDir, "Sig_1.png"), sigBytes);

                // 搬移暫存照片至正式查核目錄
                if (mode == "new" && !string.IsNullOrEmpty(input.TempDir))
                {
                    string tempFolder = Server.MapPath("~/Upload/tempUpload/" + input.TempDir);
                    if (Directory.Exists(tempFolder))
                    {
                        FileInfo[] tempFiles = new DirectoryInfo(tempFolder).GetFiles();
                        for (int i = 0; i < tempFiles.Length; i++)
                        {
                            string destFile = Path.Combine(targetDir, tempFiles[i].Name);
                            tempFiles[i].CopyTo(destFile, true);
                        }
                        try { Directory.Delete(tempFolder, true); } catch { }
                    }
                }
            }
            catch
            {
                // 檔案寫入容錯
            }

            Response.Write(json.Serialize(new
            {
                Success = true,
                ChkId = thisChkId,
                Message = "巡檢紀錄儲存成功！"
            }));
        }

        // 照片上傳處理 (支援現場照片與淹水潛勢照片共4卡槽)
        private void UploadPhoto()
        {
            Response.ContentType = "application/json";
            if (Request.Files.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未接收到上傳檔案" }));
                return;
            }

            HttpPostedFile file = Request.Files[0];
            if (file == null || file.ContentLength == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "上傳檔案為空" }));
                return;
            }

            string mode = Request["mode"] ?? "new";
            string tempDir = FileSecurityHelper.SanitizeFileName(Request["tempDir"] ?? "");
            string chkId = FileSecurityHelper.SanitizeFileName(Request["chkId"] ?? "");
            string pointId = FileSecurityHelper.SanitizeFileName(Request["pointId"] ?? "");
            string photoType = FileSecurityHelper.SanitizeFileName(Request["photoType"] ?? "");

            if (string.IsNullOrEmpty(pointId) || string.IsNullOrEmpty(photoType))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "缺少檢核點或照片類型參數" }));
                return;
            }

            string fileSuffix = "";
            switch (photoType.ToLower())
            {
                case "site0": fileSuffix = "_現場照片"; break;
                case "site1": fileSuffix = "_現場照片1"; break;
                case "flood0": fileSuffix = "_淹水潛勢照片"; break;
                case "flood1": fileSuffix = "_淹水潛勢照片1"; break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的照片類型" }));
                    return;
            }

            string targetFolderRel = "";
            if (mode == "new")
            {
                if (string.IsNullOrEmpty(tempDir))
                {
                    tempDir = "temp_" + DateTime.Now.ToString("yyyyMMddHHmmss");
                }
                targetFolderRel = "~/Upload/tempUpload/" + tempDir;
            }
            else
            {
                if (string.IsNullOrEmpty(chkId))
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "缺少查核單號" }));
                    return;
                }
                targetFolderRel = "~/Upload/RoadCleanPIC/" + chkId;
            }

            string targetFolder = Server.MapPath(targetFolderRel);
            if (!Directory.Exists(targetFolder))
            {
                Directory.CreateDirectory(targetFolder);
            }

            string baseFileName = pointId + fileSuffix;
            string[] existingFiles = Directory.GetFiles(targetFolder, baseFileName + ".*");
            for (int i = 0; i < existingFiles.Length; i++)
            {
                try { File.Delete(existingFiles[i]); } catch { }
            }

            string savePath = Path.Combine(targetFolder, baseFileName + ".jpg");
            SavePhotoWithWatermark(file.InputStream, savePath);

            string clientUrl = ResolveUrl(targetFolderRel + "/" + baseFileName + ".jpg") + "?t=" + DateTime.Now.Ticks;

            Response.Write(json.Serialize(new
            {
                Success = true,
                PointId = pointId,
                PhotoType = photoType,
                Url = clientUrl,
                TempDir = tempDir
            }));
        }

        // 照片刪除處理
        private void DeletePhoto()
        {
            Response.ContentType = "application/json";
            string mode = Request["mode"] ?? "new";
            string tempDir = FileSecurityHelper.SanitizeFileName(Request["tempDir"] ?? "");
            string chkId = FileSecurityHelper.SanitizeFileName(Request["chkId"] ?? "");
            string pointId = FileSecurityHelper.SanitizeFileName(Request["pointId"] ?? "");
            string photoType = FileSecurityHelper.SanitizeFileName(Request["photoType"] ?? "");

            string fileSuffix = "";
            switch (photoType.ToLower())
            {
                case "site0": fileSuffix = "_現場照片"; break;
                case "site1": fileSuffix = "_現場照片1"; break;
                case "flood0": fileSuffix = "_淹水潛勢照片"; break;
                case "flood1": fileSuffix = "_淹水潛勢照片1"; break;
                default:
                    Response.Write(json.Serialize(new { Success = false, Message = "未知的照片類型" }));
                    return;
            }

            string targetFolderRel = (mode == "new")
                ? "~/Upload/tempUpload/" + tempDir
                : "~/Upload/RoadCleanPIC/" + chkId;

            string targetFolder = Server.MapPath(targetFolderRel);
            if (Directory.Exists(targetFolder))
            {
                string baseFileName = pointId + fileSuffix;
                string[] files = Directory.GetFiles(targetFolder, baseFileName + ".*");
                for (int i = 0; i < files.Length; i++)
                {
                    try { File.Delete(files[i]); } catch { }
                }
            }

            Response.Write(json.Serialize(new { Success = true, PointId = pointId, PhotoType = photoType }));
        }

        // 照片浮水印與轉存 (壓印稽查日期時間)
        private void SavePhotoWithWatermark(Stream inStream, string savePath)
        {
            try
            {
                using (Image img = Image.FromStream(inStream))
                {
                    using (Graphics g = Graphics.FromImage(img))
                    {
                        int fontSize = (int)((double)img.Height * 0.035);
                        if (fontSize < 16) fontSize = 16;
                        if (fontSize > 48) fontSize = 48;
                        using (Font font = new Font("微軟正黑體", fontSize, FontStyle.Bold, GraphicsUnit.Pixel))
                        {
                            string text = "上傳日期: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                            g.DrawString(text, font, Brushes.Black, new PointF(12f, 12f));
                            g.DrawString(text, font, Brushes.Yellow, new PointF(10f, 10f));
                        }
                    }
                    img.Save(savePath, ImageFormat.Jpeg);
                }
            }
            catch
            {
                if (inStream.CanSeek) inStream.Seek(0, SeekOrigin.Begin);
                using (FileStream fs = new FileStream(savePath, FileMode.Create, FileAccess.Write))
                {
                    inStream.CopyTo(fs);
                }
            }
        }

        // 輔助檢查檔案是否存在並回傳 URL
        private string GetPhotoUrlIfExist(string dir, string dirRel, string prefix)
        {
            string[] files = Directory.GetFiles(dir, prefix + ".*");
            if (files.Length > 0 && File.Exists(files[0]))
            {
                return ResolveUrl(dirRel + "/" + Path.GetFileName(files[0])) + "?t=" + DateTime.Now.Ticks;
            }
            return "";
        }

        // TWD97 二度分帶座標轉 WGS84 經緯度演算法 (相容 C# 5.0)
        private static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
        {
            if (x <= 0 || y <= 0)
            {
                lat = 0;
                lon = 0;
                return;
            }

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

            double Q1 = D;
            double Q2 = (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.Pow(C1, 2) - 9.0 * e2) * Math.Pow(D, 3) / 6.0;
            double Q3 = (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.Pow(T1, 2) - 252.0 * e2 - 3.0 * Math.Pow(C1, 2)) * Math.Pow(D, 5) / 120.0;
            double latRad = fp - (N1 * Math.Tan(fp) / R1) * (Math.Pow(D, 2) / 2.0 - (5.0 + 3.0 * T1 + 10.0 * C1 - 4.0 * Math.Pow(C1, 2) - 9.0 * e2) * Math.Pow(D, 4) / 24.0 + (61.0 + 90.0 * T1 + 298.0 * C1 + 45.0 * Math.Pow(T1, 2) - 252.0 * e2 - 3.0 * Math.Pow(C1, 2)) * Math.Pow(D, 6) / 720.0);

            double Q4 = D;
            double Q5 = (1.0 + 2.0 * T1 + C1) * Math.Pow(D, 3) / 6.0;
            double Q6 = (5.0 - 2.0 * C1 + 28.0 * T1 - 3.0 * Math.Pow(C1, 2) + 8.0 * e2 + 24.0 * Math.Pow(T1, 2)) * Math.Pow(D, 5) / 120.0;
            double lonRad = lon0 + (Q4 - Q5 + Q6) / Math.Cos(fp);

            lat = latRad * 180.0 / Math.PI;
            lon = lonRad * 180.0 / Math.PI;
        }

        // 接收資料的模型類
        public class CheckSaveModel
        {
            public string Mode { get; set; }
            public string ChkId { get; set; }
            public string Rdid { get; set; }
            public string TempDir { get; set; }
            public string Signature { get; set; }
            public List<PointModel> Points { get; set; }
        }

        public class PointModel
        {
            public string PointId { get; set; }
            public int PIndex { get; set; }
            public string STree { get; set; }
            public string SIsland { get; set; }
            public string CivilSide { get; set; }
            public List<ScoreModel> Scores { get; set; }
        }

        public class ScoreModel
        {
            public string ChkCode { get; set; }
            public int? Score { get; set; }
            public string ChiItem1 { get; set; }
        }
    }
}
