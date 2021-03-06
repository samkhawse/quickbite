//
//  CacheService.m
//  quickbite
//
//  Created by Sam Khawase on 06/07/14.
//  Copyright (c) 2014 sifar tech. All rights reserved.
//

#import "CacheService.h"
#import "LocationDetail.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>

@interface CacheService()

@end

@implementation CacheService

+(CacheService *)sharedInstance{
    static CacheService *_sharedInstance = nil;
    static dispatch_once_t oncepPredicate;
    
    dispatch_once(&oncepPredicate, ^{
        _sharedInstance = [[CacheService init] alloc];
    });
    
    return _sharedInstance;
}

+ (NSMutableArray *)getAllLocationsForLatitude:(NSString *)latitude andLongitude:(NSString *)longitude{
    
    AppDelegate* appDelegate = [[UIApplication sharedApplication]delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
//    NSPredicate *_myPredicate = [NSPredicate predicateWithFormat:@"(firstname CONTAINS[cd] %@) OR (lastname CONTAINS[cd] %@)", _mySearchKey, _mySearchKey];

    NSRange majorRange = [latitude rangeOfString:@"."];
    NSString *latitudeMajorPart = [latitude substringToIndex:majorRange.location];
    
    NSRange minorRange =[longitude rangeOfString:@"."];
    NSString* longitudeMajorPart = [longitude substringToIndex:minorRange.location];
    
    NSPredicate *likePredicate = [NSPredicate predicateWithFormat:@"(latitude BEGINSWITH %@) AND (longitude BEGINSWITH %@)", latitudeMajorPart, longitudeMajorPart];

    NSLog(@"%@ - %@", latitudeMajorPart, longitudeMajorPart);
    
    [request setPredicate:likePredicate];
    
    NSError *fetchError;
    NSMutableArray *objects = [NSMutableArray arrayWithArray:[context executeFetchRequest:request error:&fetchError]];

    // remove objects more than 2 KM away
    NSMutableIndexSet *indexedDelete = [NSMutableIndexSet indexSet];
    NSUInteger currentIdx = 0;
    
    for (LocationDetail* aLocationObject in objects) {
        
        CLLocation *thisLocation = [[CLLocation alloc] initWithLatitude:[aLocationObject.latitude floatValue]
                                                              longitude:[aLocationObject.longitude floatValue]];
        
        CLLocation *thatLocation = [[CLLocation alloc] initWithLatitude:[latitude floatValue]
                                                              longitude:[longitude floatValue]];
        
        CLLocationDistance distance = [thisLocation distanceFromLocation:thatLocation];
        
        if (distance > 2000) {
            NSLog(@"\t %f will be removed", distance);
            [indexedDelete addIndex:currentIdx];
        }
        currentIdx++;
    }
    
    [objects removeObjectsAtIndexes:indexedDelete];
    
//    NSLog(@"Objects found in cache: %d", objects.count);
    
    return objects;
}

+ (NSArray*)saveLocationsInList:(NSArray *)fetchedLocations{
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *saveMoc = [appDelegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:saveMoc];
    
    __block NSMutableArray *arrayWithLocations = [[NSMutableArray alloc] init];
    
    for (NSDictionary *currentLocationFromJson in fetchedLocations) {

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSPredicate *checkPredicate = [NSPredicate predicateWithFormat:@"(latitude BEGINSWITH %@) AND (longitude BEGINSWITH %@)",
                                                                            [currentLocationFromJson objectForKey:@"lat"],
                                                                            [currentLocationFromJson objectForKey:@"lon"]];
        
        [fetchRequest setPredicate:checkPredicate];
        [fetchRequest setEntity:entityDescription];
        
        NSError *checkError;
        NSArray *resultsOfCheckOperation = [saveMoc executeFetchRequest:fetchRequest error:&checkError];
        
        if (resultsOfCheckOperation.count > 0) {
            //return;
            [arrayWithLocations addObject:[resultsOfCheckOperation firstObject]];
        } else {
        
            LocationDetail *location = [[LocationDetail alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:saveMoc];
            
            [location setPlace_id:[currentLocationFromJson objectForKey:@"place_id"]];
            [location setOsm_type:[currentLocationFromJson objectForKey:@"osm_type"]];
            [location setOsm_id:[currentLocationFromJson objectForKey:@"osm_id"]];
            [location setLatitude:[currentLocationFromJson objectForKey:@"lat"]];
            [location setLongitude:[currentLocationFromJson objectForKey:@"lon"]];
            [location setDisplay_name:[currentLocationFromJson objectForKey:@"display_name"]];
            
            [location setType:[currentLocationFromJson objectForKey:@"type"]];
            [location setImportance:[[currentLocationFromJson objectForKey:@"importance"] stringValue]];
            [location setIcon:[currentLocationFromJson objectForKey:@"icon"]];
            
            // append the signs for the lat-longs
            if ([location.latitude intValue] > 0) {
                location.latitude = [NSString stringWithFormat:@"+%@", location.latitude];
            } else {
                location.latitude = [NSString stringWithFormat:@"-%@", location.latitude];
            }
            
            if ([location.longitude intValue] > 0) {
                location.longitude = [NSString stringWithFormat:@"+%@", location.longitude];
            } else {
                location.longitude = [NSString stringWithFormat:@"-%@", location.longitude];
            }
            
            
            [saveMoc save:&checkError];
            
            [arrayWithLocations addObject:location];
        }
        
    }
    
    return arrayWithLocations;
    

}

/* No need for this, CLLocationDistance is better
+ (double) distanceBetweenLat1: (double)lat1
                      withLon1:(double) lon1
                       andLat2: (double) lat2
                      withLon2: (double) lon2
{
    
    double earthRadius = 6371;
    double dLat = (lat1 - lat2 * M_PI)/180;
    double dLon = (lon1 - lon2 * M_PI)/180;
    
    double sindLat = sin(dLat/2);
    double sindLon = sin(dLon/2);
    
    double a = pow(sindLat, 2) + pow(sindLon, 2) * cos(lat1 *M_PI/180) * cos(lat2 * M_PI / 180);
    
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    
    double dist = earthRadius * c;
    
    return dist;
}
*/

@end
