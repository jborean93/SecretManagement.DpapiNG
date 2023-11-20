using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace SecretManagement.DpapiNG.Native;

public static partial class NCrypt
{
    public const int NCRYPT_SILENT_FLAG = 0x00000040;

    [DllImport("NCrypt.dll")]
    private unsafe static extern int NCryptProtectSecret(
        nint hDescriptor,
        int dwFlags,
        byte* pbData,
        int cbData,
        nint pMemPara,
        nint hWnd,
        out nint ppbProtectedBlock,
        out int pcbProtectedBlock
    );

    public static SafeNCryptData NCryptProtectSecret(
        SafeNCryptProtectionDescriptor descriptor,
        int flags,
        ReadOnlySpan<byte> data
    )
    {
        int res = 0;
        nint protectedBlock;
        int protectedLength;

        unsafe
        {
            fixed (byte* toEncrypt = data)
            {
                res = NCryptProtectSecret(
                    descriptor.DangerousGetHandle(),
                    flags,
                    toEncrypt,
                    data.Length,
                    IntPtr.Zero,
                    IntPtr.Zero,
                    out protectedBlock,
                    out protectedLength
                );
            }
        }

        if (res != 0)
        {
            throw new Win32Exception(res);
        }

        return new(protectedBlock, protectedLength);
    }
}

public sealed class SafeNCryptData : SafeHandle
{
    public int Length { get; }

    internal SafeNCryptData(nint buffer, int length) : base(buffer, true)
    {
        Length = length;
    }

    public override bool IsInvalid => handle == IntPtr.Zero;

    public Span<byte> DangerousGetSpan()
    {
        unsafe
        {
            return new((void*)handle, Length);
        }
    }

    protected override bool ReleaseHandle()
    {
        Marshal.FreeHGlobal(handle);
        return true;
    }
}
