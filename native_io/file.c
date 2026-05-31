#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <moonbit.h>

static moonbit_bytes_t bap_mbt_file_response(
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

static moonbit_bytes_t bap_mbt_file_error(
  const char *action,
  const char *path,
  const char *reason
) {
  char buffer[1024];
  snprintf(
    buffer,
    sizeof(buffer),
    "failed to %s file %s: %s",
    action,
    path,
    reason
  );
  return bap_mbt_file_response(
    1,
    (const uint8_t *)buffer,
    (int32_t)strlen(buffer)
  );
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_read_file(moonbit_bytes_t path) {
  const char *filename = (const char *)path;
  FILE *file = fopen(filename, "rb");
  if (file == NULL) {
    return bap_mbt_file_error("read", filename, strerror(errno));
  }
  if (fseek(file, 0, SEEK_END) != 0) {
    moonbit_bytes_t error = bap_mbt_file_error("read", filename, strerror(errno));
    fclose(file);
    return error;
  }
  long size = ftell(file);
  if (size < 0) {
    moonbit_bytes_t error = bap_mbt_file_error("read", filename, strerror(errno));
    fclose(file);
    return error;
  }
  if (size > INT32_MAX - 1) {
    moonbit_bytes_t error = bap_mbt_file_error("read", filename, "file is too large");
    fclose(file);
    return error;
  }
  if (fseek(file, 0, SEEK_SET) != 0) {
    moonbit_bytes_t error = bap_mbt_file_error("read", filename, strerror(errno));
    fclose(file);
    return error;
  }
  moonbit_bytes_t out = moonbit_make_bytes((int32_t)size + 1, 0);
  out[0] = 0;
  if (size > 0) {
    size_t read = fread(out + 1, 1, (size_t)size, file);
    if (read != (size_t)size) {
      moonbit_bytes_t error = bap_mbt_file_error("read", filename, strerror(errno));
      fclose(file);
      return error;
    }
  }
  fclose(file);
  return out;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_mbt_write_file(moonbit_bytes_t path, moonbit_bytes_t data) {
  const char *filename = (const char *)path;
  FILE *file = fopen(filename, "wb");
  if (file == NULL) {
    return bap_mbt_file_error("write", filename, strerror(errno));
  }
  int32_t size = (int32_t)Moonbit_array_length(data);
  if (size > 0) {
    size_t written = fwrite(data, 1, (size_t)size, file);
    if (written != (size_t)size) {
      moonbit_bytes_t error = bap_mbt_file_error(
        "write",
        filename,
        strerror(errno)
      );
      fclose(file);
      return error;
    }
  }
  if (fclose(file) != 0) {
    return bap_mbt_file_error("write", filename, strerror(errno));
  }
  return bap_mbt_file_response(0, NULL, 0);
}
