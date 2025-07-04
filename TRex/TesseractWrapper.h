#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TesseractWrapper : NSObject

- (instancetype)init;
- (BOOL)initializeWithDataPath:(NSString *)dataPath language:(NSString *)language;
- (void)setImageData:(NSData *)imageData width:(NSInteger)width height:(NSInteger)height bytesPerRow:(NSInteger)bytesPerRow;
- (NSString *)recognizedText;
- (NSInteger)meanConfidence;
- (void)clear;
+ (NSArray<NSString *> *)availableLanguagesAtPath:(NSString *)dataPath;

@end

NS_ASSUME_NONNULL_END