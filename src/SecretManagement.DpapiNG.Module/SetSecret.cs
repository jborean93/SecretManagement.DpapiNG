using LiteDB;
using Microsoft.PowerShell.SecretManagement;
using SecretManagement.DpapiNG.Native;
using System;
using System.Collections;
using System.Management.Automation;
using System.Net;
using System.Security;
using System.Text;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Set, "Secret")]
public sealed class SetSecretCommand : DpapiNGSecretBase
{
    [Parameter]
    public string Name { get; set; } = "";

    [Parameter]
    public object? Secret { get; set; }

    [Parameter]
    public string VaultName { get; set; } = "";

    internal override void ProcessVault(ILiteCollection<Secret> secrets)
    {
        Secret? existingSecret = secrets.FindOne(x => x.Name == Name);

        string protectionDescriptor = GetProtectionDescriptor();

        using SafeNCryptProtectionDescriptor desc = NCrypt.NCryptCreateProtectionDescriptor(protectionDescriptor, 0);

        Span<byte> toProtect = GetSecretBytes(out SecretType secretType);
        if (secretType == SecretType.Unknown)
        {
            ErrorRecord err = new(
                new ArgumentException($"Invalid Secret type, cannot store secret of type '{Secret!.GetType().Name}'"),
                "SecretManagement.DpapiNG.InvalidSecretType",
                ErrorCategory.InvalidArgument,
                null
            );
            return;
        }

        using SafeNCryptData protectedBlock = NCrypt.NCryptProtectSecret(desc, NCrypt.NCRYPT_SILENT_FLAG, toProtect);
        byte[] protectedData = protectedBlock.DangerousGetSpan().ToArray();

        if (existingSecret != null)
        {
            existingSecret.Value = protectedData;
            existingSecret.SecretType = secretType;
            secrets.Update(existingSecret);
        }
        else
        {
            Secret secret = new()
            {
                Name = Name,
                Value = protectedData,
                SecretType = secretType,
            };
            secrets.EnsureIndex(x => x.Name, true);
            secrets.Insert(secret);
        }
    }

    private Span<byte> GetSecretBytes(out SecretType secretType)
    {
        if (Secret is byte[] ba)
        {
            secretType = SecretType.ByteArray;
            return ba;
        }
        else if (Secret is string s)
        {
            secretType = SecretType.String;
            return Encoding.UTF8.GetBytes(s);
        }
        else if (Secret is SecureString ss)
        {
            secretType = SecretType.SecureString;
            return Encoding.UTF8.GetBytes(new NetworkCredential("", ss).Password);
        }
        else if (Secret is PSCredential ps)
        {
            secretType = SecretType.PSCredential;
            Hashtable psco = new()
            {
                { "UserName", ps.UserName },
                { "Password", ps.GetNetworkCredential().Password },
            };
            return Encoding.UTF8.GetBytes(PSSerializer.Serialize(psco));
        }
        else if (Secret is Hashtable ht)
        {
            secretType = SecretType.Hashtable;
            return Encoding.UTF8.GetBytes(PSSerializer.Serialize(ht));
        }

        secretType = SecretType.Unknown;
        return default;
    }

    private string GetProtectionDescriptor()
    {
        if (AdditionalParameters.ContainsKey("ProtectionDescriptor"))
        {
            return AdditionalParameters["ProtectionDescriptor"]?.ToString() ?? "";
        }
        else
        {
            return "LOCAL=user";
        }
    }
}
