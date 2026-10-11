/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.taskmanager as TaskManager
import org.kde.activities as Activities
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Half the theme's card rounding
    readonly property real cardRadius: Math.max(2, Math.round(Kirigami.Units.cornerRadius / 2))

    readonly property var cfg: Plasmoid.configuration

    // Windows on this desktop and activity (and screen, if set)
    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
        virtualDesktop: virtualDesktopInfo.currentDesktop
        activity: activityInfo.currentActivity
        screenGeometry: Plasmoid.containment.screenGeometry
        filterByVirtualDesktop: true
        filterByActivity: true
        filterByScreen: root.cfg.filterByScreen === true
    }
    readonly property alias tasksModel: tasksModel

    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
    TaskManager.ActivityInfo { id: activityInfo }
    Activities.ActivityInfo { id: currentActivity; activityId: ":current" }

    readonly property string desktopName: {
        var i = virtualDesktopInfo.desktopIds.indexOf(virtualDesktopInfo.currentDesktop)
        return i >= 0 ? virtualDesktopInfo.desktopNames[i] : ""
    }

    // One object per window, so we can follow which one is active
    Item {
        visible: false
        Repeater {
            id: taskRepeater
            model: tasksModel
            delegate: Item {
                id: task
                required property int index
                required property var model

                readonly property int row: index
                readonly property string appName: model.AppName || ""
                readonly property string title: root.cleanTitle(model.display || "", appName)
                readonly property var icon: model.decoration
                readonly property bool isWindow: model.IsWindow === true && model.IsStartup !== true
                readonly property bool isActive: model.IsActive === true
                readonly property bool isMaximized: model.IsMaximized === true
                readonly property bool isMinimized: model.IsMinimized === true
                readonly property bool isKeepAbove: model.IsKeepAbove === true
                readonly property bool isOnAllDesktops: model.IsOnAllVirtualDesktops === true

                onIsActiveChanged: if (isActive) root.lastTask = task
                Component.onCompleted: if (isActive) root.lastTask = task
                Component.onDestruction: if (root.lastTask === task) root.lastTask = null
            }
        }
    }

    // The window that was active last. Opening the popup takes focus from it, so it stays the
    // current one while the popup is open
    property Item lastTask: null
    readonly property Item activeTask: lastTask && (lastTask.isActive || expanded)
        && (cfg.onlyMaximized !== true || lastTask.isMaximized) ? lastTask : null

    // Titles usually end in " — App"; keep the part that isn't the app
    function cleanTitle(display, appName) {
        var seps = [" — ", " – ", " -- ", " - "]
        var at = -1, len = 0
        for (var i = 0; i < seps.length; i++) {
            var j = display.lastIndexOf(seps[i])
            if (j > at) { at = j; len = seps[i].length }
        }
        if (at < 0) return display
        var before = display.substring(0, at)
        var after = display.substring(at + len)
        // Some apps put their name first, e.g. "App - Document"
        return appName !== "" && before.startsWith(appName) && !after.startsWith(appName) ? after : before
    }

    function fill(format) {
        var t = activeTask
        return format.split("%a").join(t ? t.appName : "")
            .split("%w").join(t ? t.title : "")
            .split("%q").join(currentActivity.name || "")
            .trim()
    }

    readonly property string text: activeTask
        ? fill(activeTask.appName === activeTask.title ? (cfg.sameFormat || "%a") : (cfg.titleFormat || "%a"))
        : fill(cfg.emptyFormat !== undefined ? cfg.emptyFormat : "%q")
    readonly property var icon: activeTask ? activeTask.icon : (currentActivity.icon || "preferences-system-windows")

    // Window actions

    function indexOf(task) { return tasksModel.makeModelIndex(task.row) }

    function activate(task) { tasksModel.requestActivate(indexOf(task)) }
    function close(task) { tasksModel.requestClose(indexOf(task)) }
    function toggleMaximized(task) { tasksModel.requestToggleMaximized(indexOf(task)) }
    function toggleMinimized(task) { tasksModel.requestToggleMinimized(indexOf(task)) }
    function toggleKeepAbove(task) { tasksModel.requestToggleKeepAbove(indexOf(task)) }
    function toggleAllDesktops(task) {
        // An empty list means every desktop
        tasksModel.requestVirtualDesktops(indexOf(task), task.isOnAllDesktops ? [virtualDesktopInfo.currentDesktop] : [])
    }

    // Activates the next or previous window in the model's order
    function cycle(step) {
        var windows = []
        for (var i = 0; i < taskRepeater.count; i++) {
            var t = taskRepeater.itemAt(i)
            if (t && t.isWindow) windows.push(t)
        }
        if (windows.length === 0) return
        var at = windows.indexOf(activeTask)
        var next = at < 0 ? 0 : (at + step + windows.length) % windows.length
        activate(windows[next])
    }

    Plasma5Support.DataSource {
        id: launcher
        engine: "executable"
        connectedSources: []
        onNewData: function(source) { disconnectSource(source) }
    }
    function showOverview() {
        launcher.connectSource("qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut Overview")
    }

    readonly property color accent: "#9C87F5"

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    compactRepresentation: CompactView {}
    fullRepresentation: FullView {}

    Plasmoid.icon: "preferences-system-windows"
    toolTipMainText: activeTask ? activeTask.appName : i18n("No active window")
    toolTipSubText: activeTask && activeTask.title !== activeTask.appName ? activeTask.title : ""
}
