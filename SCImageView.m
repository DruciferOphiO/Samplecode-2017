
#import "SCImageView.h"

@implementation SCImageView

@synthesize delegate;

- (id)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.zoomSize = 1;
    }
    return self;
}

- (void)configureHitDetectionWithNumberBodyParts:(int)numberOfBodyParts pathLengths:(int *)pathLengths paths:(int **)paths partIdentifers:(int *)partIdentifers partNames:(char **)partNames {
    num = numberOfBodyParts;
    lengths = pathLengths;
    coords = paths;
    partIDs = partIdentifers;
    partLabels = partNames;
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([[touches allObjects] count] == 1) {
        
        UITouch *touch = [[touches allObjects] objectAtIndex:0];
        CGPoint currSelectedLocation = [touch locationInView:self];
        
        
        CGFloat precentX = (currSelectedLocation.x - ([self aspectFitFrameForImage].origin.x/self.zoomSize)) / ((self.frame.size.width/self.zoomSize) - (([self aspectFitFrameForImage].origin.x *2)/self.zoomSize));
        CGFloat scaledX = (self.image.size.width * self.image.scale * precentX);
        
        CGFloat precentY = (currSelectedLocation.y - [self aspectFitFrameForImage].origin.y) / ((self.frame.size.height/self.zoomSize) - ([self aspectFitFrameForImage].origin.y *2));
        CGFloat scaledY = (self.image.size.height * self.image.scale * precentY);
        
        CGFloat percent = 450.0 / 900.0;
        
        CGPoint currSelectedLocationScaled = CGPointMake(scaledX, scaledY);
        
        
        CGAffineTransform shrink = CGAffineTransformMakeScale(percent, percent);
        
        for (int i = 0; i < num; i++) {
            CGMutablePathRef hitPath = [self createPath:i shrink_p:&shrink];
            
            if (CGPathContainsPoint(hitPath, NULL, currSelectedLocationScaled, YES)) {
                if ([delegate respondsToSelector:@selector(onBodyPartSelectedWithID:withLabel:)]){
                    [delegate onBodyPartSelectedWithID:partIDs[i] withLabel:[NSString stringWithUTF8String:partLabels[i]]];
                }
                CGPathRelease(hitPath);
                break;
            }
            CGPathRelease(hitPath);
        }
    }
}

- (CGMutablePathRef)createPath:(int)i shrink_p:(CGAffineTransform *)shrink_p {
    CGMutablePathRef hitPath = CGPathCreateMutable();
    for (int j = 0; j < lengths[i]; j = j + 2) {
        
        int xCord = coords[i][j];
        int yCord = coords[i][j + 1];
        
        if (j == 0){
            CGPathMoveToPoint(hitPath, &(*shrink_p), xCord, yCord);
        }else{
            CGPathAddLineToPoint(hitPath, &(*shrink_p), xCord, yCord);
        }
    }
    return hitPath;
}



-(CGRect)aspectFitFrameForImage{
    float imageRatio = self.image.size.width / self.image.size.height;
    float viewRatio = self.frame.size.width / self.frame.size.height;
    
    if(imageRatio < viewRatio){
        float scale = self.frame.size.height / self.image.size.height;
        float width = scale * self.image.size.width;
        float topLeftX = (self.frame.size.width - width) * 0.5;
        return CGRectMake(topLeftX, 0, width, self.frame.size.height);
        
    }else{
        float scale = self.frame.size.width / self.image.size.width;
        float height = scale * self.image.size.height;
        float topLeftY = (self.frame.size.height - height) * 0.5;
        return CGRectMake(0, topLeftY, self.frame.size.width, height);
    }
}

- (void)dealloc {
    self.delegate = nil;
}

@end
