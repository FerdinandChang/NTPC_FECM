using System;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// ?典?獢??璅??????脣?頛憿 (TWD97 鈭漲?葆 / WGS84 蝬楝摨?
    /// ?詨捆 C# 5.0 閬?
    /// </summary>
    public static class GeoCoordHelper
    {
        private const double A = 6378137.0;
        private const double B = 6356752.314245;
        private const double Lon0 = 121.0 * Math.PI / 180.0;
        private const double K0 = 0.9999;
        private const double Dx = 250000.0;

        /// <summary>
        /// TWD97 (璈怠?璅?X, 蝮勗?璅?Y) 頧?WGS84 (蝺臬漲 Lat, 蝬漲 Lng)
        /// </summary>
        public static void Twd97ToWgs84(double x, double y, out double lat, out double lon)
        {
            if (x <= 0 || y <= 0)
            {
                lat = 0;
                lon = 0;
                return;
            }

            double e = Math.Sqrt(1.0 - (B * B) / (A * A));
            double e2 = e * e / (1.0 - e * e);
            double xCoord = x - Dx;

            double m = y / K0;
            double mu = m / (A * (1.0 - Math.Pow(e, 2) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0));
            double e1 = (1.0 - Math.Sqrt(1.0 - Math.Pow(e, 2))) / (1.0 + Math.Sqrt(1.0 - Math.Pow(e, 2)));

            double j1 = (3.0 * e1 / 2.0 - 27.0 * Math.Pow(e1, 3) / 32.0);
            double j2 = (21.0 * Math.Pow(e1, 2) / 16.0 - 55.0 * Math.Pow(e1, 4) / 32.0);
            double j3 = (151.0 * Math.Pow(e1, 3) / 96.0);
            double j4 = (1097.0 * Math.Pow(e1, 4) / 512.0);

            double fp = mu + j1 * Math.Sin(2.0 * mu) + j2 * Math.Sin(4.0 * mu) + j3 * Math.Sin(6.0 * mu) + j4 * Math.Sin(8.0 * mu);

            double c1 = e2 * Math.Pow(Math.Cos(fp), 2);
            double t1 = Math.Pow(Math.Tan(fp), 2);
            double r1 = A * (1.0 - Math.Pow(e, 2)) / Math.Pow(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2), 1.5);
            double n1 = A / Math.Sqrt(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(fp), 2));
            double d = xCoord / (n1 * K0);

            double latRad = fp - (n1 * Math.Tan(fp) / r1) * (Math.Pow(d, 2) / 2.0 - (5.0 + 3.0 * t1 + 10.0 * c1 - 4.0 * Math.Pow(c1, 2) - 9.0 * e2) * Math.Pow(d, 4) / 24.0 + (61.0 + 90.0 * t1 + 298.0 * c1 + 45.0 * Math.Pow(t1, 2) - 252.0 * e2 - 3.0 * Math.Pow(c1, 2)) * Math.Pow(d, 6) / 720.0);
            double lonRad = Lon0 + (d - (1.0 + 2.0 * t1 + c1) * Math.Pow(d, 3) / 6.0 + (5.0 - 2.0 * c1 + 28.0 * t1 - 3.0 * Math.Pow(c1, 2) + 8.0 * e2 + 24.0 * Math.Pow(t1, 2)) * Math.Pow(d, 5) / 120.0) / Math.Cos(fp);

            lat = latRad * 180.0 / Math.PI;
            lon = lonRad * 180.0 / Math.PI;
        }

        /// <summary>
        /// WGS84 (蝺臬漲 Lat, 蝬漲 Lng) 頧?TWD97 (璈怠?璅?X, 蝮勗?璅?Y)
        /// </summary>
        public static void Wgs84ToTwd97(double lat, double lon, out double x, out double y)
        {
            if (lat <= 0 || lon <= 0)
            {
                x = 0;
                y = 0;
                return;
            }

            double latRad = lat * Math.PI / 180.0;
            double lonRad = lon * Math.PI / 180.0;

            double e = Math.Sqrt(1.0 - (B * B) / (A * A));
            double e2 = e * e / (1.0 - e * e);

            double n = A / Math.Sqrt(1.0 - Math.Pow(e, 2) * Math.Pow(Math.Sin(latRad), 2));
            double t = Math.Pow(Math.Tan(latRad), 2);
            double c = e2 * Math.Pow(Math.Cos(latRad), 2);
            double deltaLon = lonRad - Lon0;

            double m = A * ((1.0 - Math.Pow(e, 2) / 4.0 - 3.0 * Math.Pow(e, 4) / 64.0 - 5.0 * Math.Pow(e, 6) / 256.0) * latRad
                           - (3.0 * Math.Pow(e, 2) / 8.0 + 3.0 * Math.Pow(e, 4) / 32.0 + 45.0 * Math.Pow(e, 6) / 1024.0) * Math.Sin(2.0 * latRad)
                           + (15.0 * Math.Pow(e, 4) / 256.0 + 45.0 * Math.Pow(e, 6) / 1024.0) * Math.Sin(4.0 * latRad)
                           - (35.0 * Math.Pow(e, 6) / 3072.0) * Math.Sin(6.0 * latRad));

            x = Dx + K0 * n * (deltaLon * Math.Cos(latRad)
                              + Math.Pow(deltaLon, 3) * Math.Pow(Math.Cos(latRad), 3) / 6.0 * (1.0 - t + c)
                              + Math.Pow(deltaLon, 5) * Math.Pow(Math.Cos(latRad), 5) / 120.0 * (5.0 - 18.0 * t + Math.Pow(t, 2) + 72.0 * c - 58.0 * e2));

            y = K0 * (m + n * Math.Tan(latRad) * (Math.Pow(deltaLon, 2) * Math.Pow(Math.Cos(latRad), 2) / 2.0
                                                + Math.Pow(deltaLon, 4) * Math.Pow(Math.Cos(latRad), 4) / 24.0 * (5.0 - t + 9.0 * c + 4.0 * Math.Pow(c, 2))
                                                + Math.Pow(deltaLon, 6) * Math.Pow(Math.Cos(latRad), 6) / 720.0 * (61.0 - 58.0 * t + Math.Pow(t, 2) + 600.0 * c - 330.0 * e2)));
        }

        /// <summary>
        /// ?芸??⊥?銝西??WGS84 蝬楝摨?(?亙?亙?頧潭?隤文 TWD97 ?芸?靽格迤)
        /// </summary>
        public static void NormalizeWgs84(ref double lat, ref double lng)
        {
            // ?? 1: ?交?澆之??10,000嚗摰 TWD97 摨扳??脰??蔣頧?
            if (lat > 10000 || lng > 10000)
            {
                double x = lng > 10000 ? lng : lat;
                double y = lat > 10000 ? lat : lng;
                if (x > y)
                {
                    double tmp = x;
                    x = y;
                    y = tmp;
                }
                double wLat, wLon;
                Twd97ToWgs84(x, y, out wLat, out wLon);
                lat = wLat;
                lng = wLon;
                return;
            }

            // ?? 2: 蝬楝摨血?頧?(靘???121.x 憛急?蝺臬漲嚗? 25.x 憛急?蝬漲)
            if (lat > 100 && lng < 50)
            {
                double swap = lat;
                lat = lng;
                lng = swap;
            }
        }

        /// <summary>
        /// ?斗???臬摨扯?潭?????獢????輸?????(WGS84: 蝺臬漲 24.5 ~ 25.4, 蝬漲 121.2 ~ 122.1)
        /// </summary>
        public static bool IsInNtpcBounds(double lat, double lng)
        {
            if (lat <= 0 || lng <= 0) return false;
            return (lat >= 24.5 && lat <= 25.4 && lng >= 121.2 && lng <= 122.1);
        }
    }
}

