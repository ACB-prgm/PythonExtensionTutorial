from Foundation import NSBundle, NSUserNotificationCenter, NSUserNotification
import sys


def main():
    args = sys.argv
    notify(args[1], args[2], args[3])



def notify(title="", subtitle="", body="", bundle_id="com.acbgames.Boo"):
    bundle = NSBundle.mainBundle()
    info = bundle.localizedInfoDictionary() or bundle.infoDictionary()
    info["CFBundleIdentifier"] = bundle_id

    notification = NSUserNotification.alloc().init()
    notification.setTitle_(title)
    notification.setSubtitle_(subtitle)
    notification.setInformativeText_(body)

    nc = NSUserNotificationCenter.defaultUserNotificationCenter()
    nc.deliverNotification_(notification)


if __name__ == "__main__":
    main()