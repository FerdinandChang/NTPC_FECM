using System;
using System.Web.Script.Serialization;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// ?典?獢?? JSON 摨??????(?梁敹怠?瘙?瘨??? new 撖虫?撘??撠? GC 瘚芾祥)
    /// ?詨捆 C# 5.0 閬?
    /// </summary>
    public static class JsonHelper
    {
        private static readonly JavaScriptSerializer s_serializer = new JavaScriptSerializer
        {
            MaxJsonLength = int.MaxValue
        };

        /// <summary>
        /// ?拐辣摨?? JSON 摮葡 (?游??寞?)
        /// </summary>
        public static string ToJson(this object obj)
        {
            if (obj == null) return "null";
            return s_serializer.Serialize(obj);
        }

        /// <summary>
        /// JSON 摮葡???箸?摰??亦隞?(?游??寞?)
        /// </summary>
        public static T FromJson<T>(this string json)
        {
            if (string.IsNullOrEmpty(json)) return default(T);
            return s_serializer.Deserialize<T>(json);
        }

        /// <summary>
        /// ???典??桐? Serializer
        /// </summary>
        public static JavaScriptSerializer Serializer
        {
            get { return s_serializer; }
        }
    }
}

