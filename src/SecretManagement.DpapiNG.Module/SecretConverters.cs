using System;
using System.Collections;
using System.Management.Automation;
using System.Net;
using System.Security;
using System.Text;

namespace SecretManagement.DpapiNG.Module;

internal static class SecretConverters
{
    public static string ConvertToString(ReadOnlySpan<byte> data)
        => ConvertToString(data, Encoding.UTF8);

    public static string ConvertToString(ReadOnlySpan<byte> data, Encoding encoding)
    {
#if CORE
        return encoding.GetString(data);
#else
        unsafe
        {
            fixed (byte* dataPtr = data)
            {
                return encoding.GetString(dataPtr, data.Length);
            }
        }
#endif
    }

    public static SecureString ConvertToSecureString(ReadOnlySpan<byte> data)
        => ConvertToSecureString(ConvertToString(data));

    public static SecureString ConvertToSecureString(ReadOnlySpan<byte> data, Encoding encoding)
        => ConvertToSecureString(ConvertToString(data, encoding));

    public static SecureString ConvertToSecureString(string data)
    {
        unsafe
        {
            fixed (char* dataPtr = data.ToCharArray())
            {
                return new(dataPtr, data.Length);
            }
        }
    }

    public static Span<byte> ConvertFromSecureString(SecureString data)
        => Encoding.UTF8.GetBytes(new NetworkCredential("", data).Password);

    public static PSCredential ConvertToPSCredential(ReadOnlySpan<byte> data)
    {
        Hashtable raw = ConvertToHashtable(data);

        return new(
            raw["UserName"]?.ToString() ?? "",
            ConvertToSecureString(raw["Password"]?.ToString() ?? "")
        );
    }

    public static Span<byte> ConvertFromPSCredential(PSCredential data)
    {
        Hashtable psco = new()
        {
            { "UserName", data.UserName },
            { "Password", data.GetNetworkCredential().Password },
        };

        return ConvertFromHashtable(psco);
    }

    public static Hashtable ConvertToHashtable(ReadOnlySpan<byte> data)
        => (Hashtable)((PSObject)PSSerializer.Deserialize(ConvertToString(data))).BaseObject;

    public static Span<byte> ConvertFromHashtable(Hashtable data)
        => Encoding.UTF8.GetBytes(PSSerializer.Serialize(data));
}
