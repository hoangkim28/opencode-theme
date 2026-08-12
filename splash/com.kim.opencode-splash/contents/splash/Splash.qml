import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: Kirigami.Theme.backgroundColor

    property int stage
    readonly property bool darkBackground: {
        const c = Kirigami.Theme.backgroundColor;
        return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b < 0.5;
    }

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: logo
            anchors.centerIn: parent
            asynchronous: true
            source: root.darkBackground ? "images/wordmark.png" : "images/wordmark-light.png"
            sourceSize.width: Math.min(parent.width * 0.45, 1400)
            sourceSize.height: Math.min(parent.width * 0.45 / 5.57, 260)
            fillMode: Image.PreserveAspectFit
        }

        Rectangle {
            id: progressBar
            width: logo.paintedWidth * 0.55
            height: 3
            radius: 1.5
            anchors {
                top: logo.bottom
                topMargin: Kirigami.Units.largeSpacing * 2
                horizontalCenter: parent.horizontalCenter
            }
            color: Qt.rgba(
                Kirigami.Theme.textColor.r,
                Kirigami.Theme.textColor.g,
                Kirigami.Theme.textColor.b,
                0.18
            )

            Rectangle {
                id: progressFill
                width: parent.width * (Math.max(0, Math.min(root.stage, 5)) / 5)
                height: parent.height
                radius: parent.radius
                color: Kirigami.Theme.highlightColor
            }
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
