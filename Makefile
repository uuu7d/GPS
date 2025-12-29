ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0

THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GPSInjector

GPSInjector_FILES = \
Entry/Tweak.x \
Core/GPSManager.m \
Core/GPSLocationSpoofer.m \
Models/GPSLocationModel.m \
Favorites/GPSFavoritesStore.m \
UI/GPSMapPickerViewController.m

GPSInjector_CFLAGS = -fobjc-arc
GPSInjector_FRAMEWORKS = UIKit CoreLocation MapKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk