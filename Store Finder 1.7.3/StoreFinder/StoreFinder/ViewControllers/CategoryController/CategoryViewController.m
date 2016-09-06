//
//  CategoryViewController.m
//  StoreFinder
//
//
//  Copyright (c) 2014 Mangasaur Games. All rights reserved.
//

#import "CategoryViewController.h"
#import "StoreViewController.h"
#import "AppDelegate.h"

@interface CategoryViewController () <MGListViewDelegate>

@end

@implementation CategoryViewController

@synthesize listViewMain;

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
    
    
    UIBarButtonItem* itemMenu = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BUTTON_MENU]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(didClickBarButtonMenu:)];
    self.navigationItem.leftBarButtonItem = itemMenu;
    
    [self performSelector:@selector(update) withObject:nil afterDelay:SELECTOR_DELAY];
}

-(void)update {
    listViewMain.delegate = self;
    BOOL screen = IS_IPHONE_6_PLUS_AND_ABOVE;
    listViewMain.cellHeight = screen ? 66 : 44;
    [listViewMain registerNibName:@"CategoryCell" cellIndentifier:@"CategoryCell"];
    [listViewMain baseInit];
    [listViewMain addSubviewRefreshControlWithTintColor:THEME_BLACK_TINT_COLOR];
    [self beginParsing];
    
    if(SHOW_ADS_CATEGORY_VIEW) {
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
}

-(void)didClickBarButtonMenu:(id)sender {
    AppDelegate* delegate = [AppDelegate instance];
    [delegate.sideViewController updateUI];
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


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
        [listViewMain reloadData];
        
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
        @try {
            NSString* strUrl = [NSString stringWithFormat:@"%@?api_key=%@",
                                GET_CATEGORIES_JSON_URL,
                                API_KEY];
            return [DataParser getJSONAtURL:strUrl];
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
        [CoreDataController deleteAllObjects:@"StoreCategory"];
        NSDictionary* dictEntry = [dict objectForKey:@"categories"];
        for(NSDictionary* dictCat in dictEntry) {
            [CoreDataController createInstanceStoreCategory:dictCat];
        }
        NSError* error;
        if ([context hasChanges] && ![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    listViewMain.arrayData = [NSMutableArray arrayWithArray:[CoreDataController getCategories]];
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
    StoreViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"storyboardStore"];
    vc.storeCategory = listViewMain.arrayData[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

-(UITableViewCell*)MGListView:(MGListView *)listView1 didCreateCell:(MGListCell *)cell indexPath:(NSIndexPath *)indexPath {
    if(cell != nil) {
        StoreCategory* cat = [listViewMain.arrayData objectAtIndex:indexPath.row];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        
        [cell.labelTitle setText:[cat.category stringByDecodingHTMLEntities]];
        [self setImage:cat.category_icon imageView:cell.imgViewThumb];
    }
    return cell;
}

-(void)MGListView:(MGListView *)listView scrollViewDidScroll:(UIScrollView *)scrollView {
    
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
                                UIImage* croppedImage = [image imageByScalingAndCroppingForSize:size];
                                weakImgRef.image = croppedImage;
                            } failure:^(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error) { }];
}

-(void)MGListView:(MGListView *)listView didRefreshStarted:(UIRefreshControl *)refreshControl {
    [refreshControl endRefreshing];
    [self beginParsing];
}

@end
