
#import "NSUserActivity+WMFExtensions.h"
#import "MWKArticle.h"
#import "MWKTitle.h"
#import "Wikipedia-Swift.h"

@import CoreSpotlight;
@import MobileCoreServices;

@implementation NSUserActivity (WMFExtensions)

+ (void)wmf_makeActivityActive:(NSUserActivity*)activity {
    static NSUserActivity* _current = nil;

    if (_current) {
        [_current invalidate];
        _current = nil;
    }

    _current = activity;
    [_current becomeCurrent];
}

+ (instancetype)wmf_actvityWithType:(NSString*)type {
    NSUserActivity* activity = [[NSUserActivity alloc] initWithActivityType:[NSString stringWithFormat:@"org.wikimedia.wikipedia.%@", type]];
    activity.eligibleForHandoff        = YES;
    activity.eligibleForSearch         = YES;
    activity.eligibleForPublicIndexing = YES;
    activity.keywords                  = [NSSet setWithArray:@[@"Wikipedia", @"Wikimedia", @"Wiki"]];
    return activity;
}

+ (instancetype)wmf_pageActivityWithName:(NSString*)pageName {
    NSUserActivity* activity = [self wmf_actvityWithType:[pageName lowercaseString]];
    activity.title    = pageName;
    activity.userInfo = @{@"WMFPage": pageName};
    NSMutableSet* set = [activity.keywords mutableCopy];
    [set addObjectsFromArray:[pageName componentsSeparatedByString:@" "]];
    activity.keywords = set;

    return activity;
}

+ (instancetype)wmf_exploreViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Explore"];
    return activity;
}

+ (instancetype)wmf_savedPagesViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Saved"];
    return activity;
}

+ (instancetype)wmf_recentViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Recent"];
    return activity;
}

+ (instancetype)wmf_searchViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Search"];
    return activity;
}

+ (instancetype)wmf_settingsViewActivity {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Settings"];
    return activity;
}

+ (instancetype)wmf_articleViewActivityWithArticle:(MWKArticle*)article {
    NSParameterAssert(article.title.mobileURL);
    NSParameterAssert(article.title.text);
    NSParameterAssert(article.displaytitle);

    NSUserActivity* activity = [self wmf_actvityWithType:@"article"];
    activity.title      = article.displaytitle;
    activity.webpageURL = article.title.mobileURL;

    NSMutableSet* set = [activity.keywords mutableCopy];
    [set addObjectsFromArray:[article.title.text componentsSeparatedByString:@" "]];
    activity.keywords = set;

    CSSearchableItemAttributeSet* attributes = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString*)kUTTypeContent];
    if (article.imageURL) {
        NSURL* url = [NSURL URLWithString:article.imageURL];
        attributes.thumbnailData = [[WMFImageController sharedInstance] diskDataForImageWithURL:url];
    }
    attributes.contentDescription      = article.entityDescription;
    attributes.contentType             = (__bridge NSString * _Nullable)(kUTTypeItem);
    attributes.relatedUniqueIdentifier = [article.title.mobileURL absoluteString];

    activity.contentAttributeSet = attributes;
    return activity;
}

+ (instancetype)wmf_searchResultsActivityWithSearchTerm:(NSString*)searchTerm {
    NSUserActivity* activity = [self wmf_pageActivityWithName:@"Search Results"];
    activity.eligibleForSearch         = NO;
    activity.eligibleForPublicIndexing = NO;

    if (searchTerm.length > 0) {
        NSMutableDictionary* dict = [activity.userInfo mutableCopy];
        dict[@"WMFSearchTerm"] = searchTerm;
        activity.userInfo      = dict;
    }
    return activity;
}

@end
