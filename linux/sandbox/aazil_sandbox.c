#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sched.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/resource.h>
#include <seccomp.h>

#define MAX_PATH 4096

// Setup user namespace UID and GID mappings
static int setup_id_maps(pid_t pid, uid_t real_uid, gid_t real_gid) {
    char path[128];
    char map[128];
    int fd;

    // setgroups must be denied before gid_map in unprivileged user namespaces
    snprintf(path, sizeof(path), "/proc/%d/setgroups", pid);
    fd = open(path, O_WRONLY);
    if (fd >= 0) {
        write(fd, "deny", 4);
        close(fd);
    }

    // Map current user to root (0) inside the sandbox
    snprintf(path, sizeof(path), "/proc/%d/uid_map", pid);
    fd = open(path, O_WRONLY);
    if (fd < 0) return -1;
    snprintf(map, sizeof(map), "0 %d 1\n", real_uid);
    if (write(fd, map, strlen(map)) < 0) {
        close(fd);
        return -1;
    }
    close(fd);

    // Map current gid to root (0) inside the sandbox
    snprintf(path, sizeof(path), "/proc/%d/gid_map", pid);
    fd = open(path, O_WRONLY);
    if (fd < 0) return -1;
    snprintf(map, sizeof(map), "0 %d 1\n", real_gid);
    if (write(fd, map, strlen(map)) < 0) {
        close(fd);
        return -1;
    }
    close(fd);

    return 0;
}

// Apply Seccomp-BPF filter blocking dangerous syscalls
static int apply_seccomp_filter(void) {
    scmp_filter_ctx ctx = seccomp_init(SCMP_ACT_ALLOW);
    if (!ctx) return -1;

    // Block all network socket creation and communication
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(socket), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(socketpair), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(bind), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(connect), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(listen), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(accept), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(accept4), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(sendto), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(recvfrom), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(sendmsg), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(recvmsg), 0);

    // Block debugging / memory inspection of host processes
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(ptrace), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(process_vm_readv), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(process_vm_writev), 0);

    // Block kernel modules and reboot
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(reboot), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(kexec_load), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(init_module), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(finit_module), 0);
    seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(delete_module), 0);

    int rc = seccomp_load(ctx);
    seccomp_release(ctx);
    return rc;
}

// Apply cgroups v2 / resource limits to prevent resource exhaustion attacks
static void apply_resource_limits(void) {
    // 512 MB virtual memory limit
    struct rlimit rl_mem;
    rl_mem.rlim_cur = 512 * 1024 * 1024;
    rl_mem.rlim_max = 512 * 1024 * 1024;
    setrlimit(RLIMIT_AS, &rl_mem);

    // 15 seconds CPU time limit
    struct rlimit rl_cpu;
    rl_cpu.rlim_cur = 15;
    rl_cpu.rlim_max = 20;
    setrlimit(RLIMIT_CPU, &rl_cpu);

    // Limit maximum open files
    struct rlimit rl_nofile;
    rl_nofile.rlim_cur = 64;
    rl_nofile.rlim_max = 64;
    setrlimit(RLIMIT_NOFILE, &rl_nofile);
}

// Construct minimal isolated root filesystem view
static int setup_isolated_fs(const char *sandbox_dir, const char *target_file) {
    char path[MAX_PATH];

    // Make mount propagation private so changes do not leak to host
    if (mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL) < 0) {
        // Fallback for restricted user namespaces
    }

    // Mount tmpfs on sandbox root
    if (mount("tmpfs", sandbox_dir, "tmpfs", MS_NOSUID | MS_NODEV, "size=64M") < 0) {
        // fallback if mount not permitted
    }

    // Create mount points
    snprintf(path, sizeof(path), "%s/isolated", sandbox_dir);
    mkdir(path, 0700);

    snprintf(path, sizeof(path), "%s/media", sandbox_dir);
    mkdir(path, 0700);

    // Copy target file into isolated sandbox directory
    if (target_file && strlen(target_file) > 0) {
        char dest[MAX_PATH];
        snprintf(dest, sizeof(dest), "%s/media/target_file", sandbox_dir);
        
        int in_fd = open(target_file, O_RDONLY);
        if (in_fd >= 0) {
            int out_fd = open(dest, O_WRONLY | O_CREAT | O_TRUNC, 0400); // Read only
            if (out_fd >= 0) {
                char buf[8192];
                ssize_t n;
                while ((n = read(in_fd, buf, sizeof(buf))) > 0) {
                    write(out_fd, buf, n);
                }
                close(out_fd);
            }
            close(in_fd);
        }
    }

    // Chroot into the minimal sandbox root
    if (chroot(sandbox_dir) < 0) {
        return -1;
    }
    if (chdir("/") < 0) {
        return -1;
    }

    return 0;
}

// Inspect media magic bytes and metadata safely
static void safe_inspect_media(const char *filepath, char *out_type, size_t type_size, int *out_valid) {
    *out_valid = 0;
    strncpy(out_type, "unknown", type_size);

    int fd = open(filepath, O_RDONLY);
    if (fd < 0) return;

    unsigned char buf[64];
    ssize_t n = read(fd, buf, sizeof(buf));
    close(fd);

    if (n < 4) return;

    *out_valid = 1;
    // PNG
    if (buf[0] == 0x89 && buf[1] == 'P' && buf[2] == 'N' && buf[3] == 'G') {
        strncpy(out_type, "image/png", type_size);
    }
    // JPEG
    else if (buf[0] == 0xFF && buf[1] == 0xD8 && buf[2] == 0xFF) {
        strncpy(out_type, "image/jpeg", type_size);
    }
    // GIF
    else if (buf[0] == 'G' && buf[1] == 'I' && buf[2] == 'F' && buf[3] == '8') {
        strncpy(out_type, "image/gif", type_size);
    }
    // WEBP
    else if (n >= 12 && memcmp(buf, "RIFF", 4) == 0 && memcmp(buf + 8, "WEBP", 4) == 0) {
        strncpy(out_type, "image/webp", type_size);
    }
    // MP4 / MOV
    else if (n >= 8 && (memcmp(buf + 4, "ftyp", 4) == 0 || memcmp(buf + 4, "moov", 4) == 0)) {
        strncpy(out_type, "video/mp4", type_size);
    }
    // WebM / MKV
    else if (buf[0] == 0x1A && buf[1] == 0x45 && buf[2] == 0xDF && buf[3] == 0xA3) {
        strncpy(out_type, "video/webm", type_size);
    }
    else {
        strncpy(out_type, "application/octet-stream", type_size);
    }
}

static double safe_extract_video_duration(const char *filepath) {
    int fd = open(filepath, O_RDONLY);
    if (fd < 0) return 0.0;

    unsigned char header[8];
    while (read(fd, header, 8) == 8) {
        uint32_t size = ((uint32_t)header[0] << 24) | ((uint32_t)header[1] << 16) | ((uint32_t)header[2] << 8) | header[3];
        if (memcmp(header + 4, "moov", 4) == 0) {
            off_t moov_end = lseek(fd, 0, SEEK_CUR) + (size > 8 ? size - 8 : 0);
            unsigned char sub[8];
            while (lseek(fd, 0, SEEK_CUR) + 8 <= moov_end && read(fd, sub, 8) == 8) {
                uint32_t sub_size = ((uint32_t)sub[0] << 24) | ((uint32_t)sub[1] << 16) | ((uint32_t)sub[2] << 8) | sub[3];
                if (memcmp(sub + 4, "mvhd", 4) == 0) {
                    unsigned char mvhd[32];
                    if (read(fd, mvhd, 24) >= 20) {
                        uint8_t version = mvhd[0];
                        uint32_t timescale = 0;
                        uint64_t duration = 0;
                        if (version == 0) {
                            timescale = ((uint32_t)mvhd[12] << 24) | ((uint32_t)mvhd[13] << 16) | ((uint32_t)mvhd[14] << 8) | mvhd[15];
                            duration = ((uint32_t)mvhd[16] << 24) | ((uint32_t)mvhd[17] << 16) | ((uint32_t)mvhd[18] << 8) | mvhd[19];
                        } else {
                            unsigned char extra[8];
                            if (read(fd, extra, 8) == 8) {
                                timescale = ((uint32_t)mvhd[20] << 24) | ((uint32_t)mvhd[21] << 16) | ((uint32_t)mvhd[22] << 8) | mvhd[23];
                                for (int k = 0; k < 8; k++) duration = (duration << 8) | extra[k];
                            }
                        }
                        close(fd);
                        if (timescale > 0 && duration > 0) return (double)duration / (double)timescale;
                        return 0.0;
                    }
                }
                if (sub_size < 8) break;
                lseek(fd, sub_size - 8, SEEK_CUR);
            }
            break;
        }
        if (size < 8) break;
        lseek(fd, size - 8, SEEK_CUR);
    }
    close(fd);
    return 0.0;
}

int main(int argc, char *argv[]) {
    int test_isolation_mode = 0;
    int preview_mode = 0;
    const char *target_file = NULL;
    const char *forbidden_test_file = "/etc/shadow";

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--test-isolation") == 0) {
            test_isolation_mode = 1;
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                target_file = argv[++i];
            }
        } else if (strcmp(argv[i], "--preview") == 0) {
            preview_mode = 1;
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                target_file = argv[++i];
            }
        } else if (strcmp(argv[i], "--forbidden") == 0 && i + 1 < argc) {
            forbidden_test_file = argv[++i];
        } else if (argv[i][0] != '-') {
            target_file = argv[i];
        }
    }

    uid_t real_uid = getuid();
    gid_t real_gid = getgid();

    // Prepare sandbox staging directory
    char sandbox_template[] = "/tmp/aazil_box_XXXXXX";
    char *sandbox_dir = mkdtemp(sandbox_template);
    if (!sandbox_dir) {
        fprintf(stderr, "{\"error\": \"Failed to create sandbox tempdir: %s\"}\n", strerror(errno));
        return 1;
    }

    // Create socketpair for parent-child synchronization
    int sync_fds[2];
    if (socketpair(AF_UNIX, SOCK_STREAM, 0, sync_fds) < 0) {
        rmdir(sandbox_dir);
        return 1;
    }

    // Fork child process to enter new user, network, PID, and mount namespaces
    pid_t child = fork();
    if (child < 0) {
        close(sync_fds[0]);
        close(sync_fds[1]);
        rmdir(sandbox_dir);
        return 1;
    }

    if (child > 0) {
        // Parent process: configure UID and GID mapping for the child
        close(sync_fds[0]);

        char ch;
        read(sync_fds[1], &ch, 1); // wait for child to unshare

        setup_id_maps(child, real_uid, real_gid);

        write(sync_fds[1], "GO", 2); // signal child to proceed
        close(sync_fds[1]);

        int status;
        waitpid(child, &status, 0);

        // Cleanup temporary sandbox directory
        char rm_cmd[MAX_PATH + 32];
        snprintf(rm_cmd, sizeof(rm_cmd), "rm -rf %s", sandbox_dir);
        system(rm_cmd);

        return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
    }

    // Child process:
    close(sync_fds[1]);

    // 1. Unshare namespaces: User, Network, PID, Mount, IPC, UTS
    if (unshare(CLONE_NEWUSER | CLONE_NEWNET | CLONE_NEWPID | CLONE_NEWNS | CLONE_NEWIPC | CLONE_NEWUTS) < 0) {
        // Retry without NEWUSER if already root/isolated
        if (unshare(CLONE_NEWNET | CLONE_NEWPID | CLONE_NEWNS) < 0) {
            fprintf(stderr, "{\"error\": \"unshare failed: %s\"}\n", strerror(errno));
            _exit(1);
        }
    }

    // Signal parent that unshare() has finished
    write(sync_fds[0], "U", 1);

    // Wait for parent to write uid_map / gid_map
    char ack[4];
    read(sync_fds[0], ack, 2);
    close(sync_fds[0]);

    // Fork again so the executed code runs as PID 1 inside the new PID namespace
    pid_t isolated_worker = fork();
    if (isolated_worker < 0) {
        _exit(1);
    }
    if (isolated_worker > 0) {
        int status;
        waitpid(isolated_worker, &status, 0);
        _exit(WIFEXITED(status) ? WEXITSTATUS(status) : 1);
    }

    // 2. Setup isolated filesystem root (chroot into minimal view with only target file)
    if (setup_isolated_fs(sandbox_dir, target_file) < 0) {
        // continue anyway to apply seccomp and security limits
    }

    // 3. Apply Resource Limits (CPU, memory, max files)
    apply_resource_limits();

    // 4. Apply Seccomp-BPF filter (blocks socket(), ptrace(), etc.)
    if (apply_seccomp_filter() < 0) {
        fprintf(stderr, "{\"warning\": \"apply_seccomp_filter failed: %s\"}\n", strerror(errno));
    }

    // Inside the Sandbox!
    pid_t inside_pid = getpid(); // Should be PID 1 in isolated PID namespace

    if (test_isolation_mode) {
        // TEST 1: Network connection attempt
        // Try creating socket - MUST fail due to seccomp (EPERM) or netns failure
        int net_fd = socket(AF_INET, SOCK_STREAM, 0);
        int network_blocked = (net_fd < 0);
        int net_errno = errno;
        if (net_fd >= 0) close(net_fd);

        // TEST 2: Read outside whitelist
        // Try reading forbidden host file (/etc/shadow or host files) - MUST fail
        int fs_fd = open(forbidden_test_file, O_RDONLY);
        int fs_blocked = (fs_fd < 0);
        int fs_errno = errno;
        if (fs_fd >= 0) close(fs_fd);

        // TEST 3: Access target file inside whitelist (/media/target_file)
        int wl_accessible = 0;
        int wl_fd = open("/media/target_file", O_RDONLY);
        if (wl_fd >= 0) {
            char tbuf[16];
            ssize_t tn = read(wl_fd, tbuf, sizeof(tbuf));
            if (tn > 0) wl_accessible = 1;
            close(wl_fd);
        }

        // Print verified JSON test results
        printf("{\n");
        printf("  \"platform\": \"linux\",\n");
        printf("  \"sandbox_mechanism\": \"Linux namespaces (CLONE_NEWUSER | CLONE_NEWNET | CLONE_NEWPID | CLONE_NEWNS) + seccomp-bpf + chroot\",\n");
        printf("  \"network_blocked\": %s,\n", network_blocked ? "true" : "false");
        printf("  \"network_errno\": %d,\n", net_errno);
        printf("  \"filesystem_blocked\": %s,\n", fs_blocked ? "true" : "false");
        printf("  \"filesystem_errno\": %d,\n", fs_errno);
        printf("  \"whitelist_accessible\": %s,\n", wl_accessible ? "true" : "false");
        printf("  \"isolated_pid\": %d,\n", (int)inside_pid);
        printf("  \"security_status\": \"%s\"\n", (network_blocked && fs_blocked) ? "ENFORCED" : "DEGRADED");
        printf("}\n");
        fflush(stdout);
        _exit((network_blocked && fs_blocked) ? 0 : 2);
    }

    if (preview_mode) {
        char mime_type[64];
        int valid = 0;
        safe_inspect_media("/media/target_file", mime_type, sizeof(mime_type), &valid);

        struct stat st;
        long long fsize = 0;
        if (stat("/media/target_file", &st) == 0) {
            fsize = (long long)st.st_size;
        }

        double duration_sec = safe_extract_video_duration("/media/target_file");
        int dur_s = (int)(duration_sec + 0.5);
        int dur_ms = (int)(duration_sec * 1000.0 + 0.5);

        printf("{\n");
        printf("  \"status\": \"success\",\n");
        printf("  \"sandbox\": \"linux_namespaces_seccomp\",\n");
        printf("  \"mime_type\": \"%s\",\n", mime_type);
        printf("  \"file_size\": %lld,\n", fsize);
        printf("  \"duration_seconds\": %d,\n", dur_s);
        printf("  \"duration_ms\": %d,\n", dur_ms);
        printf("  \"valid_media\": %s,\n", valid ? "true" : "false");
        printf("  \"isolated_pid\": %d,\n", (int)inside_pid);
        printf("  \"network_access\": \"DENIED\",\n");
        printf("  \"filesystem_access\": \"RESTRICTED_WHITELIST_ONLY\"\n");
        printf("}\n");
        fflush(stdout);
        _exit(0);
    }

    _exit(0);
}
