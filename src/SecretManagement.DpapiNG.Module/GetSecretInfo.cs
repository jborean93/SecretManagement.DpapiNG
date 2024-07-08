using LiteDB;
using Microsoft.PowerShell.SecretManagement;
using System.Collections;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;

namespace SecretManagement.DpapiNG.Module;

[Cmdlet(VerbsCommon.Get, "SecretInfo")]
public sealed class GetSecretInfoCommand : DpapiNGSecretBase
{
    protected override bool ReadOnly => true;

    [Parameter]
    public string Filter { get; set; } = "";

    [Parameter]
    public string VaultName { get; set; } = "";

    internal override void ProcessVault(ILiteCollection<Secret> secrets)
    {
        WildcardPattern pattern = new(Filter);

        foreach (Secret s in secrets.Find(Query.All("Name")).Where(x => pattern.IsMatch(x.Name.ToString())))
        {
            Dictionary<string, object> metadata = new();
            Hashtable rawMeta = (Hashtable)((PSObject)PSSerializer.Deserialize(s.Metadata)).BaseObject;
            foreach (DictionaryEntry kvp in rawMeta)
            {
                metadata[kvp.Key?.ToString() ?? ""] = kvp.Value!;
            }

            ReadOnlyDictionary<string, object> roMetadata = new(metadata);
            SecretInformation si = new(s.Name, s.SecretType, VaultName, roMetadata);
            WriteObject(si);
        }
    }
}
