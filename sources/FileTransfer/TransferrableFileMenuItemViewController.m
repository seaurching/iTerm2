//
//  TransferrableFileMenuItemViewController.m
//  iTerm
//
//  Created by George Nachman on 12/23/13.
//
//

#import "TransferrableFileMenuItemViewController.h"
#import "FileTransferManager.h"
#import "TransferrableFileMenuItemView.h"

static const CGFloat kWidth = 300;
static const CGFloat kHeight = 63;
static const CGFloat kCollapsedHeight = 51;

@interface TransferrableFileMenuItemViewController()<NSMenuItemValidation>
@end

@implementation TransferrableFileMenuItemViewController {
    BOOL _hasOpenedMenu;
    NSVisualEffectView *_effectView;
    TransferrableFileMenuItemView *_contentView;
}

- (instancetype)initWithTransferrableFile:(TransferrableFile *)transferrableFile {
    self = [super init];
    if (self) {
        _transferrableFile = transferrableFile;
        _effectView = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(5,
                                                                           0,
                                                                           kWidth - 10,
                                                                           kHeight)];
        _effectView.material = NSVisualEffectMaterialSelection;
        _effectView.wantsLayer = YES;
        _effectView.autoresizingMask = NSViewWidthSizable;
        _effectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
        _effectView.emphasized = YES;
        _effectView.layer.cornerRadius = 4;
        _effectView.layer.masksToBounds = YES;
        _effectView.state = NSVisualEffectStateActive;
        _effectView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.view.autoresizesSubviews = YES;
        [self.view addSubview:_effectView];
        _contentView = [[TransferrableFileMenuItemView alloc] initWithFrame:NSMakeRect(0,
                                                                                       0,
                                                                                       kWidth,
                                                                                       kHeight)
                                                                 effectView:_effectView];
        _contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        [self.view addSubview:_contentView];
    }
    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0,
                                                         0,
                                                         kWidth,
                                                         kHeight)];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(itemSelected:)) {
        return YES;
    }
    TransferrableFileStatus status = _transferrableFile.status;
    if ([menuItem action] == @selector(stop:)) {
        return (status == kTransferrableFileStatusStarting ||
                status == kTransferrableFileStatusTransferring);
    }
    if ([menuItem action] == @selector(showInFinder:)) {
        if (self.transferrableFile.localPath == nil ||
            [NSURL fileURLWithPath:self.transferrableFile.localPath] == nil) {
            return NO;
        }
        return (status == kTransferrableFileStatusFinishedSuccessfully);
    }
    if ([menuItem action] == @selector(removeFromList:)) {
        return (status == kTransferrableFileStatusFinishedSuccessfully ||
                status == kTransferrableFileStatusFinishedWithError ||
                status == kTransferrableFileStatusCancelled);
    }
    if ([menuItem action] == @selector(open:)) {
        return (status == kTransferrableFileStatusFinishedSuccessfully);
    }
    if ([menuItem action] == @selector(getInfo:)) {
        return YES;
    }
    return NO;
}

- (void)showMenu {
    if (!_hasOpenedMenu) {
        if (self.transferrableFile.isDownloading) {
            [[FileTransferManager sharedInstance] openDownloadsMenu];
        } else {
            [[FileTransferManager sharedInstance] openUploadsMenu];
        }
        _hasOpenedMenu = YES;
    }
}

- (void)update {
    TransferrableFileMenuItemView *view = _contentView;
    view.filename = [_transferrableFile shortName];
    view.subheading = [_transferrableFile subheading];
    double fileSize = [_transferrableFile fileSize];
    view.size = fileSize;
    if ([_transferrableFile fileSize] > 0) {
        double fraction = [_transferrableFile bytesTransferred];
        fraction /= [_transferrableFile fileSize];
        view.progressIndicator.fraction = fraction;
        [view.progressIndicator setNeedsDisplay:YES];
    }
    view.bytesTransferred = [_transferrableFile bytesTransferred];
    switch (_transferrableFile.status) {
        case kTransferrableFileStatusUnstarted:
        case kTransferrableFileStatusStarting:
            view.statusMessage = NSLocalizedStringFromTableInBundle(@"Starting…", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: starting");
            [self collapse];
            break;

        case kTransferrableFileStatusTransferring:
            [self expand];
            [view.progressIndicator setHidden:[_transferrableFile fileSize] < 0];
            if (self.transferrableFile.isDownloading) {
                view.statusMessage = NSLocalizedStringFromTableInBundle(@"Downloading…", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: downloading");
            } else {
                view.statusMessage = NSLocalizedStringFromTableInBundle(@"Uploading…", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: uploading");
            }
            [self showMenu];
            break;

        case kTransferrableFileStatusFinishedSuccessfully:
            [self collapse];
            view.statusMessage = NSLocalizedStringFromTableInBundle(@"Finished", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: finished");
            break;

        case kTransferrableFileStatusFinishedWithError:
            [self collapse];
            view.statusMessage = NSLocalizedStringFromTableInBundle(@"Failed", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: failed");
            [self showMenu];
            break;

        case kTransferrableFileStatusCancelling:
            [self expand];
            view.statusMessage = NSLocalizedStringFromTableInBundle(@"Cancelling…", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: cancelling");
            break;

        case kTransferrableFileStatusCancelled:
            [self collapse];
            view.statusMessage = NSLocalizedStringFromTableInBundle(@"Cancelled", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: cancelled");
            break;
    }
    [view setNeedsDisplay:YES];
}

- (void)collapse {
    [_contentView.progressIndicator setHidden:YES];
    self.view.frame = NSMakeRect(0, 0, self.view.frame.size.width, kCollapsedHeight);
}

- (void)expand {
    [_contentView.progressIndicator setHidden:NO];
    self.view.frame = NSMakeRect(0, 0, self.view.frame.size.width, kHeight);
}

- (void)itemSelected:(id)sender {
    NSLog(@"Click");
}

- (void)stop:(id)sender {
    [self.transferrableFile stop];
}

- (void)showInFinder:(id)sender {
    NSURL *theUrl = [NSURL fileURLWithPath:self.transferrableFile.localPath];
    if (theUrl) {
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ theUrl ]];
    }

}
- (void)removeFromList:(id)sender {
    [[FileTransferManager sharedInstance] removeItem:self];
}

- (void)open:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:self.transferrableFile.localPath]];
}

- (NSString *)stringForStatus:(TransferrableFileStatus)status {
    switch (_transferrableFile.status) {
        case kTransferrableFileStatusUnstarted:
            return NSLocalizedStringFromTableInBundle(@"Unstarted", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: unstarted");
        case kTransferrableFileStatusStarting:
            return NSLocalizedStringFromTableInBundle(@"Starting", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: starting");
        case kTransferrableFileStatusTransferring:
            return NSLocalizedStringFromTableInBundle(@"Transferring", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: transferring");
        case kTransferrableFileStatusFinishedSuccessfully:
            return NSLocalizedStringFromTableInBundle(@"Finished", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: finished");
        case kTransferrableFileStatusFinishedWithError:
            return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Failed with error “%@”", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: failed with error"), [_transferrableFile error]];
        case kTransferrableFileStatusCancelling:
            return NSLocalizedStringFromTableInBundle(@"Waiting to cancel", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: waiting to cancel");
        case kTransferrableFileStatusCancelled:
            return NSLocalizedStringFromTableInBundle(@"Canceled by user", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Status: canceled by user");
    }
}

- (void)getInfo:(id)sender {
    NSString *extra = @"";
    if (_transferrableFile.destination) {
        extra = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"\nDestination: %@", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Get Info: destination"),
                       _transferrableFile.destination];
    } else if (_transferrableFile.localPath) {
        extra = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"\nLocal path: %@", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Get Info: local path"),
                       _transferrableFile.localPath];
    }
    NSString *text = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@\n\nStatus: %@%@", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Get Info: file transfer summary"),
                      [_transferrableFile displayName],
                      [self stringForStatus:_transferrableFile.status],
                      extra];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = NSLocalizedStringFromTableInBundle(@"File Transfer Summary", @"FileTransfer", [NSBundle bundleForClass:[self class]], @"Alert title: file transfer summary");
    alert.informativeText = text;
    [alert layout];
    [alert runModal];
}

- (NSTimeInterval)timeSinceLastStatusChange {
    return [NSDate timeIntervalSinceReferenceDate] - [_transferrableFile timeOfLastStatusChange];
}

@end
