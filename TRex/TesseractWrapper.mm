// TesseractWrapper.mm
// Objective-C++ implementation that wraps Tesseract C++ API

#import "TesseractWrapper.h"
#import <Foundation/Foundation.h>

// Include C++ headers - only what we need
#include <tesseract/baseapi.h>
#include <memory>
#include <string>

@interface TesseractWrapper () {
    std::unique_ptr<tesseract::TessBaseAPI> _tesseract;
    NSString *_currentLanguage;
}
@end

@implementation TesseractWrapper

+ (void)load {
    // This ensures the class is registered with the Objective-C runtime
    // and can be found via NSClassFromString
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _tesseract = std::make_unique<tesseract::TessBaseAPI>();
    }
    return self;
}

- (BOOL)initializeWithDataPath:(NSString *)dataPath language:(NSString *)language {
    if (!_tesseract) {
        return NO;
    }
    
    // End any previous initialization
    _tesseract->End();
    
    // Initialize Tesseract with language and data path
    const char *langCStr = [language UTF8String];
    const char *dataPathCStr = [dataPath UTF8String];
    
    if (_tesseract->Init(dataPathCStr, langCStr) != 0) {
        NSLog(@"[TesseractWrapper] Failed to initialize Tesseract with language: %@, dataPath: %@", language, dataPath);
        return NO;
    }
    
    _currentLanguage = language;
    NSLog(@"[TesseractWrapper] Successfully initialized with language: %@", language);
    return YES;
}

- (void)setImageData:(NSData *)imageData width:(NSInteger)width height:(NSInteger)height bytesPerRow:(NSInteger)bytesPerRow {
    if (!_tesseract || !imageData) {
        NSLog(@"[TesseractWrapper] setImageData called with invalid state");
        return;
    }
    
    // Tesseract expects RGBA data
    _tesseract->SetImage((unsigned char *)imageData.bytes,
                        (int)width,
                        (int)height,
                        4,  // bytes per pixel (RGBA)
                        (int)bytesPerRow);
}

- (NSString *)recognizedText {
    if (!_tesseract) {
        return @"";
    }
    
    char *outText = _tesseract->GetUTF8Text();
    if (!outText) {
        return @"";
    }
    
    NSString *result = [NSString stringWithUTF8String:outText];
    delete[] outText;
    
    return result ? result : @"";
}

- (NSInteger)meanConfidence {
    if (!_tesseract) {
        return 0;
    }
    
    return _tesseract->MeanTextConf();
}

- (void)clear {
    if (_tesseract) {
        _tesseract->Clear();
    }
}

+ (NSArray<NSString *> *)availableLanguagesAtPath:(NSString *)dataPath {
    NSMutableArray<NSString *> *languages = [NSMutableArray array];
    
    // Look for .traineddata files in the directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:dataPath error:&error];
    if (error) {
        NSLog(@"[TesseractWrapper] Error reading tessdata directory at %@: %@", dataPath, error);
        return languages;
    }
    
    for (NSString *file in files) {
        if ([file hasSuffix:@".traineddata"]) {
            NSString *lang = [file stringByDeletingPathExtension];
            [languages addObject:lang];
        }
    }
    
    NSLog(@"[TesseractWrapper] Found %lu language files at %@", (unsigned long)languages.count, dataPath);
    return [languages sortedArrayUsingSelector:@selector(compare:)];
}

@end