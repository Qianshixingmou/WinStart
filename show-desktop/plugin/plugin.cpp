#include <QQmlExtensionPlugin>
#include <qqml.h>

#include "showdesktop.h"

class QianshiShowDesktopPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterType<ShowDesktop>(uri, 1, 0, "ShowDesktop");
    }
};

#include "plugin.moc"
