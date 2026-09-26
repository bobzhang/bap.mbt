#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <moonbit.h>

/* Creates a directory with the 0777 mode. Returns 0 on success (or if a
   directory already exists), 1 if the path exists and is not a directory,
   and 2 on any other error. */
MOONBIT_FFI_EXPORT
int32_t bap_mbt_phoenix_mkdir(moonbit_bytes_t path) {
  const char *name = (const char *)path;
  struct stat st;
  if (stat(name, &st) == 0) {
    return S_ISDIR(st.st_mode) ? 0 : 1;
  }
  if (mkdir(name, 0777) == 0) {
    return 0;
  }
  return 2;
}

/* Returns the current working directory (empty on failure). */
MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_phoenix_getcwd(void) {
  char buffer[PATH_MAX];
  if (getcwd(buffer, sizeof(buffer)) == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  int32_t len = (int32_t)strlen(buffer);
  moonbit_bytes_t out = moonbit_make_bytes(len, 0);
  memcpy(out, buffer, (size_t)len);
  return out;
}
