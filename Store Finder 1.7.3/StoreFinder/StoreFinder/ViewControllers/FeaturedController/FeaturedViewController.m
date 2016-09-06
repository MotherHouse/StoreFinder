//
//  FeaturedViewController.m
//  StoreFinder
//
//
//  Copyright (c) 2014 Mangasaur Games. All rights reserved.
//

#import "FeaturedViewController.h"
#import "DetailViewController.h"
#import "AppDelegate.h"

@interface FeaturedViewController () <MGListViewDelegate> {
    
    NSDictionary* _dictJSON;
}

@end

@implementation FeaturedViewController

@synthesize listViewMain;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
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
    
    listViewMain.delegate = self;
    
    BOOL screen = IS_IPHONE_6_PLUS_AND_ABOVE;
    listViewMain.cellHeight = screen ? 300 : 250;
    
    [listViewMain registerNibName:@"SearchResultCell" cellIndentifier:@"SearchResultCell"];
    [listViewMain baseInit];
    
    
    UIBarButtonItem* itemMenu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BUTTON_MENU]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(didClickBarButtonMenu:)];
    self.navigationItem.leftBarButtonItem = itemMenu;
    
    if(SHOW_ADS_FEATURED_VIEW) {
        [MGUtilities createAdAtY:self.view.frame.size.height - AD_BANNER_HEIGHT
                  viewController:self
                         bgColor:AD_BG_COLOR];
        
        UIEdgeInsets inset = listViewMain.tableView.contentInset;
        inset.bottom = ADV_VIEW_OFFSET;
        listViewMain.tableView.contentInset = inset;
        
        inset = listViewMain.tableView.scrollIndicatorInsets;
        inset.bottom = ADV_VIEW_OFFSET;
        listViewMain.tableView.scrollIndicatorInsets = inset;
    }
    
    [self beginParsing];
}

-(void)didClickBarButtonMenu:(id)sender {
    
    AppDelegate* delegate = [AppDelegate instance];
    [delegate.sideViewController updateUI];
    
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

-(void)beginParsing {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = LOCALIZED(@"LOADING");
    
    [self.view addSubview:hud];
    [self.view setUserInteractionEnabled:NO];
	[hud showAnimated:YES whileExecutingBlock:^{
        
		_dictJSON = [self performParsing];
        
	} completionBlock:^{
        
		[hud removeFromSuperview];
        [self.view setUserInteractionEnabled:YES];
        
        [self setData:_dictJSON];
        
        if(listViewMain.arrayData == nil || listViewMain.arrayData.count == 0) {
            
            UIColor* color = [THEME_ORANGE_COLOR colorWithAlphaComponent:0.70];
            [MGUtilities showStatusNotifier:LOCALIZED(@"NO_RESULTS")
                                  textColor:[UIColor whiteColor]
                             viewController:self
                                   duration:0.5f
                                    bgColor:color
                                        atY:64];
        }
    }];
    
}

-(NSDictionary*) performParsing {
    if(WILL_DOWNLOAD_DATA && [MGUtilities hasInternetConnection]) {
        AppDelegate* delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        @try {
            float radius = [delegate getFilterDistance];
            if(radius == 0)
                radius = DEFAULT_FILTER_DISTANCE_IN_KM;
            
            CLLocation* loc = delegate.myLocation;
            if(loc != nil) {
                NSString* strUrl = [NSString stringWithFormat:@"%@?api_key=%@&lat=%f&lon=%f&radius=%f&featured=1",
                                    GET_STORES_JSON_URL,
                                    API_KEY,
                                    loc.coordinate.latitude,
                                    loc.coordinate.longitude,
                                    radius];
                return [DataParser getJSONAtURL:strUrl];
            }
        }
        @catch (NSException *exception) {
            NSLog(@"exception = %@", exception.debugDescription);
        }
    }
    return nil;
}

//-(void) performParsing {
//    
//    NSArray* arrayStores = [CoreDataController getFeaturedStores];
//    AppDelegate* instance = [AppDelegate instance];
//    if(instance.myLocation != nil && RANK_STORES_ACCORDING_TO_NEARBY) {
//        for(Store* store in arrayStores) {
//            CLLocationCoordinate2D coord;
//            coord = CLLocationCoordinate2DMake([store.lat doubleValue], [store.lon doubleValue]);
//            CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
//            
//            double distance = [instance.myLocation distanceFromLocation:location];
//            store.distance = [NSString stringWithFormat:@"%f", distance];
//        }
//        
//        NSArray *sortedArray = [arrayStores sortedArrayUsingComparator: ^(Store* obj1, Store* obj2) {
//            if ([obj1.distance floatValue] == 0 && [obj2.distance floatValue] == 0) {
//                return (NSComparisonResult)NSOrderedSame;
//            }
//            if ([obj1.distance floatValue] < [obj2.distance floatValue]) {
//                return (NSComparisonResult)NSOrderedAscending;
//            }
//            return (NSComparisonResult)NSOrderedDescending;
//        }];
//        
//        listViewMain.arrayData = [NSMutableArray new];
//        
//        float distance = [instance getFilterDistance];
//        for(Store* store in sortedArray) {
//            double km = [store.distance floatValue] / 1000;
//            if( km <= distance)
//               [listViewMain.arrayData addObject:store];
//        }
//    }
//    else {
//        listViewMain.arrayData = [NSMutableArray arrayWithArray:arrayStores];
//    }
//}

-(void) setData:(NSDictionary*)dict {
    
    AppDelegate* delegate = [AppDelegate instance];
    NSManagedObjectContext* context = delegate.managedObjectContext;
    
    listViewMain.arrayData = [NSMutableArray new];
    if(dict != nil) {
        NSDictionary* dictEntry = [dict objectForKey:@"stores"];
        for(NSDictionary* dictStore in dictEntry) {
            Store* store = [CoreDataController createInstanceStore:dictStore];
            [listViewMain.arrayData addObject:store];
            
            NSDictionary* dictPhotos = [dictStore objectForKey:@"photos"];
            for(NSDictionary* dictPhoto in dictPhotos) {
                [CoreDataController createInstancePhoto:dictPhoto];
            }
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
    else if(delegate.myLocation != nil && RANK_STORES_ACCORDING_TO_NEARBY) {
        NSArray* arrayStores = [CoreDataController getFeaturedStores];
        for(Store* store in arrayStores) {
            CLLocationCoordinate2D coord;
            coord = CLLocationCoordinate2DMake([store.lat doubleValue], [store.lon doubleValue]);
            CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
            double distance = [delegate.myLocation distanceFromLocation:location] / 1000;
            store.distance = [NSString stringWithFormat:@"%f", distance];
        }
        
        NSArray *sortedArray = [arrayStores sortedArrayUsingComparator: ^(Store* obj1, Store* obj2) {
            if ([obj1.distance floatValue] == 0 && [obj2.distance floatValue] == 0) {
                return (NSComparisonResult)NSOrderedSame;
            }
            if ([obj1.distance floatValue] < [obj2.distance floatValue]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedDescending;
        }];
        
        float distance = [delegate getFilterDistance];
        for(Store* store in sortedArray) {
            double km = [store.distance floatValue] / 1000;
            if( km <= distance)
                [listViewMain.arrayData addObject:store];
        }
    }
    else {
        NSArray* arrayStores = [CoreDataController getFeaturedStores];
        listViewMain.arrayData = [NSMutableArray arrayWithArray:arrayStores];
    }
    
    [listViewMain reloadData];
}

- (void)didReceiveMemoryWarning {
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

-(void) MGListView:(MGListView *)_listView didSelectCell:(MGListCell *)cell indexPath:(NSIndexPath *)indexPath {
    DetailViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"storyboardDetail"];
    vc.store = listViewMain.arrayData[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

-(UITableViewCell*)MGListView:(MGListView *)listView1 didCreateCell:(MGListCell *)cell indexPath:(NSIndexPath *)indexPath {
    
    if(cell != nil) {
        Store* store = [listViewMain.arrayData objectAtIndex:indexPath.row];
        Photo* p = [CoreDataController getStorePhotoByStoreId:store.store_id];
        Favorite* fave = [CoreDataController getFavoriteByStoreId:store.store_id];
        
        cell.imgViewFeatured.hidden = NO;
        cell.imgViewFave.hidden = NO;
        
        if(fave == nil)
            cell.imgViewFave.hidden = YES;
        
        if([store.featured intValue] < 1)
            cell.imgViewFeatured.hidden = YES;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        
        [cell.labelDescription setText:store.phone_no];
        
        if(p != nil)
            [self setImage:p.thumb_url imageView:cell.imgViewThumb];
        else
            [self setImage:nil imageView:cell.imgViewThumb];
        
        
        cell.labelHeader1.backgroundColor = [BLACK_TEXT_COLOR colorWithAlphaComponent:0.66];
        
        cell.lblNonSelectorTitle.textColor = THEME_ORANGE_COLOR;
        cell.labelSubtitle.textColor = WHITE_TEXT_COLOR;
        
        cell.lblNonSelectorTitle.text = [store.store_name stringByDecodingHTMLEntities];
        cell.labelSubtitle.text = [store.store_address stringByDecodingHTMLEntities];
        
        cell.ratingView.notSelectedImage = [UIImage imageNamed:STAR_EMPTY];
        cell.ratingView.halfSelectedImage = [UIImage imageNamed:STAR_HALF];
        cell.ratingView.fullSelectedImage = [UIImage imageNamed:STAR_FILL];
        cell.ratingView.editable = YES;
        cell.ratingView.maxRating = 5;
        cell.ratingView.midMargin = 0;
        cell.ratingView.userInteractionEnabled = NO;
        
        double rating = [store.rating_total doubleValue]/[store.rating_count doubleValue];
        cell.ratingView.rating = rating;
        
        NSString* info = [NSString stringWithFormat:@"%.2f %@ %@ %@", rating, LOCALIZED(@"RATING_AVERAGE"), store.rating_count, LOCALIZED(@"RATING")];
        
        if([store.rating_total doubleValue] == 0 || [store.rating_count doubleValue] == 0 )
            info = LOCALIZED(@"NO_RATING");
        
        cell.labelExtraInfo.text = info;
        
        cell.labelDetails.backgroundColor = [BLACK_TEXT_COLOR colorWithAlphaComponent:0.66];
        if(store.distance == nil) {
            [cell.labelDetails setText:LOCALIZED(@"NO_DISTANCE_SEARCH")];
            cell.labelDetails.hidden = YES;
        }
        else {
            double km = [store.distance doubleValue];
            NSString* strKm = [NSString stringWithFormat:@"%.2f %@", km, LOCALIZED(@"KILOMETERS")];
            [cell.labelDetails setText:strKm];
            cell.labelDetails.hidden = NO;
        }
    }
    return cell;
}

-(void)MGListView:(MGListView *)listView scrollViewDidScroll:(UIScrollView *)scrollView { }

-(void)setImage:(NSString*)imageUrl imageView:(UIImageView*)imgView {
    
    NSURL* url = [NSURL URLWithString:imageUrl];
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
    
    __weak typeof(imgView ) weakImgRef = imgView;
    UIImage* imgPlaceholder = [UIImage imageNamed:LIST_STORE_PLACEHOLDER];
    
    [MGUtilities createBorders:weakImgRef
                   borderColor:THEME_MAIN_COLOR
                   shadowColor:[UIColor clearColor]
                   borderWidth:CELL_BORDER_WIDTH];
    
    [imgView setImageWithURLRequest:urlRequest
                   placeholderImage:imgPlaceholder
                            success:^(NSURLRequest* request, NSHTTPURLResponse* response, UIImage* image) {
                                CGSize size = weakImgRef.frame.size;
                                if([MGUtilities isRetinaDisplay]) {
                                    size.height *= 2;
                                    size.width *= 2;
                                }
                                UIImage* croppedImage = [image imageByScalingAndCroppingForSize:size];
                                weakImgRef.image = croppedImage;
                            } failure:^(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error) { }];
}


@end
