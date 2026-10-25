using System;
using System.Web;
using System.Web.Script.Serialization;

namespace NTPC_FEC.Helpers
{
    /// <summary>
    /// AJAX ?踵????剁?蝯? ThreadAbortException ?啣虜銝行?擃?IIS ??銝衣?賢?
    /// ?詨捆 C# 5.0 閬?
    /// </summary>
    public static class AjaxResponseHelper
    {
        private static JavaScriptSerializer Serializer
        {
            get { return JsonHelper.Serializer; }
        }

        /// <summary>
        /// 頛詨 JSON 銝血??典???瘙?(??ThreadAbortException)
        /// </summary>
        public static void WriteJsonAndComplete(HttpResponse response, HttpContext context, object data)
        {
            if (response == null) return;

            response.Clear();
            response.ContentType = "application/json; charset=utf-8";

            if (data != null)
            {
                if (data is string)
                {
                    response.Write((string)data);
                }
                else
                {
                    response.Write(Serializer.Serialize(data));
                }
            }

            CompleteRequest(response, context);
        }

        /// <summary>
        /// 頛詨蝝?摮? HTML 銝血??典???瘙?        /// </summary>
        public static void WriteTextAndComplete(HttpResponse response, HttpContext context, string text, string contentType)
        {
            if (response == null) return;

            response.Clear();
            response.ContentType = string.IsNullOrEmpty(contentType) ? "text/plain; charset=utf-8" : contentType;

            if (!string.IsNullOrEmpty(text))
            {
                response.Write(text);
            }

            CompleteRequest(response, context);
        }

        /// <summary>
        /// ?詨??寞?嚗蝙??CompleteRequest 銋暹楊?蝞∠?嚗?隞????ThreadAbortException ??Response.End()
        /// </summary>
        public static void CompleteRequest(HttpResponse response, HttpContext context)
        {
            if (response == null) return;

            try
            {
                response.Flush();
            }
            catch
            {
            }

            try
            {
                response.SuppressContent = true;
            }
            catch
            {
            }

            if (context != null && context.ApplicationInstance != null)
            {
                context.ApplicationInstance.CompleteRequest();
            }
        }
    }
}

