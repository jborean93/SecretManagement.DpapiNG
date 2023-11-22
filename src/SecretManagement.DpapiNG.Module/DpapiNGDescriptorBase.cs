using System;
using System.Management.Automation;
using System.Security.Cryptography.X509Certificates;
using System.Security.Principal;

public abstract class DpapiNGDescriptorBase : PSCmdlet
{
    internal const string DEFAULT_PARAM_SET = "Local";

    [Parameter(
        ParameterSetName = "Local"
    )]
    [ValidateSet("Logon", "Machine", "User")]
    public string Local { get; set; } = "User";

    [Parameter(
        Mandatory = true,
        ParameterSetName = "Sid"
    )]
    public StringOrAccount Sid { get; set; } = default!;

    [Parameter(
        Mandatory = true,
        ParameterSetName = "SidCurrent"
    )]
    public SwitchParameter CurrentSid { get; set; }

    [Parameter(
        Mandatory = true,
        ParameterSetName = "Certificate"
    )]
    public X509Certificate2? Certificate { get; set; }

    [Parameter(
        Mandatory = true,
        ParameterSetName = "CertificateThumbprint"
    )]
    public string? CertificateThumbprint { get; set; }

    [Parameter(
        Mandatory = true,
        ParameterSetName = "WebCredential"
    )]
    public string? WebCredential { get; set; }

    internal string GetRuleString() => ParameterSetName switch
    {
        "Local" => $"LOCAL={Local.ToLowerInvariant()}",
        "Sid" => $"SID={Sid.Value}",
#pragma warning disable CA1416
#pragma warning disable CS8602
        "SidCurrent" => $"SID={WindowsIdentity.GetCurrent().User.Value}",
#pragma warning restore CA1416
#pragma warning restore CS8602
        "Certificate" => $"CERTIFICATE=CertBlob:{Convert.ToBase64String(Certificate!.Export(X509ContentType.Cert))}",
        "CertificateThumbprint" => $"CERTIFICATE=HashId:{CertificateThumbprint!}",
        "WebCredential" => $"WEBCREDENTIALS={WebCredential}",
        _ => throw new NotImplementedException(),
    };
}
