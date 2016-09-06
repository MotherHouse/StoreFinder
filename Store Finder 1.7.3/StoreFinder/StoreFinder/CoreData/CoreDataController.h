//
//  CoreDataController.h
//  StoreFinder
//
//
//  Copyright (c) 2014 Mangasaur Games. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataController : NSObject

+(void)deleteAllObjects:(NSString *)entityDescription;
+(NSArray*)getFeaturedStores;
+(Photo*)getStorePhotoByStoreId:(NSString*)storeId;
+(NSArray*)getStorePhotosByStoreId:(NSString*)storeId;
+(NSArray*)getNews;
+(News*)getNewsByNewsId:(NSString*)newsId;
+(NSArray*)getCategories;
+(NSArray*) getAllStores;
+(Favorite*) getFavoriteByStoreId:(NSString*)storeId;
+(void)insertFavorite:(NSString*)storeId;
+(NSArray*) getStoreByCategoryId:(NSString*)categoryId;
+(Store*) getStoreByStoreId:(NSString*)storeId;
+(StoreCategory*) getCategoryByCategory:(NSString*)category;
+(NSArray*) getCategoryNames;
+(NSArray*) getFavoriteStores;
+(StoreCategory*) getCategoryByCategoryId:(NSString*)categoryId;

+(Photo*) getStorePhotoByPhotoId:(NSString*)photoId;
+(StoreCategory*) createInstanceStoreCategory:(NSDictionary*)dictionary;
+(Store*) createInstanceStore:(NSDictionary*)dictionary;
+(Photo*) createInstancePhoto:(NSDictionary*)dictionary;
+(News*) createInstanceNews:(NSDictionary*)dictionary;
@end
