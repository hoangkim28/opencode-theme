import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "#211E1E"

    property int stage

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
            source: "images/wordmark.png"
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
            color: "#2A2626"

            Rectangle {
                id: progressFill
                width: parent.width * (root.stage / 5)
                height: parent.height
                radius: parent.radius
                color: "#FAB283"
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
