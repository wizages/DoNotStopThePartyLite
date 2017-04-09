SDKVERSION = 10.1
SYSROOT = $(THEOS)/sdks/iPhoneOS10.1.sdk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DoNotStopThePartyLite
DoNotStopThePartyLite_FILES = Tweak.xm
DoNotStopThePartyLite_PRIVATE_FRAMEWORKS = MediaRemote SpringboardServices

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += donotstopapps
SUBPROJECTS += playerassertdhook
include $(THEOS_MAKE_PATH)/aggregate.mk
