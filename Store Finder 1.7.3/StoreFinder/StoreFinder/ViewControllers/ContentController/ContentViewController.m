//
//  ContentViewController.m
//  ItemFinder
//
//
//  Copyright (c) 2014 Mangasaur Games. All rights reserved.
//

#import "ContentViewController.h"
#import "AppDelegate.h"
#import "NewsDetailViewController.h"
#import "DetailViewController.h"

@interface ContentViewController () <MGSliderDelegate, MGListViewDelegate, LocationDelegate> {
    
    BOOL _didAcquireLocation;
}

@property (nonatomic, retain) NSArray* arrayFeatured;

@end

@implementation ContentViewController

@synthesize slider;
@synthesize listViewNews;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(slider != nil)
        [slider resumeAnimation];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(slider != nil)
        [slider stopAnimation];
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
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIBarButtonItem* itemMenu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BUTTON_MENU]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(didClickBarButtonMenu:)];
    self.navigationItem.leftBarButtonItem = itemMenu;
    
    [self performSelector:@selector(update) withObject:nil afterDelay:SELECTOR_DELAY];
}

-(void)update {
    slider.nibName = @"SliderView";
    slider.delegate = self;
    BOOL screen = IS_IPHONE_6_PLUS_AND_ABOVE;
    if(screen) {
        CGRect frame = slider.frame;
        frame.size.width = self.view.frame.size.width;
        frame.size.height = 230;
        slider.frame = frame;
        
        frame = listViewNews.frame;
        frame.origin.y = slider.frame.origin.y + slider.frame.size.height;
        frame.size.height = self.view.frame.size.height - slider.frame.size.height-64;
        listViewNews.frame = frame;
    }
    listViewNews.delegate = self;
    listViewNews.cellHeight = screen ? 240 : 180;
    [listViewNews registerNibName:@"NewsCell" cellIndentifier:@"NewsCell"];
    [listViewNews baseInit];
    
    
    if(SHOW_ADS_MAIN_VIEW) {
        [MGUtilities createAdAtY:self.view.frame.size.height - AD_BANNER_HEIGHT
                  viewController:self
                         bgColor:AD_BG_COLOR];
        
        UIEdgeInsets inset = listViewNews.tableView.contentInset;
        inset.bottom = ADV_VIEW_OFFSET;
        listViewNews.tableView.contentInset = inset;
        
        inset = listViewNews.tableView.scrollIndicatorInsets;
        inset.bottom = ADV_VIEW_OFFSET;
        listViewNews.tableView.scrollIndicatorInsets = inset;
        NSLog(@"%@", NSStringFromCGRect(listViewNews.tableView.frame));
    }
    
    AppDelegate* delegate = [AppDelegate instance];
    delegate.locationDelegate = self;
    [delegate findMyCurrentLocation];
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

-(void)beginParsing {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = LOCALIZED(@"LOADING");
    
    [self.view addSubview:hud];
    [self.view setUserInteractionEnabled:NO];
    
    __block NSDictionary* dictJSON;
	[hud showAnimated:YES whileExecutingBlock:^{
		dictJSON = [self performParsing];
	} completionBlock:^{
		[hud removeFromSuperview];
        [self.view setUserInteractionEnabled:YES];
        [self setData:dictJSON];
        
	}];
}

-(NSDictionary*) performParsing {
    if(WILL_DOWNLOAD_DATA && [MGUtilities hasInternetConnection]) {
        AppDelegate* delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        @try {
            float radius = [delegate getFilterDistance];
            CLLocation* loc = delegate.myLocation;
            if(loc != nil) {
                NSString* strUrl = @"";
                if(radius == 0) {
                    strUrl = [NSString stringWithFormat:@"%@?api_key=%@&lat=%f&lon=%f&radius=%f&news_count=%d&featured_count=%d&default_store_count_to_find_distance=%d",
                                        GET_HOME_STORES_NEWS_JSON_URL,
                                        API_KEY,
                                        loc.coordinate.latitude,
                                        loc.coordinate.longitude,
                                        radius,
                                        HOME_NEWS_COUNT,
                                        HOME_FEATURED_COUNT,
                                        DEFAULT_STORE_COUNT_TO_FIND_DISTANCE];
                }
                else {
                    strUrl = [NSString stringWithFormat:@"%@?api_key=%@&lat=%f&lon=%f&radius=%f&news_count=%d&default_store_count_to_find_distance=%d",
                              GET_HOME_STORES_NEWS_JSON_URL,
                              API_KEY,
                              loc.coordinate.latitude,
                              loc.coordinate.longitude,
                              radius,
                              HOME_NEWS_COUNT,
                              DEFAULT_STORE_COUNT_TO_FIND_DISTANCE];
                }
                
                return [DataParser getJSONAtURL:strUrl];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"exception = %@", exception.debugDescription);
        }
    }
    return nil;
}

-(void) setData:(NSDictionary*)dict {
    if(dict != nil) {
        AppDelegate* delegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
        NSManagedObjectContext* context = delegate.managedObjectContext;
        [CoreDataController deleteAllObjects:@"Photo"];
        [CoreDataController deleteAllObjects:@"Store"];
        [CoreDataController deleteAllObjects:@"News"];
        
        NSDictionary* dictEntry = [dict objectForKey:@"stores"];
        for(NSDictionary* dictStore in dictEntry) {
            [CoreDataController createInstanceStore:dictStore];
            NSDictionary* dictPhotos = [dictStore objectForKey:@"photos"];
            for(NSDictionary* dictPhoto in dictPhotos) {
                [CoreDataController createInstancePhoto:dictPhoto];
            }
        }
        
        dictEntry = [dict objectForKey:@"news"];
        for(NSDictionary* dictNews in dictEntry) {
            [CoreDataController createInstanceNews:dictNews];
        }
        
        NSError* error;
        if ([context hasChanges] && ![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        if(AUTO_ADJUST_DISTANCE) {
            NSString* maxDistanceStr = [dict valueForKey:@"max_distance"];
            NSString* defaultDistanceStr = [dict valueForKey:@"default_distance"];
            
            float maxDistance = [maxDistanceStr floatValue];
            float defaultDistance = [defaultDistanceStr floatValue];
            
            if(maxDistance > 0)
                [delegate setFilterDistanceMax:maxDistance];
            
            if(defaultDistance > 0 && [delegate getFilterDistance] == 0)
                [delegate setFilterDistance:defaultDistance];
        }
    }
    
    NSArray* arrayStores = [CoreDataController getFeaturedStores];
    AppDelegate* instance = [AppDelegate instance];
    int count = arrayStores.count < HOME_STORE_FEATURED_COUNT ? (int)arrayStores.count : HOME_STORE_FEATURED_COUNT;
    if(HOME_STORE_FEATURED_COUNT == -1)
        count = (int)arrayStores.count;
    
    if(instance.myLocation != nil && RANK_STORES_ACCORDING_TO_NEARBY) {
        NSMutableArray* array = [NSMutableArray new];
        for(int x = 0; x < count; x++) {
            Store* store = arrayStores[x];
            CLLocationCoordinate2D coord;
            coord = CLLocationCoordinate2DMake([store.lat doubleValue], [store.lon doubleValue]);
            CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
            double distance = [instance.myLocation distanceFromLocation:location] / 1000;
            store.distance = [NSString stringWithFormat:@"%f", distance];
            [array addObject:arrayStores[x]];
        }
    
        NSArray *sortedArray = [array sortedArrayUsingComparator: ^(Store* obj1, Store* obj2) {
            if ([obj1.distance floatValue] == 0 && [obj2.distance floatValue] == 0) {
                return (NSComparisonResult)NSOrderedSame;
            }
            if ([obj1.distance floatValue] < [obj2.distance floatValue]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedDescending;
        }];
        self.arrayFeatured = sortedArray;
    }
    else {
        NSMutableArray* array = [NSMutableArray new];
        for(int x = 0; x < count; x++) {
            [array addObject:arrayStores[x]];
        }
        self.arrayFeatured = array;
    }
    slider.numberOfItems = count;
    
    [slider setNeedsReLayoutWithViewSize:CGSizeMake(self.view.frame.size.width, slider.frame.size.height)];
    [slider startAnimationWithDuration:4.0f];
//    [slider showPageControl:YES];
    
    if(listViewNews.arrayData == nil)
        listViewNews.arrayData = [NSMutableArray new];
    
    [listViewNews.arrayData removeAllObjects];
    NSArray* arrayNews = [CoreDataController getNews];
    count = arrayNews.count < HOME_NEWS_COUNT ? (int)arrayNews.count : HOME_NEWS_COUNT;
    if(HOME_NEWS_COUNT == -1)
        count = (int)arrayNews.count;
    
    for(int x = 0; x < count; x++) {
        [listViewNews.arrayData addObject:arrayNews[x]];
    }
    
    [listViewNews reloadData];
}

-(void)MGSlider:(MGSlider *)slider didCreateSliderView:(MGRawView *)rawView atIndex:(int)index {
    
    Store* store = self.arrayFeatured[index];
    Photo* p = [CoreDataController getStorePhotoByStoreId:store.store_id];
    
    rawView.label1.backgroundColor = [BLACK_TEXT_COLOR colorWithAlphaComponent:0.66];
    rawView.labelTitle.textColor = WHITE_TEXT_COLOR;
    rawView.labelSubtitle.textColor = WHITE_TEXT_COLOR;
    rawView.labelTitle.text = [store.store_name stringByDecodingHTMLEntities];
    rawView.labelSubtitle.text = [store.store_address stringByDecodingHTMLEntities];
    if(p != nil)
        [self setImage:p.photo_url imageView:rawView.imgViewPhoto];
    
    rawView.buttonGo.object = store;
    [rawView.buttonGo addTarget:self
                         action:@selector(didClickButtonGo:)
               forControlEvents:UIControlEventTouchUpInside];
    
    rawView.labelDetails.backgroundColor = [BLACK_TEXT_COLOR colorWithAlphaComponent:0.66];
    if(store.distance == nil) {
        [rawView.labelDetails setText:LOCALIZED(@"NO_DISTANCE_SEARCH")];
        rawView.labelDetails.hidden = YES;
    }
    else {
        double km = [store.distance doubleValue];
        NSString* strKm = [NSString stringWithFormat:@"%.2f %@", km, LOCALIZED(@"KILOMETERS")];
        [rawView.labelDetails setText:strKm];
        rawView.labelDetails.hidden = NO;
    }
}

-(void)didClickButtonGo:(id)sender {
    MGButton* button = (MGButton*)sender;
    DetailViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"storyboardDetail"];
    vc.store = button.object;
    [self.navigationController pushViewController:vc animated:YES];
}

-(void)MGSlider:(MGSlider *)slider didSelectSliderView:(MGRawView *)rawView atIndex:(int)index {
    
}

-(void)MGSlider:(MGSlider *)slider didPageControlClicked:(UIButton *)button atIndex:(int)index {
    
}

-(void)setImage:(NSString*)imageUrl imageView:(UIImageView*)imgView {
    NSURL* url = [NSURL URLWithString:imageUrl];
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
    __weak typeof(imgView ) weakImgRef = imgView;
    UIImage* imgPlaceholder = [UIImage imageNamed:SLIDER_PLACEHOLDER];
    
    [imgView setImageWithURLRequest:urlRequest
                   placeholderImage:imgPlaceholder
                            success:^(NSURLRequest* request, NSHTTPURLResponse* response, UIImage* image) {
                                
                                CGSize size = weakImgRef.frame.size;
                                
                                if([MGUtilities isRetinaDisplay]) {
                                    size.height *= 2;
                                    size.width *= 2;
                                }
                                
                                if(IS_IPHONE_6_PLUS_AND_ABOVE) {
                                    size.height *= 3;
                                    size.width *= 3;
                                }
                                
                                UIImage* croppedImage = [image imageByScalingAndCroppingForSize:size];
                                weakImgRef.image = croppedImage;
                                
                            } failure:^(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error) {
                                
                            }];
}

-(void) MGListView:(MGListView *)_listView didSelectCell:(MGListCell *)cell indexPath:(NSIndexPath *)indexPath {
    News* news = [listViewNews.arrayData objectAtIndex:indexPath.row];
    NewsDetailViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"storyboardNewsDetail"];
    vc.strUrl = news.news_url;
    [self.navigationController pushViewController:vc animated:YES];
}

-(UITableViewCell*)MGListView:(MGListView *)listView1 didCreateCell:(MGListCell *)cell indexPath:(NSIndexPath *)indexPath {
    if(cell != nil) {
        News* news = [listViewNews.arrayData objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.selectedColor = THEME_ORANGE_COLOR;
        cell.unSelectedColor = THEME_ORANGE_COLOR;
        cell.labelExtraInfo.backgroundColor = [BLACK_TEXT_COLOR colorWithAlphaComponent:0.66];
        cell.labelDetails.backgroundColor = [BLACK_TEXT_COLOR colorWithAlphaComponent:0.66];
        
        [cell setBackgroundColor:[UIColor clearColor]];
        [cell.labelTitle setText:news.news_title];
        [cell.labelSubtitle setText:news.news_content];
        
        double createdAt = [news.created_at doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:createdAt];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        
        NSString *formattedDateString = [dateFormatter stringFromDate:date];
        [cell.labelDetails setText:formattedDateString];
        cell.labelDetails.textColor = THEME_ORANGE_COLOR;
        if(news.photo_url != nil)
            [self setImage:news.photo_url imageView:cell.imgViewThumb];
        else
            [self setImage:nil imageView:cell.imgViewThumb];
        
        [MGUtilities createBorders:cell.imgViewThumb
                       borderColor:THEME_BLACK_TINT_COLOR
                       shadowColor:[UIColor clearColor]
                       borderWidth:CELL_BORDER_WIDTH];
    }
    return cell;
}

-(void)MGListView:(MGListView *)listView scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

-(void)appDelegate:(AppDelegate *)appDelegate locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    [MGUtilities showAlertTitle:LOCALIZED(@"LOCATION_SERVICE_ERROR")
                        message:LOCALIZED(@"LOCATION_SERVICE_ERROR_PROBLEMS_GETTING")];
    
    [self beginParsing];
}

-(void)appDelegate:(AppDelegate *)appDelegate locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [manager stopUpdatingLocation];
    
    if(!_didAcquireLocation) {
        _didAcquireLocation = YES;
        [self beginParsing];
    }
    
}

-(void)appDelegate:(AppDelegate *)appDelegate sensorError:(CLLocationManager *)manager {
    
    [MGUtilities showAlertTitle:LOCALIZED(@"LOCATION_SERVICE_ERROR")
                        message:LOCALIZED(@"LOCATION_SERVICE_ERROR_OFF_GPS")];
    
    [self beginParsing];
}

@end
