//
// UIPickerActionSheet.m
// Version 0.1
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Copyright (c) 2013 José Enrique Bolaños Gudiño
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "UIPickerActionSheet.h"

@interface UIPickerActionSheet () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (copy) PickerDismissedHandler dismissHandler;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIActionSheet *sheet;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) id selectedItem;

@end

@implementation UIPickerActionSheet
{
    UIPickerActionSheetMode _pickerMode;
}

- (id)initForView:(UIView *)view mode:(UIPickerActionSheetMode)actionSheetMode
{
    if (self = [super init])
    {
        _pickerMode = actionSheetMode;
        [self setContainerView:view];
        [self initSheetWithWidth:view.bounds.size.width mode:actionSheetMode];
    }
    return self;
}

- (void)initSheetWithWidth:(CGFloat)aWidth mode:(UIPickerActionSheetMode)actionSheetMode
{
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    UIToolbar *toolbar = [[UIToolbar alloc]
                          initWithFrame:CGRectMake(0, 0, aWidth, 0)];
    toolbar.barStyle = UIBarStyleBlackOpaque;
    [toolbar sizeToFit];
    
    [toolbar setItems:@[
     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(pickerSheetCancel)],
     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(pickerSheetDone)]]];
    
    id picker;
    CGRect pickerFrame = CGRectMake(0, toolbar.bounds.size.height, aWidth, 0);
    switch (actionSheetMode)
    {
        case UIPickerActionSheetModeItems:
        {
            picker = [[UIPickerView alloc] initWithFrame:pickerFrame];
            [picker setShowsSelectionIndicator:YES];
            [picker setDelegate:self];
        }
            break;
        case UIPickerActionSheetModeDate:
        {
            picker = [[UIDatePicker alloc] initWithFrame:pickerFrame];
            [picker setDatePickerMode:UIDatePickerModeDate];
        }
        break;
    }
    
    [sheet addSubview:toolbar];
    [sheet addSubview:picker];
    
    self.sheet = sheet;
    self.picker = picker;
}

- (void)show:(id)item
{
    if (!self.tag) self.tag = NSNotFound;
    
    [self.sheet showInView:self.containerView];
    
    // XXX: Kinda hacky, but seems to be the only way to make it display correctly.
    [UIView animateWithDuration:0.3 animations:^
    {
        [self.sheet setBounds:CGRectMake(0, 0, self.containerView.frame.size.width, self.sheet.frame.size.height + 478.0)];
    }];
    
    if (_pickerMode == UIPickerActionSheetModeItems)
    {
        if (![item isKindOfClass:[NSArray class]] || ![item count]) return;
        self.items = item;
        [self.picker selectRow:0 inComponent:0 animated:NO];
        [self.picker.delegate pickerView:self.picker didSelectRow:0 inComponent:0];
        [self.picker reloadComponent:0];
    }
    if (_pickerMode == UIPickerActionSheetModeDate)
    {
        if (![item isKindOfClass:[NSDate class]]) return;
        [(UIDatePicker *)self.picker setDate:item animated:NO];
    }
}

- (void)show:(id)item withDismissHandler:(PickerDismissedHandler)dismissHandler;
{
    [self show:item];
    self.dismissHandler = dismissHandler;
}

- (int)numberOfComponentsInPickerView:(UIPickerView*)aPickerView
{
    return 1;
}

- (int)pickerView:(UIPickerView*)aPickerView numberOfRowsInComponent:(NSInteger)aComponent
{
    return self.items.count;
}

- (NSString*)pickerView:(UIPickerView*)aPickerView titleForRow:(NSInteger)aRow forComponent:(NSInteger)aComponent
{
    id item = [self.items objectAtIndex:aRow];
    return [item description];
}

- (void)pickerView:(UIPickerView*)aPickerView didSelectRow:(NSInteger)aRow inComponent:(NSInteger)aComponent
{
    self.selectedItem = [self.items objectAtIndex:aRow];
}

- (void)pickerSheetCancel
{
    [self.sheet dismissWithClickedButtonIndex:0 animated:YES];
    if (self.dismissHandler)
    {
        self.dismissHandler(_pickerMode,YES,nil,self.tag);
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerActionSheetDidCancel:)])
        [self.delegate pickerActionSheetDidCancel:self];
}

- (void)pickerSheetDone
{
    [self.sheet dismissWithClickedButtonIndex:0 animated:YES];
    if (self.dismissHandler)
    {
        self.dismissHandler(_pickerMode,NO,[(UIDatePicker *)self.picker date],self.tag);
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(pickerActionSheet:didSelectItem:)])
        [self.delegate pickerActionSheet:self didSelectItem:self.selectedItem];
}

@end
