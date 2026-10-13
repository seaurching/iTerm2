//
//  iTermShellIntegrationPasteShellCommandsViewController.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 12/22/19.
//

#import "iTermShellIntegrationPasteShellCommandsViewController.h"

@interface iTermShellIntegrationPasteShellCommandsViewController ()

@property (nonatomic, strong) IBOutlet NSTextField *textField;
@property (nonatomic, strong) IBOutlet NSButton *previewCommandButton1;
@property (nonatomic, strong) IBOutlet NSButton *previewCommandButton2;
@property (nonatomic, strong) IBOutlet NSButton *previewCommandButton3;
@property (nonatomic, strong) IBOutlet NSButton *previewCommandButton4;
@property (nonatomic, strong) IBOutlet NSTextView *previewTextView;
@property (nonatomic, strong) IBOutlet NSViewController *popoverViewController;
@property (nonatomic, strong) IBOutlet NSPopover *popover;
@property (nonatomic, strong) IBOutlet NSButton *continueButton;
@property (nonatomic, strong) IBOutlet NSButton *skipButton;

@end

@implementation iTermShellIntegrationPasteShellCommandsViewController {
    BOOL _busy;
}

- (void)setShell:(iTermShellIntegrationShell)shell {
    _shell = shell;
    if (shell == iTermShellIntegrationShellUnknown) {
        self.continueButton.enabled = NO;
    } else {
        self.continueButton.enabled = YES;
    }
}

- (void)setStage:(int)stage {
    _stage = stage;
    [self update];
}

- (NSString *)waitingText {
    return NSLocalizedStringFromTableInBundle(@"⏳ Waiting for command to complete…", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: waiting text");
}
- (void)update {
    const int stage = _stage;
    if (stage < 0) {
        self.shell = iTermShellIntegrationShellUnknown;
    }
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    NSInteger indexToBold = NSNotFound;
    NSString *step;
    NSString *prefix;

    if (stage < 0) {
        prefix = NSLocalizedStringFromTableInBundle(@"1. Discover", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 1 label");
    } else if (stage == 0) {
        if (_busy) {
            prefix = self.waitingText;
        } else {
            prefix = NSLocalizedStringFromTableInBundle(@"➡ Select “Continue” to discover", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 1 prompt");
        }
        indexToBold = lines.count;
    } else if (stage > 0) {
        if (self.shell == iTermShellIntegrationShellUnknown) {
            prefix = NSLocalizedStringFromTableInBundle(@"🛑 Your shell is not supported.\n\nOnly bash, fish, tcsh, xonsh, and zsh work with shell integration", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: shell unsupported error");
        } else {
            prefix = NSLocalizedStringFromTableInBundle(@"✅ Discovered", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 1 done");
        }
    }
    if (self.shell == iTermShellIntegrationShellUnknown || (_busy && stage == 0)) {
        step = prefix;
    } else {
        step = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ your shell", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step action for shell"), prefix];
    }
    if (stage > 0) {
        if (self.shell != iTermShellIntegrationShellUnknown) {
            step = [step stringByAppendingFormat:NSLocalizedStringFromTableInBundle(@": you use “%@”.", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: shell name suffix"), iTermShellIntegrationShellString(self.shell)];
        }
    } else if (stage != 0 || !_busy) {
        step = [step stringByAppendingString:@"."];
    }
    [lines addObject:step];

    const BOOL unavailable = (stage == 1 && self.shell == iTermShellIntegrationShellUnknown);
    self.continueButton.enabled = !(unavailable || _busy);
    if (unavailable) {
        self.skipButton.enabled = NO;
    } else {
        if (stage < 1) {
            prefix = NSLocalizedStringFromTableInBundle(@"Step 2. Write", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 2 label");
        } else if (stage == 1) {
            if (self.shell == iTermShellIntegrationShellUnknown) {
                prefix = NSLocalizedStringFromTableInBundle(@"Step 2. Write", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 2 label");
            } else if (_busy) {
                prefix = self.waitingText;
            } else {
                prefix = NSLocalizedStringFromTableInBundle(@"➡ Select “Continue” to write", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 2 prompt");
            }
            indexToBold = lines.count;
        } else if (stage > 1) {
            prefix = NSLocalizedStringFromTableInBundle(@"✅ Wrote", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 2 done");
        }
        if (_busy && stage == 1) {
            step = prefix;
        } else {
            step = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ the shell integration script.", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 2 action"), prefix];
        }
        [lines addObject:step];

        int i = 2;
        if (self.installUtilities) {
            i += 1;
            if (stage < 2) {
                prefix = NSLocalizedStringFromTableInBundle(@"Step 3. Install", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 3 label");
            } else if (stage == 2 && !_busy) {
                prefix = NSLocalizedStringFromTableInBundle(@"➡ Select “Continue” to install", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 3 prompt");
                indexToBold = lines.count;
            } else if (stage == 2 && _busy) {
                prefix = self.waitingText;
                indexToBold = lines.count;
            } else {
                prefix = NSLocalizedStringFromTableInBundle(@"✅ Installed", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 3 done");
            }
            if (_busy && stage == 2) {
                step = prefix;
            } else {
                step = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ iTerm2 utility scripts.", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: step 3 action"), prefix];
            }
            [lines addObject:step];
        }

        // Xonsh auto-loads scripts from rc.d, so no dotfile modification is needed.
        // Show this step as already complete for xonsh.
        if (self.shell == iTermShellIntegrationShellXonsh) {
            if (stage < i) {
                step = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Step %d. Xonsh auto-loads scripts from rc.d (no dotfile update needed).", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: xonsh step label"), i + 1];
            } else {
                step = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"✅ Xonsh auto-loads scripts from rc.d (no dotfile update needed).", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: xonsh step done")];
            }
            [lines addObject:step];
        } else {
            if (stage < i) {
                prefix = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Step %d. Update", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: update step label"), i + 1];
            } else if (stage == i && !_busy) {
                prefix = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"➡ Select “Continue” to update", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: update step prompt")];
                indexToBold = lines.count;
            } else if (stage == i && _busy) {
                prefix = self.waitingText;
                indexToBold = lines.count;
            } else if (stage > i) {
                prefix = NSLocalizedStringFromTableInBundle(@"✅ Updated", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: update step done");
            }
            if (_busy && stage == i) {
                step = prefix;
            } else {
                step =
                [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@ your shell's dotfile.", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: update step action"), prefix];
            }
            [lines addObject:step];
        }
        
        // For xonsh, stage >= i means we're at the dotfile step which is a no-op,
        // so treat it as done. For other shells, we need stage > i.
        BOOL isDone = (stage > i) || (stage >= i && self.shell == iTermShellIntegrationShellXonsh);
        if (isDone) {
            [lines addObject:@""];
            indexToBold = lines.count;
            [lines addObject:NSLocalizedStringFromTableInBundle(@"Done! Select “Continue” to proceed.", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: done message")];
            self.skipButton.enabled = NO;
        } else {
            self.skipButton.enabled = !_busy;
        }
    }

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 4;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    NSDictionary *regularAttributes =
    @{ NSFontAttributeName: [NSFont systemFontOfSize:[NSFont systemFontSize]],
       NSForegroundColorAttributeName: [NSColor textColor],
       NSParagraphStyleAttributeName: paragraphStyle
    };
    NSDictionary *boldAttributes =
    @{ NSFontAttributeName: [NSFont boldSystemFontOfSize:[NSFont systemFontSize]],
       NSForegroundColorAttributeName: [NSColor textColor],
       NSParagraphStyleAttributeName: paragraphStyle
    };
    [lines enumerateObjectsUsingBlock:^(NSString * _Nonnull string, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *temp = [string stringByAppendingString:@"\n"];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:temp attributes:idx == indexToBold ? boldAttributes : regularAttributes];
        [attributedString appendAttributedString:as];
    }];
    self.textField.attributedStringValue = attributedString;
    NSString *preview = [self.shellInstallerDelegate shellIntegrationInstallerNextCommandForSendShellCommands];
    NSArray<NSButton *> *buttons = self.previewCommandButtons;
    for (NSInteger i = 0; i < self.previewCommandButtons.count; i++){
        buttons[i].hidden = unavailable || (i != stage) || preview == nil;
        if (_busy && i == stage) {
            [buttons[i] setTitle:NSLocalizedStringFromTableInBundle(@"Send Again", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: send again button")];
        } else {
            [buttons[i] setTitle:NSLocalizedStringFromTableInBundle(@"Preview Command", @"ShellIntegrationInstaller", [NSBundle bundleForClass:[self class]], @"paste commands: preview command button")];
        }
    }
    self.previewTextView.string = preview ?: @"";
}

- (NSArray<NSButton *> *)previewCommandButtons {
    return @[ self.previewCommandButton1, self.previewCommandButton2, self.previewCommandButton3, self.previewCommandButton4 ];
}

- (NSButton *)previewCommandButton {
    NSArray<NSButton *> *buttons = self.previewCommandButtons;
    if (self.stage < 0 || self.stage >= buttons.count) {
        return nil;
    }
    return buttons[self.stage];
}

- (IBAction)previewCommand:(id)sender {
    if (_busy) {
        [self.shellInstallerDelegate shellIntegrationInstallerCancelExpectations];
        [self.shellInstallerDelegate shellIntegrationInstallerSendShellCommands:_stage];
        return;
    }
    self.popover.behavior = NSPopoverBehaviorTransient;
    [self.popoverViewController view];
    self.previewTextView.font = [NSFont fontWithName:@"Menlo" size:12];
    [self.popover showRelativeToRect:self.previewCommandButton.bounds
                              ofView:self.previewCommandButton
                       preferredEdge:NSRectEdgeMaxY];
}

- (IBAction)skip:(id)sender {
    [self.shellInstallerDelegate shellIntegrationInstallerSkipStage];
}

- (IBAction)next:(id)sender {
    [self.shellInstallerDelegate shellIntegrationInstallerSendShellCommands:_stage];
}

- (IBAction)back:(id)sender {
    [self.shellInstallerDelegate shellIntegrationInstallerCancelExpectations];
    if (_stage == 0) {
        [self.shellInstallerDelegate shellIntegrationInstallerBack];
    } else {
        self.stage = self.stage - 1;
    }
}

- (void)setBusy:(BOOL)busy {
    _busy = busy;
    [self update];
}

@end

