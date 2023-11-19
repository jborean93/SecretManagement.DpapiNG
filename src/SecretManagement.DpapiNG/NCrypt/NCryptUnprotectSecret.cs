using System.Runtime.InteropServices;

namespace SecretManagement.DpapiNG.NCrypt;

public static partial class Methods
{
    public const int NCRYPT_UNPROTECT_NO_DECRYPT = 0x00000001;

    [DllImport("NCrypt.dll")]
    public unsafe static extern int NCryptUnprotectSecret(
        nint hDescriptor,
        int dwFlags,
        byte* pbProtectedBlob,
        int cbProtectedBlob,
        nint pMemPara,
        nint hWnd,
        out byte* ppbData,
        out int pcbData
    );
}
