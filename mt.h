// Private MultitouchSupport.framework types.
// Copied verbatim from:
//   https://github.com/mhuusko5/M5MultitouchSupport (M5MTDefinesInternal.h)
// cross-checked against:
//   https://github.com/artginzburg/MiddleClick-Sonoma (MoreTouch/Sources/MultitouchSupport/MultitouchSupport.h)
// Functions are resolved at runtime via dlsym (the framework binary lives in
// the dyld shared cache), so only types live here.

#include <CoreFoundation/CoreFoundation.h>

typedef struct {
	float x;
	float y;
} MTPoint;

typedef struct {
	MTPoint position;
	MTPoint velocity;
} MTVector;

enum {
	MTTouchStateNotTracking = 0,
	MTTouchStateStartInRange = 1,
	MTTouchStateHoverInRange = 2,
	MTTouchStateMakeTouch = 3,
	MTTouchStateTouching = 4,
	MTTouchStateBreakTouch = 5,
	MTTouchStateLingerInRange = 6,
	MTTouchStateOutOfRange = 7
};
typedef int MTTouchState;

typedef struct {
	int frame;
	double timestamp;
	int identifier;
	MTTouchState state;
	int fingerId;
	int handId;
	MTVector normalizedPosition;
	float size;
	int field9;
	float angle;
	float majorAxis;
	float minorAxis;
	MTVector absolutePosition;
	int field14;
	int field15;
	float density;
} MTTouch;

typedef void *MTDeviceRef;

typedef void (*MTFrameCallbackFunction)(MTDeviceRef device, MTTouch touches[], int numTouches, double timestamp, int frame);
