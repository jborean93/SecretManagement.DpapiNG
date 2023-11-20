using LiteDB;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Remove, "Secret")]
public sealed class RemoveSecretCommand : DpapiNGSecretBase
{
    [Parameter]
    public string Name { get; set; } = "";

    [Parameter]
    public string VaultName { get; set; } = "";

    internal override void ProcessVault(ILiteCollection<Secret> secrets)
    {
        Secret? existingSecret = secrets.FindOne(x => x.Name == Name);
        if (existingSecret != null)
        {
            secrets.Delete(existingSecret.Id);
        }
    }
}
