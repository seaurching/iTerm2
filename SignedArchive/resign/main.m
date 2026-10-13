//
//  main.c
//  sign
//
//  Created by George Nachman on 7/28/19.
//  Copyright © 2019 George Nachman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SIGArchiveBuilder.h"
#import "SIGArchiveCommon.h"
#import "SIGArchiveReader.h"
#import "SIGCertificate.h"
#import "SIGIdentity.h"
#import <stdio.h>

typedef enum {
    SIGReSignModeError,
    SIGReSignModeMultiple,
    SIGReSignModeSingle
} SIGReSignMode;

SIGIdentity *FindSigningIdentity(NSString *query) {
    for (SIGIdentity *identity in [SIGIdentity allSigningIdentities]) {
        if ([identity.signingCertificate.longDescription localizedCaseInsensitiveContainsString:query]) {
            printf("%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Using identity %@", @"signed_archive", @"正在使用身份 %@"), identity.signingCertificate.longDescription] UTF8String]);
            return identity;
        }
    }
    return nil;
}

NSURL *CreateTemporaryURL(NSURL *eventualDestinationURL) {
    NSURL *destinationURL = eventualDestinationURL;

    NSError *error = nil;
    NSURL *temporaryDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory
                                                                          inDomain:NSUserDomainMask
                                                                 appropriateForURL:destinationURL
                                                                            create:YES
                                                                             error:&error];
    if (!temporaryDirectoryURL || error) {
        return nil;
    }

    NSString *temporaryFilename = [[NSProcessInfo processInfo] globallyUniqueString];
    return [temporaryDirectoryURL URLByAppendingPathComponent:temporaryFilename];
}

NSURL *TemporaryURLOfExtractedUnverifiedPayload(NSURL *archiveURL) {
    SIGArchiveReader *reader;
    reader = [[SIGArchiveReader alloc] initWithURL:archiveURL];
    if (!reader) {
        return nil;
    }

    NSError *error;
    [reader load:&error];
    if (error) {
        fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Failed to load %@: %@", @"signed_archive", @"加载 %@ 失败：%@"), archiveURL.path, error.localizedDescription] UTF8String]);
        return nil;
    }

    NSInputStream *readStream = [reader payloadInputStream:&error];
    if (error || !readStream) {
        fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not realize input stream from %@: %@", @"signed_archive", @"无法从 %@ 创建输入流：%@"), archiveURL.path, error.localizedDescription] UTF8String]);
        return nil;
    }
    [readStream open];

    NSURL *url = CreateTemporaryURL([NSURL fileURLWithPath:NSTemporaryDirectory()]);
    if (!url) {
        fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not create temporary file in %@", @"signed_archive", @"无法在 %@ 中创建临时文件"), NSTemporaryDirectory()] UTF8String]);
        return nil;
    }

    NSOutputStream *writeStream = [[NSOutputStream alloc] initWithURL:url append:NO];
    if (!writeStream) {
        fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not create output stream to write to %@", @"signed_archive", @"无法创建输出流写入 %@"), url.path] UTF8String]);
        return nil;
    }
    [writeStream open];

    NSInteger numberOfBytesCopied = 0;
    while ([readStream hasBytesAvailable]) {
        uint8_t buffer[4096];
        const NSInteger numberOfBytesRead = [readStream read:buffer maxLength:sizeof(buffer)];
        if (numberOfBytesRead == 0) {
            break;
        }
        if (numberOfBytesRead < 0) {
            fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Error %@ reading from %@", @"signed_archive", @"从 %@ 读取时出错：%@"), readStream.streamError.localizedDescription, archiveURL.path] UTF8String]);
            return nil;
        }

        const NSInteger numberOfBytesWritten = [writeStream write:buffer maxLength:numberOfBytesRead];
        if (numberOfBytesWritten != numberOfBytesRead) {
            fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Error %@ while writing to %@", @"signed_archive", @"写入 %@ 时出错：%@"), writeStream.streamError.localizedDescription, url.path] UTF8String]);
            return nil;
        }

        numberOfBytesCopied += numberOfBytesWritten;
    }
    [writeStream close];

    return url;
}

static BOOL ReSignExtracted(NSURL *oldArchiveURL,
                            NSString *identityName,
                            NSURL *outputURL,
                            NSURL *payloadURL) {
    if (!payloadURL) {
        fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Could not extract from %@", @"signed_archive", @"无法从 %@ 中提取"), oldArchiveURL.path] UTF8String]);
        return NO;
    }
    SIGIdentity *identity = FindSigningIdentity(identityName);
    if (!identity) {
        fprintf(stderr, "%s\n", [NSLocalizedStringFromTable(@"No identity found", @"signed_archive", @"未找到签名身份") UTF8String]);
        return NO;
    }
    SIGArchiveBuilder *builder = [[SIGArchiveBuilder alloc] initWithPayloadFileURL:payloadURL
                                                                          identity:identity];

    NSError *error = nil;
    const BOOL ok = [builder writeToURL:outputURL error:&error];
    if (!ok) {
        fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Signing error: %@", @"signed_archive", @"签名错误：%@"), error.localizedDescription] UTF8String]);
        return NO;
    }

    return YES;
}

static void DeleteTempFile(NSURL *payloadURL) {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:payloadURL error:&error];
    if (error) {
        fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Warning: While deleting temp file %@: %@", @"signed_archive", @"警告：删除临时文件 %@ 时出错：%@"), payloadURL.path, error.localizedDescription] UTF8String]);
    }
}

static BOOL ReSign(NSURL *oldArchiveURL,
                   NSString *identityName,
                   NSURL *outputURL) {
    NSURL *payloadURL = TemporaryURLOfExtractedUnverifiedPayload(oldArchiveURL);
    const BOOL ok = ReSignExtracted(oldArchiveURL, identityName, outputURL, payloadURL);
    DeleteTempFile(payloadURL);
    return ok;
}

static void Move(NSURL *source, NSURL *dest) {
    NSError *error = nil;
    [[NSFileManager defaultManager] replaceItemAtURL:dest
                                       withItemAtURL:source
                                      backupItemName:nil
                                             options:0
                                    resultingItemURL:nil
                                               error:&error];
    if (error) {
        fprintf(stderr, "%s", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"While moving temp file %@ over input file %@: %@", @"signed_archive", @"将临时文件 %@ 移动覆盖输入文件 %@ 时出错：%@"), source.path, dest.path, error.localizedDescription] UTF8String]);
    }
}

static int ResignMultiple(int argc, const char *argv[]) {
    NSInteger errorCount = 0;
    NSString *identityName = [NSString stringWithUTF8String:argv[2]];
    for (size_t i = 3; i < argc; i++) {
        NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[i]]];
        NSURL *temporaryFileURL = CreateTemporaryURL([NSURL fileURLWithPath:NSTemporaryDirectory()]);
        if (!ReSign(fileURL, identityName, temporaryFileURL)) {
            errorCount += 1;
        }
        Move(temporaryFileURL, fileURL);
    }
    return errorCount == 0 ? 0 : 1;
}

static int ResignSingle(int argc, const char *argv[]) {
    NSURL *oldArchiveURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
    NSString *identityName = [NSString stringWithUTF8String:argv[2]];
    NSURL *outputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[3]]];
    if (!ReSign(oldArchiveURL, identityName, outputURL)) {
        return 1;
    }
    return 0;
}

static void Usage(void) {
    fprintf(stderr, "%s\n", [NSLocalizedStringFromTable(@"Usage: resign filename.in identity filename.out", @"signed_archive", @"用法：resign 输入文件 身份 输出文件") UTF8String]);
    fprintf(stderr, "%s\n", [NSLocalizedStringFromTable(@"       resign -m identity file [file...]", @"signed_archive", @"       resign -m 身份 文件 [文件...]") UTF8String]);
}

static SIGReSignMode CheckArgs(int argc, const char *argv[]) {
    if (argc < 4) {
        return SIGReSignModeError;
    }
    if (!strcmp(argv[1], "-m")) {
        return SIGReSignModeMultiple;
    }
    if (argc > 4) {
        return SIGReSignModeError;
    }
    return SIGReSignModeSingle;
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        switch (CheckArgs(argc, argv)) {
            case SIGReSignModeError:
                Usage();
                return 1;
            case SIGReSignModeSingle:
                return ResignSingle(argc, argv);
            case SIGReSignModeMultiple:
                return ResignMultiple(argc, argv);
        }
    }
}
