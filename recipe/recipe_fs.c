#include <dirent.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>

#include <moonbit.h>

/* 0 - does not exist, 1 - a regular (or other non-directory) file,
   2 - a directory. */
MOONBIT_FFI_EXPORT
int32_t bap_recipe_file_kind(moonbit_bytes_t path) {
  struct stat st;
  if (stat((const char *)path, &st) != 0) {
    return 0;
  }
  return S_ISDIR(st.st_mode) ? 2 : 1;
}

/* Returns the directory entries (except `.` and `..`), each terminated
   by a NUL byte. An unreadable directory yields an empty result. */
MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_recipe_read_dir(moonbit_bytes_t path) {
  DIR *dir = opendir((const char *)path);
  if (dir == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  size_t total = 0;
  struct dirent *entry;
  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
      continue;
    }
    total += strlen(entry->d_name) + 1;
  }
  rewinddir(dir);
  moonbit_bytes_t out = moonbit_make_bytes((int32_t)total, 0);
  size_t pos = 0;
  while ((entry = readdir(dir)) != NULL) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
      continue;
    }
    size_t len = strlen(entry->d_name);
    if (pos + len + 1 > total) {
      break;
    }
    memcpy(out + pos, entry->d_name, len);
    pos += len;
    out[pos++] = 0;
  }
  closedir(dir);
  return out;
}
