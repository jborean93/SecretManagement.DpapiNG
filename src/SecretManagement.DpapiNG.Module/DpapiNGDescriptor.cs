using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Security.Principal;
using System.Text;

public sealed class ProtectionDescriptor : IEnumerable
{
    private StringBuilder _builder = new();

    internal ProtectionDescriptor()
    { }

    internal void AppendRule(string name, string value, bool and)
    {
        if (_builder.Length > 0)
        {
            _builder.AppendFormat(" {0} ", and ? "AND" : "OR");
        }
        _builder.AppendFormat("{0}={1}", name, value);
    }

    public IEnumerator GetEnumerator()
    {
        // This is used as an easy way to splat Metadata for Set-Secret
        return GetMetadataParams().GetEnumerator();
    }

    private IEnumerable<object> GetMetadataParams()
    {
        PSObject paramName = PSObject.AsPSObject("-Metadata");
        paramName.Properties.Add(new PSNoteProperty("<CommandParameterName>", "Metadata"));
        yield return paramName;

        yield return new Hashtable()
        {
            { "ProtectionDescriptor", ToString() }
        };
    }

    public static implicit operator string(ProtectionDescriptor v)
        => v.ToString();

    public override string ToString()
        => _builder.ToString();
}

[Cmdlet(VerbsCommon.New, "DpapiNGDescriptor")]
[OutputType(typeof(ProtectionDescriptor))]
public sealed class NewDpapiNGDescriptorCommand : PSCmdlet
{
    protected override void BeginProcessing()
    {
        WriteObject(new ProtectionDescriptor());
    }
}

[Cmdlet(VerbsCommon.Add, "DpapiNGDescriptor", DefaultParameterSetName = "Local")]
[OutputType(typeof(ProtectionDescriptor))]
public class AddDpapiNGDescriptorCommand : PSCmdlet
{
    [Parameter(
        Mandatory = true,
        ValueFromPipeline = true
    )]
    public ProtectionDescriptor InputObject { get; set; } = default!;

    [Parameter(
        Mandatory = true,
        ParameterSetName = "Local"
    )]
    [ValidateSet("User", "Machine")]
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

    [Parameter]
    public SwitchParameter Or { get; set; }

    protected override void ProcessRecord()
    {
        bool isAnd = !Or.IsPresent;

        if (ParameterSetName == "Local")
        {
            InputObject.AppendRule("LOCAL", Local.ToLowerInvariant(), isAnd);
        }
        else if (ParameterSetName == "Sid")
        {
            InputObject.AppendRule("SID", Sid.Value, isAnd);
        }
        else
        {
#pragma warning disable CA1416
#pragma warning disable CS8602
            InputObject.AppendRule("SID", WindowsIdentity.GetCurrent().User.Value, isAnd);
#pragma warning restore CA1416
#pragma warning restore CS8602
        }
        WriteObject(InputObject);
    }
}

public sealed class StringOrAccount
{
    internal string Value { get; }

    public StringOrAccount(string value)
    {
        Value = value;
    }

#if CORE
    [System.Runtime.Versioning.SupportedOSPlatform("windows")]
#endif
    public StringOrAccount(IdentityReference value)
    {
        if (value is SecurityIdentifier sid)
        {
            Value = sid.Value;
        }
        else
        {
            Value = value.Translate(typeof(SecurityIdentifier)).Value;
        }
    }
}
