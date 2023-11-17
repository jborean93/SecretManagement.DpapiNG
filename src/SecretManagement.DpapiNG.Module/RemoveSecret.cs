using System.Collections;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Remove, "Secret")]
public sealed class RemoveSecretCommand : PSCmdlet
{
    [Parameter]
    public string Name { get; set; } = "";

    [Parameter]
    public string VaultName { get; set; } = "";

    [Parameter]
    public Hashtable AdditionalParameters { get; set; } = new();

    protected override void ProcessRecord()
    {
    }
}
