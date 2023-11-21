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

    internal void AppendRule(string rule, bool and)
    {
        if (_builder.Length > 0)
        {
            _builder.AppendFormat(" {0} ", and ? "AND" : "OR");
        }
        _builder.Append(rule);
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

[Cmdlet(
    VerbsCommon.Add,
    "DpapiNGDescriptor",
    DefaultParameterSetName = DEFAULT_PARAM_SET
)]
[OutputType(typeof(ProtectionDescriptor))]
public class AddDpapiNGDescriptorCommand : DpapiNGDescriptorBase
{
    [Parameter(
        Mandatory = true,
        ValueFromPipeline = true
    )]
    public ProtectionDescriptor InputObject { get; set; } = default!;

    [Parameter]
    public SwitchParameter Or { get; set; }

    protected override void ProcessRecord()
    {
        bool isAnd = !Or.IsPresent;
        string ruleValue = GetRuleString();
        InputObject.AppendRule(ruleValue, isAnd);

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
