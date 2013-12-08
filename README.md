# JYGraphViewController

JYGraphViewController is a class you can add to your project if you are looking for an easy way visually represent an array of numbers in a line graph. By default it is presented modally when the device is turned into landscape orientation.

[<img src="https://raw.github.com/johnyorke/JYGraphViewController/master/JYGraphViewController/Screenshots/screenshotOne.png">]

# Intro

JYGraphViewController is a slightly adapted version of the graph that appears in [Tempo/Weather](http://www.tempoweatherapp.com). It is meant to be presented modally and using the whole screen. The demo application it belongs to here presents it using an orientation change notification, but it could be triggered via any action. The benefit of having it presented based on orientation is that you don't have to obscure the graph with any controls. From a UX point of view, animating the presentation helps the user understand the graph is affected by gravity: ie. slides out when device is turned into landscape, and falls back away when returned to portrait.

# Implementation

If you wish to have it presented when the device is turned landscape, add the presenting view as an observer to UIDeviceOrientationDidChangeNotification with a selector such as _didRotate_. When the device is turned into landscapeLeft or landscapeRight...

```obj-c
- (void) didRotate
{
if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft ||
[UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
        
JYGraphViewController *graphView = [[JYGraphViewController alloc] initWithNibName:@"JYGraphViewController" bundle:nil];
        
// Set the data for the graph
// Send only an array of number values
graphView.graphData = [self createArrayOfNumbersToPassToGraph];

[self presentViewController:graphView animated:YES completion:nil];
    }
}
```

By default the graph uses a UIView subclass to draw each point. You can grab the JYGraphPoint files and use them if you wish, or you can use your own graphics/class. If you do that just replace any mention of JYGraphPoint in JYGraphViewController.m with your own solution. 

This is (hopefully) all you need to do! The above will take your array of numbers and divide 1136 points (2 x 4" screens) by your array count. I've tested this up to about 40 numbers, anything more than that and it starts to get a little crowded. If you need to present more than 40 numbers then I suggest you change the _graphWidth_ constant in JYGraphViewController.m to be quite a bit wider.

# Customisation

If you wish to customise the look of the graph a bit, you can set the graphStrokeColour and graphFillColour with any UIColor before you present the graph.

```obj-c
- (void) didRotate
{

...
graphView.graphFillColour = [UIColor colorWithRed:0.21f green:0.00f blue:0.40f alpha:1.0f];
graphView.graphStrokeColour = [UIColor colorWithRed:0.53f green:0.00f blue:0.98f alpha:1.0f];
...

}
```

If you don't set these properties then two shades of green will be used instead.

If you want to go a bit further with customisation then go ahead and dig around in JYGraphViewController.m. I apologise in advance for the messiness. Good luck.

# What the graph controller actually does

The original implementation was done in a rush and also had a lot of hard-coded values based on the nature of the data it was presenting (always 24 values and not a huge range between the smallest and largest). I've done my best to name methods so that they make sense, which they kind-of do (to me anyway). 

The graph takes your numbers, works out the range, translates them into coordinates, then draws the elements: 
* background bar (which is actually a label) 
* the line joining the points
* the label above each point 
* and finally the points

It's not pretty, but it works. If anyone wants to suggest a better way or improve my code then please go ahead, I just ask that you let me know so I can learn too.

# Thanks

First of all I would be thrilled if someone used this in their project and let me know about it. Secondly, I would be equally thrilled if someone gets in touch and tells me everything I did wrong or suggests other ways to improve JYGraphViewController. You can (email me [hello@johnyorke.me](mailto:hello@johnyorke.me)) or get in touch on Twitter @johnyorke

# License

MIT License (enclosed in project folder). So in other words...fill ya' boots!
