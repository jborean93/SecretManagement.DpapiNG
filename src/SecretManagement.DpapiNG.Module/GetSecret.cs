using LiteDB;
using Microsoft.PowerShell.SecretManagement;
using SecretManagement.DpapiNG.Native;
using System;
using System.Collections;
using System.Management.Automation;
using System.Security;
using System.Text;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Get, "Secret")]
public sealed class GetSecretCommand : DpapiNGSecretBase
{
    [Parameter]
    public string Name { get; set; } = "";

    [Parameter]
    public string VaultName { get; set; } = "";

    internal override void ProcessVault(ILiteCollection<Secret> secrets)
    {
        Secret? foundSecret = secrets.FindOne(x => x.Name == Name);
        if (foundSecret == null)
        {
            // SecretManagement handles this
            return;
        }

        using SafeNCryptData unprotectedData = NCrypt.NCryptUnprotectSecret(
            NCrypt.NCRYPT_SILENT_FLAG,
            foundSecret.Value,
            out var descriptor);
        descriptor.Dispose();

        object outputObj = CreateOutputObject(unprotectedData.DangerousGetSpan(), foundSecret.SecretType);
        WriteObject(outputObj);
    }

    private static object CreateOutputObject(ReadOnlySpan<byte> data, SecretType secretType) => secretType switch
    {
        SecretType.ByteArray => data.ToArray(),
        SecretType.String => CreateString(data),
        SecretType.SecureString => CreateSecureString(data),
        SecretType.PSCredential => CreatePSCredential(data),
        SecretType.Hashtable => CreateHashtable(data),
        _ => throw new NotImplementedException(),
    };

    private static string CreateString(ReadOnlySpan<byte> data)
    {
#if CORE
        return Encoding.UTF8.GetString(data);
#else
        unsafe
        {
            fixed (byte* dataPtr = data)
            {
                return Encoding.UTF8.GetString(dataPtr, data.Length);
            }
        }
#endif
    }

    private static SecureString CreateSecureString(ReadOnlySpan<byte> data)
        => CreateSecureString(CreateString(data));

    private static SecureString CreateSecureString(string data)
    {
        unsafe
        {
            fixed (char* dataPtr = data.ToCharArray())
            {
                return new(dataPtr, data.Length);
            }
        }
    }

    private static PSCredential CreatePSCredential(ReadOnlySpan<byte> data)
    {
        Hashtable raw = (Hashtable)PSSerializer.Deserialize(CreateString(data));

        return new(
            raw["UserName"]?.ToString() ?? "",
            CreateSecureString(raw["Password"]?.ToString() ?? "")
        );
    }

    private static Hashtable CreateHashtable(ReadOnlySpan<byte> data)
        => (Hashtable)PSSerializer.Deserialize(CreateString(data));
}
