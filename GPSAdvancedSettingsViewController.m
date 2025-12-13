/*
 * GPS++
 */

#import "GPSAdvancedSettingsViewController.h"
#import "GPSLocationViewModel.h"
#import "GPSRouteManager.h"

@interface GPSAdvancedSettingsViewController ()
<UIDocumentPickerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableDictionary *settings;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation GPSAdvancedSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"GPS_ADVANCED_SETTINGS_TITLE", nil);
    
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                  target:self
                                                  action:@selector(saveButtonTapped)];
    
    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                  target:self
                                                  action:@selector(cancelButtonTapped)];
    
    self.tableView =
    [[UITableView alloc] initWithFrame:self.view.bounds
                                 style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask =
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:self.tableView];
    
    self.settings = [NSMutableDictionary dictionary];
    [self loadSettings];
}

#pragma mark - Load / Save

- (void)loadSettings {
    GPSLocationViewModel *viewModel = [GPSLocationViewModel sharedInstance];
    
    self.settings[@"movingSpeed"]  = @(viewModel.movingSpeed);
    self.settings[@"randomRadius"] = @(viewModel.randomRadius);
    self.settings[@"stepDistance"] = @(viewModel.stepDistance);
    self.settings[@"movementMode"] = @(viewModel.movementMode);
    self.settings[@"course"]       = @(0.0);
    
    self.sections = @[
        NSLocalizedString(@"SECTION_MOVEMENT_SETTINGS", nil),
        NSLocalizedString(@"SECTION_RANDOM_SETTINGS", nil),
        NSLocalizedString(@"SECTION_ROUTE_SETTINGS", nil),
        NSLocalizedString(@"SECTION_OTHER_SETTINGS", nil)
    ];
    
    [self.tableView reloadData];
}

- (void)saveButtonTapped {
    GPSLocationViewModel *viewModel = [GPSLocationViewModel sharedInstance];
    
    viewModel.movingSpeed  = [self.settings[@"movingSpeed"] doubleValue];
    viewModel.randomRadius = [self.settings[@"randomRadius"] doubleValue];
    viewModel.stepDistance = [self.settings[@"stepDistance"] doubleValue];
    viewModel.movementMode = [self.settings[@"movementMode"] intValue];
    
    [viewModel saveSettings];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelButtonTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - GPX Import

- (void)importGPXFile {
    UIDocumentPickerViewController *picker =
    [[UIDocumentPickerViewController alloc]
     initWithDocumentTypes:@[@"com.topografix.gpx"]
     inMode:UIDocumentPickerModeImport];
    
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller
 didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    
    NSURL *fileURL = urls.firstObject;
    if (!fileURL) return;
    
    NSError *error = nil;
    NSArray *points =
    [[GPSRouteManager sharedInstance]
     importGPXFromPath:fileURL.path
     error:&error];
    
    if (error || !points) {
        [self showAlertWithTitle:NSLocalizedString(@"IMPORT_FAILED", nil)
                         message:error.localizedDescription
                         ?: NSLocalizedString(@"UNKNOWN_ERROR", nil)];
    } else {
        NSString *msg =
        [NSString stringWithFormat:
         NSLocalizedString(@"IMPORT_SUCCESS_POINTS", nil),
         (unsigned long)points.count];
        
        [self showAlertWithTitle:NSLocalizedString(@"IMPORT_SUCCESS", nil)
                         message:msg];
    }
}

#pragma mark - TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    
    if (section == 0) return 2;
    if (section == 1) return 1;
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section {
    return self.sections[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *ID = @"Cell";
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (!cell) {
        cell =
        [[UITableViewCell alloc]
         initWithStyle:UITableViewCellStyleValue1
         reuseIdentifier:ID];
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text =
            NSLocalizedString(@"MOVING_SPEED", nil);
            cell.detailTextLabel.text =
            [NSString stringWithFormat:@"%.1f m/s",
             [self.settings[@"movingSpeed"] doubleValue]];
        } else {
            cell.textLabel.text =
            NSLocalizedString(@"STEP_DISTANCE", nil);
            cell.detailTextLabel.text =
            [NSString stringWithFormat:@"%.1f m",
             [self.settings[@"stepDistance"] doubleValue]];
        }
    }
    else if (indexPath.section == 1) {
        cell.textLabel.text =
        NSLocalizedString(@"RANDOM_RADIUS", nil);
        cell.detailTextLabel.text =
        [NSString stringWithFormat:@"%.1f m",
         [self.settings[@"randomRadius"] doubleValue]];
    }
    else if (indexPath.section == 2) {
        cell.textLabel.text =
        NSLocalizedString(@"IMPORT_GPX", nil);
        cell.accessoryType =
        UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = @"";
    }
    else {
        cell.textLabel.text =
        NSLocalizedString(@"COURSE", nil);
        cell.detailTextLabel.text =
        [NSString stringWithFormat:@"%.1f°",
         [self.settings[@"course"] doubleValue]];
    }
    
    return cell;
}

#pragma mark - Editor

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self showEditorForIndexPath:indexPath];
}

- (void)showEditorForIndexPath:(NSIndexPath *)indexPath {
    
    NSString *key = nil;
    NSString *title = nil;
    double value = 0;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            key = @"movingSpeed";
            title = NSLocalizedString(@"EDIT_MOVING_SPEED", nil);
        } else {
            key = @"stepDistance";
            title = NSLocalizedString(@"EDIT_STEP_DISTANCE", nil);
        }
    }
    else if (indexPath.section == 1) {
        key = @"randomRadius";
        title = NSLocalizedString(@"EDIT_RANDOM_RADIUS", nil);
    }
    else {
        key = @"course";
        title = NSLocalizedString(@"EDIT_COURSE", nil);
    }
    
    value = [self.settings[key] doubleValue];
    
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:nil
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.keyboardType = UIKeyboardTypeDecimalPad;
        tf.text = [NSString stringWithFormat:@"%.1f", value];
    }];
    
    [alert addAction:
     [UIAlertAction actionWithTitle:NSLocalizedString(@"CONFIRM", nil)
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction *a) {
        self.settings[key] =
        @([alert.textFields.firstObject.text doubleValue]);
        [self.tableView reloadData];
    }]];
    
    [alert addAction:
     [UIAlertAction actionWithTitle:NSLocalizedString(@"CANCEL", nil)
                              style:UIAlertActionStyleCancel
                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Alert Helper

- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message {
    
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:
     [UIAlertAction actionWithTitle:NSLocalizedString(@"CONFIRM", nil)
                              style:UIAlertActionStyleDefault
                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end