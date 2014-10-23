//
//  CollectionViewController.m
//  InstagramSelfie
//
//  Created by Kunal Shah on 23/10/14.
//  Copyright (c) 2014 Kunal Shah. All rights reserved.
//

#import "CollectionViewController.h"

@interface CollectionViewController (){
    NSMutableArray *recipeImages;
}

@end

@implementation CollectionViewController

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
//    recipeImages = [NSArray arrayWithObjects:@"angry_birds_cake.jpg", @"creme_brelee.jpg", @"egg_benedict.jpg", @"full_breakfast.jpg", @"green_tea.jpg", @"ham_and_cheese_panini.jpg", @"ham_and_egg_sandwich.jpg", @"hamburger.jpg", @"instant_noodle_with_egg.jpg", @"japanese_noodle_with_pork.jpg", @"mushroom_risotto.jpg", @"noodle_with_bbq_pork.jpg", @"starbucks_coffee.jpg", @"thai_shrimp_cake.jpg", @"vegetable_curry.jpg", @"white_chocolate_donut.jpg", nil];
    
    recipeImages = [[NSMutableArray alloc] init];
    [self loadData];

}

-(void)loadData
{
    NSData *temp = [[NSUserDefaults standardUserDefaults] objectForKey:@"instData"];
    NSMutableDictionary *object = [NSKeyedUnarchiver unarchiveObjectWithData:temp];
    NSMutableArray *photoArray = [object objectForKey:@"data"];
    
    for (int i = 0; i<[photoArray count]; i++)
    {
        NSMutableDictionary *tempDict = [photoArray objectAtIndex:i];
        NSMutableDictionary *tempDictImages = [tempDict objectForKey:@"images"];
        NSMutableDictionary *tempLowResolDict = [tempDictImages objectForKey:@"low_resolution"];
        NSString *lowResoluUrl = [tempLowResolDict objectForKey:@"url"];
        
        NSMutableDictionary *tempStandResolDict = [tempDictImages objectForKey:@"standard_resolution"];
        NSString *standResoluUrl = [tempStandResolDict objectForKey:@"url"];
        
        NSMutableDictionary *tempThumbResolDict = [tempDictImages objectForKey:@"thumbnail"];
        NSString *thumbResoluUrl = [tempThumbResolDict objectForKey:@"url"];
        
        NSLog(@"Low: %@", lowResoluUrl);
        NSLog(@"Stand: %@", standResoluUrl);
        NSLog(@"Thumb: %@", thumbResoluUrl);
        
        [recipeImages addObject:[standResoluUrl copy]];
        [recipeImages addObject:[lowResoluUrl copy]];
        [recipeImages addObject:[thumbResoluUrl copy]];
        
    }
    
    NSLog(@"%@", recipeImages);
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return recipeImages.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    
    recipeImageView.hidden = TRUE;
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSURL *url = [NSURL URLWithString:[recipeImages objectAtIndex:indexPath.row]];
        NSData *data = [NSData dataWithContentsOfURL:url];
        if ( data == nil )
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            recipeImageView.image = [UIImage imageWithData:data];
                recipeImageView.hidden = FALSE;
        });
    });
    
    
    if (indexPath.row == [recipeImages count] - 1) {
        self.objActivityIndicator.hidden = NO;
        [self.objActivityIndicator startAnimating];
        [self performSelectorInBackground:@selector(loadMoreData) withObject:nil];
//        [self loadMoreData];
    }
    
    return cell;
}

-(void)loadMoreData
{
    NSLog(@"Reached end of CollectionView");
    
    NSData *temp = [[NSUserDefaults standardUserDefaults] objectForKey:@"instData"];
    NSMutableDictionary *object = [NSKeyedUnarchiver unarchiveObjectWithData:temp];
   
    
    NSString *popularURLString = [[object objectForKey:@"pagination"] objectForKey:@"next_url"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:popularURLString]];
    request.HTTPMethod = @"GET";
    NSOperationQueue *theQ = [NSOperationQueue new];
    
    NSData *instData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    
    [NSURLConnection sendAsynchronousRequest:request queue:theQ
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               
                               
                               NSError *err;
                               id val = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
                               NSMutableDictionary *selfieDict = val;
                               
                               NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:selfieDict];
                               [[NSUserDefaults standardUserDefaults] setObject:encodedObject forKey:@"instData"];
                               [[NSUserDefaults standardUserDefaults] synchronize];
                               
                               
                               if(!err && !error && val && [NSJSONSerialization isValidJSONObject:val])
                               {
                                   NSArray *data = [val objectForKey:@"data"];
                                   
                                   dispatch_sync(dispatch_get_main_queue(), ^{
                                       
                                       if(!data)
                                       {
                                           UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to request perform request."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                           [alertView show];
                                       } else
                                       {
                                           [self performSelectorInBackground:@selector(loadData) withObject:nil];
                                           [self performSelectorInBackground:@selector(reloadData) withObject:nil];
                                           self.objActivityIndicator.hidden = YES;
                                           [self.objActivityIndicator stopAnimating];
                                       }
                                   });
                               }
                           }];
    
    
}

-(void)reloadData
{
    [self.collectionView reloadData];
}

#pragma mark -
#pragma mark UICollectionViewFlowLayoutDelegate

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    int row = [indexPath row];
    
    if (row%3==0)
    {
        // stand
        return CGSizeMake(120, 120);
    }
    else if (row%3==1)
    {
        //low
        return CGSizeMake(80, 80);
    }
    else if (row%3==2)
    {
        //        thumb
        return CGSizeMake(60, 60);
    }
    else
    {
        return CGSizeMake(140, 140);
    }
    
//
//    image = [UIImage imageNamed:_carImages[row]];
//    
//    return image.size;
    
}




@end
