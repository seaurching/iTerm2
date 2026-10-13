//
//  main.m
//  verify
//
//  Created by George Nachman on 12/18/18.
//  Copyright © 2018 George Nachman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdio.h>
#import "SIGArchiveVerifier.h"
#import "SIGCertificate.h"
#import "SIGError.h"

static NSString *Details(SIGArchiveVerifier *verifier) {
    NSMutableArray<NSString *> *detailLines = [NSMutableArray array];
    [detailLines addObject:NSLocalizedStringFromTable(@"    The following certificates were found:", @"signed_archive", @"    找到以下证书：")];
    BOOL first = YES;
    for (NSData *data in [verifier.reader signingCertificates:nil]) {
        SIGCertificate *cert = [[SIGCertificate alloc] initWithData:data];
        if (!cert) {
            continue;
        }
        NSString *name = ((cert.name ?: cert.longDescription) ?: NSLocalizedStringFromTable(@”Unknown”, @”signed_archive”, @”未知”));
        NSString *line = [NSString stringWithFormat:NSLocalizedStringFromTable(@”       Certificate \”%@\””, @”signed_archive”, @”       证书 \”%@\””), name];
        if (first) {
            line = [line stringByAppendingFormat:NSLocalizedStringFromTable(@” [signing cert]”, @”signed_archive”, @” [签名证书]”)];
        }

        if (cert.issuer) {
            NSString *name = ((cert.issuer.name ?: cert.issuer.longDescription) ?: NSLocalizedStringFromTable(@”Unknown”, @”signed_archive”, @”未知”));
            line = [line stringByAppendingFormat:NSLocalizedStringFromTable(@”, issued by \”%@\””, @”signed_archive”, @”，由 \”%@\” 颁发”), name];
        }
        first = NO;
        [detailLines addObject:line];
    }

    NSError *error;
    NSString *metadata = [verifier.reader metadata:&error];
    if (metadata.length > 0) {
        [detailLines addObject:NSLocalizedStringFromTable(@"    Metadata:", @"signed_archive", @"    元数据：")];
        for (NSString *line in [metadata componentsSeparatedByString:@"\n"]) {
            [detailLines addObject:[@"        " stringByAppendingString:line]];
        }
    }

    [detailLines addObject:[NSString stringWithFormat:NSLocalizedStringFromTable(@"    Payload length: %@", @"signed_archive", @"    有效负载长度： %@"), @(verifier.reader.payloadLength)]];
    return [detailLines componentsJoinedByString:@"\n"];
}

static NSError *Verify(NSString *path, BOOL requireV2, NSString **detailsPtr) {
    SIGArchiveVerifier *verifier = [[SIGArchiveVerifier alloc] initWithURL:[NSURL fileURLWithPath:path]];
    __block BOOL result;
    __block NSError *errorResult = nil;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    __block NSString *details;
    verifier.minimumVersion = requireV2 ? 2 : 1;
    [verifier verifyWithCompletion:^(BOOL ok, NSError *error) {
        details = Details(verifier);
        result = ok;
        errorResult = error;
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    if (detailsPtr) {
        *detailsPtr = details;
    }
    if (result) {
        return nil;
    }
    if (errorResult) {
        return errorResult;
    }
    return [SIGError errorWithCode:SIGErrorCodeUnknown detail:NSLocalizedStringFromTable(@"Verification failed for an unknown reason", @"signed_archive", @"验证失败，原因未知")];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "%s\n", [NSLocalizedStringFromTable(@"Usage: verify [-v] [-2] file [file...]", @"signed_archive", @"用法：verify [-v] [-2] 文件 [文件...]") UTF8String]);
            return 1;
        }
        int errors = 0;
        int first = 1;
        BOOL requireV2 = NO;
        BOOL verbose = NO;
        if (argc > 1 && !strcmp(argv[1], "-v")) {
            verbose = YES;
            first++;
        }
        if (argc > first && !strcmp(argv[first], "-2")) {
            requireV2 = YES;
            first++;
        }
        for (int i = first; i < argc; i++) {
            NSString *details;
            NSError *error = Verify([NSString stringWithUTF8String:argv[i]],
                                    requireV2,
                                    verbose ? &details : NULL);
            if (error) {
                errors++;
                printf("%s: %s\n", argv[i], error.localizedDescription.UTF8String);
            } else {
                printf("%s: %s\n", argv[i], [NSLocalizedStringFromTable(@"ok", @"signed_archive", @"正常") UTF8String]);
                if (verbose) {
                    printf("%s\n", details.UTF8String);
                }
            }
        }
        return errors > 0;
    }
}
