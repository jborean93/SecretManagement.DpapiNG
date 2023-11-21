using SecretManagement.DpapiNG.Native;
using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
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

[Cmdlet(
    VerbsData.ConvertTo,
    "DpapiNGSecret",
    DefaultParameterSetName = DEFAULT_PARAM_SET
)]
[OutputType(typeof(string))]
public sealed class ConvertToDpapiNGCommand : DpapiNGDescriptorBase
{
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true
    )]
    [SecretValueTransformer]
    public StringSecureStringOrByteArray[] InputObject { get; set; } = Array.Empty<StringSecureStringOrByteArray>();

    [Parameter(
        Position = 1,
        ParameterSetName = "ProtectionDescriptor"
    )]
    public StringOrProtectionDescriptor? ProtectionDescriptor { get; set; }

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

        string protectionDescriptor;
        if (ProtectionDescriptor != null)
        {
            protectionDescriptor = ProtectionDescriptor.Value;
        }
        else
        {
            protectionDescriptor = GetRuleString();
        }

        SafeNCryptProtectionDescriptor desc;
        try
        {
            desc = NCrypt.NCryptCreateProtectionDescriptor(protectionDescriptor, 0);
        }
        catch (Win32Exception e)
        {
            ErrorRecord err = new(
                e,
                "SecretManagement.DpapiNG.InvalidDescriptor",
                ErrorCategory.InvalidArgument,
                protectionDescriptor
            );
            err.ErrorDetails = new(
                $"Failed to create protection descriptor object: {e.Message} (0x{e.NativeErrorCode:X2})");
            ThrowTerminatingError(err);
            return;
        }

        using (desc)
        {
            foreach (StringSecureStringOrByteArray input in InputObject)
            {
                SafeNCryptData blob;
                try
                {
                    blob = NCrypt.NCryptProtectSecret(desc, NCrypt.NCRYPT_SILENT_FLAG, input.GetBytes(enc));
                }
                catch (Win32Exception e)
                {
                    ErrorRecord err = new(
                        e,
                        "SecretManagement.DpapiNG.EncryptError",
                        ErrorCategory.NotSpecified,
                        null
                    );
                    err.ErrorDetails = new($"Failed to encrypt data: {e.Message} (0x{e.NativeErrorCode:X2})");
                    WriteError(err);
                    continue;
                }

                string b64;
                using (blob)
                {
#if CORE
                    b64 = Convert.ToBase64String(blob.DangerousGetSpan());
#else
                    b64 = Convert.ToBase64String(blob.DangerousGetSpan().ToArray());
#endif
                }

                WriteObject(b64);
            }
        }
    }
}

// A transformer is needed to ensure a byte[] isn't casted using the string overload.
public class SecretValueTransformer : ArgumentTransformationAttribute
{
    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
    {
        return TransformValues(inputData);
    }

    private StringSecureStringOrByteArray[] TransformValues(object? inputData)
    {
        PSObject psObj;
        if (inputData is PSObject objPS)
        {
            psObj = objPS;
        }
        else
        {
            psObj = PSObject.AsPSObject(inputData);
        }

        List<StringSecureStringOrByteArray> transformed = new();
        if (psObj.BaseObject is IList objList && psObj.BaseObject is not IList<byte>)
        {
            foreach (object? obj in objList)
            {
                transformed.AddRange(TransformValues(obj));
            }

            return transformed.ToArray();
        }
        else
        {
            transformed.Add(TransformValue(psObj));
        }

        return transformed.ToArray();
    }

    private StringSecureStringOrByteArray TransformValue(object? inputData)
    {
        PSObject psObj;
        if (inputData is PSObject objPS)
        {
            psObj = objPS;
            inputData = objPS.BaseObject;
        }
        else
        {
            psObj = PSObject.AsPSObject(inputData);
        }

        if (inputData is SecureString secString)
        {
            return new StringSecureStringOrByteArray(secString);
        }
        else if (inputData is IList<byte> objByteArray)
        {
            return new StringSecureStringOrByteArray(objByteArray);
        }
        else
        {
            return new StringSecureStringOrByteArray(LanguagePrimitives.ConvertTo<string>(psObj));
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
