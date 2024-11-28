MODULES = jailed
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = KeychainDestroyer
DISPLAY_NAME = Example App
BUNDLE_ID = com.example.app

KeychainDestroyer_FILES = Tweak.xm
KeychainDestroyer_IPA =

include $(THEOS_MAKE_PATH)/tweak.mk
