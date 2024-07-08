using System;
using System.Collections;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Text;
using System.Globalization;

namespace SecretManagement.DpapiNG.Module;

public sealed class EncodingTransformAttribute : ArgumentTransformationAttribute
{
    internal static string[] KNOWN_ENCODINGS = new[] {
        "UTF8",
        "ASCII",
        "ANSI",
        "OEM",
        "Unicode",
        "UTF8Bom",
        "UTF8NoBom"
    };

    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData) => inputData switch
    {
        Encoding => inputData,
        string s => GetEncodingFromString(s.ToUpperInvariant()),
        int i => Encoding.GetEncoding(i),
        _ => throw new ArgumentTransformationMetadataException($"Could not convert input '{inputData}' to a valid Encoding object."),
    };

    private static Encoding GetEncodingFromString(string encoding) => encoding switch
    {
        "ASCII" => new ASCIIEncoding(),
        "ANSI" => Encoding.GetEncoding(CultureInfo.CurrentCulture.TextInfo.ANSICodePage),
        "BIGENDIANUNICODE" => new UnicodeEncoding(true, true),
        "BIGENDIANUTF32" => new UTF32Encoding(true, true),
        "OEM" => Console.OutputEncoding,
        "UNICODE" => new UnicodeEncoding(),
        "UTF8" => new UTF8Encoding(),
        "UTF8BOM" => new UTF8Encoding(true),
        "UTF8NOBOM" => new UTF8Encoding(),
        "UTF32" => new UTF32Encoding(),
        _ => Encoding.GetEncoding(encoding),
    };
}

#if NET6_0_OR_GREATER
public class EncodingCompletionsAttribute : ArgumentCompletionsAttribute
{
    public EncodingCompletionsAttribute() : base(EncodingTransformAttribute.KNOWN_ENCODINGS)
    { }
}
#else
public class EncodingCompletionsAttribute : IArgumentCompleter {
    public IEnumerable<CompletionResult> CompleteArgument(
        string commandName,
        string parameterName,
        string wordToComplete,
        CommandAst commandAst,
        IDictionary fakeBoundParameters
    )
    {
        if (string.IsNullOrWhiteSpace(wordToComplete))
        {
            wordToComplete = "";
        }

        WildcardPattern pattern = new($"{wordToComplete}*");
        foreach (string encoding in EncodingTransformAttribute.KNOWN_ENCODINGS)
        {
            if (pattern.IsMatch(encoding))
            {
                yield return new CompletionResult(encoding);
            }
        }
    }
}
#endif
