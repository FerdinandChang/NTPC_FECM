using System;
using System.Net;
using System.Net.Mail;
using System.Text;
using System.Web.Configuration;
using NTPC_FEC.Models;

namespace NTPC_FEC.Services
{
    public class MailService
    {
        /// <summary>
        /// 寄送臨時密碼通知信件 (相容 C# 5.0)
        /// </summary>
        public static OperationResult SendTempPasswordEmail(string toEmail, string userId, string userName, string tempPwd)
        {
            var result = new OperationResult();

            if (string.IsNullOrEmpty(toEmail))
            {
                result.Success = false;
                result.Message = "收件者信箱不可為空！";
                return result;
            }

            string host = WebConfigurationManager.AppSettings["SMTPserver"];
            string fromAddr = WebConfigurationManager.AppSettings["EmailAddr"];
            string smtpUser = WebConfigurationManager.AppSettings["SMTP_User"];
            string smtpPass = WebConfigurationManager.AppSettings["SMTP_Password"];

            if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(fromAddr))
            {
                result.Success = false;
                result.Message = "系統 Web.config 尚未配置 SMTP 伺服器 (SMTPserver 或 EmailAddr 為空)，無法發送郵件！";
                return result;
            }

            try
            {
                // 連線 HiNet SMTP 伺服器
                var client = new SmtpClient(host, 587);
                client.EnableSsl = false;
                client.Timeout = 15000; // 15 秒逾時

                if (!string.IsNullOrEmpty(smtpUser) && !string.IsNullOrEmpty(smtpPass))
                {
                    client.Credentials = new NetworkCredential(smtpUser, smtpPass);
                }

                var msg = new MailMessage();
                msg.From = new MailAddress(fromAddr, "新北市固定溢散源管理平台", Encoding.UTF8);
                msg.To.Add(new MailAddress(toEmail.Trim()));
                msg.Subject = "【系統通知】新北市固定溢散源管理平台 - 帳號臨時密碼配發通知";
                msg.IsBodyHtml = true;
                msg.BodyEncoding = Encoding.UTF8;

                var sb = new StringBuilder();
                sb.Append("<div style='font-family: Arial, \"Microsoft JhengHei\", sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.06);'>");
                sb.Append("<div style='background: linear-gradient(135deg, #184b72 0%, #1e6091 100%); color: #ffffff; padding: 20px 24px;'>");
                sb.Append("<h3 style='margin:0; font-size: 1.25rem;'>新北市固定溢散源管理平台</h3>");
                sb.Append("<div style='font-size: 0.85rem; opacity: 0.85; margin-top: 4px;'>帳號密碼重設與安全性通知</div>");
                sb.Append("</div>");
                sb.Append("<div style='padding: 26px; color: #334155; line-height: 1.6; background-color: #ffffff;'>");
                sb.AppendFormat("<p style='font-size: 1rem;'><strong>{0}</strong> 您好：</p>", string.IsNullOrEmpty(userName) ? userId : userName);
                sb.Append("<p>系統管理員已為您的帳號重新配發臨時密碼，請使用此組密碼儘速登入系統：</p>");
                sb.Append("<div style='background: #f8fafc; border: 1px solid #cbd5e1; border-left: 5px solid #0284c7; border-radius: 6px; padding: 16px 20px; margin: 20px 0;'>");
                sb.AppendFormat("<div style='margin-bottom: 8px;'><span style='color: #64748b; font-size: 0.9rem;'>登入帳號：</span><strong style='color: #1e293b; font-family: Consolas, monospace; font-size: 1.05rem;'>{0}</strong></div>", userId);
                sb.AppendFormat("<div><span style='color: #64748b; font-size: 0.9rem;'>臨時密碼：</span><span style='color: #dc2626; font-size: 1.3rem; font-weight: bold; font-family: Consolas, monospace; letter-spacing: 2px;'>{0}</span></div>", tempPwd);
                sb.Append("</div>");
                sb.Append("<div style='background: #fef3c7; border: 1px solid #fde68a; border-radius: 8px; padding: 14px 16px; color: #92400e; font-size: 0.88rem; line-height: 1.5;'>");
                sb.Append("<strong><i style='font-style: normal;'>⚠️</i> 重要安全注意事項：</strong><br/>");
                sb.Append("1. 首次使用此臨時密碼登入後，系統將<strong>強制要求您立即設定新密碼</strong>（需包含大小寫英文、數字與符號，且長度至少 8 碼）。<br/>");
                sb.Append("2. 若您並未向系統管理人員提出重新配發密碼請求，請立即與系統管理員聯繫。");
                sb.Append("</div>");
                sb.Append("</div>");
                sb.Append("<div style='background: #f1f5f9; border-top: 1px solid #e2e8f0; padding: 14px 24px; color: #64748b; font-size: 0.8rem; text-align: center;'>新北市政府環境保護局 固定溢散源管理系統 &copy; 2026</div>");
                sb.Append("</div>");

                msg.Body = sb.ToString();
                client.Send(msg);

                result.Success = true;
                result.Message = string.Format("臨時密碼已成功寄送至 [{0}]！", toEmail);
                return result;
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.Message = "郵件寄送失敗：" + ex.Message;
                return result;
            }
        }
    }
}
