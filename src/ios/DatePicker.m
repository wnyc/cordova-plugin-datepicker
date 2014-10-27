/*
  Phonegap DatePicker Plugin
  https://github.com/sectore/phonegap3-ios-datepicker-plugin  
  
  Copyright (c) Greg Allen 2011
  Additional refactoring by Sam de Freyssinet
  
  Rewrite by Jens Krause (www.websector.de)

  MIT Licensed
*/

#import "DatePicker.h"
#import <Cordova/CDV.h>

@interface DatePicker ()

@property (nonatomic) BOOL isVisible;
@property (nonatomic) UIActionSheet* datePickerSheet;
@property (nonatomic) UIDatePicker* datePicker;
@property (nonatomic) UIPopoverController *datePickerPopover;
@property (nonatomic) UIView* datePickerView;
@property (nonatomic) UIView* touchInterceptorView;

@end

@implementation DatePicker

#pragma mark - UIDatePicker

- (BOOL) isOSAtLeast:(NSString*) version {
    return [[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending;
}

- (void)show:(CDVInvokedUrlCommand*)command {
  NSMutableDictionary *options = [command argumentAtIndex:0];
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
      //if ([self isOSAtLeast:@"8.0" ])  {
      if ([self isOSAtLeast:@"6.0" ])  {
          [self showForPhoneiOS8: options];
      } else {
          [self showForPhone: options];
      }
  } else {
    [self showForPad: options];
  }   
}

- (BOOL)showForPhone:(NSMutableDictionary *)options {
  if(!self.isVisible){
    self.datePickerSheet = [self createActionSheet:options];
    self.isVisible = TRUE;
  }
  return true;
}

- (BOOL)showForPhoneiOS8:(NSMutableDictionary *)options {
    if(!self.isVisible){
        self.datePickerView = [self createView:options];
        self.isVisible = TRUE;
    }
    return true;
}

- (BOOL)showForPad:(NSMutableDictionary *)options {
  if(!self.isVisible){
    self.datePickerPopover = [self createPopover:options];
    self.isVisible = TRUE;
  }
  return true;    
}

- (void)hide {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        //if ([self isOSAtLeast:@"8.0" ])  {
        if ([self isOSAtLeast:@"6.0" ])  {
            [UIView animateWithDuration:0.5
                                  delay:0.0
                                options: 0
                             animations:^{
                                 self.datePickerView.frame = CGRectOffset(self.viewController.view.frame, 0, [[UIScreen mainScreen] bounds].size.height);
                                 self.touchInterceptorView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
                                 
                             }
                             completion:^(BOOL finished){
                                 [self.datePickerView removeFromSuperview];
                                 [self.touchInterceptorView removeFromSuperview];
                                 self.isVisible = FALSE;
                             }];
            
        } else {
            [self.datePickerSheet dismissWithClickedButtonIndex:0 animated:YES];
        }
    } else {
        [self.datePickerPopover dismissPopoverAnimated:YES];
    }
}

- (void)doneAction:(id)sender {
  [self jsDateSelected];
  [self hide];
}


- (void)cancelAction:(id)sender {
  [self jsDateCanceled];
  [self hide];
}

- (void)dateChangedAction:(id)sender {
  [self jsDateSelected];
}

#pragma mark - JS API

- (void)jsDateSelected {
  NSTimeInterval seconds = [self.datePicker.date timeIntervalSince1970];
  NSString* jsCallback = [NSString stringWithFormat:@"datePicker._dateSelected(\"%f\");", seconds];
  [self.commandDelegate evalJs:jsCallback];
}

- (void)jsDateCanceled {
  NSString* jsCallback = [NSString stringWithFormat:@"datePicker._dateCanceled();"];
  [self.commandDelegate evalJs:jsCallback];
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {

}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    self.isVisible = FALSE;
}


#pragma mark - UIPopoverControllerDelegate methods

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
  self.isVisible = FALSE;   
}

#pragma mark - Factory methods

- (UIView *)createView:(NSMutableDictionary *)options {

    
    // date picker
    CGRect frame = CGRectMake(0, 40, 0, 0);
    if(!self.datePicker){
        self.datePicker = [self createDatePicker: options frame:frame];
    }
    [self updateDatePicker:options];
    
    // Initialize the toolbar with Cancel and Done buttons and title
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 0, self.viewSize.width, 44)];
    toolbar.barStyle = [self isOSAtLeast:@"7.0"] ? UIBarStyleDefault : UIBarStyleBlackTranslucent;
    NSMutableArray *buttons =[[NSMutableArray alloc] init];
    
    // Create Cancel button
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
    [buttons addObject:cancelButton];
    
    // Create title label aligned to center and appropriate spacers
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [buttons addObject:flexSpace];
    UILabel *label =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor: [self isOSAtLeast:@"7.0"] ? [UIColor blackColor] : [UIColor whiteColor]];
    [label setFont: [UIFont boldSystemFontOfSize:16]];
    [label setBackgroundColor:[UIColor clearColor]];
    label.text = @"";
    UIBarButtonItem *labelButton = [[UIBarButtonItem alloc] initWithCustomView:label];
    [buttons addObject:labelButton];
    [buttons addObject:flexSpace];
    
    // Create Done button
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)];
    [buttons addObject:doneButton];
    [toolbar setItems:buttons animated:YES];
 
    // No need to create it again if it already exists
    if (_touchInterceptorView==nil){
        _touchInterceptorView = [[UIView alloc] initWithFrame:self.viewController.view.frame];
    }
    // Fill the parent view
    [_touchInterceptorView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.0]];
    [self.viewController.view addSubview:_touchInterceptorView];
    [self.viewController.view bringSubviewToFront:_touchInterceptorView];
    
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, self.viewSize.width, 260)];
    [view setBackgroundColor:[UIColor whiteColor]];
    [view addSubview: toolbar];
    [view addSubview:self.datePicker];
    
    [self.viewController.view addSubview:view];
    [self.viewController.view bringSubviewToFront:view];
    [UIView beginAnimations:@"SlideUpDatePicker" context:nil];
    [UIView setAnimationDuration:0.5];
    view.frame = CGRectOffset(self.viewController.view.frame, 0, [[UIScreen mainScreen] bounds].size.height-260);
    _touchInterceptorView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    [UIView commitAnimations];
    
    return view;
}


- (UIActionSheet *)createActionSheet:(NSMutableDictionary *)options {
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                        delegate:self cancelButtonTitle:nil
                                                        destructiveButtonTitle:nil 
                                                        otherButtonTitles:nil];

  [actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
  // date picker
  CGRect frame = CGRectMake(0, 40, 0, 0);
  if(!self.datePicker){
    self.datePicker = [self createDatePicker: options frame:frame];
  } 
  [self updateDatePicker:options];
  [actionSheet addSubview: self.datePicker];
  // cancel button
  UISegmentedControl *cancelButton = [self createCancelButton:options];
  [actionSheet addSubview:cancelButton];
  // done button
  UISegmentedControl *doneButton = [self createDoneButton:options];    
  [actionSheet addSubview:doneButton];
  // show UIActionSheet
  [actionSheet setBackgroundColor:[UIColor whiteColor]];
  [actionSheet showInView:self.webView.superview];
  [actionSheet setBounds:CGRectMake(0, 0, 320, 485)];

  return actionSheet;
}

- (UIPopoverController *)createPopover:(NSMutableDictionary *)options {
    
  CGFloat pickerViewWidth = 320.0f;
  CGFloat pickerViewHeight = 216.0f;
  UIView *datePickerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pickerViewWidth, pickerViewHeight)];

  CGRect frame = CGRectMake(0, 0, 0, 0);
  if(!self.datePicker){
    self.datePicker = [self createDatePicker:options frame:frame];
    [self.datePicker addTarget:self action:@selector(dateChangedAction:) forControlEvents:UIControlEventValueChanged];    
  }
  [self updateDatePicker:options]; 
  [datePickerView addSubview:self.datePicker];

  UIViewController *datePickerViewController = [[UIViewController alloc]init];
  datePickerViewController.view = datePickerView;
  
  UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:datePickerViewController];
  popover.delegate = self;
  [popover setPopoverContentSize:CGSizeMake(pickerViewWidth, pickerViewHeight) animated:NO];
  
  CGFloat x = [[options objectForKey:@"x"] intValue];
  CGFloat y = [[options objectForKey:@"y"] intValue];
  CGRect anchor = CGRectMake(x, y, 1, 1);
  [popover presentPopoverFromRect:anchor inView:self.webView.superview  permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];   
  
  return popover;
}

- (UIDatePicker *)createDatePicker:(NSMutableDictionary *)options frame:(CGRect)frame { 
  UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:frame];      
  return datePicker;
}

- (void)updateDatePicker:(NSMutableDictionary *)options {
  NSDateFormatter *formatter = [self createISODateFormatter:k_DATEPICKER_DATETIME_FORMAT timezone:[NSTimeZone defaultTimeZone]];
  NSString *mode = [options objectForKey:@"mode"];
  NSString *dateString = [options objectForKey:@"date"];
  BOOL allowOldDates = NO;
  BOOL allowFutureDates = YES;
  NSString *minDateString = [options objectForKey:@"minDate"];
  NSString *maxDateString = [options objectForKey:@"maxDate"];
    
  if ([[options objectForKey:@"allowOldDates"] intValue] == 1) {
    allowOldDates = YES;
  }
    
  if ( !allowOldDates) {
    self.datePicker.minimumDate = [NSDate date];
  }
    
  if(minDateString){
    self.datePicker.minimumDate = [formatter dateFromString:minDateString];
  }
  
  if ([[options objectForKey:@"allowFutureDates"] intValue] == 0) {
    allowFutureDates = NO;
  }
    
  if ( !allowFutureDates) {
    self.datePicker.maximumDate = [NSDate date];
  }
    
  if(maxDateString){
    self.datePicker.maximumDate = [formatter dateFromString:maxDateString];
  }
    
  self.datePicker.date = [formatter dateFromString:dateString];
    
  if ([mode isEqualToString:@"date"]) {
    self.datePicker.datePickerMode = UIDatePickerModeDate;
  }
  else if ([mode isEqualToString:@"time"]) {
    self.datePicker.datePickerMode = UIDatePickerModeTime;
  } else {
    self.datePicker.datePickerMode = UIDatePickerModeDateAndTime;
  }
}

- (NSDateFormatter *)createISODateFormatter:(NSString *)format timezone:(NSTimeZone *)timezone {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeZone:timezone];
  [dateFormatter setDateFormat:format];

  return dateFormatter;
}


- (UISegmentedControl *)createCancelButton:(NSMutableDictionary *)options {
  NSString *label = [options objectForKey:@"cancelButtonLabel"];
  UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:label]];

  NSString *tintColorHex = [options objectForKey:@"cancelButtonColor"];
  button.tintColor = [self colorFromHexString: tintColorHex];  
    
  button.momentary = YES;
  button.segmentedControlStyle = UISegmentedControlStyleBar;
  button.apportionsSegmentWidthsByContent = YES;
  
  CGSize size = button.bounds.size;
  button.frame = CGRectMake(5, 7.0f, size.width, size.height);
  
  [button addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventValueChanged];
    
  return button;
}

- (UISegmentedControl *)createDoneButton:(NSMutableDictionary *)options {
  NSString *label = [options objectForKey:@"doneButtonLabel"];
  UISegmentedControl *button = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:label]];
  NSString *tintColorHex = [options objectForKey:@"doneButtonColor"];
  button.tintColor = [self colorFromHexString: tintColorHex];

  button.momentary = YES;
  button.segmentedControlStyle = UISegmentedControlStyleBar;
  button.apportionsSegmentWidthsByContent = YES;
    
  CGSize size = button.bounds.size;
  CGFloat width = size.width;
  CGFloat height = size.height;
  CGFloat xPos = 320 - width - 5; // 320 == width of DatePicker, 5 == offset to right side hand
  button.frame = CGRectMake(xPos, 7.0f, width, height);
  
  [button addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventValueChanged];

  return button;
}

// Helper method to convert a hex string into UIColor
// @see: http://stackoverflow.com/questions/1560081/how-can-i-create-a-uicolor-from-a-hex-string
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

//
// Utilities
//

- (CGSize) viewSize {
    if (![self isViewPortrait])
        return CGSizeMake(480, 320);
    return CGSizeMake(320, 480);
}

- (BOOL) isViewPortrait {
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
}

@end