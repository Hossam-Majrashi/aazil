#define _GNU_SOURCE
#include <sched.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>
#include <seccomp.h>
#include <errno.h>

int main() {
    int ret = unshare(CLONE_NEWUSER | CLONE_NEWNET | CLONE_NEWPID | CLONE_NEWNS);
    printf("unshare ret=%d, errno=%d\n", ret, errno);
    return 0;
}
