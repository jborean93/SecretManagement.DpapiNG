using SecretManagement.DpapiNG.Native;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Net;
using System.Security;
using System.Text;

namespace SecretManagement.DpapiNG.Module;

public sealed class StringOrProtectionDescriptor
{
    internal string Value { get; }

    public StringOrProtectionDescriptor(ProtectionDescriptor value)
    {
        Value = value.ToString();
    }

    public StringOrProtectionDescriptor(string value)
    {
        Value = value;
    }
}

[Cmdlet(VerbsData.ConvertTo, "DpapiNGSecret")]
[OutputType(typeof(string))]
public sealed class ConvertToDpapiNGCommand : PSCmdlet
{
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true
    )]
    public StringSecureStringOrByteArray[] InputObject { get; set; } = Array.Empty<StringSecureStringOrByteArray>();

    [Parameter(
        Position = 1
    )]
    public StringOrProtectionDescriptor ProtectionDescriptor { get; set; } = new("LOCAL=user");

    [Parameter]
    [EncodingTransformAttribute]
#if CORE
    [EncodingCompletionsAttribute]
#else
    [ArgumentCompleter(typeof(EncodingCompletionsAttribute))]
#endif
    public Encoding? Encoding { get; set; }

    protected override void ProcessRecord()
    {
        Encoding enc = Encoding ?? Encoding.UTF8;

        using SafeNCryptProtectionDescriptor desc = NCrypt.NCryptCreateProtectionDescriptor(
            ProtectionDescriptor.Value, 0);

        foreach (StringSecureStringOrByteArray input in InputObject)
        {
            SafeNCryptData blob = NCrypt.NCryptProtectSecret(desc, NCrypt.NCRYPT_SILENT_FLAG, input.GetBytes(enc));
#if CORE
            string b64 = Convert.ToBase64String(blob.DangerousGetSpan());
#else
            string b64 = Convert.ToBase64String(blob.DangerousGetSpan().ToArray());
#endif

            WriteObject(b64);
        }
    }
}

public sealed class StringSecureStringOrByteArray
{
    private string? _string;
    private SecureString? _secureString;
    private byte[]? _byteArray;

    public StringSecureStringOrByteArray(string value)
    {
        _string = value;
    }

    public StringSecureStringOrByteArray(SecureString value)
    {
        _secureString = value;
    }

    public StringSecureStringOrByteArray(IList<byte> value)
    {
        _byteArray = value.ToArray();
    }

    internal byte[] GetBytes(Encoding encoding)
    {
        if (_string != null)
        {
            return encoding.GetBytes(_string);
        }
        else if (_secureString != null)
        {
            return encoding.GetBytes(new NetworkCredential("", _secureString).Password);
        }
        else
        {
            return _byteArray ?? Array.Empty<byte>();
        }
    }
}
