//
//  SHMultipleSelect.h
//  Bugzilla
//
//  Created by Shamsiddin Saidov on 07/22/2015.
//  Copyright (c) 2015 shamsiddin.saidov@gmail.com. All rights reserved.
//

#import "SHMultipleSelect.h"

#define MAIN_SCREEN_RECT [[UIScreen mainScreen] bounds]

@interface SHMultipleSelect ()
- (void)btnClick:(UIButton *)sender;
@end


@implementation SHMultipleSelect
{
    //To preserve selection after selectAll has been selected and then deselected
    NSArray *selectedIBackup;
    NSMutableArray *items;
    NSMutableArray *itemsSelected;
    NSMutableArray *itemsFiltered;
    NSMutableArray *itemsFilteredSelected;
    NSString* searchTerm;
    UIBarButtonItem* doneButton;
}

const int selectionRowHeight = 40;
const int selectionBtnHeight = 40;
const int selectionLeftMargin = 10;
const int selectionTopMargin = 30;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, MAIN_SCREEN_RECT.size.width, MAIN_SCREEN_RECT.size.height);
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        self.layer.opacity = 0;
        
        _table = [[UITableView alloc] init];
        _table.dataSource = self;
        _table.delegate = self;
        _table.scrollEnabled = NO;
        _table.allowsMultipleSelectionDuringEditing = YES;
        [_table setEditing:YES animated:NO];
        
        _tableScroll = [[UIScrollView alloc] init];
        
        items = [NSMutableArray new];
        itemsFiltered = [NSMutableArray new];
        itemsSelected = [NSMutableArray new];
        itemsFilteredSelected = [NSMutableArray new];
        
        _searchBar = [[UISearchBar alloc] init];
        _searchBar.delegate = self;
        
        _cancelBtn = [[UIButton alloc] init];
        _doneBtn = [[UIButton alloc] init];
        _btnsSeparator = [[UIView alloc] init];
        
        _coverView = [[UIView alloc] init];
        
        self.hasSelectAll = NO;
        
        doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStylePlain target:self action:@selector(dismissKeyboard)];
        UIToolbar* toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.width, 44)];
        toolBar.items = @[doneButton];
        _searchBar.inputAccessoryView = toolBar;
    }
    return self;
}

#pragma mark - Process Info

- (void)processInfo {
    [items removeAllObjects];
    [itemsFiltered removeAllObjects];
    [itemsSelected removeAllObjects];
    [itemsFilteredSelected removeAllObjects];
    
    for (int i = 0; i < self.rowsCount; i++) {
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        if ([_delegate respondsToSelector:@selector(multipleSelectView:titleForRowAtIndexPath:)]) {
            NSString* text = [_delegate multipleSelectView:self titleForRowAtIndexPath:indexPath];
            [items addObject:[text copy]];
            [itemsFiltered addObject:[text copy]];
        }
        
        NSNumber* selected = [NSNumber numberWithBool:NO];
        if ([_delegate respondsToSelector:@selector(multipleSelectView:setSelectedForRowAtIndexPath:)]) {
            BOOL isSelected = [_delegate multipleSelectView:self setSelectedForRowAtIndexPath:indexPath];
            selected = [NSNumber numberWithBool:isSelected];
        }
        [itemsSelected addObject:[selected copy]];
        [itemsFilteredSelected addObject:[selected copy]];
    }
    
    
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [itemsFiltered removeAllObjects];
    [itemsFilteredSelected removeAllObjects];
    
    for (int i = 0; i < self.rowsCount; i++) {
        NSString* item      = [items objectAtIndex:i];
        NSString* selected  = [itemsSelected objectAtIndex:i];
        
        if ([searchText isEqualToString:@""]) {
            [itemsFiltered addObject:[item copy]];
            [itemsFilteredSelected addObject:[selected copy]];
            continue;
        }
        
        NSRange searchedStringRange = [item rangeOfString:searchText
                                                  options:NSCaseInsensitiveSearch
                                       | NSDiacriticInsensitiveSearch
                                       | NSWidthInsensitiveSearch];
        // location was found == should be displayed
        BOOL containsString = searchedStringRange.location != NSNotFound;
        if(containsString == TRUE) {
            [itemsFiltered addObject:[item copy]];
            [itemsFilteredSelected addObject:[selected copy]];
        }
        
    }
    
    _table.reloadData;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self endEditing:YES];
}

- (void)dismissKeyboard
{
    [self endEditing:YES];
}

- (NSInteger)numberOfItemsSelected {
    NSInteger totalItemsSelected = 0;
    for (int i = 0; i < [itemsFilteredSelected count]; i++) {
        if([itemsFilteredSelected[i] isEqualToNumber:@1]) {
            totalItemsSelected++;
        }
    }
    return totalItemsSelected;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [itemsFiltered count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [itemsFiltered objectAtIndex:indexPath.row];
    
    BOOL selected = NO;
    if([[itemsFilteredSelected objectAtIndex:indexPath.row] isEqualToNumber:@YES]) {
        selected = YES;
    }
    
    if (selected) {
        [_table selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.hasSelectAll && (indexPath.row==0)) {
        
        selectedIBackup = _table.indexPathsForSelectedRows;
        
        for (int i=1; i<[itemsFiltered count]; i++) {
            [_table selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        
    }
    
    [itemsFilteredSelected replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:YES]];
    NSString* stringSelected = [itemsFiltered objectAtIndex:indexPath.row];
    for (int i=0; i<[items count]; i++) {
        NSString* item      = [items objectAtIndex:i];
        if([item isEqualToString:stringSelected]) {
            [itemsSelected replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:YES]];
        }
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(multipleSelectView:didSelectRowAtIndexPath:)]) {
        [_delegate multipleSelectView:self didSelectRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.hasSelectAll && (indexPath.row==0)) {
        for (int i=1; i<self.rowsCount; i++) {
            [_table deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
        }
    }
    else if (self.hasSelectAll) {
        [_table deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO];
    }
    
    [itemsFilteredSelected replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:NO]];
    NSString* stringSelected = [itemsFiltered objectAtIndex:indexPath.row];
    for (int i=0; i<[items count]; i++) {
        NSString* item      = [items objectAtIndex:i];
        if([item isEqualToString:stringSelected]) {
            [itemsSelected replaceObjectAtIndex:i withObject:[NSNumber numberWithBool:NO]];
        }
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(multipleSelectView:didDeselectRowAtIndexPath:)]) {
        [_delegate multipleSelectView:self didDeselectRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return selectionRowHeight;
}

- (void)show {
    
    //Fixes an issue when triggerring while keyboard is showing
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.layer.opacity = 1;
    }];
    
    _coverView.frame = CGRectMake(selectionLeftMargin, 0, MAIN_SCREEN_RECT.size.width - (2 * selectionLeftMargin), 0);
    _coverView.layer.cornerRadius = 7;
    _coverView.clipsToBounds = YES;
    _coverView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_coverView];
    
    _tableScroll.frame = CGRectMake(0, 0, _coverView.width, 0);
    
    // table settings
    CGFloat allRowsHeight = selectionRowHeight * _rowsCount + 44;
    
    if (allRowsHeight + 100 > self.height) {
        _coverView.top = selectionTopMargin;
        _coverView.height = self.height - (2 * selectionTopMargin);
    }
    else {
        _coverView.top = (self.height - (allRowsHeight + selectionBtnHeight))/2;
        _coverView.height = allRowsHeight + selectionBtnHeight;
    }
    
    _tableScroll.top = 0;
    _tableScroll.height = _coverView.height - selectionBtnHeight;
    
    _tableScroll.contentSize = CGSizeMake(_tableScroll.width, allRowsHeight);
    [_coverView addSubview:_tableScroll];
    
    _searchBar.frame = CGRectMake(0.0, 0.0, _tableScroll.width, 44.0);
    //    [_tableScroll addSubview:_searchBar];
    _table.tableHeaderView = _searchBar;
    
    _table.frame = CGRectMake(0.0, 0.0, _tableScroll.width, allRowsHeight);
    [_tableScroll addSubview:_table];
    
    UIImage *btnImageNormal = [[UIImage imageWithColor:[UIColor whiteColor]
                                                  size:CGSizeMake(10, 10)] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
    UIImage *btnImageHighlighted = [[UIImage imageWithColor:[UIColor colorWithRed:208/255.0f green:208/255.0f blue:208/255.0f alpha:1.0f]
                                                       size:CGSizeMake(10, 10)] stretchableImageWithLeftCapWidth:3 topCapHeight:3];
    
    // _cancelBtn settings
    _cancelBtn.frame = CGRectMake(0, _tableScroll.bottom, _coverView.width/2, selectionBtnHeight);
    _cancelBtn.tag = 0;
    [_cancelBtn setTitle:NSLocalizedString(@"Cancel", @"Cancel") forState:UIControlStateNormal];
    [_cancelBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_cancelBtn setBackgroundImage:btnImageNormal forState:UIControlStateNormal];
    [_cancelBtn setBackgroundImage:btnImageHighlighted forState:UIControlStateHighlighted];
    [_cancelBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_coverView addSubview:_cancelBtn];
    
    // _doneBtn settings
    _doneBtn.frame = CGRectMake(_cancelBtn.right, _tableScroll.bottom, _coverView.width/2, selectionBtnHeight);
    _doneBtn.tag = 1;
    [_doneBtn setTitle:NSLocalizedString(@"Done", @"Done") forState:UIControlStateNormal];
    [_doneBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_doneBtn setBackgroundImage:btnImageNormal forState:UIControlStateNormal];
    [_doneBtn setBackgroundImage:btnImageHighlighted forState:UIControlStateHighlighted];
    [_doneBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_coverView addSubview:_doneBtn];
    
    // btnsSeparator settings
    _btnsSeparator.frame = CGRectMake(_cancelBtn.right, _tableScroll.bottom, 0.7, selectionBtnHeight);
    _btnsSeparator.backgroundColor = [UIColor lightGrayColor];
    [_coverView addSubview:_btnsSeparator];
    
    [self processInfo];
    
    [[[[UIApplication sharedApplication] delegate] window] addSubview:self];
}

- (void)btnClick:(UIButton *)sender {
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.layer.opacity = 0;
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                         if (_delegate && [_delegate respondsToSelector:@selector(multipleSelectView:clickedBtnAtIndex:withSelectedIndexPaths:)]) {
                             // Create list of selectedIndexPaths
                             NSMutableArray* selectedIndexPaths = [@[] mutableCopy];
                             for (int i = 0; i < [itemsSelected count]; i++) {
                                 if([[itemsSelected objectAtIndex:i] isEqualToNumber:@YES]) {
                                     NSIndexPath* indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                                     [selectedIndexPaths addObject:indexPath];
                                 }
                             }
                             [_delegate multipleSelectView:self clickedBtnAtIndex:sender.tag withSelectedIndexPaths:selectedIndexPaths];
                         }
                     }];
}

@end
