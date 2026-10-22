using System;

namespace NTPC_FEC.Models
{
    public class UserAccount
    {
        public int UID { get; set; }
        public string UserID { get; set; }
        public string Name { get; set; }
        public string PUnit { get; set; }
        public string AccState { get; set; }
        public long Lic { get; set; }
        public long Lic2 { get; set; }
        public string FacID { get; set; }
        public DateTime? LastLogin { get; set; }
    }

    public class LoginResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public string RedirectUrl { get; set; }
        public UserAccount User { get; set; }
    }

    public class OperationResult
    {
        public bool Success { get; set; }
        public string Message { get; set; }
    }
}
