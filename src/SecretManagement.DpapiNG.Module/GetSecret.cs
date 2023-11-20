using LiteDB;
using Microsoft.PowerShell.SecretManagement;
using SecretManagement.DpapiNG.Native;
using System;
using System.Management.Automation;

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
        SecretType.String => SecretConverters.ConvertToString(data),
        SecretType.SecureString => SecretConverters.ConvertToSecureString(data),
        SecretType.PSCredential => SecretConverters.ConvertToPSCredential(data),
        SecretType.Hashtable => SecretConverters.ConvertToHashtable(data),
        _ => throw new NotImplementedException(),
    };
}
