//
//  PXCanvasWindowController_Zooming.m
//  Pixen
//
//  Created by Joe Osborn on 2005.08.09.
//  Copyright 2005 Pixen. All rights reserved.
//

#import "PXCanvasWindowController_Zooming.h"

#import "PXCanvas.h"
#import "PXCanvasView.h"
#import "PXCanvasController.h"

@implementation PXCanvasWindowController(Zooming)

- (void)prepareZoom
{
	NSArray *itemsObjects = [NSArray arrayWithObjects:
		[NSNumber numberWithInt:3000], 
		[NSNumber numberWithInt:2000], 
		[NSNumber numberWithInt:1000], 
		[NSNumber numberWithInt:800], 
		[NSNumber numberWithInt:500], 
		[NSNumber numberWithInt:400],
		[NSNumber numberWithInt:200], 
		[NSNumber numberWithInt:100],
		nil];
	[zoomPercentageBox removeAllItems];
	[zoomPercentageBox addItemsWithObjectValues:itemsObjects];
	// If you're looking for arbitrarily hard-coded percentages, they're right here!
	[zoomPercentageBox selectItemAtIndex:7];
	[zoomStepper setIntValue:7];	
}

- (IBAction)zoomToFit:sender
{
	[self zoomToFit];
}

- (void)zoomToIndex:(float)index
{
	if (index < 0 || index >= [zoomPercentageBox numberOfItems]) {
		NSBeep();
		return;
	}
	
	[zoomPercentageBox selectItemAtIndex:index];
	[zoomStepper setIntValue:index];
	[[canvasController view] setZoomPercentage:[zoomPercentageBox floatValue]];
	[canvasController updateMousePosition:[[self window] mouseLocationOutsideOfEventStream]];
}

- (void)zoomToPercentage:(NSNumber *)rawPercent addZoomLevel:(BOOL)addToValues
{
	if( rawPercent == nil 
		|| [[[rawPercent description] lowercaseString] isEqualToString:PXInfinityDescription] 
		|| [[[rawPercent description] lowercaseString] isEqualToString:PXNanDescription]) 
	{ 
		[self zoomToPercentage:[NSNumber numberWithFloat:100]]; 
		return;
	}
	NSNumber *percentage = [NSNumber numberWithFloat:MIN(MAX([rawPercent floatValue], 1), 10000)];

	if ( ! addToValues )
	{
		int oldPercentInt = (int)[[canvasController view] zoomPercentage];
		int index = 0;

		// If we pass a zoom level, select it in the combo box.
		for ( id zoomLevel in [zoomPercentageBox objectValues] )
		{
			int zoomLevelInt = [zoomLevel intValue];
			if ( (oldPercentInt <= zoomLevelInt && zoomLevelInt <= [percentage intValue])
				|| (zoomLevelInt <= oldPercentInt && [percentage intValue] <= zoomLevelInt))
			{
				[zoomPercentageBox selectItemAtIndex:index];
				break;
			}
			index++;
		}

		[zoomPercentageBox setStringValue:[percentage stringValue]];
		[[canvasController view] setZoomPercentage:[percentage floatValue]];
		[canvasController updateMousePosition:[[self window] mouseLocationOutsideOfEventStream]];
		return;
	}

	// Kind of a HACK, could change if the description changes to display something other than inf or nan on such numbers.
	//Probably not an issue, but I'll mark it so it's easy to find if it breaks later.
	
	if( ! [[zoomPercentageBox objectValues] containsObject:percentage])
	{
		NSMutableArray *values = [NSMutableArray arrayWithArray:[zoomPercentageBox objectValues]];
		[values addObject:percentage];
		[values sortUsingSelector:@selector(compare:)];
		[zoomPercentageBox removeAllItems];
		[zoomPercentageBox addItemsWithObjectValues:[[values reverseObjectEnumerator] allObjects]];
	}
	
	[zoomPercentageBox selectItemWithObjectValue:percentage];
	[self zoomToIndex:[zoomPercentageBox indexOfSelectedItem]];
}

- (void)zoomToPercentage:(NSNumber *)percentage
{
    [self zoomToPercentage:percentage addZoomLevel:YES];
}

- (void)zoomToFit
{
	if([canvas size].width <= 0 ||
	   [canvas size].height <= 0)
	{
		return;
	}
	NSRect contentFrame = [[[canvasController scrollView] contentView] frame];
	float xRatio = NSWidth(contentFrame)/[canvas size].width;
	float yRatio = NSHeight(contentFrame)/[canvas size].height;
	float pct = (NSWidth(contentFrame) > [canvas size].width || NSHeight(contentFrame) > [canvas size].height) ? (floorf(xRatio < yRatio ? xRatio : yRatio))*100 : 100.0;
	[self zoomToPercentage:[NSNumber numberWithFloat:MIN(pct, 10000)]];
}

- (void)canvasController:(PXCanvasController *)controller zoomInOnCanvasPoint:(NSPoint)point
{
	[self zoomIn:self];
}

- (void)canvasController:(PXCanvasController *)controller zoomOutOnCanvasPoint:(NSPoint)point
{
	[self zoomOut:self];
}

- (void)zoomToFitCanvasController:(PXCanvasController *)controller
{
	[self zoomToFit:self];	
}

- (IBAction)zoomIn: (id) sender
{
	[self zoomToIndex:[self zoomInNextIndex]];
}

- (IBAction)zoomOut: (id) sender
{
	[self zoomToIndex:[self zoomOutNextIndex]];
}

- (IBAction)zoomStandard: (id) sender
{ 
	[self zoomToIndex:[zoomPercentageBox indexOfItemWithObjectValue:[NSNumber numberWithInt:100]]];
}

- (IBAction)zoomPercentageChanged:sender
{
	[self zoomToPercentage:[zoomPercentageBox objectValue]];
}

- (IBAction)zoomStepperStepped:(id) sender
{
	if([zoomStepper intValue] >= [zoomPercentageBox numberOfItems]) 
	{ 
		NSBeep();
		[zoomStepper setIntValue: (int)[zoomPercentageBox numberOfItems]-1]; 
		return; 
	}
	NSInteger diff = [zoomStepper intValue] - [zoomPercentageBox indexOfSelectedItem];
	if (diff < 0)
	{
		[self zoomToIndex:[self zoomInNextIndex]];
	}
	else if (diff > 0)
	{
		[self zoomToIndex:[self zoomOutNextIndex]];
	}
}

- (void)magnifyWithEvent:(NSEvent *)event
{
	NSNumber *percent = [NSNumber numberWithFloat:[zoomPercentageBox floatValue] * (1.0f + [event magnification])];
	[self zoomToPercentage:percent addZoomLevel:NO];
}

- (NSInteger)zoomInNextIndex
{
	float percent = [zoomPercentageBox floatValue];
	NSInteger index = [zoomPercentageBox numberOfItems];

	for ( id zoomLevel in [[zoomPercentageBox objectValues] reverseObjectEnumerator] )
	{
		index--;
		if ( [zoomLevel floatValue] > percent )
		{
			return index;
		}
	}
	return -1;
}

- (NSInteger)zoomOutNextIndex
{
	float percent = [zoomPercentageBox floatValue];
	NSInteger index = -1;

	for ( id zoomLevel in [zoomPercentageBox objectValues] )
	{
		index++;
		if ( [zoomLevel floatValue] < percent )
		{
			return index;
		}
	}
	return -1;
}


@end
