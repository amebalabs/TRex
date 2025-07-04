// TesseractStubs.c
// Stub implementations for image library functions that Leptonica expects
// These are no-ops since Leptonica was built with stub support

#include <stddef.h>

// TIFF stubs
void* TIFFOpen(const char* name, const char* mode) { return NULL; }
void TIFFClose(void* tif) {}
void TIFFCleanup(void* tif) {}
void* TIFFClientOpen(const char* name, const char* mode, void* clientdata,
                     void* readproc, void* writeproc, void* seekproc,
                     void* closeproc, void* sizeproc, void* mapproc, void* unmapproc) { return NULL; }
int TIFFGetField(void* tif, unsigned int tag, ...) { return 0; }
int TIFFGetFieldDefaulted(void* tif, unsigned int tag, ...) { return 0; }
int TIFFSetField(void* tif, unsigned int tag, ...) { return 0; }
int TIFFReadDirectory(void* tif) { return 0; }
int TIFFSetDirectory(void* tif, unsigned short dirnum) { return 0; }
int TIFFSetSubDirectory(void* tif, unsigned long diroff) { return 0; }
unsigned long TIFFCurrentDirOffset(void* tif) { return 0; }
int TIFFReadRGBAImageOriented(void* tif, unsigned int w, unsigned int h, unsigned int* raster, int orientation, int stopOnError) { return 0; }
int TIFFReadScanline(void* tif, void* buf, unsigned int row, unsigned short sample) { return -1; }
int TIFFWriteScanline(void* tif, void* buf, unsigned int row, unsigned short sample) { return -1; }
unsigned long TIFFScanlineSize(void* tif) { return 0; }
int TIFFIsTiled(void* tif) { return 0; }
void TIFFPrintDirectory(void* tif, void* fd, long flags) {}
void* TIFFSetErrorHandler(void* handler) { return NULL; }
void* TIFFSetWarningHandler(void* handler) { return NULL; }

// WebP stubs
int WebPGetFeaturesInternal(const unsigned char* data, size_t data_size, void* features, int version) { return 0; }
unsigned char* WebPDecodeRGBAInto(const unsigned char* data, size_t data_size,
                                  unsigned char* output_buffer, size_t output_buffer_size,
                                  int output_stride) { return NULL; }
size_t WebPEncodeLosslessRGBA(const unsigned char* rgba, int width, int height, int stride, unsigned char** output) { return 0; }
size_t WebPEncodeRGBA(const unsigned char* rgba, int width, int height, int stride, float quality_factor, unsigned char** output) { return 0; }

// cURL stubs
void* curl_easy_init(void) { return NULL; }
void curl_easy_cleanup(void* curl) {}
int curl_easy_setopt(void* curl, int option, ...) { return 0; }
int curl_easy_perform(void* curl) { return -1; }
const char* curl_easy_strerror(int errornum) { return "Stub implementation"; }

// PNG stubs
void* png_create_read_struct(const char* user_png_ver, void* error_ptr, void* error_fn, void* warn_fn) { return NULL; }
void* png_create_write_struct(const char* user_png_ver, void* error_ptr, void* error_fn, void* warn_fn) { return NULL; }
void* png_create_info_struct(void* png_ptr) { return NULL; }
void png_destroy_read_struct(void** png_ptr_ptr, void** info_ptr_ptr, void** end_info_ptr_ptr) {}
void png_destroy_write_struct(void** png_ptr_ptr, void** info_ptr_ptr) {}
void png_set_read_fn(void* png_ptr, void* io_ptr, void* read_data_fn) {}
void png_set_write_fn(void* png_ptr, void* io_ptr, void* write_data_fn, void* output_flush_fn) {}
void png_read_info(void* png_ptr, void* info_ptr) {}
void png_read_image(void* png_ptr, unsigned char** row_pointers) {}
void png_read_end(void* png_ptr, void* end_info_ptr) {}
void png_write_info(void* png_ptr, void* info_ptr) {}
void png_write_image(void* png_ptr, unsigned char** row_pointers) {}
void png_write_end(void* png_ptr, void* info_ptr) {}
int png_sig_cmp(const unsigned char* sig, size_t start, size_t num_to_check) { return -1; }
unsigned int png_get_IHDR(void* png_ptr, void* info_ptr, unsigned int* width, unsigned int* height,
                         int* bit_depth, int* color_type, int* interlace_method,
                         int* compression_method, int* filter_method) { return 0; }
void png_set_IHDR(void* png_ptr, void* info_ptr, unsigned int width, unsigned int height,
                  int bit_depth, int color_type, int interlace_method,
                  int compression_method, int filter_method) {}
void png_set_packing(void* png_ptr) {}
void png_set_strip_16(void* png_ptr) {}
void png_set_expand(void* png_ptr) {}
void png_set_gray_to_rgb(void* png_ptr) {}
int png_set_interlace_handling(void* png_ptr) { return 1; }
void png_read_update_info(void* png_ptr, void* info_ptr) {}
int png_get_channels(void* png_ptr, void* info_ptr) { return 0; }
size_t png_get_rowbytes(void* png_ptr, void* info_ptr) { return 0; }
void png_set_bgr(void* png_ptr) {}
void png_set_strip_alpha(void* png_ptr) {}
void png_error(void* png_ptr, const char* error_message) {}
void* png_jmpbuf(void* png_ptr) { return NULL; }
int setjmp(void* env) { return 0; }

// JPEG stubs
struct jpeg_compress_struct;
struct jpeg_decompress_struct;
struct jpeg_error_mgr;

void jpeg_CreateCompress(struct jpeg_compress_struct* cinfo, int version, size_t structsize) {}
void jpeg_CreateDecompress(struct jpeg_decompress_struct* cinfo, int version, size_t structsize) {}
void jpeg_destroy_compress(struct jpeg_compress_struct* cinfo) {}
void jpeg_destroy_decompress(struct jpeg_decompress_struct* cinfo) {}
void jpeg_destroy(void* cinfo) {}
void jpeg_finish_compress(struct jpeg_compress_struct* cinfo) {}
int jpeg_finish_decompress(struct jpeg_decompress_struct* cinfo) { return 1; }
void jpeg_calc_output_dimensions(struct jpeg_decompress_struct* cinfo) {}

// zlib stubs (these are actually provided by system, but including for completeness)
int deflateInit_(void* strm, int level, const char* version, int stream_size) { return -1; }
int deflate(void* strm, int flush) { return -1; }
int deflateEnd(void* strm) { return 0; }
int inflateInit_(void* strm, const char* version, int stream_size) { return -1; }
int inflate(void* strm, int flush) { return -1; }
int inflateEnd(void* strm) { return 0; }