using System;
using System.Data;
using System.Data.SqlClient;
using NTPC_FEC.Helpers;

public class UserLIC
{
    protected string pUserID;

    public UserLIC(string UserID)
    {
        pUserID = UserID;
    }

    public bool HaveThisLic(int LicCode, string chkFieldName = "LIC")
    {
        try
        {
            string sQLstr = "Select * From [Auth_List] Where FieldName='" + chkFieldName + "' order by Lic_ID desc";
            DataTable dataTable = DbHelper.ExecuteDataTable(sQLstr);

            sQLstr = "Select * From UserAcc Where [UserID] = @UserID";
            DataTable dataTable2 = DbHelper.ExecuteDataTable(sQLstr, new SqlParameter("@UserID", pUserID));

            if (dataTable2 != null && dataTable2.Rows.Count > 0)
            {
                long result = 0;
                if (long.TryParse(dataTable2.Rows[0][chkFieldName].ToString(), out result))
                {
                    bool[] AccList = new bool[dataTable != null ? dataTable.Rows.Count : 64];
                    for (int i = 0; i < AccList.Length; i++)
                    {
                        AccList[i] = false;
                    }
                    if (dataTable != null)
                    {
                        for (int j = 0; j < dataTable.Rows.Count; j++)
                        {
                            long result2 = 0;
                            if (long.TryParse(dataTable.Rows[j]["Lic_ID"].ToString(), out result2))
                            {
                                string retStr = dataTable.Rows[j]["Lic_Name"].ToString();
                                result = GetLic(result2, retStr, ref AccList, result);
                            }
                        }
                    }
                    if (LicCode >= 0 && LicCode < AccList.Length)
                    {
                        return AccList[LicCode];
                    }
                }
            }
        }
        catch
        {
        }
        return false;
    }

    private long GetLic(long ChkIndex, string RetStr, ref bool[] AccList, long pLic)
    {
        double num = Math.Pow(2.0, (double)ChkIndex);
        if ((double)pLic >= num)
        {
            if (ChkIndex >= 0 && ChkIndex < AccList.Length)
            {
                AccList[ChkIndex] = true;
            }
            return pLic - (long)num;
        }
        return pLic;
    }

    public string GetUser_FAC_ID()
    {
        string result = "";
        try
        {
            string sQLstr = "Select * From UserAcc Where UserID=@UserID";
            DataTable dataTable = DbHelper.ExecuteDataTable(sQLstr, new SqlParameter("@UserID", pUserID));
            if (dataTable != null && dataTable.Rows.Count > 0)
            {
                result = dataTable.Rows[0]["FAC_ID"].ToString();
            }
        }
        catch
        {
        }
        return result;
    }
}
