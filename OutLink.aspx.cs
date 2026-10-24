using System;
using System.Collections.Generic;
using System.Web.UI;
using Newtonsoft.Json;
using NTPC_FEC.Services;

namespace NTPC_FEC
{
    public class ExternalLinkItem
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string Code { get; set; }
        public string Category { get; set; }
        public string Authority { get; set; }
        public string Url { get; set; }
        public string Description { get; set; }
        public string IconClass { get; set; }
        public string IconBgColor { get; set; }
        public string BadgeText { get; set; }
        public string BadgeClass { get; set; }
    }

    public partial class OutLink : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["LoginUser"] == null)
            {
                Response.Redirect("Default.aspx", true);
                return;
            }
        }

        public string GetLinksJson()
        {
            List<ExternalLinkItem> list = new List<ExternalLinkItem>();

            // 1. 中央固定源與申報管制系統
            list.Add(new ExternalLinkItem
            {
                Id = "cems",
                Title = "行政院環境部 CEMS 資訊整合系統",
                Code = "CEMS",
                Category = "中央申報與許可",
                Authority = "環境部 大氣環境司",
                Url = "https://cems.moenv.gov.tw/cems/Login.aspx",
                Description = "固定污染源連續自動監測設施 (CEMS) 傳輸連線、即時數據監控、監測儀器校正查核與異常查報系統。",
                IconClass = "fas fa-satellite-dish",
                IconBgColor = "#0284c7",
                BadgeText = "連續自動監測",
                BadgeClass = "badge-sky"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "apmis",
                Title = "行政院環境部 固定污染源管理資訊系統",
                Code = "APMIS",
                Category = "中央申報與許可",
                Authority = "環境部 大氣環境司",
                Url = "https://apmis.moenv.gov.tw/",
                Description = "公私場所固定污染源設置許可證、操作許可證線上申請、核發、審查與固定源基本資料管理核心平台。",
                IconClass = "fas fa-industry",
                IconBgColor = "#2563eb",
                BadgeText = "設置操作許可",
                BadgeClass = "badge-primary"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "air10",
                Title = "固定污染源空污費暨排放量申報整合管理系統",
                Code = "AIR2020",
                Category = "中央申報與許可",
                Authority = "環境部 大氣環境司",
                Url = "https://air10.moenv.gov.tw/air2020/Default.aspx",
                Description = "固定污染源空氣污染防制費季度網路申報、排放量自主申報、線上審查繳費與歷史申報紀錄查詢。",
                IconClass = "fas fa-file-invoice-dollar",
                IconBgColor = "#d97706",
                BadgeText = "空污費申報",
                BadgeClass = "badge-warning"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "fdms",
                Title = "FDMS 固定污染源逸散性粒狀污染物管理系統",
                Code = "FDMS",
                Category = "中央申報與許可",
                Authority = "環境部 大氣環境司",
                Url = "https://fdmsepa.azurewebsites.net/",
                Description = "逸散性粒狀物管制標準管理系統，涵蓋堆置場、物料輸送、車行路徑洗掃與防制措施查核紀錄登記。",
                IconClass = "fas fa-wind",
                IconBgColor = "#059669",
                BadgeText = "逸散粒狀物防制",
                BadgeClass = "badge-success"
            });

            // 2. 公開資訊與環境監測數據
            list.Add(new ExternalLinkItem
            {
                Id = "aodmis",
                Title = "行政院環境部 固定污染源管理資訊公開平台",
                Code = "AODMIS",
                Category = "公開資訊與監測",
                Authority = "環境部",
                Url = "https://aodmis.moenv.gov.tw/opendata/",
                Description = "落實資訊公開與民眾知的權利，提供列管工廠許可排放量、空污防制設施及連續自動監測數值公開查詢。",
                IconClass = "fas fa-chart-line",
                IconBgColor = "#0891b2",
                BadgeText = "全民監督公開",
                BadgeClass = "badge-cyan"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "airtw",
                Title = "行政院環境部 空氣品質監測網",
                Code = "AIRTW",
                Category = "公開資訊與監測",
                Authority = "環境部 監測資訊司",
                Url = "https://airtw.moenv.gov.tw/",
                Description = "全國測站即時空氣品質指標 (AQI)、PM2.5、PM10、臭氧濃度即時地圖、各區空品預報與微型感測器圖資。",
                IconClass = "fas fa-smog",
                IconBgColor = "#4f46e5",
                BadgeText = "即時空品 AQI",
                BadgeClass = "badge-indigo"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "opendata",
                Title = "行政院環境部 環境資料開放平臺",
                Code = "OpenData",
                Category = "公開資訊與監測",
                Authority = "環境部 資訊處",
                Url = "https://data.moenv.gov.tw/",
                Description = "提供空氣品質、水質、廢棄物、毒化物及環境督察等官方高價值開放資料集與 API 串接規格文檔。",
                IconClass = "fas fa-database",
                IconBgColor = "#6366f1",
                BadgeText = "官方開放 API",
                BadgeClass = "badge-purple"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "ems",
                Title = "行政院環境部 國土環境監測整合系統 (EMS)",
                Code = "EMS",
                Category = "公開資訊與監測",
                Authority = "環境部 環境管理署",
                Url = "https://ems.moenv.gov.tw/",
                Description = "環保督察、各級稽查違規紀錄整合、污染源即時預警告警與重大環保裁處歷史資料庫。",
                IconClass = "fas fa-shield-alt",
                IconBgColor = "#dc2626",
                BadgeText = "督察稽查裁處",
                BadgeClass = "badge-danger"
            });

            // 3. 空間圖資與輔助查核工具
            list.Add(new ExternalLinkItem
            {
                Id = "nlsc",
                Title = "內政部 國土測繪圖資服務雲 (NLSC)",
                Code = "NLSC",
                Category = "圖資與查核輔助",
                Authority = "內政部 國土測繪中心",
                Url = "https://maps.nlsc.gov.tw/",
                Description = "全台灣地籍圖、高解析正射空拍影像、國土利用現況調查圖與都市計畫使用分區查驗工具。",
                IconClass = "fas fa-map-marked-alt",
                IconBgColor = "#16a34a",
                BadgeText = "地籍段籍圖資",
                BadgeClass = "badge-success"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "ntpc_gis",
                Title = "新北市政府 地理資訊共通平台",
                Code = "NTPC-GIS",
                Category = "圖資與查核輔助",
                Authority = "新北市政府 資訊中心",
                Url = "https://gis.ntpc.gov.tw/",
                Description = "新北市境內行政界線、都市計畫圖層、門牌定位、空拍航照影像及公共圖資查詢展示平台。",
                IconClass = "fas fa-layer-group",
                IconBgColor = "#0d9488",
                BadgeText = "新北圖資平台",
                BadgeClass = "badge-teal"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "gcis",
                Title = "經濟部 商工登記公示資料查詢服務",
                Code = "GCIS",
                Category = "圖資與查核輔助",
                Authority = "經濟部 商業發展署",
                Url = "https://findbiz.nat.gov.tw/fts/query/QueryBar/queryInit.do",
                Description = "查詢全國工廠登記、公司設立、商業登記、資本額、營業項目與統一編號比對作業。",
                IconClass = "fas fa-building",
                IconBgColor = "#475569",
                BadgeText = "工商登記驗證",
                BadgeClass = "badge-secondary"
            });

            // 4. 新北市主管機關與市府服務
            list.Add(new ExternalLinkItem
            {
                Id = "ntpc_epd",
                Title = "新北市政府環境保護局 全球資訊網",
                Code = "NTPC-EPD",
                Category = "新北市主管機關",
                Authority = "新北市政府 環境保護局",
                Url = "https://www.epd.ntpc.gov.tw/",
                Description = "新北市環保最新政策公告、法規標準發布、空氣品質維護區管制公告及便民申辦業務。",
                IconClass = "fas fa-landmark",
                IconBgColor = "#184b72",
                BadgeText = "市府環保局官網",
                BadgeClass = "badge-epd"
            });

            list.Add(new ExternalLinkItem
            {
                Id = "ntpc_efaq",
                Title = "新北市民眾公害陳情與便民報案系統",
                Code = "E-FAQ",
                Category = "新北市主管機關",
                Authority = "新北市政府",
                Url = "https://efaq.ntpc.gov.tw/",
                Description = "市民公害陳情陳報案件派工系統、現場稽查進度掌握與異味粒狀物污染案件關聯查詢。",
                IconClass = "fas fa-bullhorn",
                IconBgColor = "#e11d48",
                BadgeText = "陳情報案系統",
                BadgeClass = "badge-rose"
            });

            return JsonConvert.SerializeObject(list);
        }
    }
}
