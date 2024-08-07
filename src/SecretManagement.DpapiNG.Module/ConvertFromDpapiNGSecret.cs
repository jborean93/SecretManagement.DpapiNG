using SecretManagement.DpapiNG.Native;
using System;
using System.ComponentModel;
using System.Management.Automation;
using System.Security;
using System.Text;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsData.ConvertFrom, "DpapiNGSecret", DefaultParameterSetName = "AsSecureString")]
[OutputType(typeof(byte[]), ParameterSetName = new[] { "AsByteArray" })]
[OutputType(typeof(SecureString), ParameterSetName = new[] { "AsSecureString" })]
[OutputType(typeof(string), ParameterSetName = new[] { "AsString" })]
public sealed class ConvertFromDpapiNGCommand : PSCmdlet
{
    [Parameter(
        Mandatory = true,
        Position = 0,
        ValueFromPipeline = true
    )]
    public string[] InputObject { get; set; } = Array.Empty<string>();

    [Parameter(
            ParameterSetName = "AsByteArray"
        )]
    public SwitchParameter AsByteArray { get; set; }

    [Parameter(
        ParameterSetName = "AsSecureString"
    )]
    public SwitchParameter AsSecureString { get; set; }

    [Parameter(
        ParameterSetName = "AsString"
    )]
    public SwitchParameter AsString { get; set; }

    [Parameter(
        ParameterSetName = "AsSecureString"
    )]
    [Parameter(
        ParameterSetName = "AsString"
    )]
    [EncodingTransformAttribute]
#if NET6_0_OR_GREATER
    [EncodingCompletionsAttribute]
#else
    [ArgumentCompleter(typeof(EncodingCompletionsAttribute))]
#endif
    public Encoding? Encoding { get; set; }

    protected override void ProcessRecord()
    {
        Encoding enc = Encoding ?? Encoding.UTF8;

        foreach (string input in InputObject)
        {
            SafeNCryptData blob;
            try
            {
                blob = NCrypt.NCryptUnprotectSecret(
                    NCrypt.NCRYPT_SILENT_FLAG,
                    Convert.FromBase64String(input),
                    out var desc);
                desc.Dispose();
            }
            catch (Win32Exception e)
            {
                ErrorRecord err = new(
                    e,
                    "SecretManagement.DpapiNG.DecryptError",
                    ErrorCategory.NotSpecified,
                    null
                );
                err.ErrorDetails = new($"Failed to decrypt data: {e.Message} (0x{e.NativeErrorCode:X2})");
                WriteError(err);
                continue;
            }

            using (blob)
            {
                ReadOnlySpan<byte> blobSpan = blob.DangerousGetSpan();
                if (ParameterSetName == "AsSecureString")
                {
                    WriteObject(SecretConverters.ConvertToSecureString(blobSpan, enc));
                }
                else if (ParameterSetName == "AsString")
                {
                    WriteObject(SecretConverters.ConvertToString(blobSpan, enc));
                }
                else
                {
                    WriteObject(blobSpan.ToArray(), enumerateCollection: false);
                }
            }
        }
    }
}
