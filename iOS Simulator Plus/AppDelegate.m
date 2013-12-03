/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2013 Billy Millare
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/*
 * AppDelegate.m
 *
 *  Created on: Oct 30, 2013
 *      Author: Billy
 */

#import "AppDelegate.h"
#import <Carbon/Carbon.h>
#import <Quartz/Quartz.h>

#define TargetApplicationName               @"iPhone Simulator"
#define TargetApplicationBundleIdentifier   @"com.apple.iphonesimulator"

@interface AppDelegate ()
{
    IBOutlet NSMenu *menu;
    IBOutlet NSMenuItem *targetApplicationActivateMenuItem;
    NSStatusItem *statusItem;
    
    CFMachPortRef portRef;
    CFRunLoopSourceRef runLoopSourceRef;
    
    CGFloat windowTitleBarHeight;
    CGRect targetWindowBounds;
    CGRect normalizedTargetWindowBounds;
    CGEventFlags eventFlags;
    CGPoint currentScreenPosition;
    CGPoint cursorPosition;
    
    enum {
        UnknownGesture,
        Rotation,
        Magnification,
    } gesture;
    
    CGFloat gestureValue;
    CGFloat gestureMinValue;
    CGFloat gestureMaxValue;
    
    BOOL mouseIsDown;
    BOOL isTouchscreenMode;
    
    enum {
        Inactive,
        Ready,
        Active
    } touchStatus;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) BOOL eventTapEnabled;
@property (nonatomic, retain) NSRunningApplication *targetApplication;
- (CGRect)targetApplicationBounds;
@end

@implementation AppDelegate
@synthesize window;
@synthesize eventTapEnabled;
@synthesize targetApplication;

- (void)dealloc
{
    [[NSWorkspace sharedWorkspace].notificationCenter removeObserver:self];
    self.eventTapEnabled = NO;
    self.targetApplication = nil;
    [menu release];
    [targetApplicationActivateMenuItem release];
    [statusItem release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    windowTitleBarHeight = window.frame.size.height - [window.contentView frame].size.height;
    window.showsToolbarButton = YES;
    [window orderOut:self];
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    statusItem.highlightMode = YES;
    statusItem.image = [NSImage imageNamed:@"iconTemplate.png"];
    statusItem.image.size = NSMakeSize(21, 21);
    statusItem.menu = menu;
    [[NSWorkspace sharedWorkspace].notificationCenter addObserver:self selector:@selector(workspaceDidActivateApplication:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    [self didActivateApplication:[NSWorkspace sharedWorkspace].frontmostApplication];
}

- (IBAction)showAbout:(id)sender
{
    [NSApp orderFrontStandardAboutPanel:sender];
}

- (IBAction)terminate:(id)sender
{
    [NSApp terminate:sender];
}

- (void)activateTargetApplication:(id)sender
{
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:TargetApplicationBundleIdentifier options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
}

- (void)didActivateApplication:(NSRunningApplication *)application
{
    self.targetApplication = [application.bundleIdentifier isEqualToString:TargetApplicationBundleIdentifier] ? application : nil;
    
    if(targetApplication == nil)
        self.eventTapEnabled = NO;
    else
    {
        while(CGRectIsEmpty([self targetApplicationBounds]))
            [NSThread sleepForTimeInterval:0.1];
        
        self.eventTapEnabled = YES;
    }
}

- (void)workspaceDidActivateApplication:(NSNotification *)notification
{
    [self didActivateApplication:[[notification userInfo] objectForKey:NSWorkspaceApplicationKey]];
}

- (void)setEventTapEnabled:(BOOL)eventTapEnabled_
{
    [targetApplicationActivateMenuItem setAction:(eventTapEnabled_ ? nil : @selector(activateTargetApplication:))];
    
    if(eventTapEnabled_ != eventTapEnabled)
    {
        if(eventTapEnabled_)
        {
            mouseIsDown = NO;
            isTouchscreenMode = NO;
            touchStatus = Inactive;
            portRef = CGEventTapCreate(kCGHIDEventTap, kCGTailAppendEventTap, kCGEventTapOptionDefault, NSFlagsChangedMask | NSMouseMovedMask | NSLeftMouseDownMask | NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSEventMaskGesture, (CGEventTapCallBack)eventTapCallback, self);
            runLoopSourceRef = CFMachPortCreateRunLoopSource(NULL, portRef, 0);
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSourceRef, kCFRunLoopCommonModes);
        }
        else if(runLoopSourceRef != nil && CFRunLoopContainsSource(CFRunLoopGetMain(), runLoopSourceRef, kCFRunLoopCommonModes))
        {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSourceRef, kCFRunLoopCommonModes);
            
            if(portRef != nil)
            {
                CFMachPortInvalidate(portRef);
                CFRelease(portRef);
                portRef = nil;
            }
            
            if(runLoopSourceRef != nil)
            {
                CFRelease(runLoopSourceRef);
                runLoopSourceRef = nil;
            }
        }
        
        eventTapEnabled = eventTapEnabled_;
    }
}

- (CGRect)targetApplicationBounds
{
    NSArray *windowInfoList = (NSArray *)CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
    normalizedTargetWindowBounds = CGRectZero;
    
    for(NSDictionary *windowInfo in windowInfoList)
    {
        if([[windowInfo valueForKey:(NSString *)kCGWindowOwnerPID] intValue] == targetApplication.processIdentifier)
        {
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[windowInfo valueForKey:(NSString *)kCGWindowBounds], &targetWindowBounds);
            normalizedTargetWindowBounds = targetWindowBounds;
            normalizedTargetWindowBounds.origin.y += normalizedTargetWindowBounds.size.height;
            normalizedTargetWindowBounds.size.height -= windowTitleBarHeight;
            targetWindowBounds.origin.y = [NSScreen mainScreen].frame.size.height - (targetWindowBounds.origin.y + targetWindowBounds.size.height);
            targetWindowBounds.size.height -= windowTitleBarHeight;
            break;
        }
    }
    
    CFRelease(windowInfoList);
    return normalizedTargetWindowBounds;
}

- (void)sendFlagsChangedEvent:(CGEventFlags)flags
{
    if(flags != eventFlags)
    {
        CGEventRef eventRef = CGEventCreate(NULL);
        CGEventSetType(eventRef, kCGEventFlagsChanged);
        CGEventSetFlags(eventRef, flags);
        CGEventPost(kCGHIDEventTap, eventRef);
        CFRelease(eventRef);
        eventFlags = flags;
    }
}

- (void)sendMouseEvent:(CGEventType)eventType atPosition:(CGPoint)position
{
    BOOL send = YES;
    
    switch(eventType)
    {
        case kCGEventLeftMouseDragged:
            if(!mouseIsDown)
                [self sendMouseEvent:kCGEventLeftMouseDown atPosition:position];
            
            break;
            
        case kCGEventMouseMoved:
            if(mouseIsDown)
                [self sendMouseEvent:kCGEventLeftMouseUp atPosition:position];
            
            break;
            
        case kCGEventLeftMouseDown:
            send = !mouseIsDown;
            mouseIsDown = YES;
            break;
            
        case kCGEventLeftMouseUp:
            send = mouseIsDown;
            mouseIsDown = NO;
            break;
            
        default:
            send = NO;
            break;
    }
    
    if(send)
    {
        CGEventRef eventRef = CGEventCreateMouseEvent(NULL, eventType, position, 0);
        CGEventSetFlags(eventRef, eventFlags);
        CGEventPost(kCGHIDEventTap, eventRef);
        CFRelease(eventRef);
    }
    
    CGWarpMouseCursorPosition([self screenPosition:cursorPosition]);
}

enum {
    RotateLeft,
    RotateRight,
    ShakeGesture,
    Home,
    Lock,
    Dummy
};

- (void)triggerHardwareCommand:(int)command
{
    CGKeyCode keyCode;
    CGEventFlags flags = kCGEventFlagMaskCommand;
    
    switch(command)
    {
        case RotateLeft:
            keyCode = kVK_LeftArrow;
            break;
            
        case RotateRight:
            keyCode = kVK_RightArrow;
            break;
            
        case ShakeGesture:
            keyCode = kVK_ANSI_Z;
            flags |= kCGEventFlagMaskControl;
            break;
            
        case Home:
            keyCode = kVK_ANSI_H;
            flags |= kCGEventFlagMaskShift;
            break;
            
        case Lock:
            keyCode = kVK_ANSI_L;
            break;
            
        default:
            return;
    }
    
    CGEventRef eventRef = CGEventCreateKeyboardEvent(NULL, keyCode, true);
    CGEventSetFlags(eventRef, flags);
    CGEventPost(kCGHIDEventTap, eventRef);
    CFRelease(eventRef);
}

- (CGPoint)screenPosition:(CGPoint)normalizedPosition
{
    CGPoint screenPosition;
    screenPosition.x = normalizedTargetWindowBounds.origin.x + (normalizedTargetWindowBounds.size.width * normalizedPosition.x);
    screenPosition.y = normalizedTargetWindowBounds.origin.y - (normalizedTargetWindowBounds.size.height * normalizedPosition.y);
    return screenPosition;
}

- (CGPoint)normalizedPosition
{
    CGPoint screenPosition = [NSEvent mouseLocation];
    
    if(CGRectContainsPoint(targetWindowBounds, screenPosition))
        return CGPointMake((screenPosition.x - targetWindowBounds.origin.x) / targetWindowBounds.size.width, (screenPosition.y - targetWindowBounds.origin.y) / targetWindowBounds.size.height);
    
    return CGPointMake(0.5, 0.5);
}

static CGEventRef eventTapCallback(CGEventTapProxy proxy, CGEventType type, CGEventRef eventRef, AppDelegate *appDelegate)
{
    NSEvent *event = [NSEvent eventWithCGEvent:eventRef];
    
    switch(type)
    {
        case NSEventTypeGesture:
            switch(event.type)
            {
                case NSEventTypeGesture:
                {
                    NSArray *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:nil].allObjects;

                    if(touches.count == 1)
                    {
                        NSTouch *touch = touches.firstObject;
                        NSUInteger modifierFlags = event.modifierFlags & (NSShiftKeyMask | NSControlKeyMask);
                        
                        if(touch.phase == NSTouchPhaseBegan)
                            appDelegate->isTouchscreenMode = (modifierFlags != 0) && (event.modifierFlags & NSAlternateKeyMask) == 0;
                        
                        if(appDelegate->isTouchscreenMode)
                        {
                            CGEventType eventType = kCGEventNull;
                            CGPoint position;
                            
                            switch(touch.phase)
                            {
                                case NSTouchPhaseBegan:
                                    [appDelegate targetApplicationBounds];
                                    [appDelegate sendFlagsChangedEvent:0];
                                    appDelegate->touchStatus = (modifierFlags & NSControlKeyMask) ? Ready : Active;
                                    
                                    if(appDelegate->touchStatus == Ready)
                                    {
                                        CGEventFlags flags = kCGEventFlagMaskAlternate;
                                        
                                        if((modifierFlags & NSShiftKeyMask))
                                        {
                                            flags |= kCGEventFlagMaskShift;
                                            appDelegate->cursorPosition = touch.normalizedPosition;
                                            position.x = 0.5;
                                            position.y = 0.5;
                                        }
                                        else
                                        {
                                            appDelegate->cursorPosition = [appDelegate normalizedPosition];
                                            position.x = 0.5 + touch.normalizedPosition.x - appDelegate->cursorPosition.x;
                                            position.y = 0.5 + touch.normalizedPosition.y - appDelegate->cursorPosition.y;
                                        }
                                        
                                        [appDelegate sendFlagsChangedEvent:kCGEventFlagMaskAlternate];
                                        [appDelegate sendMouseEvent:kCGEventMouseMoved atPosition:[appDelegate screenPosition:position]];
                                        position = [appDelegate screenPosition:touch.normalizedPosition];
                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                            if(appDelegate->touchStatus == Ready)
                                            {
                                                [appDelegate sendFlagsChangedEvent:(kCGEventFlagMaskAlternate | kCGEventFlagMaskShift)];
                                                [appDelegate sendMouseEvent:kCGEventMouseMoved atPosition:position];
                                                [appDelegate sendFlagsChangedEvent:flags];
                                                [appDelegate sendMouseEvent:kCGEventLeftMouseDown atPosition:position];
                                                appDelegate->touchStatus = Active;
                                            }
                                        });
                                            
                                        break;
                                    }
                                    
                                case NSTouchPhaseMoved:
                                    if(appDelegate->touchStatus == Active)
                                    {
                                        eventType = kCGEventLeftMouseDragged;
                                        position = [appDelegate screenPosition:touch.normalizedPosition];
                                        appDelegate->currentScreenPosition = position;
                                        
                                        if(appDelegate->eventFlags != kCGEventFlagMaskAlternate)
                                            appDelegate->cursorPosition = touch.normalizedPosition;
                                    }
                    
                                    break;
                                    
                                case NSTouchPhaseEnded:
                                case NSTouchPhaseCancelled:
                                    appDelegate->touchStatus = Inactive;
                                    [appDelegate sendFlagsChangedEvent:0];
                                    eventType = kCGEventLeftMouseUp;
                                    position = appDelegate->currentScreenPosition;
                                    break;
                                    
                                default:
                                    break;
                            }
                            
                            [appDelegate sendMouseEvent:eventType atPosition:position];
                        }
                    }
                    
                    break;
                }

                case NSEventTypeBeginGesture:
                    appDelegate->gestureValue = 0;
                    appDelegate->gestureMinValue = 0;
                    appDelegate->gestureMaxValue = 0;
                    appDelegate->gesture = UnknownGesture;
                    break;
                    
                case NSEventTypeMagnify:
                    if(appDelegate->gesture == Magnification)
                    {
                        appDelegate->gestureValue += event.magnification;
                    
                        if(event.magnification < 0)
                            appDelegate->gestureMinValue += event.magnification;
                        else
                            appDelegate->gestureMaxValue += event.magnification;
                    }
                    else if(appDelegate->gesture == UnknownGesture)
                        appDelegate->gesture = Magnification;
                    
                    break;
                    
                case NSEventTypeRotate:
                    if(appDelegate->gesture == Rotation)
                    {
                        appDelegate->gestureValue += event.rotation;
                        
                        if(event.rotation < 0)
                            appDelegate->gestureMinValue += event.rotation;
                        else
                            appDelegate->gestureMaxValue += event.rotation;
                    }
                    else if(appDelegate->gesture == UnknownGesture)
                        appDelegate->gesture = Rotation;
                    
                    break;
                    
                case NSEventTypeEndGesture:
                {
                    int command = Dummy;
                    
                    if(appDelegate->gesture == Magnification)
                    {
                        if(appDelegate->gestureMinValue < -0.5 && appDelegate->gestureMaxValue > 0.5)
                            command = ShakeGesture;
                        else if(appDelegate->gestureValue > 0.5)
                            command = Lock;
                        else if(appDelegate->gestureValue < -0.5)
                            command = Home;
                    }
                    else if(appDelegate->gesture == Rotation)
                    {
                        if(appDelegate->gestureMinValue < -20 && appDelegate->gestureMaxValue > 20)
                            command = ShakeGesture;
                        else if(appDelegate->gestureValue > 20)
                            command = RotateLeft;
                        else if(appDelegate->gestureValue < -20)
                            command = RotateRight;
                    }
                    
                    [appDelegate triggerHardwareCommand:command];
                    break;
                }
                    
                default:
                    break;
            }
            
            break;
        
        case NSFlagsChanged:
            if((event.modifierFlags & 0x20000000) || appDelegate->touchStatus == Inactive)
                return eventRef;

            break;
            
        case NSMouseMoved:
        case NSLeftMouseDown:
        case NSLeftMouseDragged:
        case NSLeftMouseUp:
            if(CGEventGetIntegerValueField(eventRef, kCGMouseEventSubtype) != kCGEventMouseSubtypeDefault && appDelegate->isTouchscreenMode)
                break;
            
        default:
            return eventRef;
    }
    
    return NULL;
}

@end
