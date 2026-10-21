using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

class Program
{
    static void Main()
    {
        string[] lines = File.ReadAllLines(@"d:\NTPC_FEC_Source\NTPC_FEC\MainPage1.cs");
        string currentGroup = "";
        
        for (int i = 0; i < lines.Length; i++)
        {
            string line = lines[i];
            var grpMatch = Regex.Match(line, @"data-group-title='([^']+)'");
            if (grpMatch.Success)
            {
                currentGroup = grpMatch.Groups[1].Value;
                Console.WriteLine("\n=== " + currentGroup + " ===");
            }
            
            var btnMatch = Regex.Match(line, @"BT_Name\s*=\s*""([^""]+)""");
            if (btnMatch.Success)
            {
                string btnName = btnMatch.Groups[1].Value;
                string url = "";
                for (int j = i; j < Math.Min(i + 25, lines.Length); j++)
                {
                    var urlMatch = Regex.Match(lines[j], @"(?:location\.href|window\.open)\('([^']+)'");
                    if (urlMatch.Success)
                    {
                        url = urlMatch.Groups[1].Value;
                        break;
                    }
                }
                Console.WriteLine($"  [{btnName}] -> {url}");
            }
        }
    }
}
