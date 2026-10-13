//
//  main.m
//  sign
//
//  Created by George Nachman on 12/17/18.
//  Copyright © 2018 George Nachman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SIGArchiveBuilder.h"
#import "SIGCertificate.h"
#import "SIGIdentity.h"
#import <stdio.h>

SIGIdentity *FindSigningIdentity(NSString *query) {
    for (SIGIdentity *identity in [SIGIdentity allSigningIdentities]) {
        if ([identity.signingCertificate.longDescription localizedCaseInsensitiveContainsString:query]) {
            printf("%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Using identity %@", @"signed_archive", @"正在使用身份 %@"), identity.signingCertificate.longDescription] UTF8String]);
            return identity;
        }
    }
    return nil;
}

int main(int argc, const char * argv[]) {
    if (argc != 4) {
        fprintf(stderr, "%s\n", [NSLocalizedStringFromTable(@"Usage: sign filename.in identity filename.out", @"signed_archive", @"用法：sign 输入文件 身份 输出文件") UTF8String]);
        return -1;
    }
    
    @autoreleasepool {
        NSURL *payloadURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]];
        SIGIdentity *identity = FindSigningIdentity([NSString stringWithUTF8String:argv[2]]);
        if (!identity) {
            fprintf(stderr, "%s\n", [NSLocalizedStringFromTable(@"No identity found", @"signed_archive", @"未找到签名身份") UTF8String]);
            return -1;
        }
        SIGArchiveBuilder *builder = [[SIGArchiveBuilder alloc] initWithPayloadFileURL:payloadURL
                                                                              identity:identity];
        
        NSError *error = nil;
        NSURL *outputURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[3]]];
        const BOOL ok = [builder writeToURL:outputURL error:&error];
        if (!ok) {
            fprintf(stderr, "%s\n", [[NSString stringWithFormat:NSLocalizedStringFromTable(@"Signing error: %@", @"signed_archive", @"签名错误：%@"), error.localizedDescription] UTF8String]);
            return 1;
        }
    }
    return 0;
}
