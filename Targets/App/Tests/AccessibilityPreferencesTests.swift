import Testing

@testable import MasalciCore

struct AccessibilityPreferencesTests {
    @Test
    func disablesDecorativeMotionWhenReduceMotionIsEnabled() {
        #expect(AccessibilityPreferences.allowsMotion(reduceMotion: false))
        #expect(!AccessibilityPreferences.allowsMotion(reduceMotion: true))
    }

    @Test
    func makesCardSurfacesOpaqueWhenReduceTransparencyIsEnabled() {
        #expect(AccessibilityPreferences.surfaceOpacity(reduceTransparency: false) == 0.92)
        #expect(AccessibilityPreferences.surfaceOpacity(reduceTransparency: true) == 1)
    }
}
