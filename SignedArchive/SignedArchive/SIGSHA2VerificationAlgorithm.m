//
//  SIGSHA2VerificationAlgorithm.m
//  SignedArchive
//
//  Created by George Nachman on 12/18/18.
//  Copyright © 2018 George Nachman. All rights reserved.
//

#import "SIGSHA2VerificationAlgorithm.h"

#import "SIGArchiveCommon.h"
#import "SIGError.h"
#import "SIGVerificationAlgorithm.h"

#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>


@implementation SIGSHA2VerificationAlgorithm

+ (NSString *)name {
    return SIGArchiveDigestTypeSHA2;
}

- (BOOL)verifyInputStream:(NSInputStream *)payloadInputStream
            signatureData:(NSData *)signatureData
                publicKey:(SecKeyRef)publicKey
                    error:(out NSError **)error {
    [payloadInputStream open];

    CC_SHA256_CTX shaCtx;
    CC_SHA256_Init(&shaCtx);

    uint8_t buffer[4096];
    NSInteger bytesRead = 0;
    while ((bytesRead = [payloadInputStream read:buffer
                                     maxLength:sizeof(buffer)]) > 0) {
        CC_SHA256_Update(&shaCtx,
                         buffer,
                         (CC_LONG)bytesRead);
    }

    [payloadInputStream close];

    if (bytesRead < 0) {
        if (error) {
            *error = [SIGError errorWithCode:SIGErrorCodeUnknown
                                     detail:NSLocalizedStringFromTable(@"Error reading payload stream", @"signed_archive", @"读取有效负载流时出错")];
        }
        return NO;
    }

    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest,
                    &shaCtx);

    CFDataRef digestData = CFDataCreate(kCFAllocatorDefault,
                                        digest,
                                        CC_SHA256_DIGEST_LENGTH);

    SecKeyAlgorithm algorithm = kSecKeyAlgorithmRSASignatureDigestPKCS1v15SHA256;

    if (!SecKeyIsAlgorithmSupported(publicKey,
                                    kSecKeyOperationTypeVerify,
                                    algorithm)) {
        CFRelease(digestData);
        if (error) {
            *error = [SIGError errorWithCode:SIGErrorCodeAlgorithmCreationFailed
                                     detail:NSLocalizedStringFromTable(@"Key does not support requested algorithm", @"signed_archive", @"密钥不支持请求的算法")];
        }
        return NO;
    }

    CFErrorRef cfErr = NULL;
    Boolean result = SecKeyVerifySignature(publicKey,
                                           algorithm,
                                           digestData,
                                           (__bridge CFDataRef)signatureData,
                                           &cfErr);
    CFRelease(digestData);

    if (!result) {
        NSError *underlying = CFBridgingRelease(cfErr);
        if (error) {
            if (underlying) {
                *error = [SIGError errorWrapping:underlying
                                          code:SIGErrorCodeSignatureDoesNotMatchPayload
                                        detail:NSLocalizedStringFromTable(@"Signature verification failed", @"signed_archive", @"签名验证失败")];
            } else {
                *error = [SIGError errorWithCode:SIGErrorCodeSignatureDoesNotMatchPayload];
            }
        }
    }

    return (BOOL)result;
}

@end
