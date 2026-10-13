//
//  iTermStatusBarSwiftyStringComponent.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 6/29/18.
//

#import "iTermStatusBarSwiftyStringComponent.h"

#import "iTermScriptHistory.h"
#import "iTermStatusBarComponentKnob.h"
#import "iTermVariableScope.h"
#import "iTermWarning.h"
#import "NSDictionary+iTerm.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const iTermStatusBarSwiftyStringComponentExpressionKey = @"expression";

@implementation iTermStatusBarSwiftyStringComponent {
    iTermSwiftyString *_swiftyString;
    NSString *_errorReason;
}

- (instancetype)initWithConfiguration:(NSDictionary<iTermStatusBarComponentConfigurationKey,id> *)configuration
                                scope:(nullable iTermVariableScope *)scope {
    self = [super initWithConfiguration:configuration scope:scope];
    if (self) {
        [self updateWithKnobValues:self.configuration[iTermStatusBarComponentConfigurationKeyKnobValues]];
    }
    return self;
}

- (NSString *)statusBarComponentShortDescription {
    return NSLocalizedStringFromTableInBundle(@"Interpolated String", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Short description for interpolated string component");
}

- (NSString *)statusBarComponentDetailedDescription {
    return NSLocalizedStringFromTableInBundle(@"Shows the evaluation of a string with inline expressions which may include session variables or the output of registered scripting functions", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Detailed description for interpolated string component");
}

- (NSArray<iTermStatusBarComponentKnob *> *)statusBarComponentKnobs {
    iTermStatusBarComponentKnob *expressionKnob =
        [[iTermStatusBarComponentKnob alloc] initWithLabelText:NSLocalizedStringFromTableInBundle(@"String Value:", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Knob label for string value")
                                                          type:iTermStatusBarComponentKnobTypeText
                                                   placeholder:NSLocalizedStringFromTableInBundle(@"String with \\(expressions)", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Placeholder for string value field")
                                                  defaultValue:@""
                                                           key:iTermStatusBarSwiftyStringComponentExpressionKey];
    return [@[ expressionKnob ] arrayByAddingObjectsFromArray:[super statusBarComponentKnobs]];
}

+ (NSDictionary *)statusBarComponentDefaultKnobs {
    NSDictionary *fromSuper = [super statusBarComponentDefaultKnobs];
    return [fromSuper dictionaryByMergingDictionary:@{ iTermStatusBarSwiftyStringComponentExpressionKey: @"" }];
}

- (id)statusBarComponentExemplarWithBackgroundColor:(NSColor *)backgroundColor
                                          textColor:(NSColor *)textColor {
    if (!_swiftyString.swiftyString.length) {
        return NSLocalizedStringFromTableInBundle(@"\\(expression)", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Exemplar text for interpolated string component");
    } else {
        return _swiftyString.swiftyString;
    }
}

- (BOOL)statusBarComponentCanStretch {
    return YES;
}

- (void)setStringValue:(NSString *)value {
    _value = [value copy];
    [self updateTextFieldIfNeeded];
}

- (BOOL)statusBarComponentIsEmpty {
    return _value.length == 0;
}

- (NSTextField *)newTextField {
    NSTextField *textField = [super newTextField];

    NSClickGestureRecognizer *recognizer = [[NSClickGestureRecognizer alloc] init];
    recognizer.buttonMask = 1;
    recognizer.numberOfClicksRequired = 1;
    recognizer.target = self;
    recognizer.action = @selector(onClick:);
    [textField addGestureRecognizer:recognizer];

    return textField;
}

- (void)onClick:(id)sender {
    if (_errorReason) {
        [iTermWarning showWarningWithTitle:_errorReason
                                   actions:@[ NSLocalizedStringFromTableInBundle(@"OK", @"StatusBar", [NSBundle bundleForClass:[self class]], @"OK button") ]
                                 accessory:nil
                                identifier:@"NoSyncInterpolatedStatusBarComponentError"
                               silenceable:kiTermWarningTypePersistent
                                   heading:NSLocalizedStringFromTableInBundle(@"Error", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Error alert heading")
                                    window:self.statusBarComponentView.window];
    }
}

- (nullable NSArray<NSString *> *)stringVariants {
    return @[ _value ?: @"" ];
}

- (void)updateWithKnobValues:(NSDictionary<NSString *, id> *)knobValues {
    NSString *expression = knobValues[iTermStatusBarSwiftyStringComponentExpressionKey] ?: @"";
    __weak __typeof(self) weakSelf = self;
    if ([self.delegate statusBarComponentIsInSetupUI:self]) {
        _swiftyString = [[iTermSwiftyStringPlaceholder alloc] initWithString:expression];
        self.stringValue = expression;
    } else {
        _swiftyString = [[iTermSwiftyString alloc] initWithString:expression
                                                            scope:self.scope
                                               sideEffectsAllowed:false
                                                         observer:^NSString *(NSString * _Nonnull newValue, NSError *error) {
                                                             return [weakSelf didEvaluateExpression:expression withResult:newValue error:error];
                                                         }];
        self.stringValue = _swiftyString.evaluatedString;
    }
}

- (NSString *)didEvaluateExpression:(NSString *)expression
                         withResult:(NSString *)newValue
                              error:(NSError *)error {
    static NSString *ladybug = @"🐞";
    if (error != nil) {
        NSString *message = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Error while evaluating “%@”:\n%@", @"StatusBar", [NSBundle bundleForClass:[self class]], @"Error message when evaluating an interpolated string fails"), expression, error.localizedDescription];
        [[iTermScriptHistoryEntry globalEntry] addOutput:message completion:^{}];
        _errorReason = message;
        return ladybug;
    } else if (newValue != ladybug) {
        _errorReason = nil;
    }
    [self setStringValue:newValue];
    return newValue;
}

- (void)statusBarComponentSetKnobValues:(NSDictionary *)knobValues {
    [self updateWithKnobValues:knobValues];
    [super statusBarComponentSetKnobValues:knobValues];
}

- (NSDictionary *)statusBarComponentKnobValues {
    return self.configuration[iTermStatusBarComponentConfigurationKeyKnobValues];
}

@end

NS_ASSUME_NONNULL_END
