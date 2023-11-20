using LiteDB;
using Microsoft.PowerShell.SecretManagement;
using System.Linq;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Get, "SecretInfo")]
public sealed class GetSecretInfoCommand : DpapiNGSecretBase
{
    [Parameter]
    public string Filter { get; set; } = "";

    [Parameter]
    public string VaultName { get; set; } = "";

    internal override void ProcessVault(ILiteCollection<Secret> secrets)
    {
        WildcardPattern pattern = new(Filter);

        foreach (Secret s in secrets.Find(Query.All("Name")).Where(x => pattern.IsMatch(x.Name.ToString())))
        {
            SecretInformation si = new(s.Name, s.SecretType, VaultName);
            WriteObject(si);
        }
    }
}
