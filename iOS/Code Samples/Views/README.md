Views
=====

RoundedRectViewContainer
------------------------

This is a simple UIView subclass to composite another view inside a rounded rectangle box, underneath an inner shadow. So it looks like the composited view is recessed behind the view. An example of it in use is in the Write Post screenshot, where the map view is the composited view. Touch events can still be passed though to it, so the map is perfectly functional.

This view class has some default style properties, defined by the RoundedRectViewContainerStyle struct. This allows very simple modification of the metrics (size and padding) of the container, the color, and shadow properties.

Note that the class has it's own private InnerShadowViewContainer which uses CoreGraphics to draw the inner shadow - a suprisingly tricky problem in UIKit, as explained here: http://stackoverflow.com/questions/4431292/inner-shadow-effect-on-uiview-layer/5542116#5542116 

