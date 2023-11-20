using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace SecretManagement.DpapiNG.Native;

public static partial class NCrypt
{
    public const int NCRYPT_UNPROTECT_NO_DECRYPT = 0x00000001;

    [DllImport("NCrypt.dll")]
    private unsafe static extern int NCryptUnprotectSecret(
        out nint hDescriptor,
        int dwFlags,
        byte* pbProtectedBlob,
        int cbProtectedBlob,
        nint pMemPara,
        nint hWnd,
        out nint ppbData,
        out int pcbData
    );

    public static SafeNCryptData NCryptUnprotectSecret(
        int flags,
        ReadOnlySpan<byte> protectedBlob,
        out SafeNCryptProtectionDescriptor descriptor
    )
    {
        int res = 0;
        nint descriptorHandle;
        nint data;
        int dataLength;

        unsafe
        {
            fixed (byte* toDecrypt = protectedBlob)
            {
                res = NCryptUnprotectSecret(
                    out descriptorHandle,
                    flags,
                    toDecrypt,
                    protectedBlob.Length,
                    IntPtr.Zero,
                    IntPtr.Zero,
                    out data,
                    out dataLength
                );
            }
        }

        if (res != 0)
        {
            throw new Win32Exception(res);
        }

        descriptor = new(descriptorHandle);
        return new(data, dataLength);
    }
}
