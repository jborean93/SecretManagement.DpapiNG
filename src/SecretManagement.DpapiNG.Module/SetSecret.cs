using LiteDB;
using Microsoft.PowerShell.SecretManagement;
using SecretManagement.DpapiNG.Native;
using System;
using System.Collections;
using System.Management.Automation;
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

    [Parameter]
    public Hashtable Metadata { get; set; } = new();

    internal override void ProcessVault(ILiteCollection<Secret> secrets)
    {
        Secret? existingSecret = secrets.FindOne(x => x.Name == Name);

        string metadata = ProcessMetadata(out string protectionDescriptor);

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
            existingSecret.Metadata = metadata;
            secrets.Update(existingSecret);
        }
        else
        {
            Secret secret = new()
            {
                Name = Name,
                Value = protectedData,
                SecretType = secretType,
                Metadata = metadata,
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
            return SecretConverters.ConvertFromSecureString(ss);
        }
        else if (Secret is PSCredential ps)
        {
            secretType = SecretType.PSCredential;
            return SecretConverters.ConvertFromPSCredential(ps);
        }
        else if (Secret is Hashtable ht)
        {
            secretType = SecretType.Hashtable;
            return SecretConverters.ConvertFromHashtable(ht);
        }

        secretType = SecretType.Unknown;
        return default;
    }

    private string ProcessMetadata(out string protectionDescriptor)
    {
        Hashtable localMetadata = (Hashtable)Metadata.Clone();

        object? rawDescriptor = null;
        if (localMetadata.ContainsKey("ProtectionDescriptor"))
        {
            rawDescriptor = localMetadata["ProtectionDescriptor"];
        }
        else if (AdditionalParameters.ContainsKey("DefaultProtectionDescriptor"))
        {
            rawDescriptor = AdditionalParameters["DefaultProtectionDescriptor"];
        }

        if (rawDescriptor is not null)
        {
            protectionDescriptor = LanguagePrimitives.ConvertTo<string>(rawDescriptor);
        }
        else
        {
            protectionDescriptor = "LOCAL=user";
        }

        localMetadata["ProtectionDescriptor"] = protectionDescriptor;

        return PSSerializer.Serialize(localMetadata);
    }
}
