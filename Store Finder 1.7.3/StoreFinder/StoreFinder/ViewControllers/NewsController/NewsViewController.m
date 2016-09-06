//
//  NewsViewController.m
//  StoreFinder
//
//
//  Copyright (c) 2014 Mangasaur Games. All rights reserved.
//

#import "NewsViewController.h"
#import "NewsDetailViewController.h"
#import "AppDelegate.h"

@interface NewsViewController () <MGListViewDelegate>

@end

@implementation NewsViewController

@synthesize listViewNews;


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
    listViewNews.delegate = self;
    BOOL screen = IS_IPHONE_6_PLUS_AND_ABOVE;
    listViewNews.cellHeight = screen ? 260 : 220;
    [listViewNews registerNibName:@"NewsCell" cellIndentifier:@"NewsCell"];
    [listViewNews baseInit];
    [listViewNews addSubviewRefreshControlWithTintColor:THEME_BLACK_TINT_COLOR];
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
    
    __block NSDictionary* dictJSON;
    [hud showAnimated:YES whileExecutingBlock:^{
        dictJSON = [self performParsing];
    } completionBlock:^{
        [hud removeFromSuperview];
        [self.view setUserInteractionEnabled:YES];
        [self setData:dictJSON];
        [listViewNews reloadData];
        
        if(listViewNews.arrayData == nil || listViewNews.arrayData.count == 0) {
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
                                GET_NEWS_JSON_URL,
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
        
        NSDictionary* dictEntry = [dict objectForKey:@"news"];
        for(NSDictionary* dict in dictEntry) {
            [CoreDataController createInstanceNews:dict];

        }
        
        NSError* error;
        if ([context hasChanges] && ![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    listViewNews.arrayData = [NSMutableArray arrayWithArray:[CoreDataController getNews]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setImage:(NSString*)imageUrl imageView:(UIImageView*)imgView {
    
    NSURL* url = [NSURL URLWithString:imageUrl];
    NSURLRequest* urlRequest = [NSURLRequest requestWithURL:url];
    
    __weak typeof(imgView ) weakImgRef = imgView;
    UIImage* imgPlaceholder = [UIImage imageNamed:LIST_NEWS_PLACEHOLDER];
    
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
        [cell.labelTitle setText:[news.news_title stringByDecodingHTMLEntities]];
        [cell.labelSubtitle setText:[news.news_content stringByDecodingHTMLEntities]];
        
        double createdAt = [news.created_at doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:createdAt];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        
        NSString *formattedDateString = [dateFormatter stringFromDate:date];
        [cell.labelDetails setText:formattedDateString];
        cell.labelDetails.textColor = THEME_ORANGE_COLOR;
        
        [self setImage:news.photo_url imageView:cell.imgViewThumb];
    }
    
    return cell;
}

-(void)MGListView:(MGListView *)listView scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

-(void)MGListView:(MGListView *)listView didRefreshStarted:(UIRefreshControl *)refreshControl {
    
    [refreshControl endRefreshing];
    [self beginParsing];
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
