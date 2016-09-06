//
//  WeatherViewController.m
//  StoreFinder
//
//
//  Copyright (c) 2014 Mangasaur Games. All rights reserved.
//

#import "WeatherViewController.h"
#import "AppDelegate.h"

@interface WeatherViewController () <CLLocationManagerDelegate>{
    
     MGRawView* _weatherView;
    CLLocationManager* _myLocationManager;
    CLLocation* _myLocation;
    NSString* _strTemp;
    NSString* _desc;
    NSString* _icon;
}

@end

@implementation WeatherViewController

@synthesize scrollViewMain;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.titleView = [MGUIAppearance createLogo:HEADER_LOGO];
    self.view.backgroundColor = BG_VIEW_COLOR;
    
    [MGUIAppearance enhanceNavBarController:self.navigationController
                               barTintColor:WHITE_TEXT_COLOR
                                  tintColor:WHITE_TEXT_COLOR
                             titleTextColor:WHITE_TEXT_COLOR];
    
    _weatherView = [[MGRawView alloc] initWithNibName:@"WeatherView"];
    
    CGRect frame = scrollViewMain.frame;
    frame.size.height -= 64;
    _weatherView.frame = frame;
    
    BOOL screen = IS_IPHONE_6_PLUS_AND_ABOVE;
    if(screen) {
        frame = _weatherView.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = self.view.frame.size.height;
        _weatherView.frame = frame;
    }

    scrollViewMain.frame = self.view.frame;
    scrollViewMain.contentSize = _weatherView.frame.size;
    [scrollViewMain addSubview:_weatherView];
    
    _weatherView.label1.text = LOCALIZED(@"EMPTY_WEATHER");
    _weatherView.label2.text = LOCALIZED(@"EMPTY_WEATHER");
    _weatherView.label3.text = LOCALIZED(@"EMPTY_WEATHER");
    
    [self findMyCurrentLocation];
    UIBarButtonItem* itemMenu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BUTTON_MENU]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(didClickBarButtonMenu:)];
    self.navigationItem.leftBarButtonItem = itemMenu;
    

}

-(void)didClickBarButtonMenu:(id)sender {
    
    AppDelegate* delegate = [AppDelegate instance];
    [delegate.sideViewController updateUI];
    
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - FIND USER LOCATION

-(void)findMyCurrentLocation {
    
    _myLocationManager = [[CLLocationManager alloc] init];
    _myLocationManager.delegate = self;
    
    if(IS_OS_8_OR_LATER) {
        [_myLocationManager requestWhenInUseAuthorization];
        [_myLocationManager requestAlwaysAuthorization];
    }
    
    [_myLocationManager startUpdatingLocation];
    
    if( [CLLocationManager locationServicesEnabled] ) {
        NSLog(@"Location Services Enabled....");
    }
    else {
        [MGUtilities showAlertTitle:LOCALIZED(@"LOCATION_SERVICE_ERROR")
                            message:LOCALIZED(@"LOCATION_SERVICE_NOT_ENABLED")];
    }
    
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    _myLocation = newLocation;
    [manager stopUpdatingLocation];
    [self beginParsing];
}


- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error {
    
    [MGUtilities showAlertTitle:LOCALIZED(@"LOCATION_SERVICE_ERROR")
                        message:error.localizedDescription];
    
}

-(void)beginParsing {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = LOCALIZED(@"UPDATING");
    
    [self.view addSubview:hud];
	[self.view setUserInteractionEnabled:NO];
    
	[hud showAnimated:YES whileExecutingBlock:^{
        
		[self startParsing];
        
	} completionBlock:^{
        
		[hud removeFromSuperview];
        [self.view setUserInteractionEnabled:YES];
        
        if(_strTemp != nil)
            _weatherView.label1.text = _strTemp;
        
        if(_desc != nil)
            _weatherView.label2.text = _desc;
        
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
        [geocoder reverseGeocodeLocation:_myLocation
                       completionHandler:^(NSArray *placemarks, NSError *error) {
                           
                           if (error){
                               NSLog(@"Geocode failed with error: %@", error);
                               return;
                           }
                           
                           CLPlacemark* placemark = [placemarks objectAtIndex:0];
                           NSDictionary* dic = placemark.addressDictionary;
                           
                           NSString* city = @"";
                           NSString* country = @"";
                           NSString* street = @"";
                           NSString* zipCode = @"";
                           
                           if([dic valueForKey:@"City"] != nil)
                               city = [[dic valueForKey:@"City"] stringByAppendingString:@", "];
                           
                           if([dic valueForKey:@"Country"] != nil)
                               country = [dic valueForKey:@"Country"];
                           
                           if([dic valueForKey:@"Street"] != nil)
                               street = [[dic valueForKey:@"Street"] stringByAppendingString:@", "];
                           
                           if([dic valueForKey:@"Country"] != nil)
                               zipCode = [dic valueForKey:@"ZIP"];
                           
                           NSString* fullAddress = [NSString stringWithFormat:@"%@%@%@", street, city, country];
                           
                           _weatherView.label3.text = fullAddress;
                       }];
        
	}];
    
}

-(void)startParsing {
    
    NSString* weatherUrl = [NSString stringWithFormat:@"%@lat=%f&lon=%f&APPID=%@",
                            WEATHER_URL,
                            _myLocation.coordinate.latitude,
                            _myLocation.coordinate.longitude,
                            WEATHER_APP_ID];
    
    NSDictionary* dict = [MGParser getJSONAtURL:weatherUrl];
    
    if(dict == nil)
        return;
    
    NSDictionary* weatherDict = [dict objectForKey:@"weather"];
    
    if(weatherDict == nil)
        return;
    
    NSDictionary* mainDict = [dict objectForKey:@"main"];
    
    if(mainDict == nil)
        return;
    
    NSString* kelvin = [mainDict valueForKey:@"temp"];
    
    if(kelvin == nil)
        return;
    
    float celsius = [kelvin floatValue] - 273.15;
//    float fahrenheit = (celsius * 1.8) + 32 ;
    
    _strTemp = [NSString stringWithFormat:@"%.1f %@",
                         celsius,
                         LOCALIZED(@"CELSIUS")];
    
    _desc = nil;
    _icon = nil;
    
    for(NSDictionary* wDict in weatherDict) {
        
        _desc = [wDict valueForKey:@"description"];
        _icon = [wDict valueForKey:@"icon"];
    }
    
    if(_icon != nil) {
        NSString* newIcon = [NSString stringWithFormat:@"%@%@.png", ICON_URL, _icon];
        _icon = newIcon;
    }
}


-(void)setImage:(NSString*)imageUrl imageView:(UIImageView*)imgView {
    
    NSURL* url = [NSURL URLWithString:imageUrl];
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
    
    __weak typeof(imgView ) weakImgRef = imgView;
    UIImage* imgPlaceholder = [UIImage new];
    
    [imgView setImageWithURLRequest:urlRequest
                   placeholderImage:imgPlaceholder
                            success:^(NSURLRequest* request, NSHTTPURLResponse* response, UIImage* image) {
                                
                                weakImgRef.image = image;
                                
                            } failure:^(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error) {
                                
                                
                            }];
}

@end
