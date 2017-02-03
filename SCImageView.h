
#import <UIKit/UIKit.h>

@protocol SCImageViewDelegate
@optional
- (void)onBodyPartSelectedWithID:(int)partID withLabel:(NSString *__nonnull )partLabel;
@end

@interface SCImageView : UIImageView {
    int num;
    int *lengths;
    int *partIDs;
    int **coords;
    
    char ** partLabels;
    UIView *hitView;
    
}

@property(nonatomic, weak) id __nullable delegate;

// property should be set by parent scrollViewDidEndZooming. Defaults to 1
@property(nonatomic, assign) CGFloat zoomSize;

- (void)configureHitDetectionWithNumberBodyParts:(int)numberOfBodyParts pathLengths:(int *__nonnull )pathLengths paths:(int *__nonnull *__nonnull )paths partIdentifers:(int *__nonnull )partIdentifers partNames:(char *__nonnull *__nonnull )partNames;

-(CGRect)aspectFitFrameForImage;
@end
