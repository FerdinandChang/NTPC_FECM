using System;
using System.Collections.Generic;
using System.Data;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using NTPC_FEC.Helpers;

namespace NTPC_FEC.NDVI
{
    /// <summary>
    /// 新北市 NDVI 植被監測 (Sentinel-2 月報圖磚 + Leaflet)
    /// 圖磚由排程 (NdviJob/ndvi_build.py) 產生於 NDVI/Tiles/，本頁僅負責登入檢查與裸露地點位 API。
    /// </summary>
    public partial class NdviMap : Page
    {
        private JavaScriptSerializer json;

        public NdviMap()
        {
            json = new JavaScriptSerializer();
            json.MaxJsonLength = int.MaxValue;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["LoginUser"] == null || string.IsNullOrEmpty(Session["LoginUser"].ToString()))
            {
                string action0 = Request["action"];
                if (!string.IsNullOrEmpty(action0))
                {
                    Response.Clear();
                    Response.StatusCode = 401;
                    Response.ContentType = "application/json; charset=utf-8";
                    Response.Write(json.Serialize(new { Success = false, Message = "登入逾時，請重新登入" }));
                    Response.End();
                    return;
                }
                Response.Redirect("~/Default.aspx", true);
                return;
            }

            string action = Request["action"];
            if (!string.IsNullOrEmpty(action))
            {
                Response.Clear();
                Response.ContentType = "application/json; charset=utf-8";
                Response.Cache.SetCacheability(HttpCacheability.NoCache);
                try
                {
                    switch (action.ToLower())
                    {
                        case "getpoints":
                            GetPoints();
                            break;
                        default:
                            Response.Write(json.Serialize(new { Success = false, Message = "未知的動作" }));
                            break;
                    }
                }
                catch (Exception ex)
                {
                    Response.Write(json.Serialize(new { Success = false, Message = "執行錯誤：" + ex.Message }));
                }
                Response.End();
            }
        }

        /// <summary>
        /// 取得裸露地列管點位 (WGS84)，供前端與 NDVI 圖磚交叉分析。
        /// </summary>
        private void GetPoints()
        {
            string sql = @"
                SELECT
                    bm.Bare_ID,
                    ISNULL(bm.BareGroundNo, '--') AS BareGroundNo,
                    ISNULL(bm.ADDR, '--') AS ADDR,
                    ISNULL(bm.LAND_USE, '--') AS LAND_USE,
                    bm.latitude,
                    bm.longtitude,
                    (SELECT TOP 1 bi.Check_DATE FROM Bare_INV bi WHERE bi.Bare_ID = bm.Bare_ID AND bi.INV_State != 'Z00' ORDER BY bi.Check_DATE DESC, bi.INV_NO DESC) AS Last_Check_Date
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

                // 座標若為 TWD97 (公尺) 則轉為 WGS84
                if (lat > 1000 && lng > 1000)
                {
                    double wLat, wLon;
                    Twd97ToWgs84(lat, lng, out wLat, out wLon);
                    lat = wLat;
                    lng = wLon;
                }

                if (lat < 24.5 || lat > 25.5 || lng < 121.0 || lng > 122.2) continue;

                string cdate = "--";
                if (r["Last_Check_Date"] != DBNull.Value)
                {
                    cdate = Convert.ToDateTime(r["Last_Check_Date"]).ToString("yyyy/MM/dd");
                }

                markers.Add(new
                {
                    Id = r["Bare_ID"].ToString(),
                    No = r["BareGroundNo"].ToString(),
                    Addr = r["ADDR"].ToString(),
                    LandUse = r["LAND_USE"].ToString(),
                    Lat = Math.Round(lat, 6),
                    Lng = Math.Round(lng, 6),
                    LastDate = cdate
                });
            }

            Response.Write(json.Serialize(new { Success = true, Markers = markers }));
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
    }
}
