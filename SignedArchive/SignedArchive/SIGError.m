//
//  SIGError.m
//  SignedArchive
//
//  Created by George Nachman on 12/18/18.
//  Copyright © 2018 George Nachman. All rights reserved.
//

#import "SIGError.h"

NSString *const SIGErrorDomain = @"com.iterm2.sig";

@implementation SIGError

+ (instancetype)errorWithCode:(SIGErrorCode)code {
    NSString *localizedDescription = [self localizedDescriptionFcode:code];
    return [SIGError errorWithDomain:SIGErrorDomain
                                code:code
                            userInfo:@{ NSLocalizedDescriptionKey: [localizedDescription stringByAppendingString:@"."] }];
}

+ (instancetype)errorWithCode:(SIGErrorCode)code detail:(NSString *)detail {
    if (!detail) {
        return [self errorWithCode:code];
    }
    return [SIGError errorWithDomain:SIGErrorDomain
                                code:code
                            userInfo:@{ NSLocalizedDescriptionKey: [detail stringByAppendingString:@"."] }];
}

+ (instancetype)errorWrapping:(NSError *)otherError code:(SIGErrorCode)code detail:(NSString *)detail {
    if (!otherError) {
        return [self errorWithCode:code detail:detail];
    }

    if (!detail) {
        return [self errorWrapping:otherError code:code detail:[self localizedDescriptionFcode:code]];
    }

    NSString *innerDetail = otherError.localizedDescription ?: [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ error code %@", @"signed_archive", @"错误域与错误代码的兜底描述"),
                                                                otherError.domain, @(otherError.code)];
    NSString *description = [NSString stringWithFormat:@"%@: %@", detail, innerDetail];
    return [self errorWithCode:code detail:description];
}

#pragma mark - Private

+ (NSString *)localizedDescriptionFcode:(SIGErrorCode)code {
    switch (code) {
        case SIGErrorCodeConsistency:
            return NSLocalizedStringFromTable(@"Inconsistency discovered", @"signed_archive", @"发现数据不一致");
        case SIGErrorCodeIOWrite:
            return NSLocalizedStringFromTable(@"Error writing destination file", @"signed_archive", @"写入目标文件时出错");
        case SIGErrorCodeIORead:
            return NSLocalizedStringFromTable(@"Error reading source file", @"signed_archive", @"读取源文件时出错");
        case SIGErrorCodeNoPrivateKey:
            return NSLocalizedStringFromTable(@"No private key found", @"signed_archive", @"未找到私钥");
        case SIGErrorCodeNoCertificate:
            return NSLocalizedStringFromTable(@"No certificate found", @"signed_archive", @"未找到证书");
        case SIGErrorCodeNoMetadata:
            return NSLocalizedStringFromTable(@"No metadata found", @"signed_archive", @"未找到元数据");
        case SIGErrorCodeNoSignature:
            return NSLocalizedStringFromTable(@"No signature found", @"signed_archive", @"未找到签名");
        case SIGErrorCodeNoPayload:
            return NSLocalizedStringFromTable(@"No payload found", @"signed_archive", @"未找到有效负载");
        case SIGErrorCodeNoHeader:
            return NSLocalizedStringFromTable(@"No header found", @"signed_archive", @"未找到文件头");
        case SIGErrorCodeAlgorithmCreationFailed:
            return NSLocalizedStringFromTable(@"Could not create algorithm", @"signed_archive", @"无法创建算法");
        case SIGErrorCodeVersionTooNew:
            return NSLocalizedStringFromTable(@"This file is from a newer version of this app and cannot be loaded. Please upgrade and try again", @"signed_archive", @"此文件来自更高版本的应用，无法加载。请升级后重试");
        case SIGErrorCodeMalformedMetadata:
            return NSLocalizedStringFromTable(@"Metadata chunk malformed", @"signed_archive", @"元数据块格式错误");
        case SIGErrorCodeDeprecatedOldVersion:
            return NSLocalizedStringFromTable(@"This file is in an older format that is no longer supported because its authenticity cannot be guaranteed. It cannot be opened by this version of the app", @"signed_archive", @"此文件使用了已不再支持的旧格式，因为无法保证其真实性，当前版本的应用无法打开");
        case SIGErrorCodeMalformedHeader:
            return NSLocalizedStringFromTable(@"Header chunk malformed", @"signed_archive", @"文件头块格式错误");
        case SIGErrorCodeUnsupportedAlgorithm:
            return NSLocalizedStringFromTable(@"Unsupported algorithm", @"signed_archive", @"不支持的算法");
        case SIGErrorCodeUnknown:
            return NSLocalizedStringFromTable(@"Unknown or unexpected error", @"signed_archive", @"未知或意外错误");
        case SIGErrorCodeInputFileMalformed:
            return NSLocalizedStringFromTable(@"Input file malformed", @"signed_archive", @"输入文件格式错误");
        case SIGErrorCodeInputMalformedCertificate:
            return NSLocalizedStringFromTable(@"Malformed certificate", @"signed_archive", @"证书格式错误");
        case SIGErrorCodeTrust:
            return NSLocalizedStringFromTable(@"Error creating trust object", @"signed_archive", @"创建信任对象时出错");
        case SIGErrorCodeTrustUserDeny:
            return NSLocalizedStringFromTable(@"Trust chain verification failed by user preference", @"signed_archive", @"信任链验证因用户设置而失败");
        case SIGErrorCodeTrustMisconfiguration:
            return NSLocalizedStringFromTable(@"Trust chain verification internal error", @"signed_archive", @"信任链验证内部错误");
        case SIGErrorCodeTrustFailed:
            return NSLocalizedStringFromTable(@"Trust chain verification failed", @"signed_archive", @"信任链验证失败");
        case SIGErrorCodeSignatureDoesNotMatchPayload:
            return NSLocalizedStringFromTable(@"Signature does not match payload", @"signed_archive", @"签名与有效负载不匹配");
    }
    return NSLocalizedStringFromTable(@"Unknown error", @"signed_archive", @"未知错误");
}

@end
