import SwiftUI
import WidgetKit

@main
struct MyFiveWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextPrayerWidget()
        TodayPrayersWidget()
    }
}
