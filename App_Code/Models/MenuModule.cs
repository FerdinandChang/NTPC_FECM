using System;
using System.Collections.Generic;

namespace NTPC_FEC.Models
{
    public class MenuModule
    {
        public string Id { get; set; }
        public string Title { get; set; }
        public string SubTitle { get; set; }
        public string Url { get; set; }
        public string BgColor { get; set; }
        public string IconSvg { get; set; }
        public int BadgeCount { get; set; }
        public bool IsExternal { get; set; }
        public List<MenuSubItem> SubItems { get; set; } = new List<MenuSubItem>();
    }

    public class MenuSubItem
    {
        public string Title { get; set; }
        public string Url { get; set; }
        public int BadgeCount { get; set; }
    }
}
