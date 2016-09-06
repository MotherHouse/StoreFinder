//
//  AnimationViewController.m
//  StoreFinder
//
//  
//  Copyright (c) 2014 Mangasaur Games. All rights reserved.
//

#import "AnimationViewController.h"
#import "AppDelegate.h"

@interface AnimationViewController () <UITextFieldDelegate>

@end

@implementation AnimationViewController

@synthesize scrollViewMain;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.titleView = [MGUIAppearance createLogo:HEADER_LOGO];
    self.view.backgroundColor = BG_VIEW_COLOR;
    [MGUIAppearance enhanceNavBarController:self.navigationController
                               barTintColor:WHITE_TEXT_COLOR
                                  tintColor:WHITE_TEXT_COLOR
                             titleTextColor:WHITE_TEXT_COLOR];
    
    _animationView = [[MGRawView alloc] initWithFrame:scrollViewMain.frame nibName:@"AnimationView"];
    _animationView.frame = scrollViewMain.frame;
    
    [_animationView.label1 setText:LOCALIZED(@"MENU_ANIMATION")];
    
    [_animationView.segmentAnimation setTitle:LOCALIZED(@"DEFAULT") forSegmentAtIndex:0];
//    [_animationView.segmentAnimation setTitle:LOCALIZED(@"FOLD") forSegmentAtIndex:1];
    [_animationView.segmentAnimation setTitle:LOCALIZED(@"ZOOM") forSegmentAtIndex:1];
    
    AppDelegate* delegate = [AppDelegate instance];
    [_animationView.segmentAnimation setTintColor:THEME_BLACK_TINT_COLOR];
    [_animationView.segmentAnimation setSelectedSegmentIndex:[delegate getTransitionIndex]];
    
    [_animationView.segmentAnimation addTarget:self
                                        action:@selector(didSelectSegmentAnimation:)
                              forControlEvents:UIControlEventValueChanged];
    
    [scrollViewMain addSubview:_animationView];
    scrollViewMain.contentSize = _animationView.frame.size;

    UIBarButtonItem* itemMenu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BUTTON_MENU]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(didClickBarButtonMenu:)];
    self.navigationItem.leftBarButtonItem = itemMenu;
    
    _animationView.sliderRadius.tintColor = THEME_ORANGE_COLOR;
    _animationView.sliderRadius.maximumValue = AUTO_ADJUST_DISTANCE ? [delegate getFilterDistanceMax] : MAX_RADIUS_STORE_VALUE_IN_KM;
    _animationView.sliderRadius.value = [delegate getFilterDistance];
    [_animationView.sliderRadius addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self updateLabels];
    
    [_animationView.buttonCustom addTarget:self action:@selector(showDialog) forControlEvents:UIControlEventTouchUpInside];
    
    _animationView.label2.text = [NSString stringWithFormat:@"%@ (Max: %.2f %@)",
                                  LOCALIZED(@"STORE_NEARBY_RADIUS"),
                                  [delegate getFilterDistanceMax], LOCALIZED(@"STORE_NEARBY_RADIUS_KM")];
}

-(void)sliderChanged:(UISlider*)slider {
    
    AppDelegate* delegate = [AppDelegate instance];
    float round = roundf(slider.value);
    [delegate setFilterDistance:round];
    [self updateLabels];
}

-(void)updateLabels {
    AppDelegate* delegate = [AppDelegate instance];
    _animationView.label3.text = [NSString stringWithFormat:@"%.2f %@", [delegate getFilterDistance], LOCALIZED(@"STORE_NEARBY_RADIUS_KM")];
}

-(void)didClickBarButtonMenu:(id)sender {
    AppDelegate* delegate = [AppDelegate instance];
    [delegate.sideViewController updateUI];
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

-(void)didSelectSegmentAnimation:(id)sender {
    int index = (int) [_animationView.segmentAnimation selectedSegmentIndex];
    AppDelegate* delegate = [AppDelegate instance];
    [delegate setTransitionIndex:index];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSArray  *arrayOfString = [newString componentsSeparatedByString:@"."];
    
    if ([arrayOfString count] > 2 )
        return NO;
    
    return YES;
}

-(void)showDialog {
    AppDelegate* delegate = [AppDelegate instance];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LOCALIZED(@"STORE_RADIUS")
                                                                             message:LOCALIZED(@"ENTER_RADIUS_IN_KM")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = LOCALIZED(@"ENTER_RADIUS_IN_KM");
        textField.keyboardType = UIKeyboardTypeDecimalPad;
        textField.text = [NSString stringWithFormat:@"%.2f", [delegate getFilterDistance]];
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.delegate = self;
     }];
    
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:LOCALIZED(@"CANCEL")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action){
                                                         
                                                     }];
    
    UIAlertAction *actionOk = [UIAlertAction actionWithTitle:LOCALIZED(@"OK")
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action){
                                                         UITextField* textfieldRadius = alertController.textFields.firstObject;
                                                         NSString* valueStr = textfieldRadius.text;
                                                         
                                                         float value = 0;
                                                         if([valueStr length] > 0 )
                                                             value = [valueStr floatValue];
                                                         
                                                         AppDelegate* delegate = [AppDelegate instance];
                                                         [delegate setFilterDistance:value];
                                                         [self updateLabels];
                                                     }];
    
    [alertController addAction:actionCancel];
    [alertController addAction:actionOk];
    [self presentViewController:alertController animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
