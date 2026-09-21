package com.h.aazil;

import android.os.ParcelFileDescriptor;

interface IMediaSandboxService {
    String inspectMediaFd(in ParcelFileDescriptor pfd);
    boolean verifyNetworkBlocked();
    boolean verifyFilesystemBlocked();
}
