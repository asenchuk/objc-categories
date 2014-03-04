// The MIT License (MIT)
//
// Copyright (c) 2014 Andrei Senchuk
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import <objc/runtime.h>
#import "UIViewController+PrepareSegueWithBlock.h"

static const char *kPrepareBlocksDictAssociationKey = "prepareBlocksDict";

@interface UIViewController (Private)
- (void)origPrepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
- (void)newPrepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
- (NSMutableDictionary *)seguePrepareBlocks;
@end

@implementation UIViewController (PrepareSegueWithBlock)

+ (void)initialize
{
    SEL origSelector = @selector(prepareForSegue:sender:);
    Method originalMethod = class_getInstanceMethod(self, origSelector);
    
    SEL newReplacementSelector = @selector(newPrepareForSegue:sender:);
    Method newMethod = class_getInstanceMethod(self, newReplacementSelector);
    
    IMP originalPrepare = class_replaceMethod(self, origSelector, method_getImplementation(newMethod), method_getTypeEncoding(originalMethod));
    if(originalPrepare)
    {
        class_replaceMethod(self, @selector(origPrepareForSegue:sender:), originalPrepare, method_getTypeEncoding(originalMethod));
    }
}

- (void)origPrepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // noop
}

- (void)newPrepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self origPrepareForSegue:segue sender:sender];
    
    // call block
    NSMutableDictionary *blocks = self.seguePrepareBlocks;
    UISeguePrepareBlock block = [blocks objectForKey:segue.identifier];
    
    if(block)
    {
        [blocks removeObjectForKey:segue.identifier];
        block(segue);
    }
}

- (NSMutableDictionary *)seguePrepareBlocks
{
    NSMutableDictionary *blocks = (NSMutableDictionary *)objc_getAssociatedObject(self, kPrepareBlocksDictAssociationKey);
    if(!blocks)
    {
        blocks = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, kPrepareBlocksDictAssociationKey, blocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return blocks;
}

- (void)performSegueWithIdentifier:(NSString *)identifier sender:(id)sender prepareBlock:(UISeguePrepareBlock)prepareBlock
{
    UISeguePrepareBlock copyBlock = Block_copy(prepareBlock);
    [self.seguePrepareBlocks setObject:copyBlock forKey:identifier];
    Block_release(copyBlock);
    
    [self performSegueWithIdentifier:identifier sender:sender];
}

@end
