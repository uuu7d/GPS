#import "GPSMapPickerViewController.h"
#import <MapKit/MapKit.h>

#import "GPSLocationModel.h"
#import "GPSFavoritesStore.h"
#import "GPSLocationSpoofer.h"

@interface GPSMapPickerViewController () <MKMapViewDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UILabel *coordinateLabel;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, strong) UIImageView *centerPin;

@end

@implementation GPSMapPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - UI Setup

- (void)setupUI {

    self.view.backgroundColor = UIColor.clearColor;

    // خلفية Blur
    UIVisualEffectView *blur =
    [[UIVisualEffectView alloc] initWithEffect:
     [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];

    blur.frame = self.view.bounds;
    blur.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:blur];

    // الخريطة
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;

    [self.view addSubview:self.mapView];

    // دبوس في المنتصف
    self.centerPin =
    [[UIImageView alloc] initWithImage:
     [UIImage systemImageNamed:@"mappin.circle.fill"]];

    self.centerPin.tintColor = UIColor.systemRedColor;
    self.centerPin.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.centerPin];

    [NSLayoutConstraint activateConstraints:@[
        [self.centerPin.centerXAnchor
         constraintEqualToAnchor:self.view.centerXAnchor],
        [self.centerPin.centerYAnchor
         constraintEqualToAnchor:self.view.centerYAnchor constant:-18]
    ]];

    // بطاقة الإحداثيات
    self.coordinateLabel = [[UILabel alloc] init];
    self.coordinateLabel.backgroundColor =
        [[UIColor blackColor] colorWithAlphaComponent:0.6];
    self.coordinateLabel.textColor = UIColor.whiteColor;
    self.coordinateLabel.font =
        [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    self.coordinateLabel.textAlignment = NSTextAlignmentCenter;
    self.coordinateLabel.layer.cornerRadius = 10;
    self.coordinateLabel.clipsToBounds = YES;
    self.coordinateLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:self.coordinateLabel];

    // زر التأكيد
    self.confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.confirmButton setTitle:@"📍 确认位置"
                        forState:UIControlStateNormal];

    self.confirmButton.titleLabel.font =
        [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];

    self.confirmButton.backgroundColor = UIColor.systemBlueColor;
    [self.confirmButton setTitleColor:UIColor.whiteColor
                             forState:UIControlStateNormal];

    self.confirmButton.layer.cornerRadius = 14;
    self.confirmButton.translatesAutoresizingMaskIntoConstraints = NO;

    [self.confirmButton addTarget:self
                           action:@selector(confirmTapped)
                 forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:self.confirmButton];

    // Layout
    [NSLayoutConstraint activateConstraints:@[
        [self.coordinateLabel.topAnchor
         constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor
                        constant:12],
        [self.coordinateLabel.centerXAnchor
         constraintEqualToAnchor:self.view.centerXAnchor],
        [self.coordinateLabel.widthAnchor
         constraintEqualToConstant:260],
        [self.coordinateLabel.heightAnchor
         constraintEqualToConstant:36],

        [self.confirmButton.bottomAnchor
         constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor
                        constant:-20],
        [self.confirmButton.centerXAnchor
         constraintEqualToAnchor:self.view.centerXAnchor],
        [self.confirmButton.widthAnchor
         constraintEqualToConstant:260],
        [self.confirmButton.heightAnchor
         constraintEqualToConstant:52]
    ]];

    // موقع افتراضي (شنغهاي)
    CLLocationCoordinate2D start =
        CLLocationCoordinate2DMake(31.230525, 121.473667);

    MKCoordinateRegion region =
        MKCoordinateRegionMakeWithDistance(start, 1000, 1000);

    [self.mapView setRegion:region animated:NO];
    [self updateCoordinateLabel:start];
}

#pragma mark - Map Delegate

- (void)mapView:(MKMapView *)mapView
regionDidChangeAnimated:(BOOL)animated {

    CLLocationCoordinate2D center = mapView.centerCoordinate;
    [self updateCoordinateLabel:center];
}

#pragma mark - Helpers

- (void)updateCoordinateLabel:(CLLocationCoordinate2D)coord {

    self.coordinateLabel.text =
        [NSString stringWithFormat:
         @"纬度: %.6f   经度: %.6f",
         coord.latitude,
         coord.longitude];
}

#pragma mark - Action

- (void)confirmTapped {

    // 1) أخذ الإحداثيات من مركز الخريطة
    CLLocationCoordinate2D center =
        self.mapView.centerCoordinate;

    // 2) إنشاء نموذج الموقع
    GPSLocationModel *model =
        [[GPSLocationModel alloc]
         initWithLatitude:center.latitude
                longitude:center.longitude];

    // 3) حفظ الموقع كمفضل
    [[GPSFavoritesStore shared] saveLocation:model];

    // 4) تفعيل التزييف
    CLLocation *fakeLocation = [model asCLLocation];
    [[GPSLocationSpoofer shared] enableWithLocation:fakeLocation];

    NSLog(@"[GPSInjector] Spoofing enabled: %.6f , %.6f",
          center.latitude,
          center.longitude);

    // 5) إغلاق الواجهة
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end