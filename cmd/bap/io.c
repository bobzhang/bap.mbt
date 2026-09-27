/* Standard streams and the process exit status for the `bap` executable. */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <moonbit.h>

/* Writes the bytes to the standard output (fd = 1) or error (fd = 2). */
MOONBIT_FFI_EXPORT
int32_t bap_cli_write(int32_t fd, moonbit_bytes_t data) {
  FILE *stream = fd == 2 ? stderr : stdout;
  int32_t size = (int32_t)Moonbit_array_length(data);
  size_t written = size > 0 ? fwrite(data, 1, (size_t)size, stream) : 0;
  fflush(stream);
  return (int32_t)written;
}

/* Reads a line from the standard input. The first byte of the result is
   0 at the end of the input and 1 otherwise; the line follows (without
   the newline). */
MOONBIT_FFI_EXPORT
moonbit_bytes_t bap_cli_read_line(void) {
  size_t cap = 256, len = 0;
  char *buf = malloc(cap);
  int c = EOF;
  int got = 0;
  if (buf == NULL) {
    return moonbit_make_bytes(1, 0);
  }
  while ((c = fgetc(stdin)) != EOF) {
    got = 1;
    if (c == '\n') {
      break;
    }
    if (len + 1 >= cap) {
      char *next = realloc(buf, cap * 2);
      if (next == NULL) {
        break;
      }
      buf = next;
      cap *= 2;
    }
    buf[len++] = (char)c;
  }
  moonbit_bytes_t out = moonbit_make_bytes((int32_t)len + 1, 0);
  out[0] = got ? 1 : 0;
  if (len > 0) {
    memcpy(out + 1, buf, len);
  }
  free(buf);
  return out;
}

/* Terminates the process with the exit status. */
MOONBIT_FFI_EXPORT
void bap_cli_exit(int32_t code) {
  fflush(stdout);
  fflush(stderr);
  exit(code);
}
