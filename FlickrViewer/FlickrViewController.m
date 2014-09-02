//
//  FlickrViewController.m
//  FlickrViewer
//
//  Created by Ivan Magda on 02.09.14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import "FlickrViewController.h"
#import "PhotoDetailViewController.h"
#import "PSRClassWichPerformsAsyncOperations.h"
#import "PSRFlickrAPI.h"
#import "PSRFlickrPhoto.h"
#import "CollectionViewCell.h"


static const int kNumberOfPhotosThatAreVisible = 6;


@interface FlickrViewController ()

@property (nonatomic, strong) PSRFlickrSearchOptions *searchOptions;

@end


@implementation FlickrViewController {
    NSMutableArray *_photos;
    NSMutableArray *_parsedPhotosInfo;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    PSRFlickrSearchOptions *options = [[PSRFlickrSearchOptions alloc]init];
    options.extra = @[@"original_format",
                      @"tags",
                      @"description",
                      @"geo",
                      @"date_upload",
                      @"owner_name"];
    self.searchOptions = options;
}

- (IBAction)showPhotos:(UIButton *)sender {
    _photos = [[NSMutableArray alloc]init];
    _parsedPhotosInfo = [[NSMutableArray alloc]init];
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        [self.collectionView reloadData];
    });
    
    PSRClassWichPerformsSomethingWithComplitionBlock *customClassWithComplition = [PSRClassWichPerformsSomethingWithComplitionBlock new];
    
    [customClassWithComplition performSomeOperationWithSearchOptions:self.searchOptions complition:^(id result) {
        [self showPhotosFromEnumerator:[result objectEnumerator]];
    }];
}

- (void)showPhotosFromEnumerator:(NSEnumerator *)enumerator {
    dispatch_queue_t downloadQueue = dispatch_queue_create("download queue", 0);
    dispatch_async(downloadQueue, ^{
        PSRFlickrPhoto *parsedPhoto = [enumerator nextObject];
        if (!parsedPhoto){
            return;
        }
        [_parsedPhotosInfo addObject:parsedPhoto];
        
        NSData *photoData = [NSData dataWithContentsOfURL:[parsedPhoto highQualityURL]];
        
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_async(mainQueue, ^{
            [_photos addObject:[UIImage imageWithData:photoData]];
            
            NSLog(@"%@",_photos);
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_photos.count - 1 inSection:0];
            
            if (indexPath.row < kNumberOfPhotosThatAreVisible) {
                CollectionViewCell *cell = (CollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                NSAssert(cell, @"Cell does not exist!");
                cell.photo.image = _photos[indexPath.row];
            }
            
            [self showPhotosFromEnumerator:enumerator];
        });
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self configurateSearchOptionsWithTextFiled:textField];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    [self configurateSearchOptionsWithTextFiled:textField];
}

- (void)configurateSearchOptionsWithTextFiled:(UITextField *)textField {
    if (textField.keyboardType == UIKeyboardTypeNumberPad) {
        NSString *itemsLimit = self.numberOfPhotosTextField.text;
        self.searchOptions.itemsLimit = [itemsLimit intValue];
    } else {
        self.searchOptions.tags = @[self.tagTextField.text];
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.searchOptions.itemsLimit;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CollectionViewCell *collectionCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (collectionCell) {
        if (indexPath.row > kNumberOfPhotosThatAreVisible - 1) {
            collectionCell.photo.image = _photos[indexPath.row];
        }
    }
    
    return collectionCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ShowDetail" sender:indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowDetail"]) {
        NSIndexPath *path = sender;
        NSParameterAssert(path);
        
        PhotoDetailViewController *controller = segue.destinationViewController;
        controller.photoToShowDetail = _parsedPhotosInfo[path.row];
        controller.imageToShow = _photos[path.row];
    }
}

@end