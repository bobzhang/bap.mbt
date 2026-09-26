/* File-system primitives for the native target: stat, directories,
   removal, renaming, permissions, temporary files and advisory locks.

   Every function that can fail returns a MoonBit `Bytes` response whose
   first byte is a status tag (0 - success, 1 - failure) followed by
   either the payload or a UTF-8 error message. Paths are NUL-terminated
   UTF-8 byte strings borrowed from MoonBit. */

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <moonbit.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

static moonbit_bytes_t bap_mbt_fs_response(
  uint8_t tag,
  const uint8_t *data,
  int32_t len
) {
  moonbit_bytes_t out = moonbit_make_bytes(len + 1, 0);
  out[0] = tag;
  if (len > 0) {
    memcpy(out + 1, data, (size_t)len);
  }
  return out;
}

static moonbit_bytes_t bap_mbt_fs_ok(void) {
  return bap_mbt_fs_response(0, NULL, 0);
}

static moonbit_bytes_t bap_mbt_fs_ok_string(const char *str) {
  return bap_mbt_fs_response(0, (const uint8_t *)str, (int32_t)strlen(str));
}

/* Formats "<action> <path>: <strerror(errno)>" as a failure response. */
static moonbit_bytes_t bap_mbt_fs_error(const char *action, const char *path) {
  char buffer[PATH_MAX + 256];
  snprintf(buffer, sizeof(buffer), "failed to %s %s: %s", action, path,
           strerror(errno));
  return bap_mbt_fs_response(1, (const uint8_t *)buffer,
                             (int32_t)strlen(buffer));
}

static void bap_mbt_fs_put_i64(uint8_t *out, int64_t value) {
  uint64_t v = (uint64_t)value;
  for (int i = 0; i < 8; i++) {
    out[i] = (uint8_t)(v >> (8 * i));
  }
}

/* Success payload: kind (1 byte: 1 - regular file, 2 - directory,
   3 - symbolic link, 4 - other), size (8 bytes), mtime seconds (8 bytes),
   mtime nanoseconds (8 bytes), permission bits (8 bytes); all integers
   are little-endian. */
static moonbit_bytes_t bap_mbt_fs_stat_response(const struct stat *st) {
  uint8_t payload[33];
  uint8_t kind = 4;
  if (S_ISREG(st->st_mode)) {
    kind = 1;
  } else if (S_ISDIR(st->st_mode)) {
    kind = 2;
  } else if (S_ISLNK(st->st_mode)) {
    kind = 3;
  }
  payload[0] = kind;
  bap_mbt_fs_put_i64(payload + 1, (int64_t)st->st_size);
#if defined(__APPLE__)
  bap_mbt_fs_put_i64(payload + 9, (int64_t)st->st_mtimespec.tv_sec);
  bap_mbt_fs_put_i64(payload + 17, (int64_t)st->st_mtimespec.tv_nsec);
#else
  bap_mbt_fs_put_i64(payload + 9, (int64_t)st->st_mtim.tv_sec);
  bap_mbt_fs_put_i64(payload + 17, (int64_t)st->st_mtim.tv_nsec);
#endif
  bap_mbt_fs_put_i64(payload + 25, (int64_t)(st->st_mode & 07777));
  return bap_mbt_fs_response(0, payload, (int32_t)sizeof(payload));
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_stat(moonbit_bytes_t path, int32_t follow) {
  const char *name = (const char *)path;
  struct stat st;
  int rc = follow ? stat(name, &st) : lstat(name, &st);
  if (rc != 0) {
    return bap_mbt_fs_error("stat", name);
  }
  return bap_mbt_fs_stat_response(&st);
}

/* Success payload: the entry names (except `.` and `..`), each
   terminated by a NUL byte. */
MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_read_dir(moonbit_bytes_t path) {
  const char *name = (const char *)path;
  DIR *dir = opendir(name);
  if (dir == NULL) {
    return bap_mbt_fs_error("read directory", name);
  }
  size_t total = 0;
  size_t capacity = 256;
  char *buffer = (char *)malloc(capacity);
  if (buffer == NULL) {
    closedir(dir);
    return bap_mbt_fs_error("read directory", name);
  }
  struct dirent *entry;
  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
      continue;
    }
    size_t len = strlen(entry->d_name);
    if (total + len + 1 > capacity) {
      while (total + len + 1 > capacity) {
        capacity *= 2;
      }
      char *grown = (char *)realloc(buffer, capacity);
      if (grown == NULL) {
        free(buffer);
        closedir(dir);
        return bap_mbt_fs_error("read directory", name);
      }
      buffer = grown;
    }
    memcpy(buffer + total, entry->d_name, len);
    total += len;
    buffer[total++] = 0;
  }
  closedir(dir);
  moonbit_bytes_t out =
    bap_mbt_fs_response(0, (const uint8_t *)buffer, (int32_t)total);
  free(buffer);
  return out;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_mkdir(moonbit_bytes_t path, int32_t mode) {
  const char *name = (const char *)path;
  if (mkdir(name, (mode_t)mode) != 0) {
    return bap_mbt_fs_error("create directory", name);
  }
  return bap_mbt_fs_ok();
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_rmdir(moonbit_bytes_t path) {
  const char *name = (const char *)path;
  if (rmdir(name) != 0) {
    return bap_mbt_fs_error("remove directory", name);
  }
  return bap_mbt_fs_ok();
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_remove(moonbit_bytes_t path) {
  const char *name = (const char *)path;
  if (unlink(name) != 0) {
    return bap_mbt_fs_error("remove file", name);
  }
  return bap_mbt_fs_ok();
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_rename(moonbit_bytes_t src, moonbit_bytes_t dst) {
  const char *from = (const char *)src;
  if (rename(from, (const char *)dst) != 0) {
    return bap_mbt_fs_error("rename", from);
  }
  return bap_mbt_fs_ok();
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_chmod(moonbit_bytes_t path, int32_t mode) {
  const char *name = (const char *)path;
  if (chmod(name, (mode_t)mode) != 0) {
    return bap_mbt_fs_error("change permissions of", name);
  }
  return bap_mbt_fs_ok();
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_getcwd(void) {
  char buffer[PATH_MAX];
  if (getcwd(buffer, sizeof(buffer)) == NULL) {
    return bap_mbt_fs_error("get", "the current directory");
  }
  return bap_mbt_fs_ok_string(buffer);
}

/* `template` must end with "XXXXXX"; the success payload is the name of
   the created (empty, closed, 0600) file. */
MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_mkstemp(moonbit_bytes_t template_) {
  char buffer[PATH_MAX];
  snprintf(buffer, sizeof(buffer), "%s", (const char *)template_);
  int fd = mkstemp(buffer);
  if (fd < 0) {
    return bap_mbt_fs_error("create a temporary file", (const char *)template_);
  }
  close(fd);
  return bap_mbt_fs_ok_string(buffer);
}

/* `template` must end with "XXXXXX"; the success payload is the name of
   the created (0700) directory. */
MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_mkdtemp(moonbit_bytes_t template_) {
  char buffer[PATH_MAX];
  snprintf(buffer, sizeof(buffer), "%s", (const char *)template_);
  if (mkdtemp(buffer) == NULL) {
    return bap_mbt_fs_error("create a temporary directory",
                            (const char *)template_);
  }
  return bap_mbt_fs_ok_string(buffer);
}

/* Opens (creating if needed) `path` and places an advisory `flock` on
   it. The success payload is the file descriptor (8 bytes). */
MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_fs_lock(
  moonbit_bytes_t path,
  int32_t exclusive,
  int32_t blocking
) {
  const char *name = (const char *)path;
  int fd = open(name, O_RDWR | O_CREAT, 0644);
  if (fd < 0) {
    return bap_mbt_fs_error("open lock file", name);
  }
  int op = (exclusive ? LOCK_EX : LOCK_SH) | (blocking ? 0 : LOCK_NB);
  int rc;
  do {
    rc = flock(fd, op);
  } while (rc != 0 && errno == EINTR);
  if (rc != 0) {
    moonbit_bytes_t error = bap_mbt_fs_error("lock", name);
    close(fd);
    return error;
  }
  uint8_t payload[8];
  bap_mbt_fs_put_i64(payload, (int64_t)fd);
  return bap_mbt_fs_response(0, payload, (int32_t)sizeof(payload));
}

/* Releases a lock obtained with `bap_mbt_fs_lock` and closes its
   descriptor. Returns 0 on success. */
MOONBIT_FFI_EXPORT
int32_t bap_mbt_fs_unlock(int32_t fd) {
  int rc = flock(fd, LOCK_UN);
  if (close(fd) != 0) {
    rc = -1;
  }
  return rc == 0 ? 0 : -1;
}
