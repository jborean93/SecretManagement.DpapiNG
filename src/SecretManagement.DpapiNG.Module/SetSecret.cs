using System.Collections;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Set, "Secret")]
public sealed class SetSecretCommand : PSCmdlet
{
    [Parameter]
    public string Name { get; set; } = "";

    [Parameter]
    public object? Secret { get; set; }

    [Parameter]
    public string VaultName { get; set; } = "";

    [Parameter]
    public Hashtable AdditionalParameters { get; set; } = new();

    protected override void ProcessRecord()
    {
    }
}
