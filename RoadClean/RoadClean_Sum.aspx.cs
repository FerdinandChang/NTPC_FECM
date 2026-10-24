using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NPOI.HSSF.UserModel;
using NPOI.HSSF.Util;
using NPOI.SS.UserModel;
using NPOI.SS.Util;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.RoadClean
{
    public partial class RoadClean_Sum : Page
    {
        private JavaScriptSerializer json;

        public RoadClean_Sum()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        public class SumFilterModel
        {
            public List<string> Towns { get; set; }
            public string RoadName { get; set; }
            public string DateS { get; set; }
            public string DateE { get; set; }
            public double? DisS { get; set; }
            public double? DisE { get; set; }
            public string RdLv { get; set; }
            public bool OnlyBc { get; set; }
            public string MatrixMode { get; set; }

            public SumFilterModel()
            {
                Towns = new List<string>();
                RoadName = "";
                DateS = "";
                DateE = "";
                RdLv = "";
                OnlyBc = false;
                MatrixMode = "clean";
            }
        }

        public class MonthColModel
        {
            public int Year { get; set; }
            public int Month { get; set; }
            public string Key { get; set; }
            public string Label { get; set; }
            public string ShortLabel { get; set; }
        }

        public class MonthGradeModel
        {
            public string ChkID { get; set; }
            public int? Score { get; set; }
            public string Grade { get; set; }
            public string ShowTxt { get; set; }
            public string ChkDate { get; set; }
            public bool HasData { get; set; }

            public MonthGradeModel()
            {
                Grade = "-";
                ShowTxt = "-";
                HasData = false;
            }
        }

        public class RoadRowModel
        {
            public string RDID { get; set; }
            public string Town { get; set; }
            public string RdLv { get; set; }
            public string RoadName { get; set; }
            public double Dis { get; set; }
            public double Wid { get; set; }
            public Dictionary<string, MonthGradeModel> RoadScores { get; set; }
            public Dictionary<string, MonthGradeModel> FloodScores { get; set; }
            public int BcCount { get; set; }

            public RoadRowModel()
            {
                RoadScores = new Dictionary<string, MonthGradeModel>();
                FloodScores = new Dictionary<string, MonthGradeModel>();
                BcCount = 0;
            }
        }

        public class CountStatRowModel
        {
            public int Year { get; set; }
            public int Month { get; set; }
            public string MonthLabel { get; set; }
            public int CountA { get; set; }
            public int CountB { get; set; }
            public int CountC { get; set; }
            public int CountTotal { get; set; }
            public double PercentA { get; set; }
            public double PercentB { get; set; }
            public double PercentC { get; set; }
        }

        public class DisStatRowModel
        {
            public int Year { get; set; }
            public int Month { get; set; }
            public string MonthLabel { get; set; }
            public double DisA { get; set; }
            public double DisB { get; set; }
            public double DisC { get; set; }
            public double DisTotal { get; set; }
            public double PercentA { get; set; }
            public double PercentB { get; set; }
            public double PercentC { get; set; }
        }

        public class TownStatModel
        {
            public string Town { get; set; }
            public int RoadCount { get; set; }
            public double TotalDis { get; set; }
            public int CountA { get; set; }
            public int CountB { get; set; }
            public int CountC { get; set; }
            public double DisA { get; set; }
            public double DisB { get; set; }
            public double DisC { get; set; }
        }

        public class SumResultModel
        {
            public List<MonthColModel> MonthCols { get; set; }
            public List<RoadRowModel> RoadList { get; set; }
            public List<CountStatRowModel> CountStats { get; set; }
            public List<DisStatRowModel> DisStats { get; set; }
            public List<TownStatModel> TownStats { get; set; }
            public int TotalRoads { get; set; }
            public double TotalDistance { get; set; }
            public int TotalChecks { get; set; }
            public double AvgPassRate { get; set; }

            public SumResultModel()
            {
                MonthCols = new List<MonthColModel>();
                RoadList = new List<RoadRowModel>();
                CountStats = new List<CountStatRowModel>();
                DisStats = new List<DisStatRowModel>();
                TownStats = new List<TownStatModel>();
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();
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
                    Response.Write(json.Serialize(new { Success = false, Message = ex.Message }));
                }

                Response.End();
                return;
            }
        }

        private void HandleAjaxAction(string action)
        {
            string act = action.ToLower();
            if (act == "gettowns")
            {
                GetTowns();
            }
            else if (act == "getsumdata")
            {
                GetSumData();
            }
            else if (act == "getchkdetail")
            {
                GetChkDetail();
            }
            else if (act == "exportroads")
            {
                ExportRoads();
            }
            else if (act == "exportcounts")
            {
                ExportCounts();
            }
            else if (act == "exportlengths")
            {
                ExportLengths();
            }
        }

        private void GetTowns()
        {
            Response.ContentType = "application/json; charset=utf-8";

            string sql = "SELECT TOWN_NO, TOWN_NA FROM C_TOWN WHERE COUNTRY = 'F' ORDER BY TOWN_NO";
            DataTable dt = DbHelper.ExecuteDataTable(sql);
            List<object> list = new List<object>();
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

        private SumFilterModel ParseFilterFromRequest()
        {
            string jsonBody = "";
            if (Request.HttpMethod == "POST")
            {
                using (StreamReader reader = new StreamReader(Request.InputStream))
                {
                    jsonBody = reader.ReadToEnd();
                }
            }

            SumFilterModel filter = null;
            if (!string.IsNullOrEmpty(jsonBody))
            {
                filter = json.Deserialize<SumFilterModel>(jsonBody);
            }
            if (filter == null)
            {
                filter = new SumFilterModel();
                string townsParam = Request["towns"];
                if (!string.IsNullOrEmpty(townsParam))
                {
                    string[] arr = townsParam.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                    foreach (string t in arr)
                    {
                        filter.Towns.Add(t.Trim());
                    }
                }
                filter.RoadName = Request["roadName"] != null ? Request["roadName"].ToString().Trim() : "";
                filter.DateS = Request["dateS"] != null ? Request["dateS"].ToString().Trim() : "";
                filter.DateE = Request["dateE"] != null ? Request["dateE"].ToString().Trim() : "";
                filter.RdLv = Request["rdLv"] != null ? Request["rdLv"].ToString().Trim() : "";
                filter.OnlyBc = Request["onlyBc"] == "1" || Request["onlyBc"] == "true";
                filter.MatrixMode = Request["matrixMode"] != null ? Request["matrixMode"].ToString().Trim() : "clean";

                double dVal;
                if (!string.IsNullOrEmpty(Request["disS"]) && double.TryParse(Request["disS"], out dVal))
                {
                    filter.DisS = dVal;
                }
                if (!string.IsNullOrEmpty(Request["disE"]) && double.TryParse(Request["disE"], out dVal))
                {
                    filter.DisE = dVal;
                }
            }

            DateTime now = DateTime.Now;
            if (string.IsNullOrEmpty(filter.DateS))
            {
                filter.DateS = string.Format("{0}-01-01", now.Year);
            }
            if (string.IsNullOrEmpty(filter.DateE))
            {
                DateTime endOfMonth = new DateTime(now.Year, now.Month, DateTime.DaysInMonth(now.Year, now.Month));
                filter.DateE = endOfMonth.ToString("yyyy-MM-dd");
            }

            return filter;
        }

        private SumResultModel CalculateSumData(SumFilterModel filter)
        {
            DateTime dtS, dtE;
            if (!DateTime.TryParse(filter.DateS, out dtS))
            {
                dtS = new DateTime(DateTime.Now.Year, 1, 1);
            }
            if (!DateTime.TryParse(filter.DateE, out dtE))
            {
                dtE = DateTime.Now;
            }
            if (dtE < dtS)
            {
                DateTime tmp = dtS;
                dtS = dtE;
                dtE = tmp;
            }

            List<MonthColModel> monthCols = new List<MonthColModel>();
            DateTime curMonth = new DateTime(dtS.Year, dtS.Month, 1);
            DateTime lastMonth = new DateTime(dtE.Year, dtE.Month, 1);
            while (curMonth <= lastMonth)
            {
                int rocYear = curMonth.Year - 1911;
                MonthColModel col = new MonthColModel();
                col.Year = curMonth.Year;
                col.Month = curMonth.Month;
                col.Key = curMonth.ToString("yyyy-MM");
                col.Label = string.Format("{0}年{1}月", rocYear, curMonth.Month);
                col.ShortLabel = string.Format("{0}月", curMonth.Month);
                monthCols.Add(col);

                curMonth = curMonth.AddMonths(1);
            }

            StringBuilder whereRoad = new StringBuilder(" WHERE 1=1 ");
            List<SqlParameter> pRoadList = new List<SqlParameter>();

            if (filter.Towns != null && filter.Towns.Count > 0)
            {
                List<string> tParams = new List<string>();
                for (int i = 0; i < filter.Towns.Count; i++)
                {
                    string p = "@t_" + i;
                    tParams.Add(p);
                    pRoadList.Add(new SqlParameter(p, filter.Towns[i]));
                }
                whereRoad.Append(" AND R.TOWN IN (" + string.Join(",", tParams.ToArray()) + ") ");
            }

            if (!string.IsNullOrEmpty(filter.RoadName))
            {
                whereRoad.Append(" AND R.RoadName LIKE @rName ");
                pRoadList.Add(new SqlParameter("@rName", "%" + filter.RoadName.Trim() + "%"));
            }

            if (!string.IsNullOrEmpty(filter.RdLv))
            {
                whereRoad.Append(" AND R.RDLV = @rdLv ");
                pRoadList.Add(new SqlParameter("@rdLv", filter.RdLv.Trim()));
            }

            if (filter.DisS.HasValue)
            {
                whereRoad.Append(" AND ISNULL(R.Dis, 0) >= @disS ");
                pRoadList.Add(new SqlParameter("@disS", filter.DisS.Value));
            }
            if (filter.DisE.HasValue)
            {
                whereRoad.Append(" AND ISNULL(R.Dis, 0) <= @disE ");
                pRoadList.Add(new SqlParameter("@disE", filter.DisE.Value));
            }

            string sqlRoads = "SELECT R.RDID, R.TOWN, R.RDLV, R.RoadName, ISNULL(R.Dis, 0) AS Dis, ISNULL(R.Wid, 0) AS Wid FROM RoadClean_CheckPointMain R " + whereRoad.ToString() + " ORDER BY R.TOWN, R.RDLV, R.RoadName";
            DataTable dtRoads = DbHelper.ExecuteDataTable(sqlRoads, pRoadList.ToArray());

            StringBuilder whereChk = new StringBuilder(" WHERE M.ChkDate >= @chkS AND M.ChkDate <= @chkE ");
            List<SqlParameter> pChkList = new List<SqlParameter>();
            pChkList.Add(new SqlParameter("@chkS", dtS.ToString("yyyy-MM-dd 00:00:00")));
            pChkList.Add(new SqlParameter("@chkE", dtE.ToString("yyyy-MM-dd 23:59:59")));

            if (filter.Towns != null && filter.Towns.Count > 0)
            {
                List<string> tParams = new List<string>();
                for (int i = 0; i < filter.Towns.Count; i++)
                {
                    string p = "@ct_" + i;
                    tParams.Add(p);
                    pChkList.Add(new SqlParameter(p, filter.Towns[i]));
                }
                whereChk.Append(" AND R.TOWN IN (" + string.Join(",", tParams.ToArray()) + ") ");
            }

            if (!string.IsNullOrEmpty(filter.RoadName))
            {
                whereChk.Append(" AND R.RoadName LIKE @cRoadName ");
                pChkList.Add(new SqlParameter("@cRoadName", "%" + filter.RoadName.Trim() + "%"));
            }

            string sqlChecks = @"
                SELECT 
                    M.ChkID,
                    M.ChkRoadID,
                    M.ChkDate,
                    M.Case_State,
                    R.TOWN,
                    R.RoadName,
                    R.RDLV,
                    ISNULL(R.Dis, 0) AS Dis,
                    (SELECT AVG(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = M.ChkID AND PS.Chk_Code LIKE 'RCC%') AS RoadScore,
                    (SELECT SUM(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = M.ChkID AND PS.Chk_Code LIKE 'FLD%') 
                        / NULLIF((SELECT COUNT(*) FROM RoadClean_ChkRecord_PointMain PM WHERE PM.ChkID = M.ChkID), 0) AS FloodScore
                FROM RoadClean_ChkRecord_Main M
                INNER JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID " + whereChk.ToString() + @"
                ORDER BY M.ChkDate ASC, M.ChkID ASC";

            DataTable dtChecks = DbHelper.ExecuteDataTable(sqlChecks, pChkList.ToArray());

            Dictionary<string, DataRow> chkIndex = new Dictionary<string, DataRow>();
            foreach (DataRow row in dtChecks.Rows)
            {
                if (row["ChkDate"] != DBNull.Value && row["ChkRoadID"] != DBNull.Value)
                {
                    DateTime cDt = Convert.ToDateTime(row["ChkDate"]);
                    string rdid = row["ChkRoadID"].ToString().Trim();
                    string mKey = cDt.ToString("yyyy-MM");
                    string dictKey = rdid + "_" + mKey;
                    chkIndex[dictKey] = row;
                }
            }

            SumResultModel result = new SumResultModel();
            result.MonthCols = monthCols;

            Dictionary<string, CountStatRowModel> countStatsDict = new Dictionary<string, CountStatRowModel>();
            Dictionary<string, DisStatRowModel> disStatsDict = new Dictionary<string, DisStatRowModel>();
            foreach (MonthColModel m in monthCols)
            {
                CountStatRowModel cr = new CountStatRowModel();
                cr.Year = m.Year;
                cr.Month = m.Month;
                cr.MonthLabel = m.Label;
                countStatsDict[m.Key] = cr;

                DisStatRowModel dr = new DisStatRowModel();
                dr.Year = m.Year;
                dr.Month = m.Month;
                dr.MonthLabel = m.Label;
                disStatsDict[m.Key] = dr;
            }

            Dictionary<string, TownStatModel> townStatsDict = new Dictionary<string, TownStatModel>();

            int totalChecksCount = 0;
            int totalPassChecks = 0;

            foreach (DataRow rRow in dtRoads.Rows)
            {
                string rdid = rRow["RDID"].ToString().Trim();
                string town = rRow["TOWN"] != DBNull.Value ? rRow["TOWN"].ToString().Trim() : "";
                string rName = rRow["RoadName"] != DBNull.Value ? rRow["RoadName"].ToString().Trim() : "";
                string rLv = rRow["RDLV"] != DBNull.Value ? rRow["RDLV"].ToString().Trim() : "";

                double dis = 0;
                if (rRow["Dis"] != DBNull.Value)
                {
                    double.TryParse(rRow["Dis"].ToString(), out dis);
                }

                double wid = 0;
                if (rRow["Wid"] != DBNull.Value)
                {
                    double.TryParse(rRow["Wid"].ToString(), out wid);
                }

                if (!string.IsNullOrEmpty(town))
                {
                    if (!townStatsDict.ContainsKey(town))
                    {
                        TownStatModel tsm = new TownStatModel();
                        tsm.Town = town;
                        townStatsDict[town] = tsm;
                    }
                    TownStatModel currentTownStat = townStatsDict[town];
                    currentTownStat.RoadCount++;
                    currentTownStat.TotalDis += dis;
                }

                RoadRowModel roadItem = new RoadRowModel();
                roadItem.RDID = rdid;
                roadItem.Town = town;
                roadItem.RdLv = rLv;
                roadItem.RoadName = rName;
                roadItem.Dis = dis;
                roadItem.Wid = wid;

                int bcTimes = 0;

                foreach (MonthColModel m in monthCols)
                {
                    string key = m.Key;
                    string dictKey = rdid + "_" + key;

                    MonthGradeModel gRoad = new MonthGradeModel();
                    MonthGradeModel gFlood = new MonthGradeModel();

                    if (chkIndex.ContainsKey(dictKey))
                    {
                        DataRow cRow = chkIndex[dictKey];
                        totalChecksCount++;

                        string chkId = cRow["ChkID"].ToString().Trim();
                        DateTime cDate = Convert.ToDateTime(cRow["ChkDate"]);
                        gRoad.ChkID = chkId;
                        gRoad.ChkDate = cDate.ToString("yyyy-MM-dd");
                        gRoad.HasData = true;

                        gFlood.ChkID = chkId;
                        gFlood.ChkDate = cDate.ToString("yyyy-MM-dd");
                        gFlood.HasData = true;

                        if (cRow["RoadScore"] != DBNull.Value)
                        {
                            int sc = Convert.ToInt32(Math.Round(Convert.ToDouble(cRow["RoadScore"])));
                            gRoad.Score = sc;
                            if (sc >= 85)
                            {
                                gRoad.Grade = "A";
                                gRoad.ShowTxt = string.Format("A ({0})", sc);
                                countStatsDict[key].CountA++;
                                disStatsDict[key].DisA += dis;
                                if (!string.IsNullOrEmpty(town) && townStatsDict.ContainsKey(town))
                                {
                                    townStatsDict[town].CountA++;
                                    townStatsDict[town].DisA += dis;
                                }
                                totalPassChecks++;
                            }
                            else if (sc >= 60)
                            {
                                gRoad.Grade = "B";
                                gRoad.ShowTxt = string.Format("B ({0})", sc);
                                bcTimes++;
                                countStatsDict[key].CountB++;
                                disStatsDict[key].DisB += dis;
                                if (!string.IsNullOrEmpty(town) && townStatsDict.ContainsKey(town))
                                {
                                    townStatsDict[town].CountB++;
                                    townStatsDict[town].DisB += dis;
                                }
                            }
                            else
                            {
                                gRoad.Grade = "C";
                                gRoad.ShowTxt = string.Format("C ({0})", sc);
                                bcTimes++;
                                countStatsDict[key].CountC++;
                                disStatsDict[key].DisC += dis;
                                if (!string.IsNullOrEmpty(town) && townStatsDict.ContainsKey(town))
                                {
                                    townStatsDict[town].CountC++;
                                    townStatsDict[town].DisC += dis;
                                }
                            }
                        }

                        if (cRow["FloodScore"] != DBNull.Value)
                        {
                            int scF = Convert.ToInt32(Math.Round(Convert.ToDouble(cRow["FloodScore"])));
                            gFlood.Score = scF;
                            if (scF >= 85)
                            {
                                gFlood.Grade = "A";
                                gFlood.ShowTxt = string.Format("A ({0})", scF);
                            }
                            else if (scF >= 60)
                            {
                                gFlood.Grade = "B";
                                gFlood.ShowTxt = string.Format("B ({0})", scF);
                            }
                            else
                            {
                                gFlood.Grade = "C";
                                gFlood.ShowTxt = string.Format("C ({0})", scF);
                            }
                        }
                    }

                    roadItem.RoadScores[key] = gRoad;
                    roadItem.FloodScores[key] = gFlood;
                }

                roadItem.BcCount = bcTimes;
                result.RoadList.Add(roadItem);
            }

            foreach (MonthColModel m in monthCols)
            {
                CountStatRowModel cr = countStatsDict[m.Key];
                cr.CountTotal = cr.CountA + cr.CountB + cr.CountC;
                if (cr.CountTotal > 0)
                {
                    cr.PercentA = Math.Round((double)cr.CountA / cr.CountTotal * 100.0, 1);
                    cr.PercentB = Math.Round((double)cr.CountB / cr.CountTotal * 100.0, 1);
                    cr.PercentC = Math.Round((double)cr.CountC / cr.CountTotal * 100.0, 1);
                }
                result.CountStats.Add(cr);

                DisStatRowModel dr = disStatsDict[m.Key];
                dr.DisTotal = Math.Round(dr.DisA + dr.DisB + dr.DisC, 1);
                dr.DisA = Math.Round(dr.DisA, 1);
                dr.DisB = Math.Round(dr.DisB, 1);
                dr.DisC = Math.Round(dr.DisC, 1);
                if (dr.DisTotal > 0)
                {
                    dr.PercentA = Math.Round(dr.DisA / dr.DisTotal * 100.0, 1);
                    dr.PercentB = Math.Round(dr.DisB / dr.DisTotal * 100.0, 1);
                    dr.PercentC = Math.Round(dr.DisC / dr.DisTotal * 100.0, 1);
                }
                result.DisStats.Add(dr);
            }

            foreach (KeyValuePair<string, TownStatModel> kvp in townStatsDict)
            {
                TownStatModel t = kvp.Value;
                t.TotalDis = Math.Round(t.TotalDis, 1);
                t.DisA = Math.Round(t.DisA, 1);
                t.DisB = Math.Round(t.DisB, 1);
                t.DisC = Math.Round(t.DisC, 1);
                result.TownStats.Add(t);
            }

            result.TotalRoads = result.RoadList.Count;
            double sumDis = 0;
            for (int i = 0; i < result.RoadList.Count; i++)
            {
                sumDis += result.RoadList[i].Dis;
            }
            result.TotalDistance = Math.Round(sumDis, 1);
            result.TotalChecks = totalChecksCount;
            result.AvgPassRate = totalChecksCount > 0 ? Math.Round((double)totalPassChecks / totalChecksCount * 100.0, 1) : 0.0;

            return result;
        }

        private void GetSumData()
        {
            Response.ContentType = "application/json; charset=utf-8";

            SumFilterModel filter = ParseFilterFromRequest();
            SumResultModel result = CalculateSumData(filter);

            Response.Write(json.Serialize(new { Success = true, Data = result }));
        }

        private void GetChkDetail()
        {
            Response.ContentType = "application/json; charset=utf-8";

            string chkId = Request["chkId"];
            if (string.IsNullOrEmpty(chkId))
            {
                Response.Write(json.Serialize(new { Success = false, Message = "未提供查核單號" }));
                return;
            }

            string sqlMain = @"
                SELECT 
                    M.ChkID,
                    M.ChkDate,
                    M.Case_State,
                    M.Create_User,
                    M.Memo,
                    M.Sign_Img,
                    R.TOWN,
                    R.RoadName,
                    R.RDLV,
                    R.Dis,
                    R.ST_Road,
                    R.ED_Road,
                    (SELECT AVG(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = M.ChkID AND PS.Chk_Code LIKE 'RCC%') AS RoadScore,
                    (SELECT SUM(Score) FROM RoadClean_ChkRecord_PointScore PS WHERE PS.ChkID = M.ChkID AND PS.Chk_Code LIKE 'FLD%') 
                        / NULLIF((SELECT COUNT(*) FROM RoadClean_ChkRecord_PointMain PM WHERE PM.ChkID = M.ChkID), 0) AS FloodScore
                FROM RoadClean_ChkRecord_Main M
                LEFT JOIN RoadClean_CheckPointMain R ON M.ChkRoadID = R.RDID
                WHERE M.ChkID = @chkId";

            DataTable dtMain = DbHelper.ExecuteDataTable(sqlMain, new SqlParameter("@chkId", chkId));
            if (dtMain.Rows.Count == 0)
            {
                Response.Write(json.Serialize(new { Success = false, Message = "查無查核紀錄" }));
                return;
            }

            DataRow mRow = dtMain.Rows[0];

            string sqlPoints = @"
                SELECT 
                    PM.Point_ID,
                    CP.Point_Name,
                    CP.Lat,
                    CP.Lng,
                    PM.STree,
                    PM.SDrain,
                    PM.Point_Img
                FROM RoadClean_ChkRecord_PointMain PM
                LEFT JOIN RoadClean_CheckPointList CP ON PM.Point_ID = CP.Point_ID
                WHERE PM.ChkID = @chkId
                ORDER BY PM.Point_ID";

            DataTable dtPoints = DbHelper.ExecuteDataTable(sqlPoints, new SqlParameter("@chkId", chkId));

            string sqlScores = @"
                SELECT 
                    PS.Point_ID,
                    PS.Chk_Code,
                    PS.Score,
                    PS.Reason
                FROM RoadClean_ChkRecord_PointScore PS
                WHERE PS.ChkID = @chkId
                ORDER BY PS.Point_ID, PS.Chk_Code";

            DataTable dtScores = DbHelper.ExecuteDataTable(sqlScores, new SqlParameter("@chkId", chkId));

            List<object> pointsList = new List<object>();
            foreach (DataRow pRow in dtPoints.Rows)
            {
                string pId = pRow["Point_ID"].ToString().Trim();
                List<object> scoreItems = new List<object>();
                foreach (DataRow sRow in dtScores.Rows)
                {
                    if (sRow["Point_ID"].ToString().Trim() == pId)
                    {
                        scoreItems.Add(new
                        {
                            ChkCode = sRow["Chk_Code"].ToString().Trim(),
                            Score = Convert.ToInt32(sRow["Score"]),
                            Reason = sRow["Reason"] != DBNull.Value ? sRow["Reason"].ToString().Trim() : ""
                        });
                    }
                }

                pointsList.Add(new
                {
                    PointId = pId,
                    PointName = pRow["Point_Name"] != DBNull.Value ? pRow["Point_Name"].ToString().Trim() : "",
                    Lat = pRow["Lat"] != DBNull.Value ? pRow["Lat"].ToString() : "",
                    Lng = pRow["Lng"] != DBNull.Value ? pRow["Lng"].ToString() : "",
                    STree = pRow["STree"] != DBNull.Value ? pRow["STree"].ToString().Trim() : "",
                    SDrain = pRow["SDrain"] != DBNull.Value ? pRow["SDrain"].ToString().Trim() : "",
                    PointImg = pRow["Point_Img"] != DBNull.Value ? pRow["Point_Img"].ToString().Trim() : "",
                    Scores = scoreItems
                });
            }

            object detailData = new
            {
                ChkId = mRow["ChkID"].ToString().Trim(),
                ChkDate = mRow["ChkDate"] != DBNull.Value ? Convert.ToDateTime(mRow["ChkDate"]).ToString("yyyy-MM-dd") : "",
                Town = mRow["TOWN"] != DBNull.Value ? mRow["TOWN"].ToString().Trim() : "",
                RoadName = mRow["RoadName"] != DBNull.Value ? mRow["RoadName"].ToString().Trim() : "",
                RdLv = mRow["RDLV"] != DBNull.Value ? mRow["RDLV"].ToString().Trim() : "",
                Dis = mRow["Dis"] != DBNull.Value ? string.Format("{0:0.0}", mRow["Dis"]) : "0",
                RoadScore = mRow["RoadScore"] != DBNull.Value ? Convert.ToInt32(Math.Round(Convert.ToDouble(mRow["RoadScore"]))) : -1,
                FloodScore = mRow["FloodScore"] != DBNull.Value ? Convert.ToInt32(Math.Round(Convert.ToDouble(mRow["FloodScore"]))) : -1,
                CreateUser = mRow["Create_User"] != DBNull.Value ? mRow["Create_User"].ToString().Trim() : "",
                Memo = mRow["Memo"] != DBNull.Value ? mRow["Memo"].ToString().Trim() : "",
                SignImg = mRow["Sign_Img"] != DBNull.Value ? mRow["Sign_Img"].ToString().Trim() : "",
                Points = pointsList
            };

            Response.Write(json.Serialize(new { Success = true, Data = detailData }));
        }

        // =========================================================================
        // 原生 NPOI Excel (.xls) 匯出核心工具與方法 (無格式警告、無亂碼、多頁籤)
        // =========================================================================

        private ICellStyle CreateHeaderStyle(HSSFWorkbook wb, short bgColorIndex)
        {
            IFont font = wb.CreateFont();
            font.FontName = "微軟正黑體";
            font.FontHeightInPoints = 10;
            font.IsBold = true;
            font.Color = HSSFColor.White.Index;

            ICellStyle style = wb.CreateCellStyle();
            style.Alignment = HorizontalAlignment.Center;
            style.VerticalAlignment = VerticalAlignment.Center;
            style.FillForegroundColor = bgColorIndex;
            style.FillPattern = FillPattern.SolidForeground;
            style.BorderTop = BorderStyle.Thin;
            style.BorderBottom = BorderStyle.Thin;
            style.BorderLeft = BorderStyle.Thin;
            style.BorderRight = BorderStyle.Thin;
            style.WrapText = true;
            style.SetFont(font);
            return style;
        }

        private ICellStyle CreateDataStyle(HSSFWorkbook wb, short fontColorIndex, short bgColorIndex, bool isBold, HorizontalAlignment align)
        {
            IFont font = wb.CreateFont();
            font.FontName = "微軟正黑體";
            font.FontHeightInPoints = 10;
            font.IsBold = isBold;
            font.Color = fontColorIndex;

            ICellStyle style = wb.CreateCellStyle();
            style.Alignment = align;
            style.VerticalAlignment = VerticalAlignment.Center;
            if (bgColorIndex > 0)
            {
                style.FillForegroundColor = bgColorIndex;
                style.FillPattern = FillPattern.SolidForeground;
            }
            style.BorderTop = BorderStyle.Thin;
            style.BorderBottom = BorderStyle.Thin;
            style.BorderLeft = BorderStyle.Thin;
            style.BorderRight = BorderStyle.Thin;
            style.SetFont(font);
            return style;
        }

        private void SetMergedRegionBorder(ISheet sheet, CellRangeAddress region, ICellStyle style)
        {
            if (region.FirstRow < region.LastRow || region.FirstColumn < region.LastColumn)
            {
                sheet.AddMergedRegion(region);
            }
            for (int r = region.FirstRow; r <= region.LastRow; r++)
            {
                IRow row = sheet.GetRow(r);
                if (row == null) row = sheet.CreateRow(r);
                for (int c = region.FirstColumn; c <= region.LastColumn; c++)
                {
                    ICell cell = row.GetCell(c);
                    if (cell == null) cell = row.CreateCell(c);
                    cell.CellStyle = style;
                }
            }
        }

                private void WriteWorkbookToResponse(HSSFWorkbook workbook, string fileName)
        {
            using (MemoryStream ms = new MemoryStream())
            {
                workbook.Write(ms);
                byte[] bytes = ms.ToArray();

                Response.Clear();
                Response.ClearHeaders();
                Response.Buffer = true;
                Response.ContentType = "application/vnd.ms-excel";
                string encodedName = HttpUtility.UrlEncode(fileName, Encoding.UTF8).Replace("+", "%20");
                Response.AddHeader("Content-Disposition", "attachment; filename=" + encodedName);
                Response.AddHeader("Content-Length", bytes.Length.ToString());
                Response.BinaryWrite(bytes);
                Response.Flush();
                Response.SuppressContent = true;
                HttpContext.Current.ApplicationInstance.CompleteRequest();
            }
        }

        private void ExportRoads()
        {
            SumFilterModel filter = ParseFilterFromRequest();
            SumResultModel result = CalculateSumData(filter);

            List<RoadRowModel> targetRoads = new List<RoadRowModel>();
            for (int i = 0; i < result.RoadList.Count; i++)
            {
                if (!filter.OnlyBc || result.RoadList[i].BcCount > 0)
                {
                    targetRoads.Add(result.RoadList[i]);
                }
            }

            HSSFWorkbook wb = new HSSFWorkbook();

            // 自訂柔和色盤對齊現代化網頁配色
            HSSFPalette palette = wb.GetCustomPalette();
            palette.SetColorAtIndex(HSSFColor.RoyalBlue.Index, 2, 132, 199);      // #0284c7 科技藍
            palette.SetColorAtIndex(HSSFColor.Teal.Index, 13, 148, 136);          // #0d9488 防汛綠
            palette.SetColorAtIndex(HSSFColor.DarkRed.Index, 225, 29, 72);        // #e11d48 警示紅
            palette.SetColorAtIndex(HSSFColor.LightGreen.Index, 220, 252, 231);   // #dcfce7 A級淺綠底
            palette.SetColorAtIndex(HSSFColor.Green.Index, 21, 128, 61);          // #15803d A級深綠字
            palette.SetColorAtIndex(HSSFColor.LightYellow.Index, 254, 243, 199);  // #fef3c7 B級淺黃底
            palette.SetColorAtIndex(HSSFColor.Brown.Index, 180, 83, 9);           // #b45309 B級深橘字
            palette.SetColorAtIndex(HSSFColor.Rose.Index, 254, 226, 226);         // #fee2e2 C級淺紅底
            palette.SetColorAtIndex(HSSFColor.Red.Index, 185, 28, 28);            // #b91c1c C級深紅字

            ICellStyle styleThPrimary = CreateHeaderStyle(wb, HSSFColor.RoyalBlue.Index);
            ICellStyle styleThFlood = CreateHeaderStyle(wb, HSSFColor.Teal.Index);
            ICellStyle styleThAlert = CreateHeaderStyle(wb, HSSFColor.DarkRed.Index);

            ICellStyle styleNormal = CreateDataStyle(wb, HSSFColor.Black.Index, 0, false, HorizontalAlignment.Center);
            ICellStyle styleRoadLeft = CreateDataStyle(wb, HSSFColor.Black.Index, 0, true, HorizontalAlignment.Left);
            ICellStyle styleGradeA = CreateDataStyle(wb, HSSFColor.Green.Index, HSSFColor.LightGreen.Index, true, HorizontalAlignment.Center);
            ICellStyle styleGradeB = CreateDataStyle(wb, HSSFColor.Brown.Index, HSSFColor.LightYellow.Index, true, HorizontalAlignment.Center);
            ICellStyle styleGradeC = CreateDataStyle(wb, HSSFColor.Red.Index, HSSFColor.Rose.Index, true, HorizontalAlignment.Center);

            int mCount = result.MonthCols.Count;
            string[] baseHeaders = new string[] { "行政區", "道路級別", "道路名稱", "巡查長度(km)", "B級(含以下)累計次數" };

            // =========================================================================
            // Sheet 1: 道路潔淨度巡檢成果表 (與網頁預設畫面一致，適合直接 A4 橫印)
            // =========================================================================
            ISheet sheetClean = wb.CreateSheet("1_道路潔淨度成果");
            IRow scHead = sheetClean.CreateRow(0);
            scHead.HeightInPoints = 26;

            for (int i = 0; i < baseHeaders.Length; i++)
            {
                ICell ch = scHead.CreateCell(i);
                ch.SetCellValue(baseHeaders[i]);
                ch.CellStyle = i == 4 ? styleThAlert : styleThPrimary;
            }
            for (int i = 0; i < mCount; i++)
            {
                ICell ch = scHead.CreateCell(5 + i);
                ch.SetCellValue(result.MonthCols[i].Label + "\n道路潔淨");
                ch.CellStyle = styleThPrimary;
            }

            for (int rIdx = 0; rIdx < targetRoads.Count; rIdx++)
            {
                RoadRowModel road = targetRoads[rIdx];
                IRow row = sheetClean.CreateRow(1 + rIdx);
                row.HeightInPoints = 20;

                ICell c0 = row.CreateCell(0); c0.SetCellValue(road.Town); c0.CellStyle = styleNormal;
                ICell c1 = row.CreateCell(1); c1.SetCellValue(road.RdLv); c1.CellStyle = styleNormal;
                ICell c2 = row.CreateCell(2); c2.SetCellValue(road.RoadName); c2.CellStyle = styleRoadLeft;
                ICell c3 = row.CreateCell(3); c3.SetCellValue(Math.Round(road.Dis, 1)); c3.CellStyle = styleNormal;
                ICell c4 = row.CreateCell(4); c4.SetCellValue(road.BcCount); c4.CellStyle = road.BcCount > 0 ? styleGradeC : styleNormal;

                for (int mIdx = 0; mIdx < mCount; mIdx++)
                {
                    MonthGradeModel gClean = road.RoadScores.ContainsKey(result.MonthCols[mIdx].Key) ? road.RoadScores[result.MonthCols[mIdx].Key] : new MonthGradeModel();
                    ICell cellC = row.CreateCell(5 + mIdx);
                    cellC.SetCellValue(gClean != null && gClean.ShowTxt != null ? gClean.ShowTxt : "");
                    if (gClean.Grade == "A") cellC.CellStyle = styleGradeA;
                    else if (gClean.Grade == "B") cellC.CellStyle = styleGradeB;
                    else if (gClean.Grade == "C") cellC.CellStyle = styleGradeC;
                    else cellC.CellStyle = styleNormal;
                }
            }

            sheetClean.SetColumnWidth(0, 11 * 256);
            sheetClean.SetColumnWidth(1, 11 * 256);
            sheetClean.SetColumnWidth(2, 22 * 256);
            sheetClean.SetColumnWidth(3, 14 * 256);
            sheetClean.SetColumnWidth(4, 18 * 256);
            for (int i = 0; i < mCount; i++)
            {
                sheetClean.SetColumnWidth(5 + i, 13 * 256);
            }
            sheetClean.CreateFreezePane(5, 1);

            // =========================================================================
            // Sheet 2: 防汛期側溝巡檢成果表
            // =========================================================================
            ISheet sheetFlood = wb.CreateSheet("2_防汛期側溝成果");
            IRow sfHead = sheetFlood.CreateRow(0);
            sfHead.HeightInPoints = 26;

            for (int i = 0; i < 4; i++)
            {
                ICell ch = sfHead.CreateCell(i);
                ch.SetCellValue(baseHeaders[i]);
                ch.CellStyle = styleThFlood;
            }
            for (int i = 0; i < mCount; i++)
            {
                ICell ch = sfHead.CreateCell(4 + i);
                ch.SetCellValue(result.MonthCols[i].Label + "\n防汛側溝");
                ch.CellStyle = styleThFlood;
            }

            for (int rIdx = 0; rIdx < targetRoads.Count; rIdx++)
            {
                RoadRowModel road = targetRoads[rIdx];
                IRow row = sheetFlood.CreateRow(1 + rIdx);
                row.HeightInPoints = 20;

                ICell c0 = row.CreateCell(0); c0.SetCellValue(road.Town); c0.CellStyle = styleNormal;
                ICell c1 = row.CreateCell(1); c1.SetCellValue(road.RdLv); c1.CellStyle = styleNormal;
                ICell c2 = row.CreateCell(2); c2.SetCellValue(road.RoadName); c2.CellStyle = styleRoadLeft;
                ICell c3 = row.CreateCell(3); c3.SetCellValue(Math.Round(road.Dis, 1)); c3.CellStyle = styleNormal;

                for (int mIdx = 0; mIdx < mCount; mIdx++)
                {
                    MonthGradeModel gFlood = road.FloodScores.ContainsKey(result.MonthCols[mIdx].Key) ? road.FloodScores[result.MonthCols[mIdx].Key] : new MonthGradeModel();
                    ICell cellF = row.CreateCell(4 + mIdx);
                    cellF.SetCellValue(gFlood != null && gFlood.ShowTxt != null ? gFlood.ShowTxt : "");
                    if (gFlood.Grade == "A") cellF.CellStyle = styleGradeA;
                    else if (gFlood.Grade == "B") cellF.CellStyle = styleGradeB;
                    else if (gFlood.Grade == "C") cellF.CellStyle = styleGradeC;
                    else cellF.CellStyle = styleNormal;
                }
            }

            sheetFlood.SetColumnWidth(0, 11 * 256);
            sheetFlood.SetColumnWidth(1, 11 * 256);
            sheetFlood.SetColumnWidth(2, 22 * 256);
            sheetFlood.SetColumnWidth(3, 14 * 256);
            for (int i = 0; i < mCount; i++)
            {
                sheetFlood.SetColumnWidth(4 + i, 13 * 256);
            }
            sheetFlood.CreateFreezePane(4, 1);

            // =========================================================================
            // Sheet 3: 綜合對照總表 (道路潔淨度 + 防汛期側溝 雙表完整展開)
            // =========================================================================
            ISheet sheetAll = wb.CreateSheet("3_綜合對照總表(潔淨+側溝)");
            IRow r0 = sheetAll.CreateRow(0);
            IRow r1 = sheetAll.CreateRow(1);
            IRow r2 = sheetAll.CreateRow(2);
            r0.HeightInPoints = 22;
            r1.HeightInPoints = 20;
            r2.HeightInPoints = 20;

            r0.CreateCell(0).SetCellValue("行政區");
            r0.CreateCell(1).SetCellValue("道路級別");
            r0.CreateCell(2).SetCellValue("道路名稱");
            r0.CreateCell(3).SetCellValue("巡查距離(km)");

            SetMergedRegionBorder(sheetAll, new CellRangeAddress(0, 2, 0, 0), styleThPrimary);
            SetMergedRegionBorder(sheetAll, new CellRangeAddress(0, 2, 1, 1), styleThPrimary);
            SetMergedRegionBorder(sheetAll, new CellRangeAddress(0, 2, 2, 2), styleThPrimary);
            SetMergedRegionBorder(sheetAll, new CellRangeAddress(0, 2, 3, 3), styleThPrimary);

            if (mCount > 0)
            {
                r0.CreateCell(4).SetCellValue("道路潔淨度巡檢成果");
                SetMergedRegionBorder(sheetAll, new CellRangeAddress(0, 0, 4, 4 + mCount - 1), styleThPrimary);

                r0.CreateCell(4 + mCount).SetCellValue("防汛期側溝巡檢成果");
                SetMergedRegionBorder(sheetAll, new CellRangeAddress(0, 0, 4 + mCount, 4 + mCount * 2 - 1), styleThFlood);

                for (int i = 0; i < mCount; i++)
                {
                    MonthColModel m = result.MonthCols[i];
                    ICell cCleanM = r1.CreateCell(4 + i);
                    cCleanM.SetCellValue(m.Label);
                    cCleanM.CellStyle = styleThPrimary;

                    ICell cCleanSub = r2.CreateCell(4 + i);
                    cCleanSub.SetCellValue("評級(分)");
                    cCleanSub.CellStyle = styleThPrimary;

                    ICell cFloodM = r1.CreateCell(4 + mCount + i);
                    cFloodM.SetCellValue(m.Label);
                    cFloodM.CellStyle = styleThFlood;

                    ICell cFloodSub = r2.CreateCell(4 + mCount + i);
                    cFloodSub.SetCellValue("評級(分)");
                    cFloodSub.CellStyle = styleThFlood;
                }
            }

            int bcColIdx = 4 + mCount * 2;
            r0.CreateCell(bcColIdx).SetCellValue("B級(或以下)\n月份次數");
            SetMergedRegionBorder(sheetAll, new CellRangeAddress(0, 2, bcColIdx, bcColIdx), styleThAlert);

            for (int rIdx = 0; rIdx < targetRoads.Count; rIdx++)
            {
                RoadRowModel road = targetRoads[rIdx];
                IRow row = sheetAll.CreateRow(3 + rIdx);
                row.HeightInPoints = 20;

                ICell c0 = row.CreateCell(0); c0.SetCellValue(road.Town); c0.CellStyle = styleNormal;
                ICell c1 = row.CreateCell(1); c1.SetCellValue(road.RdLv); c1.CellStyle = styleNormal;
                ICell c2 = row.CreateCell(2); c2.SetCellValue(road.RoadName); c2.CellStyle = styleRoadLeft;
                ICell c3 = row.CreateCell(3); c3.SetCellValue(Math.Round(road.Dis, 1)); c3.CellStyle = styleNormal;

                for (int mIdx = 0; mIdx < mCount; mIdx++)
                {
                    string mKey = result.MonthCols[mIdx].Key;
                    MonthGradeModel gClean = road.RoadScores.ContainsKey(mKey) ? road.RoadScores[mKey] : new MonthGradeModel();
                    ICell cellC = row.CreateCell(4 + mIdx);
                    cellC.SetCellValue(gClean != null && gClean.ShowTxt != null ? gClean.ShowTxt : "");
                    if (gClean.Grade == "A") cellC.CellStyle = styleGradeA;
                    else if (gClean.Grade == "B") cellC.CellStyle = styleGradeB;
                    else if (gClean.Grade == "C") cellC.CellStyle = styleGradeC;
                    else cellC.CellStyle = styleNormal;

                    MonthGradeModel gFlood = road.FloodScores.ContainsKey(mKey) ? road.FloodScores[mKey] : new MonthGradeModel();
                    ICell cellF = row.CreateCell(4 + mCount + mIdx);
                    cellF.SetCellValue(gFlood != null && gFlood.ShowTxt != null ? gFlood.ShowTxt : "");
                    if (gFlood.Grade == "A") cellF.CellStyle = styleGradeA;
                    else if (gFlood.Grade == "B") cellF.CellStyle = styleGradeB;
                    else if (gFlood.Grade == "C") cellF.CellStyle = styleGradeC;
                    else cellF.CellStyle = styleNormal;
                }

                ICell cellBc = row.CreateCell(bcColIdx);
                cellBc.SetCellValue(road.BcCount);
                cellBc.CellStyle = road.BcCount > 0 ? styleGradeC : styleNormal;
            }

            sheetAll.SetColumnWidth(0, 11 * 256);
            sheetAll.SetColumnWidth(1, 11 * 256);
            sheetAll.SetColumnWidth(2, 22 * 256);
            sheetAll.SetColumnWidth(3, 14 * 256);
            for (int i = 0; i < mCount * 2; i++)
            {
                sheetAll.SetColumnWidth(4 + i, 13 * 256);
            }
            sheetAll.SetColumnWidth(bcColIdx, 15 * 256);
            sheetAll.CreateFreezePane(4, 3);

            // 根據前端當前選擇的檢視模式自動設定開啟時聚焦的 Sheet
            if (filter.MatrixMode == "flood")
            {
                wb.SetActiveSheet(1);
            }
            else if (filter.MatrixMode == "both")
            {
                wb.SetActiveSheet(2);
            }
            else
            {
                wb.SetActiveSheet(0);
            }

            string fileName = string.Format("道路清淨巡檢執行成果表_{0}.xls", DateTime.Now.ToString("yyyyMMddHHmmss"));
            WriteWorkbookToResponse(wb, fileName);
        }

        private void ExportCounts()
        {
            SumFilterModel filter = ParseFilterFromRequest();
            SumResultModel result = CalculateSumData(filter);

            HSSFWorkbook wb = new HSSFWorkbook();
            HSSFPalette palette = wb.GetCustomPalette();
            palette.SetColorAtIndex(HSSFColor.RoyalBlue.Index, 2, 132, 199);
            palette.SetColorAtIndex(HSSFColor.SeaGreen.Index, 13, 148, 136);

            ICellStyle styleThPrimary = CreateHeaderStyle(wb, HSSFColor.RoyalBlue.Index);
            ICellStyle styleThPct = CreateHeaderStyle(wb, HSSFColor.SeaGreen.Index);
            ICellStyle styleNormal = CreateDataStyle(wb, HSSFColor.Black.Index, 0, false, HorizontalAlignment.Center);
            ICellStyle styleBold = CreateDataStyle(wb, HSSFColor.Black.Index, HSSFColor.Grey25Percent.Index, true, HorizontalAlignment.Center);

            ISheet sheet = wb.CreateSheet("道路數分析統計表");
            IRow r0 = sheet.CreateRow(0);
            IRow r1 = sheet.CreateRow(1);
            r0.HeightInPoints = 22;
            r1.HeightInPoints = 20;

            r0.CreateCell(0).SetCellValue("年份");
            r0.CreateCell(1).SetCellValue("月份");
            r0.CreateCell(2).SetCellValue("各級道路數 (條)");
            r0.CreateCell(6).SetCellValue("各級道路數百分比 (%)");

            SetMergedRegionBorder(sheet, new CellRangeAddress(0, 1, 0, 0), styleThPrimary);
            SetMergedRegionBorder(sheet, new CellRangeAddress(0, 1, 1, 1), styleThPrimary);
            SetMergedRegionBorder(sheet, new CellRangeAddress(0, 0, 2, 5), styleThPrimary);
            SetMergedRegionBorder(sheet, new CellRangeAddress(0, 0, 6, 9), styleThPct);

            string[] subCols = new string[] { "A級", "B級", "C級", "合計" };
            for (int i = 0; i < 4; i++)
            {
                ICell cCount = r1.CreateCell(2 + i);
                cCount.SetCellValue(subCols[i]);
                cCount.CellStyle = styleThPrimary;

                ICell cPct = r1.CreateCell(6 + i);
                cPct.SetCellValue(subCols[i]);
                cPct.CellStyle = styleThPct;
            }

            int sumA = 0, sumB = 0, sumC = 0, sumTot = 0;
            for (int i = 0; i < result.CountStats.Count; i++)
            {
                CountStatRowModel cr = result.CountStats[i];
                sumA += cr.CountA;
                sumB += cr.CountB;
                sumC += cr.CountC;
                sumTot += cr.CountTotal;

                IRow row = sheet.CreateRow(2 + i);
                row.HeightInPoints = 19;

                ICell c0 = row.CreateCell(0); c0.SetCellValue(cr.Year); c0.CellStyle = styleNormal;
                ICell c1 = row.CreateCell(1); c1.SetCellValue(string.Format("{0}月", cr.Month)); c1.CellStyle = styleNormal;
                ICell c2 = row.CreateCell(2); c2.SetCellValue(cr.CountA); c2.CellStyle = styleNormal;
                ICell c3 = row.CreateCell(3); c3.SetCellValue(cr.CountB); c3.CellStyle = styleNormal;
                ICell c4 = row.CreateCell(4); c4.SetCellValue(cr.CountC); c4.CellStyle = styleNormal;
                ICell c5 = row.CreateCell(5); c5.SetCellValue(cr.CountTotal); c5.CellStyle = styleNormal;
                ICell c6 = row.CreateCell(6); c6.SetCellValue(string.Format("{0:0.0}%", cr.PercentA)); c6.CellStyle = styleNormal;
                ICell c7 = row.CreateCell(7); c7.SetCellValue(string.Format("{0:0.0}%", cr.PercentB)); c7.CellStyle = styleNormal;
                ICell c8 = row.CreateCell(8); c8.SetCellValue(string.Format("{0:0.0}%", cr.PercentC)); c8.CellStyle = styleNormal;
                ICell c9 = row.CreateCell(9); c9.SetCellValue("100.0%"); c9.CellStyle = styleNormal;
            }

            double totPctA = sumTot > 0 ? Math.Round((double)sumA / sumTot * 100.0, 1) : 0.0;
            double totPctB = sumTot > 0 ? Math.Round((double)sumB / sumTot * 100.0, 1) : 0.0;
            double totPctC = sumTot > 0 ? Math.Round((double)sumC / sumTot * 100.0, 1) : 0.0;

            int totRowIdx = 2 + result.CountStats.Count;
            IRow totRow = sheet.CreateRow(totRowIdx);
            totRow.HeightInPoints = 20;
            totRow.CreateCell(0).SetCellValue("全期累計 / 平均");
            SetMergedRegionBorder(sheet, new CellRangeAddress(totRowIdx, totRowIdx, 0, 1), styleBold);

            ICell tc2 = totRow.CreateCell(2); tc2.SetCellValue(sumA); tc2.CellStyle = styleBold;
            ICell tc3 = totRow.CreateCell(3); tc3.SetCellValue(sumB); tc3.CellStyle = styleBold;
            ICell tc4 = totRow.CreateCell(4); tc4.SetCellValue(sumC); tc4.CellStyle = styleBold;
            ICell tc5 = totRow.CreateCell(5); tc5.SetCellValue(sumTot); tc5.CellStyle = styleBold;
            ICell tc6 = totRow.CreateCell(6); tc6.SetCellValue(string.Format("{0:0.0}%", totPctA)); tc6.CellStyle = styleBold;
            ICell tc7 = totRow.CreateCell(7); tc7.SetCellValue(string.Format("{0:0.0}%", totPctB)); tc7.CellStyle = styleBold;
            ICell tc8 = totRow.CreateCell(8); tc8.SetCellValue(string.Format("{0:0.0}%", totPctC)); tc8.CellStyle = styleBold;
            ICell tc9 = totRow.CreateCell(9); tc9.SetCellValue("100.0%"); tc9.CellStyle = styleBold;

            for (int c = 0; c < 10; c++)
            {
                sheet.SetColumnWidth(c, 13 * 256);
            }

            string fileName = string.Format("道路潔淨度_道路數分析統計表_{0}.xls", DateTime.Now.ToString("yyyyMMddHHmmss"));
            WriteWorkbookToResponse(wb, fileName);
        }

        private void ExportLengths()
        {
            SumFilterModel filter = ParseFilterFromRequest();
            SumResultModel result = CalculateSumData(filter);

            HSSFWorkbook wb = new HSSFWorkbook();
            HSSFPalette palette = wb.GetCustomPalette();
            palette.SetColorAtIndex(HSSFColor.RoyalBlue.Index, 2, 132, 199);
            palette.SetColorAtIndex(HSSFColor.SeaGreen.Index, 13, 148, 136);

            ICellStyle styleThPrimary = CreateHeaderStyle(wb, HSSFColor.RoyalBlue.Index);
            ICellStyle styleThPct = CreateHeaderStyle(wb, HSSFColor.SeaGreen.Index);
            ICellStyle styleNormal = CreateDataStyle(wb, HSSFColor.Black.Index, 0, false, HorizontalAlignment.Center);
            ICellStyle styleBold = CreateDataStyle(wb, HSSFColor.Black.Index, HSSFColor.Grey25Percent.Index, true, HorizontalAlignment.Center);

            ISheet sheet = wb.CreateSheet("道路長度分析統計表");
            IRow r0 = sheet.CreateRow(0);
            IRow r1 = sheet.CreateRow(1);
            r0.HeightInPoints = 22;
            r1.HeightInPoints = 20;

            r0.CreateCell(0).SetCellValue("年份");
            r0.CreateCell(1).SetCellValue("月份");
            r0.CreateCell(2).SetCellValue("各級道路長度 (公里)");
            r0.CreateCell(6).SetCellValue("各級道路長度百分比 (%)");

            SetMergedRegionBorder(sheet, new CellRangeAddress(0, 1, 0, 0), styleThPrimary);
            SetMergedRegionBorder(sheet, new CellRangeAddress(0, 1, 1, 1), styleThPrimary);
            SetMergedRegionBorder(sheet, new CellRangeAddress(0, 0, 2, 5), styleThPrimary);
            SetMergedRegionBorder(sheet, new CellRangeAddress(0, 0, 6, 9), styleThPct);

            string[] subCols = new string[] { "A級", "B級", "C級", "合計" };
            for (int i = 0; i < 4; i++)
            {
                ICell cDis = r1.CreateCell(2 + i);
                cDis.SetCellValue(subCols[i]);
                cDis.CellStyle = styleThPrimary;

                ICell cPct = r1.CreateCell(6 + i);
                cPct.SetCellValue(subCols[i]);
                cPct.CellStyle = styleThPct;
            }

            double sumA = 0, sumB = 0, sumC = 0, sumTot = 0;
            for (int i = 0; i < result.DisStats.Count; i++)
            {
                DisStatRowModel dr = result.DisStats[i];
                sumA += dr.DisA;
                sumB += dr.DisB;
                sumC += dr.DisC;
                sumTot += dr.DisTotal;

                IRow row = sheet.CreateRow(2 + i);
                row.HeightInPoints = 19;

                ICell c0 = row.CreateCell(0); c0.SetCellValue(dr.Year); c0.CellStyle = styleNormal;
                ICell c1 = row.CreateCell(1); c1.SetCellValue(string.Format("{0}月", dr.Month)); c1.CellStyle = styleNormal;
                ICell c2 = row.CreateCell(2); c2.SetCellValue(Math.Round(dr.DisA, 1)); c2.CellStyle = styleNormal;
                ICell c3 = row.CreateCell(3); c3.SetCellValue(Math.Round(dr.DisB, 1)); c3.CellStyle = styleNormal;
                ICell c4 = row.CreateCell(4); c4.SetCellValue(Math.Round(dr.DisC, 1)); c4.CellStyle = styleNormal;
                ICell c5 = row.CreateCell(5); c5.SetCellValue(Math.Round(dr.DisTotal, 1)); c5.CellStyle = styleNormal;
                ICell c6 = row.CreateCell(6); c6.SetCellValue(string.Format("{0:0.0}%", dr.PercentA)); c6.CellStyle = styleNormal;
                ICell c7 = row.CreateCell(7); c7.SetCellValue(string.Format("{0:0.0}%", dr.PercentB)); c7.CellStyle = styleNormal;
                ICell c8 = row.CreateCell(8); c8.SetCellValue(string.Format("{0:0.0}%", dr.PercentC)); c8.CellStyle = styleNormal;
                ICell c9 = row.CreateCell(9); c9.SetCellValue("100.0%"); c9.CellStyle = styleNormal;
            }

            double totPctA = sumTot > 0 ? Math.Round(sumA / sumTot * 100.0, 1) : 0.0;
            double totPctB = sumTot > 0 ? Math.Round(sumB / sumTot * 100.0, 1) : 0.0;
            double totPctC = sumTot > 0 ? Math.Round(sumC / sumTot * 100.0, 1) : 0.0;

            int totRowIdx = 2 + result.DisStats.Count;
            IRow totRow = sheet.CreateRow(totRowIdx);
            totRow.HeightInPoints = 20;
            totRow.CreateCell(0).SetCellValue("全期累計 / 平均");
            SetMergedRegionBorder(sheet, new CellRangeAddress(totRowIdx, totRowIdx, 0, 1), styleBold);

            ICell tc2 = totRow.CreateCell(2); tc2.SetCellValue(Math.Round(sumA, 1)); tc2.CellStyle = styleBold;
            ICell tc3 = totRow.CreateCell(3); tc3.SetCellValue(Math.Round(sumB, 1)); tc3.CellStyle = styleBold;
            ICell tc4 = totRow.CreateCell(4); tc4.SetCellValue(Math.Round(sumC, 1)); tc4.CellStyle = styleBold;
            ICell tc5 = totRow.CreateCell(5); tc5.SetCellValue(Math.Round(sumTot, 1)); tc5.CellStyle = styleBold;
            ICell tc6 = totRow.CreateCell(6); tc6.SetCellValue(string.Format("{0:0.0}%", totPctA)); tc6.CellStyle = styleBold;
            ICell tc7 = totRow.CreateCell(7); tc7.SetCellValue(string.Format("{0:0.0}%", totPctB)); tc7.CellStyle = styleBold;
            ICell tc8 = totRow.CreateCell(8); tc8.SetCellValue(string.Format("{0:0.0}%", totPctC)); tc8.CellStyle = styleBold;
            ICell tc9 = totRow.CreateCell(9); tc9.SetCellValue("100.0%"); tc9.CellStyle = styleBold;

            for (int c = 0; c < 10; c++)
            {
                sheet.SetColumnWidth(c, 13 * 256);
            }

            string fileName = string.Format("道路潔淨度_道路長度分析統計表_{0}.xls", DateTime.Now.ToString("yyyyMMddHHmmss"));
            WriteWorkbookToResponse(wb, fileName);
        }
    }
}
