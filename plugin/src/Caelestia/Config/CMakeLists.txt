qml_module(caelestia-config
    URI Caelestia.Config
    SOURCES
        config.cpp
        configattached.cpp
        configlist.cpp
        confignode.cpp
        configobject.cpp
        rootconfig.cpp
        i18n.cpp
        i18n.hpp
        appearanceconfig.cpp
        font.cpp
        fontbuilder.cpp
        tokens.cpp
        tokensattached.cpp
        anim.cpp
        monitorconfigmanager.cpp
        backgroundconfig.hpp
        barconfig.hpp
        borderconfig.hpp
        dashboardconfig.hpp
        generalconfig.hpp
        launcherconfig.hpp
        lockconfig.hpp
        nexusconfig.hpp
        notifsconfig.hpp
        osdconfig.hpp
        quickpanelconfig.hpp
        serviceconfig.hpp
        sessionconfig.hpp
        sidebarconfig.hpp
        userpaths.hpp
        utilitiesconfig.hpp
        winfoconfig.hpp
    LIBRARIES
        Qt::Quick
        Qt::QuickControls2
)

set_source_files_properties(translations/caelestia_zh_CN.qm PROPERTIES
    QT_RESOURCE_ALIAS caelestia_zh_CN.qm
)
qt_add_resources(caelestia-config "caelestia-translations"
    PREFIX "/caelestia/i18n"
    FILES
        translations/caelestia_zh_CN.qm
)
