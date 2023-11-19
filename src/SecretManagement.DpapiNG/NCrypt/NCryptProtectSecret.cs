using System.Runtime.InteropServices;

namespace SecretManagement.DpapiNG.NCrypt;

public static partial class Methods
{
    public const int NCRYPT_SILENT_FLAG = 0x00000040;

    [DllImport("NCrypt.dll")]
    public unsafe static extern int NCryptProtectSecret(
        nint hDescriptor,
        int dwFlags,
        byte* pbData,
        int cbData,
        nint pMemPara,
        nint hWnd,
        out byte* ppbProtectedBlock,
        out int pcbProtectedBlock
    );
}
